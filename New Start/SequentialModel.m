classdef SequentialModel < EvolvingUnit
    methods
        function y = transproc(obj, x)
            for i = 1 : numel(obj.unitList)
                x = obj.unitList{i}.transform(x);
            end
            y = x;
        end
        
        function d = errprop(obj, d)
            for i = numel(obj.unitList) : -1 : 1
                d = obj.unitList{i}.errprop(d);
            end
        end
        
        function update(obj)
            for i = 1 : numel(obj.unitList)
                if isa(obj.unitList{i}, 'EvolvingUnit')
                    obj.unitList{i}.update();
                end
            end
            obj.updateCounter = obj.updateCounter + 1;
        end
        
        function value = evaluate(obj, datapkg)
            value = obj.objective.evaluate(obj.forward(datapkg));
        end
    end
    
    methods
        function appendUnit(obj, unit)
            obj.unitList = [obj.unitList, {unit}];
        end
    end
    
    methods
        function trainproc(obj, datapkg)
            obj.errprop(obj.objective.delta(obj.forward(datapkg)));
            obj.update();
        end
        
        function train(obj, dataset, objective, varargin)
            obj.objective = objective;
            Trainer.minibatch(obj, dataset, varargin{:});          
        end
    end
    
    properties
        unitList
        objective
        logger
        tasktype
        updateCounter = 0;
    end
    methods
        function set.tasktype(obj, value)
            assert(isempty(value) || ...
                (ischar(value) && any(strcmpi(value, Task.typelist()))));
            obj.tasktype = value;
        end
    end
end
