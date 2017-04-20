classdef MemoryDataBlock < DataBlock
    methods
        function refresh(obj)
            obj.cache  = obj.cache(randperm(numel(obj.cache)));
            obj.icache = 0;
        end
        
        function mdb = subset(obj, n)
            index = randperm(obj.volumn, n);
            if obj.stat.status
                mdb = MemoryDataBlock(obj.cache(index), 'stat', obj.stat.collector.dsample);
            else
                mdb = MemoryDataBlock(obj.cache(index));
            end
            obj.cache(index) = [];
        end
    end
    
    methods
        function obj = enableStatistics(obj, statdim)
            obj.stat = struct( ...
                'status',    true, ...
                'collector', StatisticCollector(statdim));
        end
        
        function obj = disableStatistics(obj)
            obj.stat = struct('status', false);
        end
    end
    
    methods
        % [NECESSARY]
        %   data : cell array or numerical matrix. In the latter case, this
        %          program would assuming the last dimension of matrix
        %          corresponds to sample index and no label for each sample
        % [KEY-VALUE PAIRS]
        %   ('stat', STATDIM) create statistic collector with statistical dimension STATDIM
        function obj = MemoryDataBlock(data, varargin)
            conf = Config(varargin);
            if iscell(data)
                if all(cellfun(@isstruct, data)) && ...
                        all(cellfun(@(s) all(isfield(s, {'data', 'label'})), data))
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
            if conf.exist('stat')
                obj.enableStatistics(conf.pop('stat'));
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
