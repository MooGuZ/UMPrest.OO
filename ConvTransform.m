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
            % calculate padding information
            obj.padding.top    = floor(size(weight, 1) / 2);
            obj.padding.bottom = floor((size(weight, 1) - 1) / 2);
            obj.padding.left   = floor(size(weight, 2) / 2);
            obj.padding.right  = floor((size(weight, 2) - 1) / 2);
            % normalize stride
            if not(exist('stride', 'var'))
                obj.stride = [1, 1];
            elseif numel(stride) == 1
                obj.stride = stride * [1, 1];
            end
            % prepare filter according to stride
            if obj.useStride
                obj.W = obj.prepareFilter(weight, stride);
            else
                obj.W = HyperParam(weight); 
            end
            obj.B = HyperParam(reshape(bias, 1, 1, numel(bias)));
            % initialize IO
            obj.I = {UnitAP(obj, 3, '-recdata')};
            obj.O = {UnitAP(obj, 3)};
        end
    end
    
    methods (Static)
        function [xset, xpadding] = decomposeData(x, stride)
            xset = cell([stride, size(x, 3)]);
            [xset(:, :, 1), xpadding] = getStrideSet(x(:, :, 1), stride);
            for i = 2 : size(x, 3)
                xset(:, :, i) = getStrideSet(x(:, :, i), stride);
            end
        end
        
        function x = composeData(xset, xpadding)
            [h, w]    = size(xset{1});
            [m, n, c] = size(xset);
            % combine matrix in cell array
            x = cat(3, xset{:});
            x = reshape(x, [h, w, m, n, c]);
            x = permute(x, [3, 1, 4, 2, 5]);
            x = reshape(x, [h * m, w * n, c]);
            % remove zero-padding
            x = x(1 : end - xpadding(1), 1 : end - xpadding(2), :);
        end
        
        function [wset, wpadding] = decomposeFilter(w, stride)
            wset = cell([stride, size(w, 3), size(w, 4)]);
            referPoint = ceil(([size(w, 1), size(w, 2)] + 1) / 2);
            for i = 1 : size(w, 3)
                for j = 1 : size(w, 4)
                    if exist('wpadding', 'var')
                        wset(:, :, i, j) = getStrideSet(w(:, :, i, j), stride, referPoint, 'reverse');
                    else
                        [wset(:, :, i, j), wpadding] = ...
                            getStrideSet(w(:, :, i, j), stride, referPoint, 'reverse');
                    end
                end
            end
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
            y = cell(size(f, 4), 1);
            for n = 1 : numel(y)
                y{n} = 0;
                for i = 1 : size(x, 1)
                    for j = 1 : size(x, 2)
                        for k = 1 : size(x, 3)
                            y{n} = y{n} + conv2(x{i, j, k}, f{i, j, k, n}, 'same');
                        end
                    end
                end
            end
            % combine cells into a matrix
            y = cat(3, y{:});
            % add bias
            y = bsxfun(@plus, y, reshape(bias, [1, 1, numel(bias)]));
        end
        
        function [d, dW, dB] = grad2d(d, x, weight, padding, fBuildIn, fGPU, fOldVer)
            if fBuildIn
                issymmetric = (padding.top == padding.bottom) && (padding.left == padding.right);
                % padding array for non-symmetric cases (or GPU)
                if not(issymmetric) && (fGPU || (not(fGPU) && fOldVer))
                    x = padarray(x, [padding.top, padding.left], 0, 'pre');
                    x = padarray(x, [padding.bottom, padding.right], 0, 'post');
                    padding = struct('top', 0, 'left', 0, 'bottom', 0, 'right', 0);
                end
                % calcuate gradient under GPU or CPU environment
                if fGPU
                    if fOldVer || ispc
                        d = nnet.internal.cnngpu.convolveBackwardData2D( ...
                            x, weight, d, padding.top, padding.left, 1, 1);
                        if nargout > 1
                            dW = nnet.internal.cnngpu.convolveBackwardFilter2D( ...
                                x, weight, d, padding.top, padding.left, 1, 1);
                            dB = nnet.internal.cnngpu.convolveBackwardBias2D(d);
                        end
                    else
                        d = nnet.internal.cnngpu.convolveBackwardData2D( ...
                            x, weight, d, ...
                            padding.top, padding.left, padding.bottom, padding.right, ...
                            1, 1);
                        if nargout > 1
                            dW = nnet.internal.cnngpu.convolveBackwardFilter2D( ...
                                x, weight, d, ...
                                padding.top, padding.left, padding.bottom, padding.right, ...
                                1, 1);
                            dB = nnet.internal.cnngpu.convolveBackwardBias2D(d);
                        end
                    end
                else
                    if fOldVer
                        d = nnet.internal.cnnhost.convolveBackwardData2D( ...
                            x, weight, d, padding.top, padding.left, 1, 1);
                        if nargout > 1
                            dW = nnet.internal.cnnhost.convolveBackwardFilter2D( ...
                                x, weight, d, padding.top, padding.left, 1, 1);
                            dB = nnet.internal.cnnhost.convolveBackwardBias2D(d);
                        end
                    else
                        d = nnet.internal.cnnhost.convolveBackwardData2D( ...
                            x, weight, d, ...
                            padding.top, padding.left, padding.bottom, padding.right, ...
                            1, 1);
                        if nargout > 1
                            dW = nnet.internal.cnnhost.convolveBackwardFilter2D( ...
                                x, weight, d, ...
                                padding.top, padding.left, padding.bottom, padding.right, ...
                                1, 1);
                            dB = nnet.internal.cnnhost.convolveBackwardBias2D(d);
                        end
                    end
                end
            else
                if nargout > 1
                    [d, dW, dB] = MathLib.nnconvDifferential(d, x, weight, 'same');
                else
                    d = MathLib.nnconvDifferential(d, x, weight, 'same');
                end
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
    
    properties (Constant)
        enableGPU = logical(gpuDeviceCount)
        % useBuildInConv2D = ...
        %     not(isempty(which('nnet.internal.cnnhost.convolveForward2D')))
        useBuildInConv2D = false
        useOldVersion = sscanf(version('-release'), '%g', 1) < 2017
    end
    
    properties (Constant, Hidden)
        taxis = false;
    end
    
    properties
        stride
    end
    
    properties (Access = protected)
        W, B, padding
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