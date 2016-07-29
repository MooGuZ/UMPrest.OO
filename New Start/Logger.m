% TODO: redesign the logic and interfaces
classdef Logger < handle
    methods
        function initRecord(obj, id, datapkg, varargin)
            assert(ischar(id));
            
            conf = Config.parse(varargin);
            if not(isfield(obj.rec, id))
                obj.rec.(id) = struct( ...
                    'counter',   0,  ...
                    'timestamp', zeros(1, 1e3), ...
                    'objective', zeros(1, 1e3), ...
                    'interval',  1);
            end
            obj.rec.(id) = Config.apply(obj.rec.(id), conf);
            
            obj.record(id, datapkg);
        end
        
        function record(obj, id, datapkg)
            counter = obj.rec.(id).counter + 1;
            if counter > numel(obj.rec.(id).timestamp)
                obj.rec.(id) = obj.extendRecord(obj.rec.(id));
            end
            timestamp = obj.model.age;
            if counter < 2 || ...
                    timestamp - obj.rec.(id).timestamp(counter - 1) >= obj.rec.(id).interval
                result = obj.model.forward(datapkg);
                obj.rec.(id).timestamp(counter) = timestamp;
                obj.rec.(id).objective(counter) = obj.model.likelihood.evaluate(result);
                obj.rec.(id).counter = counter;
                switch obj.dmode
                    case {'shell'}
                        fprintf('%13s >> objective value after [%04d] updates [%.2f]\n', ...
                            upper(id), timestamp, obj.rec.(id).objective(counter));
                        if not(isempty(obj.model.task))
                            disp(obj.model.task.run(result.data, result.label));
                        end
                end
            end
        end
        
        function ext = recordExtend(~, rec)
            ext = rec;
            n = numel(rec.timestamp);
            ext.timestamp = zeros(1, 2 * n);
            ext.objective = zeros(1, 2 * n);
            ext.timestamp(1 : n) = rec.timestamp;
            ext.objective(1 : n) = rec.objective;
        end
    end
    
    methods
        function obj = Logger(model, dispmode)
            if isempty(model.logger)
                obj.model = model;
                obj.rec = struct();
                model.logger = obj;
            else
                obj = model.logger;
            end
            
            if exist('dispmode', 'var')
                obj.dmode = dispmode;
            else
                obj.dmode = 'shell';
            end
        end
    end
    
    properties
        model
        rec
        dmode
    end
    methods
        function set.dmode(obj, value)
            assert(ischar(value) && any(strcmpi(value, obj.dmodeSet)));
            obj.dmode = lower(value);
        end
    end
    
    properties (Constant)
        dmodeSet = {'off', 'shell', 'gui'};
    end
end
