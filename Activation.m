classdef Activation < Unit
    % ======================= DATA PROCESSING =======================
    methods
        function d = delta(obj, d)
            d = d .* obj.differential(obj.O.state.data);
        end
        
        function d = invdelta(obj, d)
            d = d ./ obj.differential(obj.O.state.data);
        end
        
        function sizeout = sizeIn2Out(~, sizein)
            sizeout = sizein;
        end
        
        function sizein = sizeOut2In(~, sizeout)
            sizein = sizeout;
        end
    end
    
    methods
        function output = forwardOperation(obj, input)
            switch obj.apshare.class
              case {'DataPackage'}
                output = obj.process(input);
                
              case {'SizePackage'}
                output = obj.sizeIn2Out(input);
                
              case {'ErrorPackage'}
                output = obj.invdelta(input);
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function input = backwardOperation(obj, output)
            switch obj.apshare.class
              case {'DataPackage'}
                input = obj.invproc(output);
                
              case {'SizePackage'}
                input = obj.sizeOut2In(output);
                
              case {'ErrorPackage'}
                input = obj.delta(output);
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Activation(type)
            obj.type = type;
            obj.I = AccessPoint(obj, 1);
            obj.O = AccessPoint(obj, 1);
            obj.id = UMPrest.unit(obj);
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (Constant)
        taxis = false;
        expandable = true;
    end
    properties (Access = private)
        type, process, invproc, differential
    end
    methods
        function set.type(obj, type)
            assert(ischar(type), 'Actiation type should be a string');
            obj.type = lower(type);
            switch obj.type
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
