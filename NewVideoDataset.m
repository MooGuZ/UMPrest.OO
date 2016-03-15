classdef NewVideoDataset < Dataset
% NEWVIDEODATASET is the abstraction of dataset of video materials

% MooGu Z. <hzhu@case.edu>
% Mar 13, 2016

% NOTES:
% 1. initialize database in constructor, ensure 'db' is not empty
% 2. ensure every video get same length
% 3. currently only support one dimension tags
% 4. video data

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

        end

        function data = datainfo(obj, data, tag)
            if exist('tag', 'var')
                data = struct( ...
                    'x', data, ...
                    'y', tag);
            else
                data = struct('x', data);
            end
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
            obj.fpath = fpath;
            obj.flist = listFileWithExt(fpath, {'.gif', ''});
            
            obj.db = cell(numel(obj.flist)); jdb = 0;
           
            for i = 1 : numel(obj.flist)
                [~, ~, ext] = fileparts(obj.flist{i})
                try
                    switch lower(ext)
                      case {''}
                        data = obj.loadRawVideo(fullfile(obj.fpath, obj.flist{i}));
                        
                      case {'.gif'}
                        data = obj.loadGifVideo(fullfile(obj.fpath, obj.flist{i}));
                        
                      otherwise
                        error('[VIDEODATASET] unrecognized video file type.');
                    end
                catch excpt
                    warning(excpt.msg);
                    continue
                end
                obj.db{j} = data; 
                j = j + 1;
            end
            
            if j ~= numel(obj.flist)
                obj.db = obj.db(1 : j);
            end
            obj.idb = 0;
        end
    end
    properties
        autoload = struct(...
            'flist', cell());

        db
        idb

        patch = struct('status', false, 'size', []);

        postproc = struct('method', []);

        statistic
    end
end
