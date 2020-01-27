classdef ConvTransform < SISOUnit & FeedforwardOperation & Evolvable
    % NOTE: currently ConvTransform use convolution in 'SAME' shape
    methods
        function y = dataproc(obj, x)
            xset = ConvTransform.decomposeData(x, obj.stride);
            y = ConvTransform.conv2d(xset, obj.WSet, obj.bias);
        end
        
        % NOTE: omit output parameter of dW and dB can save calculation
        %       power in case they are not necessary, such as, when
        %       hyperparameter is frozen.
        function dX = deltaproc(obj, dY)
            x = obj.I{1}.datarcd.pop();
            % decompose input data into stride group
            [xset, xpadding] = ConvTransform.decomposeData(x, obj.stride);
            % branch of whether or not update hypter-parameters
            if obj.pkginfo.updateHParam
                [dXSet, dWSet, dB] = ConvTransform.grad2d(dY, xset, obj.WSet);
                % compose gradient of data and filter
                dX = ConvTransform.composeData(dXSet, xpadding);
                dW = ConvTransform.composeFilter(dWSet, obj.WPadding);
                % update hyper-parameters
                obj.W.addgrad(dW);
                obj.B.addgrad(dB);
            else
                dXSet = ConvTransform.grad2d(dY, xset, obj.WSet);
                dX = ConvTransform.composeData(dXSet, xpadding);
            end
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.W, obj.B};
        end
        
        function update(obj)
            update@Evolvable(obj);
            [obj.WSet, obj.WPadding] = ConvTransform.decomposeFilter(obj.weight, obj.stride);
        end
    end
    
    methods
        function sizeinfo = sizeIn2Out(obj, sizeinfo)
            sizeinfo(3) = size(obj.W, 4);
        end
        
        function sizeinfo = sizeOut2In(obj, sizeinfo)
            sizeinfo(3) = size(obj.W, 3);
        end
        
        function value = smpsize(~, ~)
            error('UNSUPPORTED');
        end
    end
    
    methods
        function obj = ConvTransform(weight, bias, stride)
            % normalize stride
            if not(exist('stride', 'var'))
                obj.stride = [1, 1];
            elseif numel(stride) == 1
                obj.stride = stride * [1, 1];
            end
            % initialize filter and bias
            obj.W = HyperParam(weight);
            obj.B = HyperParam(reshape(bias, 1, 1, numel(bias)));
            % initialize filter set and corresponding padding information
            [obj.WSet, obj.WPadding] = ConvTransform.decomposeFilter(weight, obj.stride);
            % initialize IO
            obj.I = {UnitAP(obj, 3, '-recdata')};
            obj.O = {UnitAP(obj, 3)};
        end
    end
    
    methods (Static)
        function [xset, xpadding] = decomposeData(x, stride)
            [xset, xpadding] = getStrideSet(x, stride);
        end
        
        function x = composeData(xset, xpadding)
            [h, w]       = size(xset{1});
            [m, n, c, s] = size(xset);
            % combine matrix in cell array
            x = cat(3, xset{:});
            x = reshape(x, [h, w, m, n, c, s]);
            x = permute(x, [3, 1, 4, 2, 5, 6]);
            x = reshape(x, [h * m, w * n, c, s]);
            % remove zero-padding
            x = x(1 : end - xpadding(1), 1 : end - xpadding(2), :, :);
        end
        
        function [wset, wpadding] = decomposeFilter(w, stride)
            referPoint = ceil(([size(w, 1), size(w, 2)] + 1) / 2);
            [wset, wpadding] = getStrideSet(w, stride, referPoint, 'reverse');
        end
        
        function weight = composeFilter(wset, wpadding)
            [h, w]       = size(wset{1});
            [m, n, c, f] = size(wset);
            % flip cell array in both 1st and 2nd dimension
            wset = flip(flip(wset, 1), 2);
            % combine matrix in cell array
            weight = cat(3, wset{:});
            weight = reshape(weight, [h, w, m, n, c, f]);
            weight = permute(weight, [3, 1, 4, 2, 5, 6]);
            weight = reshape(weight, [h * m, w * n, c, f]);
            % remove zero-padding
            weight = weight( ...
                wpadding(1) + 1 : end - wpadding(3), wpadding(2) + 1 : end - wpadding(4), :, :);
        end
    end
    
    methods (Static)
        function y = conv2d(x, f, bias)
            buffer = cell(size(f, 4), size(x, 4));
            for m = 1 : size(x, 4) % for each sample
                for n = 1 : size(f, 4) % for each output layer
                    buffer{n, m} = 0;
                    for i = 1 : size(x, 1)
                        for j = 1 : size(x, 2)
                            for k = 1 : size(x, 3)
                                buffer{n, m} = buffer{n, m} + conv2(x{i, j, k}, f{i, j, k, n}, 'same');
                            end
                        end
                    end
                end
            end
            % combine cells into a matrix
            temp = cell(size(x, 4), 1);
            for m = 1 : numel(temp)
                temp{m} = cat(3, buffer{:, m});
            end
            y = cat(4, temp{:});
            % add bias
            y = bsxfun(@plus, y, reshape(bias, [1, 1, numel(bias)]));
        end
        
        function [dXSet, dWSet, dB] = grad2d(d, xset, wset)
        % NOTE: this function is based on the fact that all the filter in WSET has odd
        %       width and length. If this is not established, the calculation will be
        %       wrong.
            
            dXSet = cell(size(xset));
            % put output gradient in cell array
            dY = cell(size(d, 3), size(d, 4));
            for s = 1 : size(d, 4)
                for c = 1 : size(d, 3)
                    dY{c, s} = d(:, :, c, s);
                end
            end
            % flip filter matrix
            wflip = cell(size(wset));            
            for i = 1 : numel(wset)
                wflip{i} = flip(flip(wset{i}, 1), 2);
            end
            % calculate gradients of input
            for s = 1 : size(xset, 4)
                for k = 1 : size(xset, 3) 
                    for j = 1 : size(xset, 2)
                        for i = 1 : size(xset, 1)
                            buffer = 0;
                            for c = 1 : size(d, 3)
                                buffer = buffer + conv2(dY{c, s}, wflip{i, j, k, c}, 'same');
                            end
                            dXSet{i, j, k, s} = buffer;
                        end
                    end
                end
            end
            % calculate filter gradient
            if nargout > 1
                dWSet = cell(size(wset));
                % calculate padding size
                padsize = (size(wset{1}) - 1) / 2;
                % pad output gradients
                d = padarray(d, padsize, 0, 'both');
                for s = 1 : size(d, 4)
                    for c = 1 : size(d, 3)
                        dY{c, s} = d(:, :, c, s);
                    end
                end
                % flip input matrix
                xflip = cell(size(xset));
                for i = 1 : numel(xset)
                    xflip{i} = flip(flip(xset{i}, 1), 2);
                end
                % calculate filter's gradients
                for c = 1 : size(wset, 4)
                    for k = 1 : size(wset, 3)
                        for j = 1 : size(wset, 2)
                            for i = 1 : size(wset, 1)
                                buffer = 0;
                                for s = 1 : size(d, 4)
                                    buffer = buffer + conv2(dY{c, s}, xflip{i, j, k, s}, 'valid');
                                end
                                dWSet{i, j, k, c} = buffer;
                            end
                        end
                    end
                end               
            end
            % calculate gradients of bias
            if nargout > 2
                dB = MathLib.margin(d, 3);
                dB = reshape(dB, 1, 1, numel(dB));
            end
        end
    end
    
    methods (Static)
        function obj = randinit(fltsize, nchannel, nfilter)
            obj = ConvTransform( ...
                HyperParam.randct(fltsize, nchannel, nfilter), ...
                zeros(nfilter, 1));
        end
        
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            sizein   = [probScale, probScale];
            nfilter  = ceil(log2(probScale));
            fltsize  = ceil(sqrt(sizein));
            nchannel = nfilter;
            % reference model
            refer = ConvTransform.randinit(fltsize, nchannel, nfilter);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            refer.update();
            % approximate model
            model = ConvTransform.randinit(fltsize, nchannel, nfilter);
            % data generator
            dataset = DataGenerator('normal', [sizein, nchannel]);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, dataset, objective);
            task.run(niter, batchsize, validsize);
        end
    end
    
    properties (Constant, Hidden)
        taxis = false;
    end
    
    properties (Access = protected)
        W, B, WSet, WPadding, stride
    end
    
    properties (Dependent)
        weight, bias
    end
    methods
        function value = get.weight(obj)
            value = obj.W.get();
        end
        function set.weight(obj, value)
            obj.W.set(value);
            [obj.WSet, obj.WPadding] = ConvTransform.decomposeFilter(value, obj.stride);
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
end