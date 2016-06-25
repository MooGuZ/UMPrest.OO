classdef Activation < Unit
% TO-DO List
% 1. [x] finish inverse functions 
%
% Problem
% 1. [ ] inclusive and exclusive boundary
    methods
        function y = transproc(obj, x)
            y = obj.actfuncs.transform( ...
                MathLib.bound(x, obj.actfuncs.range.x));
        end
        
        function x = inferproc(obj, y)
            x = obj.actfuncs.inference( ...
                MathLib.bound(y, obj.actfuncs.range.y));
        end
        
        function d = errprop(obj, d)
            d = obj.actfuncs.errprop(d, obj.O);
        end
    end
    
    methods
        function obj = Activation(type)
            if exist('type', 'var')
                obj.actType = type;
            else
                obj.actType = 'ReLU';
            end
        end
    end
    
    properties (Access = private)
        actfuncs
    end
    
    properties (Dependent)
        actType
    end
    methods
        function value = get.actType(obj)
            value = obj.actfuncs.type;
        end
        function set.actType(obj, type)
            switch lower(type)
                case {'sigmoid', 'logistic'}
                    obj.actfuncs = struct( ...
                        'type',      type, ...
                        'transform', @(x) 1 ./ (1 + exp(-x)), ...
                        'inference', @(y) -log(1 ./ y - 1), ...
                        'errprop',   @(d, y) d .* (y .* (1 - y)), ...
                        'range',     struct('x', [-inf, inf], 'y', [0, 1]));
                    
                case {'hypertgt'}
                    obj.actfuncs = struct( ...
                        'type',      type, ...
                        'transform', @tanh, ...
                        'inference', @(y) log((1 + x) ./ (1 - x)) / 2, ...
                        'errprop',   @(d, y) d .* (1 - y.^2), ...
                        'range',     struct('x', [-inf, inf], 'y', [-1, 1]));
                    
                case {'relu'}
                    obj.actfuncs = struct( ...
                        'type',      type, ...
                        'transform', @(x) max(x, 0), ...
                        'inference', @(y) max(y, 0), ...
                        'errprop',   @(d, y) MathLib.mask(d, y > 0), ...
                        'range',     struct('x', [-inf, inf], 'y', [0, inf]));
                    
                otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized activation type : %s', upper(type));
            end
        end
    end
end
