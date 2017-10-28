classdef FileDataBlock < DataBlock
    methods
        function refresh(obj)
            if not(obj.autoload.status)
                obj.shuffle();
                return
            elseif obj.autoload.iid >= numel(obj.order)
                if not(isempty(obj.autoload.ifailed))
                    obj.deleteFiles(obj.order(obj.autoload.ifailed));
                    obj.autoload.ifailed = [];
                end
                obj.shuffle();
                return
            end
            % initialize variables
            i = 1;
            n = min(numel(obj.order) - obj.autoload.iid, obj.capacity);
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
                if obj.autoload.iid > numel(obj.order)
                    obj.autoload.iid = numel(obj.order);
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
                    obj.autoload.ifailed(end + 1) = obj.autoload.iid;
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
        
        function deleteFiles(obj, index)
            % index = unique(index); % this is necessary for public use
            obj.ftree.delete(index);
            % remove tags in statistic controller
            if obj.stat.status
                obj.stat.tag(index) = [];
            end
            % update order list
            pos = true(1, numel(obj.order));
            pos(index) = false;
            map = zeros(1, numel(obj.order));
            map(pos) = 1 : numel(obj.order) - numel(index);
            obj.order = map(obj.order);
            obj.order(obj.order == 0) = [];
        end
        
        function shuffle(obj)
            if obj.autoload.status
                % get new random order
                obj.order = randperm(obj.volume);
                % reset file index
                obj.autoload.iid = 0;
                % initialize cache in new order
                if obj.volume
                    obj.refresh();
                end
                % CASE: cache capacity is sufficient for whole data
                if obj.autoload.iid >= numel(obj.order)
                    obj.disableAutoload();
                end
            else
                % generate permutation map
                index = randperm(obj.volume);
                % reorganize order and cache according to the map
                obj.order = obj.order(index);
                obj.cache = obj.cache(index);
                % reset index of cache
                obj.icache = 0;
            end
        end
        
        function data = getdata(obj, index)
            dataPath = obj.ftree.get(index);
            % load data from file system to memory
            data = obj.dataReadFcn(dataPath);
            % collect statistics information
            if obj.stat.status && not(obj.stat.tag(index))
                obj.stat.collector.commit(data);
                obj.stat.tag(index) = true;
            end
            % load corresponding label
            if obj.islabelled
                data = struct('data', data, ...
                    'label', obj.labelReadFcn(obj.labelSearchFcn(dataPath)));
            end
        end
    end
    
    methods
        function mdb = subset(obj, n)
        % create a MemoryDataBlock containing subset of this FileDataBlock's files. And
        % remove these file from this DB.
            assert(n < obj.volume && n > 0 && MathLib.isinteger(n) && isscalar(n), ...
                'ILLEGAL OPERATION');
            
            if obj.autoload.status
                count = 0;
                dcell = cell(1, n);
                while count < n
                    ndata   = numel(obj.cache);
                    ndelete = min(n - count, ndata);
                    % fill update data cell
                    dcell(count + (1 : ndelete)) = obj.cache(ndata + (1 - ndelete : 0));
                    % note all these files as to-be-deleted
                    if isempty(obj.autoload.ifailed)
                        obj.autoload.ifailed = obj.autoload.iid + (1 - ndelete : 0);
                    else
                        dist = diff([0, obj.autoload.ifailed, obj.autoload.iid + 1]) - 1;
                        dcum = cumsum(dist(end : -1 : 1));
                        index = find(ndelete <= dcum, 1, 'first');
                        if index <= 1
                            obj.autoload.ifailed = ...
                                [obj.autoload.ifailed, obj.autoload.iid + (1 - ndelete : 0)];
                        else
                            start = obj.autoload.ifailed(numel(dcum) - index + 1) ...
                                    - (ndelete - dcum(index - 1));
                            obj.autoload.ifailed = [obj.autoload.ifailed(1 : numel(dcum) - index), ...
                                start : obj.autoload.iid];
                        end
                    end
                    % update count
                    count = count + ndelete;
                    % refresh cache
                    obj.refresh();
                    % CASE : autoload is turned off
                    if not(obj.autoload.status) && count < n
                        assert(obj.volume > n - count, 'DATA IS NOT ENOUGH');
                        index = randperm(obj.volume);
                        dcell(count + 1 : n) = obj.cache(index(1 : n - count));
                        obj.cache = obj.cache(index(n - count + 1 : end));
                        obj.deleteFiles(obj.order(index(1 : n - count)));
                        break
                    end
                end
            else
                index = randperm(obj.volume);
                dcell = obj.cache(index(1 : n));
                obj.cache = obj.cache(index(n+1 : end));
                obj.deleteFiles(obj.order(index(1 : n)));
            end
            % build a MemoryDataBlock
            if obj.stat.status
                mdb = MemoryDataBlock(dcell, 'stat', obj.stat.collector.dsample);
            else
                mdb = MemoryDataBlock(dcell);
            end
        end
    end
    
    methods
        function obj = enableStatistics(obj, dim)
            obj.stat = struct( ...
                'status',    true, ...
                'collector', StatisticCollector(dim), ...
                'tag',       false(1, obj.volume));
        end
        
        function obj = disableStatistics(obj)
            obj.stat = struct('status', false);
        end
    end
    
    properties (SetAccess = protected)
        autoload % control structure of autoload system
    end
    methods 
        function enableAutoload(obj)
            obj.autoload = struct('status', true, 'iid', 0, 'ifailed', []);
        end
        
        function disableAutoload(obj)
            if not(isempty(obj.autoload.ifailed))
                obj.deleteFiles(obj.order(obj.autoload.ifailed));
            end
            obj.autoload = struct('status', false);
        end
    end
       
    methods (Access = protected)
        function enableLabel(obj, labelSearchFcn, labelReadFcn)
            obj.islabelled = true;
            obj.labelSearchFcn = labelSearchFcn;
            obj.labelReadFcn = labelReadFcn;
        end
        
        function disableLabel(obj)
            obj.islabelled = false;
            obj.labelSearchFcn = [];
            obj.labelReadFcn = [];
        end
    end
    
    methods
        function obj = FileDataBlock(flist, dataReadFcn, extList, varargin)
            conf = Config(varargin);
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
            % setup data read function handle
            obj.dataReadFcn = dataReadFcn;
            % setup autoload feature
            obj.enableAutoload();
            % setup statistic collecter
            if conf.exist('stat')
                obj.enableStatistics(conf.pop('stat'));
            else
                obj.disableStatistics();
            end
            % setup label mode
            if conf.exist('labelReadFcn')
                obj.enableLabel( ...
                    conf.pop('labelSearchFcn', @(p) p), ...
                    conf.pop('labelReadFcn'));
            else
                obj.disableLabel();
            end
            % initialize the library
            obj.shuffle();
        end
    end
    
    properties (Constant)
        capacity = UMPrest.parameter.get('datasetCapacity');
    end
    
    properties (SetAccess = protected)
        ftree % FileTree instance containing all file system information
        order % integer array indicating current order of files 
        dataReadFcn % function handle that read data file from system
        labelSearchFcn % function handle : DataFilePath -> LabelFilePath 
        labelReadFcn % function handle that read label file from system
    end
    
    properties (Dependent)
        volume
    end
    methods
        function value = get.volume(obj)
            value = obj.ftree.volume;
            if obj.autoload.status
                value = value - numel(obj.autoload.ifailed);
            end
        end
    end
end
