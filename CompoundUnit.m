classdef CompoundUnit < Unit
    methods
        function varargout = forward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.kernel.forward(varargin{:});
        end
        
        function varargout = backward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.kernel.backward(varargin{:});
        end
        
        function init(obj, model)
            obj.kernel = model;
            % setup I/O access points
            obj.I = cell2array(arrayfun( ...
                @(ap) GhostAP(obj, ap), obj.kernel.I, 'UniformOutput', false));
            obj.O = cell2array(arrayfun( ...
                @(ap) GhostAP(obj, ap), obj.kernel.O, 'UniformOutput', false));
            % TODO: prevent modification of the kernel
            % kernel.freeze();
        end
        
        function clear(obj)
            obj.kernel.clear();
        end
    end
    
    properties (SetAccess = protected)
        kernel
    end
    methods
        function set.kernel(obj, value)
            assert(isa(value, 'Model'), 'ILLEGAL OPERATION');
            obj.kernel = value;
        end 
    end
end
