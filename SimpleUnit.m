classdef SimpleUnit < Unit & Operation
    methods
        function varargout = forward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.propagate(obj.I, obj.O, @obj.process, varargin{:});
        end
        
        function varargout = backward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.propagate(obj.O, obj.I, @obj.invproc, varargin{:});
        end
    end
    
    methods
        function clear(obj)
            arrayfun(@clear, obj.I);
            arrayfun(@clear, obj.O);
        end
    end

    methods (Abstract)
        varargout = propagate(obj, apin, apout, proc, varargin)
    end
    
    methods
        function obj = SimpleUnit()
            obj.apshare = struct();
        end
    end
    
    properties (Abstract, Constant, Hidden)
        taxis, expandable
    end
    
    properties (Hidden) % TODO: Restrict Access
        apshare % shared field between AccessPoint
    end
end
