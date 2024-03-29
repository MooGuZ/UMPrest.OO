classdef SimulationTest < Task
    methods
        function objval = run(obj, iteration, batchsize, validsize)
            if iscell(obj.dataset)
                validset.data = cellfun(@(ds) ds.next(validsize), obj.dataset, 'UniformOutput', false);
            else
                validset.data = {obj.dataset.next(validsize)};
            end
            if iscell(obj.objective)
                validset.label = cell(1, numel(obj.objective));
                [validset.label{:}] = obj.ref.forward(validset.data{:});
            else                
                validset.label = obj.ref.forward(validset.data{:});
            end
            % get optimizer and reserve current setting
            opt = HyperParam.getOptimizer();
            opt.push();
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
            % compare hyperparam
            if obj.rawcompare
                distinfo(abs(obj.ref.dumpraw() - obj.model.dumpraw()), 'HPARAM ERROR', false);
            end
            disp(repmat('=', 1, 100));
            fprintf('Initial objective value : %.2e\n', objval);
            if opt.cache.rcdmode.status
                opt.record(objval, false);
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
                    [label{:}] = obj.ref.forward(data{:});
                    [odata{:}] = obj.model.forward(data{:});
                    for j = 1 : numel(delta)
                        delta{j} = obj.objective{j}.delta(odata{j}, label{j});
                    end
                    obj.model.backward(delta{:});
                else
                    label = obj.ref.forward(data{:});
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
                    fprintf('Objective Value after [%04d] turns: %.2e ', i, objval);
                    if opt.cache.rcdmode.status
                        fprintf('[ESTCH : %.2e]\n', opt.cache.stepmode.estch);
                        opt.record(objval, false);
                    else
                        fprintf('\n');
                    end
                end
            end
            disp(repmat('=', 1, 100));
            if obj.rawcompare
                distinfo(abs(obj.ref.dumpraw() - obj.model.dumpraw()), 'HPARAM ERROR', false);
            end
            % restore optimization setting reserved at beginning
            opt.pop();
        end
    end
    
    methods
        function obj = SimulationTest(model, ref, dataset, objective)
            obj.model     = model;
            obj.ref       = ref;
            obj.dataset   = dataset;
            obj.objective = objective;
        end
    end
    
    properties
        rawcompare = true
    end
    
    properties (SetAccess = protected)
        ref
    end
    methods
        function set.ref(obj, value)
            assert(isa(value, 'BuildingBlock'), 'ILLEGAL ASSIGNMENT');
            obj.ref = value;
        end
    end
end