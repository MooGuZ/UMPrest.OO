classdef LibUtility < hgsetget
    methods
        % ------- SETUPBYARG -------
        function setupByArg(obj, varargin)
            [keys, values] = propertyParse(varargin{:});
            if isempty(keys), return; end
            % analyse and set up each value according to its key
            fprintf('\n======= Parameter Setting [%s] =======\n', class(obj));
            for i = 1 : numel(keys)
                key   = keys{i};
                value = values{i};
                % decompose key into fields
                fields = strsplit(key, '.');
                % recursively search properties accrding to fields
                ret = findSubField(obj, fields);
                if iscell(ret)
                    eval(sprintf('obj.%s = value;', strcatby(ret, '.')));
                    fprintf('[%13s] %-17s : %s\n', class(obj), strcatby(ret, '.'), var2str(value));
                end
            end
        end
    end
end
