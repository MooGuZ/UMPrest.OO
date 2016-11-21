classdef GenerativeModel < Model
    properties
        gunit
    end
    
    methods
        function varargout = forward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.gunit.backward(varargin{:});
        end
        
        function varargout = backward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.gunit.forward(varargin{:});
        end
    end
end
