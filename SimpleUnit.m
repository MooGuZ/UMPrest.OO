classdef SimpleUnit < Unit & Operation
%     methods
%         function varargout = forward(obj, varargin)
%             varargout = cell(1, nargout);
%             [varargout{:}] = obj.propagate(obj.I, obj.O, @obj.process, varargin{:});
%         end
%         
%         function varargout = backward(obj, varargin)
%             varargout = cell(1, nargout);
%             [varargout{:}] = obj.propagate(obj.O, obj.I, @obj.invproc, varargin{:});
%         end
%     end
    
    methods
        function obj = recrtmode(obj, n)
        % NOTE: currently there is no way to turn of recurrent mode
            for i = 1 : numel(obj.I)
                if obj.I{i}.recdata
                    obj.I{i}.datarcd.init(n);
                end
            end
            for i = 1 : numel(obj.O)
                if obj.O{i}.recdata
                    obj.O{i}.datarcd.init(n);
                end
            end
        end
    end

%     methods (Abstract)
%         varargout = propagate(obj, apin, apout, proc, varargin)
%     end
    
    properties (Abstract, Constant, Hidden)
        taxis % TRUE/FALSE, indicating this unit process data with time-axis
    end
    
    properties (Hidden)
        pkginfo
    end
end
