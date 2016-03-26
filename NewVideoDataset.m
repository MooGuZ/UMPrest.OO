classdef NewVideoDataset < Autoload & Statistics
% NEWVIDEODATASET is the abstraction of dataset of video materials

% MooGu Z. <hzhu@case.edu>
% Mar 13, 2016

% NOTES:
% 1. initialize database in constructor, ensure 'db' is not empty
% 2. ensure every video get same length
% 3. currently only support one dimension tags
% 4. frame dimension need to be the same
    
    % ================= [AUTOLOD] IMPLEMENTATION =================
    methods
        function idlist = getIDList(obj)
            idlist = listFileWithExt(obj.dataPath, {'', '.gif'});
        end
        
        function data = id2data(obj, id)
            data = videoread(fullfile(obj.dataPath, id));
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
            if obj.patchmode
                assert(datasize(end) == frmPerSmp)
            else
                assert(all(datasize == [obj.unitsize, frmPerSmp]), ...
                       'Data size mismatch.');
            end
        end
        
        function dbinitCallback(obj)
            obj.statInit(obj.unitdim);
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
                dim = [size(obj.statCoder.encode, 1), obj.frmPerSmp];
            else
                dim = [obj.unitsize, obj.frmPerSmp];
            end
        end
        
        function data = next(obj, n)
        % TODO : patchPerSmp implementation
            if exist('n', 'var')
                assert(n > 0 && n == floor(n));
            else
                n = 1;
            end

            data = obj.dataform(obj.fetch(n));
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
                
                data = struct('x', x, 'y', y);
                data = datainfo(data);
            else % single case
                if obj.patch.status
                    data = randpatch(datacell , obj.patch.size);
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
            assert(isnumeric(value) && numel(value) = obj.unitdim);
            obj.patchmode = true;
            obj.unitsize  = value;
        end
    end

    % ================= CORE DATA =================
    properties (Constant)
        unitdim = 2;
        tagged  = false;
    end

    properties
        patchmode = false;
        patchPerSmp = 7;
        frmPerSmp = nan;
        unitsize  = nan;
    end
    
    % ================= CONSTRUCTOR ================= 
    methods
        function obj = NewVideoDataset()
        % !!!
        end
    end
end
