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

        function tof = autosave(obj, key)
            % create saving folder if necessary
            if not(isdir(obj.savePath))
                mkdir(obj.savePath);
            end
            % save object according to time
            if obj.saveCriteria(key)
                save( ...
                    fullfile(obj.savePath, sprintf('%s-%s.mat', lower(class(obj)), obj.timestamp())), ...
                    'obj');
                obj.lastsave = key;
                tof = true;
            else
                tof = false;
            end
        end

        function tof = saveCriteria(obj, key)
            tof = false;
            if islogical(key) && key
                tof = true;
            elseif obj.lastsave == -inf
                if key >= obj.interval * obj.unit
                    tof = true;
                end
            elseif key - obj.lastsave >= obj.interval * obj.unit
                tof = true;
            end
        end
    end
    properties
        mode = 'count';
        interval = 1000;
        savePath = './';
    end
    properties (Access = protected)
        timestamp = @() datestr(now, 30);
    end
    properties (Access = private)
        lastsave = -inf;
    end
    properties (Dependent, Hidden)
        unit
    end
    methods
        function value = get.unit(obj)
            switch lower(obj.mode)
            case {'time', 'second'}
                value = datenum(0, 0, 0, 0, 0, 1);
            case {'count', 'iteration', 'sample'}
                value = 1;
            otherwise
                error('[AUTOSAVE] unrecognized mode : %s', obj.mode)
            end
        end
    end
end
