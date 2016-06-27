classdef EvolvingUnit < Unit
    methods
        function y = transform(obj, x)
            y = obj.process(x);
            
            obj.I = x; 
            obj.O = y;
        end
        
        function x = compose(obj, y)
            x = obj.infer(y);
            
            obj.I = x;
            obj.O = y;
        end
    end
    
    methods (Abstract)
        y = process(obj, x)
    end
    
    methods
        function data = infer(obj, rep)
            sizeIn = [obj.size('in'), numel(rep) / prod(obj.size('out'))];
            data = reshape(OptimLib.minimize(@obj.objfunc, randn(prod(sizeIn), 1), ...
                OptimLib.config('default'), rep, sizeIn), sizeIn);
        end
    end
    
    methods
        function [value, grad] = objfunc(obj, dataIn, dataOut, sizeIn)
            dataIn  = reshape(dataIn, sizeIn);
            dataGet = obj.process(dataIn);
            value = obj.likelihood.evaluate(dataGet, dataOut);
            if nargout > 1
                grad = obj.deltaproc(obj.likelihood.delta(dataGet, dataOut), false);
                grad = grad(:);
            end
        end
    end

    methods
        function trainproc(obj, datapkg)
            if datapkg.isunified
                obj.learn(datapkg);
            else
                for i = 1 : numel(datapkg.ndata)
                    obj.learn(datapkg.get(i));
                end
            end
        end
        
        function learn(obj, datapkg)
            if not(isempty(obj.likelihood))
                obj.errprop(obj.likelihood.delta(obj.forward(datapkg)));
                obj.update();
            else
                warning('UMPrest:RuntimeError', ...
                        'Learning process is aborded, likelihood is unset.');
            end
        end
    end

    methods (Abstract)
        update(obj, stepsize)
    end
    
    methods (Abstract)
        unit = symmetryUnit(obj)
    end
    
    properties
        likelihood
    end
    methods
        function set.likelihood(obj, value)
            assert(isempty(value) || isa(value, 'Likelihood'));
            obj.likelihood = value;
        end
    end
end
