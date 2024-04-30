classdef SimulationTest < Task
    methods
        function exprcd = run(obj, iteration, batchsize, validsize)
            if iscell(obj.dataset)
                validset.data = cellfun(@(ds) ds.next(validsize), obj.dataset, 'UniformOutput', false);
            else
                validset.data = {obj.dataset.next(validsize)};
            end
            if iscell(obj.objective)
                validset.label = cell(1, numel(obj.objective));
                [validset.label{:}] = obj.refer.forward(validset.data{:});
            else                
                validset.label = obj.refer.forward(validset.data{:});
            end
            % reserve current setting
            obj.optimizer.push();
            % check objective value of current state
            if iscell(obj.objective)
                objval = 0;
                output = cell(1, numel(obj.objective));
                [output{:}] = obj.model.forward(validset.data{:});
                for i = 1 : numel(obj.objective)
                    objval = objval + obj.objective{i}.evaluate(output{i}, validset.label{i});
                end
            else                
                objval = obj.objective.evaluate(obj.model.forward(validset.data{:}), validset.label);
            end
            % compare hyper-parameter
            if obj.rawcompare
                distinfo(abs(obj.refer.dumpraw() - obj.model.dumpraw()), 'HPARAM ERROR', false);
            end

            % start to record the process
            exprcd = ExperimentRecord(iteration);
            if obj.recordParam
                exprcd.record(0, objval, obj.model.getParam());
            else
                exprcd.record(0, objval);
            end
            % start simulation process
            for i = 1 : iteration
                if iscell(obj.dataset)
                    data = cellfun(@(ds) ds.next(batchsize), obj.dataset, 'UniformOutput', false);
                else
                    data = {obj.dataset.next(batchsize)};
                end
                if iscell(obj.objective)
                    label = cell(1, numel(obj.objective));
                    odata = cell(1, numel(label));
                    delta = cell(1, numel(label));
                    [label{:}] = obj.refer.forward(data{:});
                    [odata{:}] = obj.model.forward(data{:});
                    for j = 1 : numel(delta)
                        delta{j} = obj.objective{j}.delta(odata{j}, label{j});
                    end
                    obj.model.backward(delta{:});
                else
                    label = obj.refer.forward(data{:});
                    odata = obj.model.forward(data{:});
                    obj.model.backward(obj.objective.delta(odata, label));
                end                
                obj.model.update();
                % check objective value of current state
                if not(mod(i, 10))
                    if iscell(obj.objective)
                        objval = 0;
                        output = cell(1, numel(obj.objective));
                        [output{:}] = obj.model.forward(validset.data{:});
                        for j = 1 : numel(obj.objective)
                            objval = objval + obj.objective{j}.evaluate(output{j}, validset.label{j});
                        end
                    else
                        objval = obj.objective.evaluate(obj.model.forward(validset.data{:}), validset.label);
                    end
                    
                    if obj.recordParam
                        exprcd.record(i, objval, obj.model.getParam());
                    else
                        exprcd.record(i, objval);
                    end
                end
            end

            if obj.rawcompare
                distinfo(abs(obj.refer.dumpraw() - obj.model.dumpraw()), 'HPARAM ERROR', false);
            end
            % restore optimization setting reserved at beginning
            obj.optimizer.pop();
        end
    end
    
    methods
        function obj = SimulationTest(model, refer, dataset, objective)
            obj.model     = model;
            obj.refer     = refer;
            obj.dataset   = dataset;
            obj.objective = objective;
        end
    end
    
    properties
        rawcompare  = true
        recordParam = false
    end
    properties (SetAccess = protected)
        refer
    end
    properties (Constant)
        optimizer = UMPrest.getGlobalOptimizer()
    end
end