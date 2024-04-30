classdef FeedforwardOperation < Operation
    methods
        function varargout = process(obj, type, varargin)
            varargout = cell(1, nargout);
            switch type
              case {'DataPackage'}
                [varargout{:}] = obj.dataproc(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeIn2Out(varargin{:});
                
              case {'ErrorPackage'}
                error('UMPrest:RuntimeError', 'This operation is not supported!');
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function varargout = invproc(obj, type, varargin)
            varargout = cell(1, nargout);
            switch type
              case {'DataPackage'}
                error('UMPrest:RuntimeError', 'This operation is not supported!');
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeOut2In(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = obj.deltaproc(varargin{:});
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
    methods (Abstract)
        varargout = dataproc(obj, varargin)
        varargout = deltaproc(obj, varargin)
        % varargout = sizeIn2Out(obj, varargin)
        % varargout = sizeOut2In(obj, varargin)
    end
end
