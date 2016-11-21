classdef SimpleUnit < Unit
    methods
        function varargout = forwardOperation(obj, varargin)
            varargout = cell(1, nargout);
            switch obj.apshare.class
              case {'DataPackage'}
                [varargout{:}] = obj.process(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeIn2Out(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = obj.invdelta(varargin{:});
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function varargout = backwardOperation(obj, varargin)
            varargout = cell(1, nargout);
            switch obj.apshare.class
              case {'DataPackage'}
                [varargout{:}] = obj.invproc(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeOut2In(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = obj.delta(varargin{:});
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
    methods (Abstract)
        data = process(obj, data)
        data = invproc(obj, data)
        error = delta(obj, error)
        error = invdelta(obj, error)
        outsize = sizeIn2Out(obj, insize)
        insize  = sizeOut2In(obj, outsize)
    end
end
