classdef ConvTransform < SISOUnit & FeedforwardOperation & Evolvable
    % NOTE: currently ConvTransform use convolution in 'SAME' shape
    methods
        function y = dataproc(obj, x)
            % if obj.useBuildInConv2D
            %     if obj.useGPU
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
                y = MathLib.nnconv(x, obj.weight, obj.bias, 'same');
            % end
        end
        
        % NOTE: omit output parameter of dW and dB can save calculation
        %       power in case they are not necessary, such as, when
        %       hyperparameter is frozen.
        function d = deltaproc(obj, d)
            x = obj.I{1}.datarcd.pop();
            % if obj.useBuildInConv2D
            %     if obj.useGPU
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
                if obj.pkginfo.updateHParam
                    [d, dW, dB] = MathLib.nnconvDifferential(...
                        d, x, obj.weight, 'same');
                else
                    d = MathLib.nnconvDifferential(...
                        d, obj.I{1}.datarcd.pop(), obj.weight, 'same');
                end
            % end
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
            % % calculate padding information
            % obj.padding.top    = floor(size(weight, 1) / 2);
            % obj.padding.bottom = floor((size(weight, 1) - 1) / 2);
            % obj.padding.left   = floor(size(weight, 2) / 2);
            % obj.padding.right  = floor((size(weight, 2) - 1) / 2);
        end
    end
    
    methods (Static)
        function obj = randinit(fltsize, nchannel, nfilter)
            ksize = [fltsize, nchannel, nfilter];
            obj = ConvTransform( ...
                (rand(ksize) - 0.5) * (2 / sqrt(prod(ksize))), ...
                zeros(nfilter, 1));
        end
    end
    
    methods (Static)
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
        % useGPU = logical(gpuDeviceCount)
        % useBuildInConv2D = ...
        %     not(isempty(which('nnet.internal.cnnhost.convolveForward2D')))        
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