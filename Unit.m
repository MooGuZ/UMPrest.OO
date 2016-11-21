classdef Unit < Interface
    % ======================= DATA PROCESSING  =======================
    methods % (Access = private)
        function varargout = propagate(obj, apin, apout, proc, varargin)
            % clear CDINFO of parent unit
            obj.apshare = struct();
            % Single-In-Single-Out version
            if isscalar(apin) && isscalar(apout)
                % NOTE: arguments in the VARARGIN is ignored from 2nd term
                % get input package
                if isempty(varargin)
                    ipackage = apin.pop();
                else
                    ipackage = varargin{1};
                end
                % unpack input data from package
                idata = apin.unpack(ipackage);
                % process the data
                odata = proc(idata);
                % get output package
                opackage = apout.packup(odata);
                % send or return output package
                if nargout
                    varargout{1} = opackage;
                else
                    apout.send(opackage);
                end
            % General MIMO version
            else
                % get input package
                if isempty(varargin)
                    ipackage = arrayfun(@pop, apin, 'UniformOutput', false);
                else
                    ipackage = varargin;
                end
                % unpack data from package
                idata = cell(1, numel(apin));
                for i = 1 : numel(apin)
                    idata{i} = apin(i).unpack(ipackage{i});
                end
                % process the data
                odata = cell(1, numel(apout));
                [odata{:}] = proc(idata{:});
                % send or return output package
                if nargout
                    for i = 1 : min(nargout, numel(apout))
                        varargout{i} = apout(i).packup(odata{i});
                    end
                else
                    for i = 1 : numel(apout)
                        apout(i).send(apout(i).packup(odata{i}));
                    end
                end
            end
        end
    end
    
    methods
        function varargout = forward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.propagate(obj.I, obj.O, @obj.forwardOperation, varargin{:});
        end
        
        function varargout = backward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.propagate(obj.O, obj.I, @obj.backwardOperation, varargin{:});
        end
    end
    
    methods (Abstract)
        varargout = forwardOperation(obj, varargin)
        varargout = backwardOperation(obj, varargin)
    end

    properties
        name, id
    end
    properties (Hidden)
        apshare % field shared between input/output access points
    end
    properties (Abstract, Constant)
        taxis      % [TRUE/FALSE] indicator of capability of dealing with time axis
        expandable % [TRUE/FALSE] indicator of capability of higher dimensional data
    end
end
