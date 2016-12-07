classdef MIMOUnit < SimpleUnit
    methods
        function varargout = propagate(obj, apin, apout, proc, varargin)
            % clear CDINFO of parent unit
            obj.apshare = struct();
            % get input package
            if isempty(varargin)
                ipackage = arrayfun(@pop, apin, 'UniformOutput', false);
            else
                ipackage = varargin;
            end
            % unpack data from package
            idata = arrayfun(@(i) apin(i).unpack(ipackage{i}), 1 : numel(apin), ...
                'UniformOutput', false);
            % process the data
            odata = cell(1, numel(apout));
            [odata{:}] = proc(obj.apshare.class, idata{:});
            % packup data into package
            varargout = arrayfun(@(i) apout(i).packup(odata{i}), 1 : numel(apout), ...
                'UniformOutput', false);
            % send package if no output argument
            if nargout == 0
                arrayfun(@(i) apout(i).send(varargout{i}), 1 : numel(apout));
            end
        end
    end
end
