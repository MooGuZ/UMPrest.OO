classdef Activation < Unit
% TO-DO List
% 1. [x] finish inverse functions 
%
% Problem
% 1. [ ] inclusive and exclusive boundary
    methods
        function y = transform(obj, x)
            y = obj.process(x);
        end
        
        function x = compose(obj, y)
            x = obj.invproc(y);
        end
        
        function d = deltaproc(obj, d)
            d = obj.differential(d, obj.O);
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
        process, invproc, differential
    end
    methods
        function set.process(obj, value)
            assert(isa(value, 'function_handle'));
            obj.process = value;
        end
        
        function set.invproc(obj, value)
            assert(isa(value, 'function_handle'));
            obj.invproc = value;
        end
        
        function set.differential(obj, value)
            assert(isa(value, 'function_handle'));
            obj.differential = value;
        end
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
                obj.process = @MathLib.sigmoid;
                obj.invproc = @MathLib.sigmoidInverse;
                obj.differential = @MathLib.sigmoidDifferential;
                
              case {'hypertgt', 'tanh'}
                obj.process = @tanh;
                obj.invproc = @MathLib.tanhInverse;
                obj.differential = @MathLib.tanhDifferential;
                    
              case {'relu'}
                obj.process = @MathLib.relu;
                obj.invproc = @MathLib.reluInverse;
                obj.differential = @MathLib.reluDifferential;
                
              otherwise
                error('UMPrest:ArgumentError', ...
                      'Unrecognized activation type : %s', upper(type));
            end
        end
    end
end
