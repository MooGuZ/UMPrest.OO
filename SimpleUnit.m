classdef SimpleUnit < Unit & Operation
    methods (Abstract)
        varargout = propagate(obj, apin, apout, proc, varargin)
    end
    
    methods
        function obj = SimpleUnit()
            % initialize operations
            obj.forward  = @(varargin) obj.propagate(obj.I, obj.O, @obj.process, varargin{:});
            obj.backward = @(varargin) obj.propagate(obj.O, obj.I, @obj.invproc, varargin{:});
            % initialize shared field between AccessPoint
            obj.apshare = struct();
        end
    end
    
    properties (Abstract, Constant, Hidden)
        taxis, expandable
    end
    
    properties (Hidden) % TODO: Restrict Access
        apshare
    end
    properties (SetAccess = protected, Hidden)
        forward, backward
    end
    methods
        function set.forward(obj, value)
            assert(isa(value, 'function_handle'), 'ILLEGAL OPERATION');
            obj.forward = value;
        end
        
        function set.backward(obj, value)
            assert(isa(value, 'function_handle'), 'ILLEGAL OPERATION');
            obj.backward = value;
        end
    end
end
