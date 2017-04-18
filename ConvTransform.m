classdef ConvTransform < SISOUnit & FeedforwardOperation & Evolvable
    % NOTE: currently ConvTransform use convolution in 'SAME' shape
    methods
        function y = dataproc(obj, x)
            y = MathLib.nnconv(x, obj.weight, obj.bias, 'same');
        end
        
        % NOTE: omit output parameter of dW and dB can save calculation
        %       power in case they are not necessary, such as, when
        %       hyperparameter is frozen.
        function d = deltaproc(obj, d)
            [d, dW, dB] = MathLib.nnconvDifferential(...
                d, obj.I{1}.datarcd.pop(), obj.weight, 'same');
            obj.W.addgrad(dW);
            obj.B.addgrad(dB);
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
            obj.B = HyperParam(bias);
            obj.I = {UnitAP(obj, 3, '-recdata')};
            obj.O = {UnitAP(obj, 3)};
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
        function debug()
            sizein   = [16, 16];
            nfilter  = 3;
            fltsize  = [7, 7];
            nchannel = 3;
            weight = randn([fltsize, nchannel, nfilter]);
            bias   = randn(nfilter, 1);
            refer = ConvTransform(weight, bias);
            model = ConvTransform.randinit(fltsize, nchannel, nfilter);
            likelihood = Likelihood('mse');
            % create validate set
            % data = randn(sizein, 1e2);
            % validset = DataPackage(data, 'label', bsxfun(@plus, ltrans * data, bias));
            validsetIn  = DataPackage(randn([sizein, nchannel, 1e2]), 3, false);
            validsetOut = refer.forward(validsetIn);
            % get optimizer
            opt = HyperParam.getOptimizer();
            % setup optimizer
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-2);            
            opt.enableRcdmode(3);
            % start to learn the linear transformation
            objval = likelihood.evaluate(model.forward(validsetIn).data, validsetOut.data);
            fprintf('Initial objective value : %.2f\n', objval);
            opt.record(objval);
            for i = 1 : UMPrest.parameter.get('iteration')
                data = randn([sizein, nchannel, 8]);
                ipkg = DataPackage(data, 3, false);
                opkg = refer.forward(ipkg);
                model.backward(likelihood.delta(model.forward(ipkg), opkg));
                model.update();
                objval = likelihood.evaluate(model.forward(validsetIn).data, validsetOut.data);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, objval);
                opt.record(objval);
            end
            % show result
            werr = weight - model.weight;
            berr = bias - model.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
    
    properties (Constant, Hidden)
        taxis = false;
    end
    
    properties (Access = protected)
        W, B
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