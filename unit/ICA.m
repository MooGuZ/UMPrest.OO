classdef ICA < GUnit
% ICA is an abstraction of Independent Component Analysis units.

% MooGu Z. <hzhu@case.edu>
% Feb 29, 2016

    methods
        function param = invp(obj, data)
            data  = datafmt(data, obj.dimin());
            param = minFunc(@obj.objFunc, obj.initParam(data), inferOptions, data);
        end
        
        function data = proc(obj, param)
            param = datafmt(param, obj.dimout());
            data  = obj.operate(param);
        end
        
        function delta = bprop(obj, delta)
            [delta, dBase] = obj.eprop(delta);
            obj.addGradient(dBase, @obj.updateBase);
            obj.optimize();
        end
    end
    
    methods
        function [objval, grad] = objFunc(obj, param, data)
            recdata = obj.operate(param);
            objval  = obj.objective(recdata, data)
            if nargout > 1
                d = obj.delta(recdata, data);
                grad = obj.eprop(d);
                grad = grad(:);
            end
        end
    end
    
    methods (Abstract)
        param = initParam(obj, data)
        data  = operate(obj, param)
        [delta, dBase] = eprop(obj, delta) % error propagation
        updateBase(obj, delta)
        value = objective(obj, output, ref)
        d     = delta(obj, output, ref)
    end
end
