% AutoSave < hgsetget
%   AutoSave provide user interface 'autosave' to save objects according to
%   given keys. Different modes are supported in the library. For example,
%   in mode 'time', key can be current time.
%
% see also, handle, hgsetget
%
% MooGu Z. <hzhu@case.edu>
% Nov 30, 2015
%
% [Change Log]
% Nov 30, 2015 - initial commit
classdef AutoSave < hgsetget
    methods
        function tof = autosave(obj, key)
            if isemtpy(obj.taskCode)
                obj.taskCode = lower(class(obj));
            end
            % create saving folder if necessary
            if not(isdir(obj.savePath))
                mkdir(obj.savePath);
            end
            % save object according to time
            if obj.saveCriteria(key)
                save(fullfile(obj.savePath, ...
                        sprintf('%s-%s.mat', obj.taskCode, obj.timestamp())), ...
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
        interval = 5000;
        savePath = './';
        taskCode;
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
