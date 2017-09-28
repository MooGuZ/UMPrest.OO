classdef BidirectionOperation < Operation
    methods
        function varargout = process(self, type, varargin)
            varargout = cell(1, nargout);
            switch type
              case {'DataPackage'}
                [varargout{:}] = self.dataproc(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = self.deltainvp(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = self.sizeIn2Out(varargin{:});
                
              otherwise
                error('UNKNOWN PACKAGE TYPE');
            end
        end
        
        function varargout = invproc(self, type, varargin)
            varargout = cell(1, nargout);
            switch type
              case {'DataPackage'}
                [varargout{:}] = self.datainvp(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = self.deltaproc(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = self.sizeOut2In(varargin{:});
                
              otherwise
                error('UNKNOWN PACKAGE TYPE');
            end
        end
    end
    
    methods (Abstract)
        varargout = dataproc(self, varargin)
        varargout = datainvp(self, varargin)
        varargout = deltaproc(self, varargin)
        varargout = deltainvp(self, varargin)
        varargout = sizeIn2Out(self, varargin)
        varargout = sizeOut2In(self, varargin)
    end
end