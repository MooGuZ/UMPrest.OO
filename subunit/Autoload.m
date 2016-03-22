classdef Autoload < Statitsitcs
% AUTOLOAD provide methods to help sub-class control memeory allocation in file
% loading tasks. This unit also provide statistics of data.

% MooGu Z. <hzhu@case.edu>
% 3 22, 2016

    properties (Abstract)
        db
        idb
    end

    properties (Access = private)
        idb
        index
        irepeat
    end

    properties
        autoload = struct(...
            'idlist', {}, ...
            'complete', false, ...
            'capacity', 5e4, ...
            'read', struct(), ...
            'repeat', 0);
    end

    methods (Abstract)
        id2data
        getIDList
    end

    methods
        function dbinit(obj, reload)
            if exist('reload', 'var')
                assert(islogical(reload), 'ArgumentError:Autoload', ...
                       'Argument RELOAD should be TRUE or FALSE.');
            else
                reload = false;
            end

            % search data file under specified path
            if isempty(obj.autoload.idlist) || reload
                obj.autoload.idlist = obj.getIDList();
                assert(~isempty(obj.autoload.idlist), 'RuntimeError:Autoload', ,...
                       'Found no data');
                obj.statcmd('reset');
            end

            % load data into memory
            obj.autoload.idlist = obj.autoload.idlist( ...
                randperm(numel(obj.autoload.idlist)));
            if obj.autoload.capacity < numel(obj.autoload.idlist)
                obj.dataload(1 : obj.autoload.capacity);
                obj.autoload.complete = false;
            else
                obj.dataload(1 : numel(obj.autoload.idlist));
                obj.autoload.complete = true;
                obj.stat.lock = true;
            end
            obj.index = numel(obj.db);
            obj.idb = 0;
        end
        
        function dataload(obj, idx)
            obj.db  = cell(numel(idx), 1);
            failidx = false(numel(idx), 1);
            for i = 1 : numel(idx)
                try
                    obj.db{i} = obj.id2data(obj.autoload.idlist{idx(i)});
                catch me
                    warning('File Loading Failure : %s', fname);
                    failidx(i) = true;
                    continue
                end

                if obj.statistic.status
                    if isstruct(obj.db{i})
                        obj.statcol(obj.db{i}.data);
                    else
                        obj.statcol(obj.db{i});
                    end
                end
            end
            % delete empty element and remove that file from list of autoload system
            if any(failidx)
                obj.db = obj.db(~failidx);
                fileidx = true(numel(obj.autoload.idlist), 1);
                fileidx(idx(failidx)) = false;
                obj.autoload.idlist = obj.autoload.idlist(fileidx);
            end
        end

        function dbrefresh(obj)
            obj.idb = 0;
            % count on quantity of patches have been croped
            if obj.autoload.repeat
                obj.irepeat = obj.irepeat - 1;
                if obj.irepeat > 0
                    return
                else
                    obj.irepeat = obj.autoload.repeat;
                end
            end
            % reload data file to dataBlockSet if necessary
            if obj.autoload.complete
                idx = randperm(numel(obj.db));
                obj.db = obj.db(idx);
                obj.autoload.idlist = obj.autload.idlist(idx);
            elseif obj.index < numel(obj.autoload.idlist)
                nfile = min(numel(obj.autoload.idlist) - obj.index, ...
                            obj.autoload.capacity);
                obj.dataload(obj.index + (1 : n));
                obj.index = obj.index + nfile;

                if obj.index >= numel(obj.autoload.idlist)
                    obj.stat.lock = true;
                end
            else
                obj.dbinit();
            end
        end

        function datacell = dbfetch(obj, n)
            if obj.idb >= numel(obj.db)
                obj.dbrefresh();
            end

            if n > numel(obj.db) - obj.idb % case : need refresh db
                nbatch = ceil((n - (numel(obj.db) - obj.idb)) / ...
                              obj.autoload.capacity) + 1;

                buffer = cell(nbatch);

                buffer{1} = obj.dbfetch(obj.idb + 1 : numel(obj.db));
                n = n - (numel(obj.db) - obj.idb);
                for i = 2 : nbatch - 1
                    obj.dbrefresh();
                    buffer{i} = obj.dbfetch(1 : numel(obj.db));
                    n = n - numel(obj.db);
                end
                obj.dbrefresh();
                buffer{end} = obj.dbfetch(1 : n);
                obj.idb = n;

                datacell = cellcomb(buffer);
            else % case : normal
                datacell = obj.dbfetch(obj.idb + (1 : n));
                obj.idb = obj.idb + n;
            end
        end
    end
end
