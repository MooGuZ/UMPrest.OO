classdef ConvTransform < SISOUnit & FeedforwardOperation & Evolvable
    % NOTE: currently ConvTransform use convolution in 'SAME' shape
    methods
        function y = dataproc(obj, x)
            % if obj.useBuildInConv2D
            %     if obj.enableGPU
            %         % NOTE: GPU version seems only accept symmetric
            %         % padding, should deal with it latter.
            %         y = nnet.internal.cnngpu.convolveForward2D( ...
            %             x, obj.weight, ...
            %             obj.padding.top, obj.padding.left, ...
            %             obj.padding.bottom, obj.padding.right, ...
            %             1, 1) + obj.bias;                    
            %     else
            %         y = nnet.internal.cnnhost.convolveForward2D( ...
            %             x, obj.weight, ...
            %             obj.padding.top, obj.padding.left, ...
            %             obj.padding.bottom, obj.padding.right, ...
            %             1, 1) + obj.bias;
            %     end
            % else
            %    y = MathLib.nnconv(x, obj.weight, obj.bias, 'same');
            % end
            % z = ConvTransform.conv2d(x, obj.weight, obj.bias, obj.padding, ...
            %     not(obj.useBuildInConv2D), obj.enableGPU, obj.useOldVersion);
            y = ConvTransform.conv2d(x, obj.weight, obj.bias, obj.padding, ...
                obj.useBuildInConv2D, obj.enableGPU, obj.useOldVersion);
            % disp('[Difference of Y]');
            % disp([y(1:5, 1:5, 1, 1), z(1:5, 1:5, 1, 1)]);
            % fprintf('\n\n');
        end
        
        % NOTE: omit output parameter of dW and dB can save calculation
        %       power in case they are not necessary, such as, when
        %       hyperparameter is frozen.
        function d = deltaproc(obj, d)
            x = obj.I{1}.datarcd.pop();
            % if obj.useBuildInConv2D
            %     if obj.enableGPU
            %         d = nnet.internal.cnngpu.convolveBackwardData2D( ...
            %             x, obj.weight, d, ...
            %             obj.padding.top, obj.padding.left, ...
            %             obj.padding.bottom, obj.padding.right, ...
            %             1, 1);
            %         if obj.pkginfo.updateHParam
            %             dW = nnet.internal.cnngpu.convolveBackwardFilter2D( ...
            %                 x, obj.weight, d, ...
            %                 obj.padding.top, obj.padding.left, ...
            %                 obj.padding.bottom, obj.padding.right, ...
            %                 1, 1);
            %             dB = nnet.internal.cnngpu.convolveBackwardBias2D(d);
            %         end
            %     else
            %         d = nnet.internal.cnnhost.convolveBackwardData2D( ...
            %             x, obj.weight, d, ...
            %             obj.padding.top, obj.padding.left, ...
            %             obj.padding.bottom, obj.padding.right, ...
            %             1, 1);
            %         if obj.pkginfo.updateHParam
            %             dW = nnet.internal.cnnhost.convolveBackwardFilter2D( ...
            %                 x, obj.weight, d, ...
            %                 obj.padding.top, obj.padding.left, ...
            %                 obj.padding.bottom, obj.padding.right, ...
            %                 1, 1);
            %             dB = nnet.internal.cnnhost.convolveBackwardBias2D(d);
            %         end
            %     end
            % else
            %     if obj.pkginfo.updateHParam
            %         [d, dW, dB] = MathLib.nnconvDifferential(...
            %             d, x, obj.weight, 'same');
            %     else
            %         d = MathLib.nnconvDifferential(...
            %             d, obj.I{1}.datarcd.pop(), obj.weight, 'same');
            %     end
            % end
            if obj.pkginfo.updateHParam
                % [z, zW, zB] = ConvTransform.grad2d(d, x, obj.weight, ...
                %     not(obj.useBuildInConv2D), obj.enableGPU, obj.useOldVersion);
                [d, dW, dB] = ConvTransform.grad2d(d, x, obj.weight, obj.padding, ...
                    obj.useBuildInConv2D, obj.enableGPU, obj.useOldVersion);
            else
                % z = ConvTransform.grad2d(d, x, obj.weight, ...
                %     not(obj.useBuildInConv2D), obj.enableGPU, obj.useOldVersion);
                d = ConvTransform.grad2d(d, x, obj.weight, obj.padding, ...
                    obj.useBuildInConv2D, obj.enableGPU, obj.useOldVersion);
            end
            % % show difference
            % disp('[Difference of D]');
            % disp([d(1:5, 1:5, 1, 1), z(1:5, 1:5, 1, 1)]);
            % disp('[Difference of dWeight]');
            % disp([dW(:, :, 1, 1), zW(:, :, 1, 1)]);
            % disp('[Difference of dBias]');
            % disp([dB(:), zB(:)]);
            % fprintf('\n\n');
            % record gradients to Hyper-Parameters
            if obj.pkginfo.updateHParam
                obj.W.addgrad(dW);
                obj.B.addgrad(dB);
            end
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.W, obj.B};
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
        function obj = ConvTransform(weight, bias)
            obj.W = HyperParam(weight);
            obj.B = HyperParam(reshape(bias, 1, 1, numel(bias)));
            obj.I = {UnitAP(obj, 3, '-recdata')};
            obj.O = {UnitAP(obj, 3)};
            % calculate padding information
            obj.padding.top    = floor(size(weight, 1) / 2);
            obj.padding.bottom = floor((size(weight, 1) - 1) / 2);
            obj.padding.left   = floor(size(weight, 2) / 2);
            obj.padding.right  = floor((size(weight, 2) - 1) / 2);
        end
    end
    
    methods (Static)
        function y = conv2d(x, weight, bias, padding, fBuildIn, fGPU, fOldVer)
            if fBuildIn % use build-in function from neural-network toolbox
                issymmetric = (padding.top == padding.bottom) && (padding.left == padding.right);
                % padding array for non-symmetric cases (or GPU)
                if not(issymmetric)
                    if fGPU || (not(fGPU) && fOldVer)
                        x = padarray(x, [padding.top, padding.left] - 1, 0, 'pre');
                        x = padarray(x, [padding.bottom, padding.right] + 1, 0, 'post');
                        padding = struct('top', 0, 'left', 0, 'bottom', 0, 'right', 0);
                    else
                        padding.top    = padding.top    - 1;
                        padding.left   = padding.left   - 1;
                        padding.bottom = padding.bottom + 1;
                        padding.right  = padding.right  + 1;
                    end
%                     if fGPU || (not(fGPU) && fOldVer)
%                         x = padarray(x, [padding.top, padding.left], 0, 'pre');
%                         x = padarray(x, [padding.bottom, padding.right] + 1, 0, 'post');
%                         padding = struct('top', 0, 'left', 0, 'bottom', 0, 'right', 0);
%                     end
                end
                % flip x-axis and y-axis to actually do convlution not correlation
                weight = matflip(weight);
                % do convolution under GPU or CPU environment
                if fGPU
                    if fOldVer || ispc
                        y = nnet.internal.cnngpu.convolveForward2D( ...
                            x, weight, padding.top, padding.left, 1, 1) + bias;
                    else
                        y = nnet.internal.cnngpu.convolveForward2D( ...
                            x, weight, padding.top, padding.left, ...
                            padding.bottom, padding.right, 1, 1) + bias;
                    end
                else
                    if fOldVer
                        y = nnet.internal.cnnhost.convolveForward2D( ...
                            x, weight, padding.top, padding.left, 1, 1) + bias;
                    else
                        y = nnet.internal.cnnhost.convolveForward2D( ...
                            x, weight, padding.top, padding.left, ...
                            padding.bottom, padding.right, 1, 1) + bias;
                    end
                end
            else
                y = MathLib.nnconv(x, weight, bias, 'same');
            end        
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
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
end