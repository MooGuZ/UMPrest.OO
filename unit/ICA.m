classdef ICA < GUnit
% ICA is an abstraction of Independent Component Analysis units.

% MooGu Z. <hzhu@case.edu>
% Feb 29, 2016

    methods
        function param = proc(obj, data)
            data  = datafmt(data, obj.dimin());
            param = minFunc(@obj.objFunc, obj.initParam(data), inferOptions, data);
        end
        
        function data = invp(obj, param)
            param = datafmt(param, obj.dimout());
            data  = obj.operator(param);
        end
        
        function delta = fprop(obj, delta)
            [delta, dBase] = obj.gradient(delta);
            
            obj.addGradient(dBase, @obj.updateBase);
            
            obj.optimize();
        end
    end
    
    methods
        function [objval, delta] = gradient(obj, delta)
    
    methods (Abstract)
        param = initParam(obj, data)
        [delta, dBase] = gradient(obj, delta)
    end

end
