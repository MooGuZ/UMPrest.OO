classdef SimpleActivation < SISOUnit & ElementwiseOperation
    methods
        function obj = SimpleActivation(type)
            switch lower(type)
                case {'sigmoid', 'logistic'}
                    obj.type     = 'Sigmoid';
                    obj.dataproc = @MathLib.sigmoid;
                    obj.datainvp = @MathLib.sigmoidInverse;
                    obj.gradient = @MathLib.sigmoidDifferential;
                    
                case {'hypertgt', 'tanh', 'hypertangent'}
                    obj.type     = 'HyperTangent';
                    obj.dataproc = @tanh;
                    obj.datainvp = @MathLib.tanhInverse;
                    obj.gradient = @MathLib.tanhDifferential;
                    
                case {'relu'}
                    obj.type     = 'ReLU';
                    obj.dataproc = @MathLib.relu;
                    obj.datainvp = @MathLib.reluInverse;
                    obj.gradient = @MathLib.reluDifferential;
                    
                otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized activation type : %s', upper(type));
            end
            % setup access points
            obj.I = {UnitAP(obj, 0, '-expandable')};
            obj.O = {UnitAP(obj, 0, '-expandable', '-recdata')};
        end
    end
    
    properties (SetAccess = protected)
        type
    end
    properties (Constant, Hidden)
        taxis      = false;
        expandable = true;
    end
    properties (SetAccess = protected, Hidden)
        dataproc, datainvp, gradient
    end
    methods
        function set.dataproc(obj, value)
            assert(isa(value, 'function_handle'), 'ILLEGAL OPERATION');
            obj.dataproc = value;
        end
        
        function set.datainvp(obj, value)
            assert(isa(value, 'function_handle'), 'ILLEGAL OPERATION');
            obj.datainvp = value;
        end
        
        function set.gradient(obj, value)
            assert(isa(value, 'function_handle'), 'ILLEGAL OPERATION');
            obj.gradient = value;
        end
    end
end
