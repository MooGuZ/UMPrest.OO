classdef MappingUnit < EvolvingUnit
    % ======================= DATA PROCESSING =======================
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
        
        function [value, grad] = objfunc(obj, dataIn, dataOut, sizeIn)
            dataIn  = reshape(dataIn, sizeIn);
            dataGet = obj.process(dataIn);
            value = obj.likelihood.evaluate(dataGet, dataOut);
            if nargout > 1
                grad = obj.errprop(obj.likelihood.delta(dataGet, dataOut), false);
                grad = grad(:);
            end
        end
    end
    
    % ======================= EVOLVING LOGIC =======================
    methods
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
end
