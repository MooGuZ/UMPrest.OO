classdef NewVideoDataset < Autoload & Statistics
% NEWVIDEODATASET is the abstraction of dataset of video materials

% MooGu Z. <hzhu@case.edu>
% Mar 13, 2016

% NOTES:
% 1. initialize database in constructor, ensure 'db' is not empty
% 2. ensure every video get same length
% 3. currently only support one dimension tags
% 4. frame dimension need to be the same
% 5. solve the problem that Statistic failed with non-formated data that
%    prepared to work in patchsize.
    
    % ================= [AUTOLOAD] IMPLEMENTATION =================
    methods
        function idlist = getIDList(obj)
            idlist = listFileWithExt(obj.dataPath, {'', '.gif'});
        end
        
        function data = id2data(obj, id)
            if isfield(obj.config, 'raw')
                data = videoread(fullfile(obj.dataPath, id), obj.config.raw);
            else
                data = videoread(fullfile(obj.dataPath, id));
            end
            % check input data size
            datasize = size(data);
            assert(numel(datasize) == obj.unitdim + 1); % debug
            % setup size of fundamental unit
            if not(obj.patchmode) && any(isnan(obj.unitsize))
                obj.unitsize = datasize(1 : obj.unitdim);
            end
            % setup number of frame in a sample
            if isnan(obj.frmPerSmp)
                obj.frmPerSmp = datasize(end);
            end
            % check consistancy of size
            if not(obj.patchmode)
                assert(all(datasize(1 : obj.unitdim) == obj.unitsize), ...
                       'Data size mismatch.');
            end
        end
        
        function dbinitCallback(obj)
            obj.statInit(obj.unitdim);
            % search and load configuration file
            if exist(fullfile(obj.dataPath, 'rawconfig.mat'), 'file') == 2
                obj.config.raw = load(fullfile(obj.dataPath, 'rawconfig.mat'));
            end
        end
        
        function dbupdateCallback(obj, sample)
            if not(obj.autoload.traversed)
                if obj.tagged
                    obj.statUpdate(sample.data);
                else
                    obj.statUpdate(sample);
                end
            end
        end
    end

    % ================= APPLICATION INTERFACE =================
    methods
        function dim = dimout(obj)
            if strcmpi(obj.statCoder.mode, 'whiten')
                % condition : statistical encoding (whitening)
                if isempty(obj.whitenOutDimension)
                    obj.statCoderUpdate(obj.unitsize);
                end
                dim = [obj.whitenOutDimension, obj.frmPerSmp];
            else
                dim = [obj.unitsize, obj.frmPerSmp];
            end
        end
        
        function data = next(obj, n)
        % LIMIT : current implementation of multiple patches per sample is
        %         roughly one. It would ignore the last sample in last
        %         fetch, even if the count of patches of it is not
        %         complete.
            if exist('n', 'var')
                assert(n > 0 && n == floor(n));
            else
                n = 1;
            end
            
            if obj.patchmode
                data = repmat(obj.fetch(ceil(n / obj.patchPerSmp)), ...
                    [obj.patchPerSmp, 1]);
            else
                data = obj.dbfetch(n);
            end

            data = obj.dataform(data);
        end
        
        function data = datainfo(obj, data)
        % to be continue
        % 1. add fild of 'help' in structure to contain help information of
        %    each field of 'data' structure
            data.d = obj.unitdim;
        end

        function data = dataform(obj, datacell)
            if iscell(datacell) % batch case
                n = numel(datacell);
                x = zeros([prod(obj.dimout), n]);
                
                if obj.tagged
                    y = zeros([prod(obj.dimtag), n]);
                    for i = 1 : n
                        x(:, i) = MathLib.vec(obj.dataform(datacell{i}.data));
                        y(:, i) = MathLib.vec(datacell{i}.tag);
                    end
                    y = reshape(y, [obj.dimtag, n]);
                else
                    for i = 1 : n
                        x(:, i) = MathLib.vec(obj.dataform(datacell{i}));
                    end
                end
                
                x = reshape(x, [obj.dimout, n]);
                
                if obj.tagged
                    data = struct('x', x, 'y', y);
                else
                    data = struct('x', x);
                end
                data = obj.datainfo(data);
            else % single case
                if obj.patchmode
                    data = randpatch(datacell , obj.patch.size);
                else
                    data = datacell;
                end
                
                if size(data, obj.unitdim + 1) > obj.frmPerSmp
                    data = MathLib.vec(data, obj.unitdim, 'front');
                    data = reshape(data(:, 1 : obj.frmPerSmp), ...
                        [obj.unitsize, obj.frmPerSmp]);
                    warning('Data has been truncated');
                elseif size(data, obj.unitdim + 1) < obj.frmPerSmp
                    data = MathLib.vec(data, obj.unitdim, 'front');
                    data = reshape([data, ...
                        repmat(data(:, end), [1, obj.frmPerSmp - datasize(end)])], ...
                        [obj.unitsize, obj.frmPerSmp]);                    
                end
                
                data = obj.encode(data);
            end
        end
        
        function data = recover(obj, data)
            if isstruct(data)
                data = data.x;
            end
            
            data = obj.decode(data);
        end
    end
    
    % ================= DYNAMIC ATTRIBUTES =================
    properties (Dependent)
        patchsize
    end
    methods
        function value = get.patchsize(obj)
            if obj.patchmode
                value = obj.unitsize;
            else
                value = nan;
            end
        end
        function set.patchsize(obj, value)
            assert(isnumeric(value));
            obj.patchmode = true;
            if numel(value) ~= obj.unitdim
                if numel(value) == 1
                    obj.unitsize = value * ones(1, obj.unitdim);
                else
                    assert('ArgumentError:Patchsize', 'Illegal patch size');
                end
            else
                obj.unitsize  = value;
            end
        end
    end

    % ================= CORE DATA =================
    properties (Constant)
        unitdim = 2;
        tagged  = false;
    end

    properties
        dataPath
        patchPerSmp = 7;
        frmPerSmp = nan;
        unitsize  = nan;
        config
    end
    
    properties (SetAccess = private)
        patchmode = false;
    end
    
    % ================= SAVE&LOAD SUPPORT =================
    methods
        function sobj = saveobj(obj)
            % -------------------------------------------------------------
            % Cannot deal with partial dataset at this time
            if not(obj.autoload.complete)
                warning('Dataset is too big to save into pure structure');
                sobj = obj;
                return
            end
            % -------------------------------------------------------------
            sobj.db = obj.db;
            sobj.id = obj.autoload.idlist;
            if obj.statmode
                sobj.stat = obj.stat;
            end
            if obj.patchmode
                sobj.patchsize = obj.patchsize;
            end
        end
    end
    methods (Static)
        function obj = loadobj(sobj)
            if isstruct(sobj)
                obj = NewVideoDataset();
                obj.dbimport(sobj.db, sobj.id);
                [nd, dim] = obj.datadim();
                if all(not(isnan(dim))) && nd >= obj.unitdim
                    obj.unitsize = dim(1 : obj.unitdim);
                    if nd > obj.unitdim
                        obj.frmPerSmp = dim(obj.unitdim + 1);
                    else
                        obj.frmPerSmp = 1;
                    end
                else
                    error('Loaded data do not meet dimension requirement of VideoDataset');
                end                    
                if isfield(sobj, 'stat')
                    obj.statInit(obj.unitdim);
                    obj.stat = sobj.stat;
                end
                if isfield(sobj, 'patchsize')
                    obj.patchsize = sobj.patchsize;
                end
            else
                obj = sobj;
            end
        end
    end
    
    % ================= CONSTRUCTOR ================= 
    methods
        function obj = NewVideoDataset(dataPath)
            if exist('dataPath', 'var')
                obj.dataPath = dataPath;
                % obj.patchsize = 32;
                obj.dbinit();
            end
        end
    end
end
