classdef FileDataBlock < DataBlock
    methods
        function [dcell, lcell] = fetch(obj, n)
            if obj.icache >= numel(obj.cache)
                obj.refreshCache();
            end

            % case : need refresh cache
            if n > numel(obj.cache) - obj.icache 
                nbatch = ceil((n - (numel(obj.cache) - obj.icache)) / ...
                              obj.capacity) + 1;

                buffer = cell(1, nbatch);

                buffer{1} = obj.cache(obj.icache + 1 : numel(obj.cache));
                n = n - (numel(obj.cache) - obj.icache);
                for i = 2 : nbatch - 1
                    obj.refreshCache();
                    buffer{i} = obj.cache(:);
                    n = n - numel(obj.cache);
                end
                obj.refreshCache();
                buffer{end} = obj.cache(1 : n);
                obj.icache = n;

                dcell = cellcomb(buffer);
            else % case : normal
                dcell = obj.cache(obj.icache + (1 : n));
                obj.icache = obj.icache + n;
            end
            
            lcell = {};
        end
        
        function [data, label] = recent(obj)
            if obj.icache
                data = obj.cache(obj.icache);
            else
                data = [];
            end
            label = [];
        end
        
        function refreshCache(obj)
            if not(obj.autoload.status) || obj.autoload.iid >= obj.volumn()
                obj.shuffle();
                return
            end
            
            n = min(obj.volumn() - obj.autoload.iid, obj.capacity);
            
            i = 1;
            hwbar = waitbar(0);
            set(get(get(hwbar, 'children'), 'title'), 'Interpreter', 'none');
            obj.cache = cell(1, n);
            while i <= n
                obj.autoload.iid = obj.autoload.iid + 1;
                if obj.autoload.iid > obj.volumn()
                    obj.autoload.iid = obj.volumn();
                    obj.cache = obj.cache(1:i-1);
                    break
                end
                try
                    obj.cache{i} = obj.getdata(obj.getid(obj.order(obj.autoload.iid)));
                    waitbar(i / n, hwbar, sprintf('Loading file in progress : %d / %d', i, n));
                    i = i + 1;
                catch ME
                    obj.loadfail(obj.autoload.iid) = true;
                    warning('File cannot load as data : %s\n  [INFO] %s', ...
                        obj.getid(obj.order(obj.autoload.iid)), ME.message);
                end
            end
            close(hwbar);
            
            obj.icache = 0;
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
        
        function shuffle(obj)
            if any(obj.loadfail)
                obj.removeid(obj.order(obj.loadfail));
                obj.loadfail = false(1, obj.volumn());
            end
            
            index = randperm(obj.volumn());
            obj.order = obj.order(index);
            if obj.autoload.status
                obj.autoload.iid = 0;
                obj.refreshCache();
                if obj.autoload.iid >= obj.volumn()
                    obj.disableAutoload();
                end
            else
                obj.cache = obj.cache(index);
                obj.icache = 0;
            end
        end
        
        function id = getid(obj, varargin)
            narginchk(2, 3);
            
            if nargin == 2
                index = varargin{1};
                if numel(index) == 1
                    assert(index <= obj.volumn());
                    if isempty(obj.folderList)
                        id = obj.fileList{index};
                    else
                        ifolder = 1;
                        while numel(obj.fileList{ifolder}) < index
                            index = index - numel(obj.fileList{ifolder});
                            ifolder = ifolder + 1;
                        end
                        id = fullfile(obj.folderList{ifolder}, obj.fileList{ifolder}{index});
                    end
                else
                    id = cell(1, numel(index));
                    for i = 1 : numel(index)
                        id{i} = obj.getid(index(i));
                    end
                end
            elseif nargin == 3
                head = varargin{1};
                tail = varargin{2};
                assert(head <= obj.volumn());
                assert(tail <= obj.volumn());
                if isempty(obj.folderList)
                    id = obj.fileList(head : tail);
                else
                    id = cell(1, tail - head + 1);
                    index = head;
                    ifolder = 1;
                    while numel(obj.fileList{ifolder}) < index
                        index = index - numel(obj.fileList{ifolder});
                        ifolder = ifolder + 1;
                    end
                    if tail - head + index <= numel(obj.fileList{ifolder})
                        id(:) = cellfun(@(f) fullfile(obj.folderList{ifolder}, f), ...
                            obj.fileList{ifolder}(index : tail - head + index), ...
                            'UniformOutput', false);
                    else
                        count = (tail - head) - (numel(obj.fileList{ifolder}) - index);
                        id(1 : end - count) = cellfun(@(f) fullfile(obj.folderList{ifolder}, f), ...
                            obj.fileList{ifolder}(index : end), 'UniformOutput', false);
                        ifolder = ifolder + 1;
                        while count > numel(obj.fileList{ifolder})
                            n = numel(obj.fileList{ifolder});
                            id(count + (1 : n)) = cellfun(@(f) fullfile(obj.folderList{ifolder}, f), ...
                                obj.fileList{ifolder}, 'UniformOutput', false);
                            count = count - n;
                            ifolder = ifolder + 1;
                        end
                        id(end - count + 1 : end) = cellfun(@(f) fullfile(obj.folderList{ifolder}, f), ...
                            obj.fileList{ifolder}(1 : count), 'UniformOutput', false);
                    end
                end                
            end
        end
        
        function removeid(obj, index)
            index = sort(index, 'ascend');
            if isempty(obj.folderList)
                reserve = true(1, numel(obj.fileList));
                reserve(index) = false;
                obj.fileList = obj.fileList(reserve);
            else
                count = 0;
                for i = 1 : numel(obj.folderList)
                    n = numel(obj.fileList{i});
                    inrange = index((index >= count + 1) && (index <= count + n));
                    reserve = true(1, n);
                    reserve(inrange) = false;
                    obj.fileList{i} = obj.fileList{i}(reserve);
                    count = count + n;
                end
            end
            obj.nfile = cellcount(obj.fileList);
        end
        
        function data = getdata(obj, id)
            data = obj.readfunc(id);
            if obj.stat.status && obj.stat.ncommit < obj.volumn()
                obj.stat.commit(data);
            end
        end
        
        function enableAutoload(obj)
            obj.autoload = struct('status', true, 'iid', 0);
        end
        
        function disableAutoload(obj)
            obj.autoload = struct('status', false);
        end
        
        function value = volumn(obj)
            value = obj.nfile;
        end
    end
    
    methods
        function obj = FileDataBlock(flist, readfunc, extList, stat)
            if exist('stat', 'var')
                obj.stat = stat;
            else
                obj.stat = StatisticCollector();
            end
            
            if ischar(extList)
                extList = {extList};
            end
            if iscell(flist)
                if isdir(flist{1})
                    for i = 2 : numel(flist)
                        assert(isdir(flist{i}));
                    end
                    obj.folderList = flist;
                    obj.extList = extList;
                elseif exist(flist{1}, 'file') == 2
                    for i = 2 : numel(flist)
                        assert(exist(flist{i}, 'file') == 2);
                    end
                    obj.fileList = flist;
                else
                    error('The 1st argument should be group of files or folders');
                end
            elseif ischar(flist)
                if isdir(flist)
                    obj.folderList = {flist};
                    obj.extList = extList;
                elseif exist(flist, 'file') == 2;
                    obj.fileList = {flist};
                else
                    error('The 1st argument should be file or folder');
                end
            else
                error('The 1st argument should be string or cell array');
            end
                
            if not(isempty(obj.folderList))
                obj.fileList = cell(1, numel(obj.folderList));
                for i = 1 : numel(obj.folderList)
                    obj.fileList{i} = listFileWithExt(obj.folderList{i}, obj.extList);
                end
                obj.nfile = cellcount(obj.fileList);
            else
                obj.nfile = numel(obj.fileList);
            end
            
            obj.readfunc = readfunc;

            obj.enableAutoload();
            obj.order = 1 : obj.volumn();
            obj.loadfail = false(1, obj.volumn());
            obj.shuffle();            
        end
    end
    
    properties
        capacity = 5e4;
    end
    
    properties (Access = private)
        nfile
    end
    
    properties (SetAccess = private, Hidden)
        folderList, fileList, extList
        cache, icache
        autoload, order, loadfail
        stat
        readfunc
    end
    
    properties (Dependent)
        islabelled
    end
    methods
        function tof = get.islabelled(~)
            tof = false;
        end
    end
end
