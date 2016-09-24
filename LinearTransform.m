classdef LinearTransform < MappingUnit
    methods
        function y = process(obj, x)
            obj.I.state = x;
            y = bsxfun(@plus, obj.weight * x, obj.bias);
            obj.O.state = y;
        end
        
        function d = delta(obj, d, isEvolving)
            if not(exist('isEvolving', 'var')) || isEvolving
                obj.B.addgrad(sum(d, 2));
                obj.W.addgrad(d * obj.I.state');
            end
            d = obj.weight' * d;
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.W.update(stepsize);
                obj.B.update(stepsize);
            else
                obj.W.update();
                obj.B.update();
            end
        end
    end
    
    methods
        function unit = inverseUnit(obj)
            unit = LinearTransform(obj.weight', zeros(size(obj.W, 2), 1), true);
        end
        
        function kernel = kernelDump(obj)
            w = obj.W.getcpu();
            b = obj.B.getcpu();
            kernel = [w(:); b(:)];
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    methods
        function sizeinfo  = sizeIn2Out(obj, sizeinfo)
            sizeinfo(1) = size(obj.W, 1);
        end
        
        function sizeinfo = sizeOut2In(obj,sizeinfo)
            sizeinfo(1) = size(obj.W, 2);
        end
    end
    
    methods
        function obj = LinearTransform(argA, argB, opt)
            if exist('opt', 'var') && opt
                weight = argA; bias = argB;
                assert(MathLib.ndims(weight) <= 2 && MathLib.ndims(bias) <= 1 && ...
                       size(weight, 1) == size(bias, 1), 'UMPrest:ArgumentError', ...
                       'Provide WEIGHT and BIAS are illeagal.');
                obj.W = HyperParam(weight);
                obj.B = HyperParam(bias);
            else
                inputSize = argA; outputSize = argB;
                % Initialize weight to uniform distribution in the suggestion
                % range inverse proportional to square root of input element
                % quantity. While, bias are initialized as zeros.
                obj.W = HyperParam((rand(outputSize, inputSize) - 0.5) * (2 / sqrt(inputSize)));
                obj.B = HyperParam(zeros(outputSize, 1));
            end
            
            obj.I = AccessPoint(obj, size(obj.W, 2));
            obj.O = AccessPoint(obj, size(obj.W, 1));
        end
    end
    
    methods (Static)
        function debug()
            sizein = 64; sizeout = 128;
            ltrans = randn(sizeout, sizein); bias = randn(sizeout, 1);
            refer = LinearTransform(ltrans, bias, true);
            model = LinearTransform(sizein, sizeout);
            model.likelihood = Likelihood('mse');
            % create validate set
            % data = randn(sizein, 1e2);
            % validset = DataPackage(data, 'label', bsxfun(@plus, ltrans * data, bias));
            validsetIn  = DataPackage(randn(sizein, 1e2), 1, false);
            validsetOut = refer.transform(validsetIn);
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.transform(validsetIn), validsetOut));
            for i = 1 : UMPrest.parameter.get('iteration')
                data = randn(sizein, 8);
                ipkg = DataPackage(data, 1, false);
                opkg = refer.transform(ipkg);
                model.learn(ipkg, opkg);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    model.likelihood.evaluate(model.transform(validsetIn), validsetOut));
            end
            % show result
            werr = ltrans - model.weight;
            berr = bias - model.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
    
    properties (Constant)
        taxis = false;
        expandable = false;
    end
    
    properties (Access = private)
        W, B
    end
    
    properties (Dependent)
        weight
        bias
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
