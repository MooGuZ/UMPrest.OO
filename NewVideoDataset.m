classdef NewVideoDataset < Dataset
% NEWVIDEODATASET is the abstraction of dataset of video materials

% MooGu Z. <hzhu@case.edu>
% Mar 13, 2016

% NOTES:
% 1. initialize database in constructor, ensure 'db' is not empty
% 2. ensure every video get same length
% 3. currently only support one dimension tags

    methods
        function value = volumn(obj)
            value = numel(obj.autoload.flist)
        end

        function [elsmp, smpsz] = dimout(obj)
            if isempty(obj.db)
                elsmp = nan;
                smpsz = nan;
            else
                smpsz = size(obj.db{1});
                elsmp = prod(smpsz);
            end
        end

        function data = next(obj, n)
            if exist('n', 'var')
                assert(n > 0 && n == floor(n));
            else
                n = 1;
            end

            if obj.idb >= numel(obj.db)
                obj.dbrefresh();
            end
            
            if n > numel(obj.db) - obj.idb % case : need load new data
                nbatch = ceil((n - numel(obj.db) + obj.idb) / ...
                              obj.autoload.capacity) + 1;

                databuf = cell(nbatch);
                if obj.tagged
                    tagbuf  = cell(nbatch);
                    [databuf{1}, tagbuf{1}] = ...
                        obj.dbfetch(obj.idb + 1 : numel(obj.db));
                else
                    databuf{1} = obj.dbfetch(obj.idb + 1 : numel(obj.db));
                end
                n = n - (numel(obj.db) - obj.idb);

                for i = 2 : numel(databuf) - 1
                    obj.dbrefresh();
                    if obj.tagged
                        [databuf{i}, tagbuf{i}] = obj.dbfetch(1 : numel(obj.db));
                    else
                        databuf{i} = obj.dbfetch(1 : numel(obj.db));
                    end
                    n = n - numel(obj.db);
                end

                obj.dbrefresh();
                if obj.tagged
                    [databuf{end}, tagbuf{end}] = obj.dbfetch(1 : n);
                else
                    databuf{end} = obj.dbfetch(1 : n);
                end
                obj.idb = n;

                data = cellcomb(databuf);
                if obj.tagged
                    tag  = cellcomb(tagbuf);
                end
            else % case : normal
                if obj.tagged
                    [data, tag] = obj.dbfetch(obj.idb + (1 : n));
                else
                    data = obj.dbfetch(obj.idb + (1 : n));
                end
                obj.idb = obj.idb + n;
            end

            % attach assistant information
            if obj.tagged
                data = obj.dbinfo(data, tag);
            else
                data = obj.dbinfo(data);
            end
        end

        function [data, tag] = dbfetch(obj, idx)
            if exist('idx', 'var')
                assert(numel(idx) > 0 && all(floor(idx) == idx));
                assert(all(idx > 0) && all(idx <= numel(obj.db)));
            else
                idx = randi(numel(obj.db));
            end

            data = cell(numel(idx));
            if obj.tagged
                tag = cell(numel(idx));
                for i = 1 : numel(idx)
                    [data{i}, tag{i}] = obj.dataform(obj.db{idx(i)});
                end
            else
                for i = 1 : numel(idx)
                    data{i} = obj.dataform(obj.db{idx(i)}, true);
                end
            end
        end

        function dbrefresh(obj)
            obj.iterDataBlock = 0;
            % count on quantity of patches have been croped
            if obj.patch.status
                obj.patch.count = obj.patch.count - 1;
                if obj.patch.count > 0
                    return
                else
                    obj.patch.count = obj.patch.n;
                end
            end
            % reload data file to dataBlockSet if necessary
            if obj.autoload.complete
                obj.db  = obj.db(randperm(numel(obj.db)));
            elseif obj.autoload.ifile < numel(obj.autoload.flist)
                nfile = min(numel(obj.autoload.flist) - obj.autoload.ifile, ...
                            obj.autoload.capacity);
                obj.dataload(obj.autoload.ifile + (1 : n));
                obj.autoload.ifile = obj.autoload.ifile + nfile;
            else
                obj.dbinit();
            end            
        end
        
        function dataload(obj, idx)
        % remove unreadible file from file list and show warning
        end
        
        function dbinit(obj, fpath)
            if exist('fpath', 'var')
                obj.autoload.froot = fpath;
                reload = true;
            else
                fpath = obj.autoload.froot;
                reload = false;
            end

            % search data file under specified path
            if isempty(obj.autoload.flist) || reload
                obj.autoload.flist = listFileWithExt(fpath, obj.autoload.ftype);
                assert(~isempty(obj.autoload.flist), ...
                       'no qualified data file found in specified path');
            end
            
            % load data into memory
            obj.autoload.flist = obj.autoload.flist( ...
                randperm(numel(obj.autoload.flist)));
            if obj.autoload.capacity < numel(obj.autoload.flist)
                obj.dataload(1 : obj.autoload.capacity);
                obj.autoload.complete = false;
            else
                obj.dataload(1 : numel(obj.autoload.flist));
                obj.autoload.complete = true;
            end
            obj.autoload.ifile = numel(obj.db);
            obj.idb = 0;      
        end
       
        
        
        function data = datainfo(obj, data, tag)
            if exist('tag', 'var')
                data = struct( ...
                    'x', data, ...
                    'y', tag);
            else
                data = struct('x', data);
            end
            
            ...
            % 1. add fild of 'help' in structure to contain help information of
            %    each field of 'data' structure
        end

        function [data, tag] = dataform(obj, datasrc)
            if obj.tagged
                tag = datasrc.tag;
                datasrc = datasrc.data;
            end

            if obj.patch.status
                data = randpatch(datasrc, obj.patch.size);
            end

            switch lower(obj.postproc.method)
              case {'whitening'}
                data = obj.whitening(data);

              case {'dimnorm'}
                data = obj.dimnorm(data);

              case {'recenter'}
                data = obj.recenter(data);

              otherwise
                error('[VIDEODATASET] unrecognized post-processing method.');
            end
        end

        function data = whitening(obj, data)
        end

        function data = dimnorm(obj, data)
        end

        function data = recenter(obj, data)
        end
    end

    methods
        function obj = NewVideoDataset(fpath)
            obj.tagged = false;         % [!restriction]
            
            obj.dbinit(fpath);
            
            if obj.patch.status
                obj.patch.count = obj.patch.n;
            end
        end
    end
    
    properties
        autoload = struct(...
            'froot', '', ...
            'ftype', {'', '.gif'}, ...
            'flist', {}, ...
            'complete', false, ...
            'capacity', 5e4);

        db
        idb

        patch = struct( ...
            'status', false, ...
            'size', [], ...
            'n', 7, ...
            'count', []);

        postproc = struct('method', []);

        statistic
    end
end
