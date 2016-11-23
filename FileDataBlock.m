classdef FileDataBlock < DataBlock
    methods
        function data = fetch(obj, n)
            % initialize output
            data = {};
            % fillup output from cache util done
            while n > 0
                % CASE: enough data in cache
                if n <= numel(obj.cache) - obj.icache
                    data = [data, obj.cache(obj.icache + (1 : n))];
                    obj.icache = obj.icache + n;
                    break
                % CASE: cache is traversed
                elseif obj.icache >= numel(obj.cache)
                    obj.refresh();
                % CASE: not enough data in cache
                else
                    n = n - (numel(obj.cache) - obj.icache);
                    data = [data, obj.cache(obj.icache + 1 : end)];
                    obj.refresh();
                end
            end
        end
        
        function refresh(obj)
            if not(obj.autoload.status) || obj.autoload.iid >= obj.volumn
                obj.shuffle();
                return
            end
            % initialize variables
            i = 1;
            n = min(obj.volumn - obj.autoload.iid, obj.capacity);
            obj.cache = cell(1, n);
            % initialize output information
            if usejava('desktop')
                hwbar = waitbar(0);
                set(get(get(hwbar, 'children'), 'title'), 'Interpreter', 'none');
            else
                disp('START LOADING FILES');
            end
            % fillup cache one by one
            while i <= n
                obj.autoload.iid = obj.autoload.iid + 1;
                % CASE: files have been traversed
                if obj.autoload.iid > obj.volumn
                    obj.autoload.iid = obj.volumn;
                    obj.cache = obj.cache(1:i-1);
                    break
                end
                % read a file to cache
                index = obj.order(obj.autoload.iid);
                try
                    obj.cache{i} = obj.getdata(index);
                    % CASE: successfully read the file
                    if usejava('desktop')
                        waitbar(i / n, hwbar, sprintf('LOADING FILE : %d / %d', i, n));
                    elseif mod(i, ceil(n / 10)) == 0
                        fprintf('%5d%% FILES LOADED\n', round((i / n) * 100));
                    end
                    i = i + 1;
                catch ME % CASE: file reading failed
                    warning('NOT LOAD: %s\n [INFO] %s', obj.ftree.get(index), ME.message);
                    obj.autoload.ifailed(end + 1) = index;
                end
            end
            if usejava('desktop')
                close(hwbar);
            else
                disp('FILE LOADIND COMPLETE');
            end
            % reset index of cache
            obj.icache = 0;
        end
        
        function shuffle(obj)
            if obj.autoload.status
                % remove bad files from file tree
                if not(isempty(obj.autoload.ifailed))
                    arrayfun(@obj.ftree.delete, ...
                        sort(obj.autoload.ifailed, 'descent'));
                    obj.autoload.ifailed = [];
                end
                % get new random order
                obj.order = randperm(obj.volumn);
                % reset file index
                obj.autoload.iid = 0;
                % initialize cache in new order
                obj.refresh();
                % CASE: cache capacity is sufficient for whole data
                if obj.autoload.iid >= obj.volumn
                    obj.disableAutoload();
                end
            else
                % generate permutation map
                index = randperm(obj.volumn);
                % reorganize order and cache according to the map
                obj.order = obj.order(index);
                obj.cache = obj.cache(index);
                % reset index of cache
                obj.icache = 0;
            end
        end
        
        function [data, label] = recent(obj)
            if obj.icache
                data = obj.cache(obj.icache);
            else
                data = [];
            end
            label = [];
        end

        function reset(obj)
            if obj.autoload.status
                cacheStart = obj.autoload.iid - numel(obj.cache) + 1;
                if cacheStart > 1
                    obj.order = obj.order([cacheStart : end, 1 : cacheStart - 1]);
                end
            end
            obj.icache = 0;
        end
        
        function data = getdata(obj, index)
            data = obj.readFcn(obj.ftree.get(index));
            if obj.stat.status && not(obj.stat.tag(index))
                obj.stat.collector.commit(data);
                obj.stat.tag(index) = true;
            end
        end
        
        function enableStatistics(obj, sc)
            obj.stat = struct( ...
                'status',    true, ...
                'collector', sc, ...
                'tag',       false(1, obj.volumn));
        end
        
        function disableStatistics(obj)
            obj.stat = struct('status', false);
        end
        
        function enableAutoload(obj)
            obj.autoload = struct('status', true, 'iid', 0, 'ifailed', []);
        end
        
        function disableAutoload(obj)
            obj.autoload = struct('status', false);
        end
    end
    
    methods
        function obj = FileDataBlock(flist, readFcn, extList, stat)
            obj.readFcn = readFcn;
            % create file tree
            if iscell(flist)
                if isscalar(flist)
                    obj.ftree = FileTree(flist{1}, 'pattern', extList);
                else
                    obj.ftree = FileTree('/', 'pattern', extList, '-noexpand');
                    for i = 1 : numel(flist)
                        p = abspath(flist{i});
                        if isdir(p)
                            obj.ftree.subfolder = [obj.ftree.subfolder, ...
                                FileTree(p, 'parent', obj.ftree, 'pattern', extList)];
                        elseif exist(p, 'file')
                            obj.ftree.subfile = [obj.ftree.subfile, p];
                        else
                            warning('NOT EXIST: %s', p);
                        end
                    end
                    obj.ftree.refresh();
                end
            elseif ischar(flist)
                obj.ftree = FileTree(flist, 'pattern', extList);
            else
                error('The 1st argument should be string or cell array');
            end
            % setup statistic collecter
            if exist('stat', 'var')
                obj.enableStatistics(stat)
            else
                obj.disableStatistics();
            end
            % setup autoload feature
            obj.enableAutoload();
            % initialize the library
            obj.shuffle();            
        end
    end
    
    properties
        capacity = UMPrest.parameter.get('datasetCapacity');
    end
    
    properties %(SetAccess = private, Hidden)
        ftree, order
        cache, icache
        autoload, stat
        readFcn
    end
    
    properties (Dependent)
        volumn
    end
    methods
        function value = get.volumn(obj)
            value = obj.ftree.volumn;
        end
    end
end
