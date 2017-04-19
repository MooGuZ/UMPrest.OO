% DATABLOCK works as a container of data. It provides a method FETCH for
% caller to obtain sample without concern of implementation detail.
% DATABLOCK would automatically load data and shuffle samples.
classdef DataBlock < handle
    methods (Abstract)
        refresh(obj) % reload data from source to cache
        db = subset(obj, n)
    end
    
    methods (Abstract)
        obj = enableStatistics(obj, statdim)
        obj = disableStatistics(obj)
    end
    
    methods
        function data = fetch(obj, n)
            data = cell(1, n);
            % refresh cache if it is traversed
            if obj.icache >= numel(obj.cache)
                obj.refresh();
            end
            % initialize index filled units
            index = 0;
            % fillup output from cache util done
            while n > 0
                if n <= numel(obj.cache) - obj.icache % CASE: enough data in cache
                    data(index + (1 : n)) = obj.cache(obj.icache + (1 : n));
                    obj.icache = obj.icache + n;
                    break
                else % CASE: not enough data in cache
                    m = numel(obj.cache) - obj.icache;
                    data(index + (1 : m)) = obj.cache(obj.icache + 1 : end);
                    % update index, counter, and cache
                    n     = n - m;
                    index = index + m;
                    obj.refresh();
                end
            end
        end
    end
    
    % PRP: abstract fetch method of cache or made cache a linear container
    %      that automatically choose most effective storage method
    properties (SetAccess = protected)
        cache  % cell array containing data loaded in the memeory
        icache % index of cache indicating fetching progress (pointing to last readed unit)
        islabelled % (T/F) indicating whether or not data comes with label
        stat % control structure of statistical collector
    end
    methods
        function set.cache(obj, value)
            assert(iscell(value), 'ILLEGAL ASSIGNMENT');
            obj.cache = value;
        end
        
        function set.icache(obj, value)
            assert(MathLib.isinteger(value) && value >= 0, 'ILLEGAL ASSIGNMENT');
            obj.icache = value;
        end
        
        function set.islabelled(obj, value)
            assert(islogical(value), 'ILLEGAL ASSIGNMENT');
            obj.islabelled = value;
        end
    end
    
    properties (Abstract, Dependent)
        volumn % quantity of unique data unit containes
    end
end
