% PROPOSAL: specialize each activation function as a class
% TODO: [ ] implement 'inverseUnit'
classdef Activation < Unit
    % ======================= DATA PROCESSING =======================
    methods
        function y = transform(obj, x)
            y = obj.process(x);
            obj.I = x; obj.O = y;
        end
        
        function x = compose(obj, y)
            x = obj.invproc(y);
            obj.I = x; obj.O = y;
        end
        
        function d = errprop(obj, d, ~)
            if obj.isinversed
                d = d ./ obj.differential(obj.I);
            else
                d = d .* obj.differential(obj.O);
            end
        end
    end
    
    % ======================= TOPOLOGY LOGIC =======================
    methods
        function unit = inverseUnit(obj)
            switch obj.type
              case {'sigmoid', 'logistic'}
                unit = Activation('invsigmoid');
                
              case {'invsigmoid', 'invlogistic'}
                unit = Activation('sigmoid');
                
              case {'hypertgt', 'tanh'}
                unit = Activation('invtanh');
                
              case {'invhypertgt', 'invtanh'}
                unit = Activation('tanh');
                
              case {'relu'}
                unit = Activation('relu');
            end
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(~)
            value = sym.inf();
        end
        
        function descriptionOut = sizeIn2Out(~, descriptionIn)
            descriptionOut = descriptionIn;
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Activation(type)
            obj.actType = type;
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (Access = private)
        type, process, invproc, differential, isinversed
    end
    
    properties (Dependent)
        actType
    end
    methods
        function value = get.actType(obj)
            value = obj.type;
        end
        function set.actType(obj, type)
            assert(ischar(type), 'Actiation type should be a string');
            obj.type = lower(type);
            switch obj.type
              case {'sigmoid', 'logistic'}
                obj.process = @MathLib.sigmoid;
                obj.invproc = @MathLib.sigmoidInverse;
                obj.differential = @MathLib.sigmoidDifferential;
                obj.isinversed = false;
                
              case {'invsigmoid', 'invlogistic'}
                obj.process = @MathLib.sigmoidInverse;
                obj.invproc = @MathLib.sigmoid;
                obj.differential = @MathLib.sigmoidDifferential;
                obj.isinversed = true;
                
              case {'hypertgt', 'tanh'}
                obj.process = @tanh;
                obj.invproc = @MathLib.tanhInverse;
                obj.differential = @MathLib.tanhDifferential;
                obj.isinversed = false;
                
              case {'invhypertgt', 'invtanh'}
                obj.process = @tanhInverse;
                obj.invproc = @MathLib.tanh;
                obj.differential = @MathLib.tanhDifferential;
                obj.isinversed = true;
                    
              case {'relu'}
                obj.process = @MathLib.relu;
                obj.invproc = @MathLib.reluInverse;
                obj.differential = @MathLib.reluDifferential;
                obj.isinversed = false;
                
              otherwise
                error('UMPrest:ArgumentError', ...
                      'Unrecognized activation type : %s', upper(type));
            end
        end
    end
end
