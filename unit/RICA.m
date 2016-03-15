classdef RICA < ICA
% RICA is the abstraction of ICA based on real numbers.

% MooGu Z. <hzhu@case.edu>
% Feb 29, 2016

    methods
        function param = initParam(obj, data)
            param = mtimesnd(obj.base', data); % approximation
        end
        
        function data = operate(obj, param)
            data = mtimesnd(obj.base, param);
            obj.I = param;
            obj.O = data;
        end
        
        function updateBase(obj, delta)
            obj.base = obj.base - delta;
        end
        
        function [delta, dBase] = eprop(obj, delta)
            sz = size(delta);
            if nargout > 1
                dBase = reshape(delta, [obj.dimout(), prod(sz(2:end))]) ...
                        * reshape(obj.I, [obj.dimin(), prod(sz(2:end))])';
            end
            delta = mtimesnd(obj.base', delta);
        end
    end
end
