classdef EvolvingUnit < Unit
    % ======================= EVOLVING MODULE =======================
    methods
        function trainproc(obj, datapkg)
            if datapkg.isunified
                obj.learn(datapkg);
            else
                for i = 1 : numel(datapkg.ndata)
                    obj.learn(datapkg.get(i));
                end
            end
            obj.age = obj.age + datapkg.ndata;
        end
    end

    methods (Abstract)
        learn(obj, datapkg)
        update(obj, stepsize)
    end
    
    properties
        age = 0;
        likelihood
    end
    methods
        function set.likelihood(obj, value)
            assert(isempty(value) || isa(value, 'Likelihood'));
            obj.likelihood = value;
        end
    end
end
