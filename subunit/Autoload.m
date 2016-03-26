classdef Autoload < Statitsitcs
% AUTOLOAD provide methods to help sub-class control memeory allocation in file
% loading tasks. This unit also provide statistics of data.

% MooGu Z. <hzhu@case.edu>
% 3 22, 2016
    
% ================= INTERFACE FOR SUBCLASS ================= 
    methods (Abstract)
        data = id2data(obj, id)
        idlist = getIDList(obj)
    end
    
    % ================= CALLBACK FUNCTIONS =================
    methods (Abstract) 
        dbinitCallback(obj)
        dbupdataCallback(obj, data)
    end

    % ================= APPLICATION INTERFACE =================
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
                obj.dbinitCallback();
                obj.autoload.idlist = obj.getIDList();
                assert(~isempty(obj.autoload.idlist), 'RuntimeError:Autoload', ...
                       'Found no data');
                obj.autoload.traversed = false;                
            end

            % load data into memory
            obj.autoload.idlist = obj.autoload.idlist( ...
                randperm(numel(obj.autoload.idlist)));
            if obj.autoload.capacity < numel(obj.autoload.idlist)
                obj.dataload(1 : obj.autoload.capacity);
                obj.autoload.complete  = false;
            else
                obj.dataload(1 : numel(obj.autoload.idlist));
                obj.autoload.complete  = true;
                obj.autoload.traversed = true;
            end
            obj.irepeat = obj.autoload.repeat;
            obj.index = numel(obj.db);
            obj.idb = 0;
        end

        function datacell = dbfetch(obj, n)
            if obj.idb >= numel(obj.db)
                obj.dbrefresh();
            end

            if n > numel(obj.db) - obj.idb % case : need refresh db
                nbatch = ceil((n - (numel(obj.db) - obj.idb)) / ...
                              obj.autoload.capacity) + 1;

                buffer = cell(nbatch);

                buffer{1} = obj.db(obj.idb + 1 : numel(obj.db));
                n = n - (numel(obj.db) - obj.idb);
                for i = 2 : nbatch - 1
                    obj.dbrefresh();
                    buffer{i} = obj.db(:);
                    n = n - numel(obj.db);
                end
                obj.dbrefresh();
                buffer{end} = obj.db(1 : n);
                obj.idb = n;

                datacell = cellcomb(buffer);
            else % case : normal
                datacell = obj.db(obj.idb + (1 : n));
                obj.idb = obj.idb + n;
            end
        end
    end
    
    % ================= SUPPORTIVE FUNCTIONS =================
    methods
        function dataload(obj, idx)
            obj.db  = cell(numel(idx), 1);
            failidx = false(numel(idx), 1);
            for i = 1 : numel(idx)
                try
                    obj.db{i} = obj.id2data(obj.autoload.idlist{idx(i)});
                catch ME
                    warning('File Loading Failure : %s\n[MESSAGE] %s', ...
                            fname, ME.message);
                    failidx(i) = true;
                    continue
                end

                obj.dbupdateCallback(obj.db{i});
            end
            % delete empty element and remove that file from list of autoload system
            if any(failidx)
                obj.db = obj.db(~failidx);
                index = true(numel(obj.autoload.idlist), 1);
                index(idx(failidx)) = false;
                obj.autoload.idlist = obj.autoload.idlist(index);
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
                n = min(numel(obj.autoload.idlist) - obj.index, ...
                            obj.autoload.capacity);
                obj.dataload(obj.index + (1 : n));
                obj.index = obj.index + n;

                if obj.index >= numel(obj.autoload.idlist)
                    obj.autoload.traversed = true;
                end
            else
                obj.dbinit();
            end
        end
    end
    
    % ================= DYNAMIC ATTRIBUTES =================
    properties (Dependent)
        volumn
        capacity
    end
    methods
        function value = get.volumn(obj)
            value = numel(obj.autoload.idlist);
        end
        
        function value = get.capacity(obj)
            value = obj.autoload.capacity;
        end
        function set.capacity(obj, value)
            assert(isnumeric(value) && isscalar(value));
            obj.autoload.capacity = value;
        end
    end
    
    % ================= CORE DATA =================
    properties
        db
    end
    properties (Access = protected)
        autoload = struct(...
            'idlist',    {}, ...
            'capacity',  5e4, ...
            'complete',  false, ...
            'traversed', false);
    end
    properties (Access = private)
        idb
        index
    end
end
