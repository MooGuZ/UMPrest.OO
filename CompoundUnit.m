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
            obj.kernel = model.seal();
            % setup I/O access points
            obj.I = cellfun(@(ap) GhostAP(obj, ap), obj.kernel.I, 'UniformOutput', false);
            obj.O = cellfun(@(ap) GhostAP(obj, ap), obj.kernel.O, 'UniformOutput', false);
        end
        
        function recrtmode(obj)
            obj.kernel.recrtmode();
        end
    end
    
    properties (SetAccess = protected)
        I = {}  % input access point set
        O = {}  % output access point set
        kernel  % model, which does actual works
    end
end
