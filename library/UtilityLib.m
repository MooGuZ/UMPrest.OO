% UTILITYLIB < handle
%   UTILITYLIB provides functions that help subclass finish common
%   tasks accross different classes.
%
% see also, handle, hgsetget
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
classdef UtilityLib < hgsetget
    methods (Access = protected)
        % SETUPBYARG setup object's properties by arguments
        %   SETUPBYARG(OBJ, VARARGIN) provides subclass capability to take
        %   <string, value> pairs as arguments to setup its property values.
        %   This function is extremely useful in constructor. This function
        %   also accept name of sub-field of a property in the form <p.subfield>.
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
                    fprintf('%-13s %17s : %s\n', ...
                        ['[',class(obj),']'], strcatby(ret, '.'), var2str(value));
                end
            end
        end
    end
end
