classdef MemoryDataBlock < DataBlock
    methods
        function [dcell, lcell] = fetch(obj, n)
            if obj.icache >= numel(obj.cache)
                obj.refreshCache();
            end
            
            % case : need refresh cache
            if n > obj.volumn() - obj.icache
                nbatch = ceil((n - (obj.volumn() - obj.icache)) / ...
                    obj.volumn()) + 1;
                
                if obj.islabelled
                    dbuffer = cell(1, nbatch);
                    lbuffer = cell(1, nbatch);
                    
                    index = obj.order(obj.icache + 1 : obj.volumn());
                    dbuffer{1} = obj.cache.data(index);
                    lbuffer{1} = obj.cache.label(index);
                    
                    n = n - (obj.volumn() - obj.icache);
                    for i = 2 : nbatch - 1
                        obj.refreshCache();
                        dbuffer{i} = obj.cache.data(obj.order);
                        lbuffer{i} = obj.cache.label(obj.order);
                        n = n - obj.volumn();
                    end
                    obj.refreshCache();
                    dbuffer{end} = obj.cache.data(obj.order(1 : n));
                    lbuffer{end} = obj.cache.label(obj.order(1 : n));
                    obj.icache = n;
                    dcell = cellcomb(dbuffer);
                    lcell = cellcomb(lbuffer);
                else
                    buffer = cell(1, nbatch);
                    buffer{1} = obj.cache(obj.order(obj.icache + 1 : obj.volumn()));
                    n = n - (obj.volumn() - obj.icache);
                    for i = 2 : nbatch - 1
                        obj.refreshCache();
                        buffer{i} = obj.cache(obj.order);
                        n = n - obj.volumn();
                    end
                    obj.refreshCache();
                    buffer{end} = obj.cache(obj.order(1 : n));
                    obj.icache = n;
                    dcell = cellcomb(buffer);
                    lcell = {};
                end
            else % case : normal
                if obj.islabelled
                    dcell = obj.cache.data(obj.order(obj.icache + (1 : n)));
                    lcell = obj.cache.label(obj.order(obj.icache + (1 : n)));
                else
                    dcell = obj.cache(obj.order(obj.icache + (1 : n)));
                    lcell = {};
                end
                obj.icache = obj.icache + n;
            end
        end
        
        function [data, label] = recent(obj)
            if obj.islabelled
                if obj.icache
                    data  = obj.cache.data(obj.order(obj.icache));
                    label = obj.cache.label(obj.order(obj.icache));
                else
                    data  = [];
                    label = [];
                end
            else
                if obj.icache
                    data = obj.cache(obj.order(obj.icache));
                else
                    data = [];
                end
            end
        end
        
        function n = volumn(obj)
            if obj.islabelled
                n = numel(obj.cache.data);
            else
                n = numel(obj.cache);
            end
        end
    end
    
    methods
        function reset(obj)
            obj.icache = 0;
        end
        
        function refreshCache(obj)
            if obj.islabelled
                obj.order = randperm(numel(obj.cache.data));
            else
                obj.order = randperm(numel(obj.cache));
            end
            obj.icache = 0;
        end
    end
    
    methods
        function obj = MemoryDataBlock(dcell, stat, varargin)
            conf = Config.parse(varargin);
            if Config.keyExist(conf, 'label')
                lcell = Config.getValue(conf, 'label', {});
                assert(iscell(dcell) && iscell(lcell));
                assert(numel(dcell) == numel(lcell));
                obj.cache = struct('data', {dcell}, 'label', {lcell});
            else
                obj.cache = dcell;
            end
            obj.order  = randperm(obj.volumn());
            obj.icache = 0;
            if exist('stat', 'var')
                obj.stat = stat;
                if obj.stat.status && obj.stat.ncommit == 0
                    for i = 1 : obj.volumn()
                        obj.stat.commit(dcell{i});
                    end
                end
            else
                obj.stat = StatisticCollector();
            end
        end
    end
    
    properties
        stat, cache
    end
    methods
        function set.stat(obj, statobj)
            assert(isa(statobj, 'StatisticCollector'));
            obj.stat = statobj;
        end
        
        function set.cache(obj, value)
            if iscell(value)
                for i = 1 : numel(value)
                    assert(isnumeric(value{i}));
                end
                obj.cache = value;
            elseif isstruct(value)
                assert(all(isfield(value, {'data', 'label'})));
                assert(iscell(value.data) && iscell(value.label));
                assert(numel(value.data) == numel(value.label));
                for i = 1 : numel(value.data)
                    assert(isnumeric(value.data{i}));
                    assert(isnumeric(value.label{i}) || islogical(value.label{i}));
                end
                obj.cache = struct();
                obj.cache.data = value.data;
                obj.cache.label = value.label;
            end
        end
    end
    
    properties (Dependent, SetAccess = private)
        islabelled        
    end
    methods
        function value = get.islabelled(obj)
            value = isstruct(obj.cache);
        end
    end
    
    properties (Access = private)
        order, icache
    end
end
