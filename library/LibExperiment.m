classdef LibExperiment < hgsetget
    methods
        % ------- AUTOSAVE -------
        function autosave(obj)
            % initialize LASTSAVE if necessary
            if isempty(obj.lastsave)
                obj.lastsave = now();
                return
            end
            % save object according to time
            if isdir(obj.savePath)
                if now() - obj.lastsave > obj.interval
                    objname = inputname(1);
                    eval(sprintf('%s = obj;', objname));
                    save( ...
                        fullfile(obj.savePath, sprintf('%s-%s.mat', objname, obj.timestamp())), ...
                        objname);
                    % update time of last save
                    obj.lastsave = now();
                end
            else
                mkdir(obj.savePath);
            end
        end
    end
    properties
        % ------- AUTOSAVE -------
        savePath = 'autosave';
    end
    properties (Access = protected)
        % ------- UTILITIES -------
        timestamp = @() datestr(now, 30);
    end
    properties (Access = private)
        % ------- AUTOSAVE -------
        lastsave
        interval = datenum(0, 0, 0, 1, 0, 0);
    end
    properties (Dependent)
        % ------- AUTOSAVE -------
        saveInterval
    end
    methods
        function value = get.saveInterval(obj)
            value = round(obj.interval / datenum(0, 0, 0, 0, 0, 1));
        end
        function set.saveInterval(obj, value)
            obj.interval = datenum(0, 0, 0, 0, 0, value);
        end
    end
end
