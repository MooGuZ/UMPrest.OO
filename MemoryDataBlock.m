classdef MemoryDataBlock < DataBlock
    methods
        function refresh(obj)
            obj.cache  = obj.cache(randperm(numel(obj.cache)));
            obj.icache = 0;
        end
    end
    
    methods
        function enableStatistics(obj, collector)
            obj.stat = struct( ...
                'status', true, ...
                'collector', collector);
        end
        
        function disableStatistics(obj)
            obj.stat = struct('status', false);
        end
    end
    
    methods
        % [NECESSARY]
        %   data : cell array or numerical matrix. In the latter case, this
        %          program would assuming the last dimension of matrix
        %          corresponds to sample index and no label for each sample
        % [OPTIONAL]
        %   scollector : statistic collector
        function obj = MemoryDataBlock(data, scollector)
            if iscell(data)
                if all(cellfun(@isstruct, data)) && ...
                        all(cellfun(@(s) isfield(s, {'data', 'label'}), data))
                    obj.islabelled = true;
                else
                    assert(all(cellfun(@isnumeric, data)), 'ILLEGAL ARGUMENT');
                    obj.islabelled = false;
                end
                obj.cache = data;
            else
                assert(isnumeric(data), 'ILLEGAL ARGUMENT');
                obj.islabelled = false;
                obj.cache = pack2cell(data);
            end
            obj.icache = 0;
            % initialize statistic structure
            if exist('scollector', 'var') && isa(scollector, 'StatisticCollector')
                obj.enableStatistics(scollector);
                if obj.islablled
                    cellfun(@(s) obj.stat.collector.commit(s.data), obj.cache);
                else
                    cellfun(@(d) obj.stat.collector.commit(d), obj.cache);
                end
                obj.stat.collector.freeze();
            else
                obj.disableStatistics();
            end
        end
    end
    
    properties (Dependent)
        volumn
    end
    methods
        function value = get.volumn(obj)
            value = numel(obj.cache);
        end
    end
end
