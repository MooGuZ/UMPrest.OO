classdef VideoDataset < handle
    methods
        function dataset = subset(obj, n)
            if n > obj.db.volumn()
                warning(['Cannot create subset bigger than original one,', ...
                    ' create same size one instead.']);
                n = obj.db.volumn();
            end
            
            if obj.islabelled
                [data, label] = obj.db.fetch(n);
                datablock = MemoryDataBlock(data, obj.stat, 'label', label, ...
                    'datadim', obj.db.datadim, 'labeldim', obj.db.labeldim);
                dataset = VideoDataset(datablock);
                % dataset = VideoDataset(datablock, 'coder', obj.coder.mode);
            else
                datablock = MemoryDataBlock(obj.db.fetch(n), obj.stat, ...
                    'datadim', obj.db.datadim, 'labeldim', obj.db.labeldim);
                dataset = VideoDataset(datablock);
                % dataset = VideoDataset(datablock, 'coder', obj.coder.mode);
            end
        end
        
        function varargout = subsets(obj, division)
            assert(isnumeric(division) && isvector(division));
            assert(sum(division) <= 1);
            
            % get number of elements in each subset
            n = round(division * obj.volumn());
            if sum(n) > obj.volumn()
                ind = randperm(numel(n), sum(n) - obj.volumn());
                n(ind) = n(ind) - 1;
            end
            
            obj.db.reset()
            % generate subset one by one
            varargout = cell(1, min(numel(n), nargout));
            for i = 1 : numel(varargout)
                varargout{i} = obj.subset(n(i));
            end
        end
        
        function [datapkg, labelpkg] = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % get data cells
            if obj.patchmode
                m = ceil((n - obj.patchCounter) / obj.patchPerSample);
                r = mod(n - obj.patchCounter, obj.patchPerSample);
                if obj.patchCounter
                    if obj.islabelled
                        [dunit, lunit] = obj.db.last();
                        [dcell, lcell] = obj.db.fetch(m);
                        dcell = [{dunit}, dcell];
                        lcell = [{lunit}, lcell];
                    else
                        dcell = [obj.db.last(), obj.db.fetch(m)];
                    end
                    if r == 0
                        npatch = [obj.patchCounter, obj.patchPerSample * ones(1, m)];
                    else
                        npatch = [obj.patchCounter, obj.patchPerSample * ones(1, m-1), r];
                    end
                else
                    if obj.islabelled
                        [dcell, lcell] = obj.db.fetch(m);
                    else
                        dcell = obj.db.fetch(m);
                    end
                    if r == 0
                        npatch = obj.patchPerSample * ones(1, m);
                    else
                        npatch = [obj.patchPerSample * ones(1, m-1), r];
                    end
                end
                dcell = randcrop(dcell, obj.patchSize, npatch);
                if obj.islabelled
                    lcell = MathLib.dupcell(lcell, npatch);
                end
                obj.patchCounter = obj.patchPerSample - r;
            else
                if obj.islabelled
                    [dcell, lcell] = obj.db.fetch(n);
                else
                    dcell = obj.db.fetch(n);
                end
            end
            
            % % forming data package
            % if obj.islabelled
            %     datapkg = DataPackage(dcell, 'label', lcell, 'info', obj.dpkginfo);
            % else
            %     datapkg = DataPackage(dcell, 'info', obj.dpkginfo);
            % end
            % 
            % % adjust data package
            % if not(isempty(obj.db.datadim))
            %     datapkg.setdatadim(obj.db.datadim);
            % end
            % if not(isempty(obj.db.labeldim))
            %     datapkg.setlabeldim(obj.db.labeldim);
            % end
            
            % TODO:
            % 1. add TAXIS field into DATABLOCK class
            % 2. make STATISTICCOLLECTOR a standard UNIT
            
            datapkg = obj.apdata.packup(dcell);
            if obj.islabelled
                labelpkg = obj.aplabel.packup(lcell);
            end
            
%             % forming DATAPACKAGE of data and label
%             datapkg  = DataPackage.create(dcell, 2, true);
%             if obj.islabelled
%                 % PROBLEM: label dimension is undefined
%                 labelpkg = DataPackage.create(lcell, obj.db.labeldim, obj.db.taxis);
%             end
            
%             % apply statistic coder
%             if obj.coder.status
%                 datapkg = obj.coder.forward(datapkg);
%             end
        end
        
%         function data = recover(obj, datapkg)
%             if obj.coder.status
%                 data = obj.coder.backward(datapkg).data;
%             else
%                 data = datapkg.data;
%             end
%         end
        
        function info = dpkginfo(~)
            info = struct();
        end
        
        function n = volumn(obj)
            n = obj.db.volumn();
        end
    end
    
    methods
        function obj = VideoDataset(dbsource, varargin)
            conf = Config(varargin);
            if iscell(dbsource) || ischar(dbsource)
                obj.stat = conf.get('stat', StatisticCollector(2));
                obj.db = FileDataBlock(dbsource, @videoread, {'.gif'}, obj.stat);
            elseif isa(dbsource, 'DataBlock')
                obj.db = dbsource;
                obj.stat = obj.db.stat;
            end
%             obj.coder = StatisticTransform(obj.stat, conf.get('coder', 'off'));
            % setup patch mode
            psize = conf.get('patchSize', []);
            if isempty(psize)
                obj.disablePatch();
            else
                obj.enablePatch(psize, varargin{:});
            end
            % setup access point
            obj.apdata = AccessPoint(obj, obj.db.datadim);
            if obj.islabelled
                obj.aplabel = AccessPoint(obj, obj.db.labeldim);
            end
        end
    end
    
    properties
        db, stat%, coder
        apdata, aplabel
    end
    methods
        function set.db(obj, value)
            assert(isa(value, 'DataBlock'));
            obj.db = value;
        end
        
        function set.stat(obj, value)
            assert(isa(value, 'StatisticCollector'));
            obj.stat = value;
        end
        
%         function set.coder(obj, value)
%             assert(isa(value, 'StatisticTransform'));
%             obj.coder = value;
%         end
    end
    
    properties
        patchSize, patchPerSample
    end
    properties (Access = private)
        patchCounter
    end
    properties (Dependent)
        patchmode
    end
    methods
        function set.patchSize(obj, value)
            assert((isreal(value) && numel(value) == 2) || isempty(value));
            obj.patchSize = value;
        end
        
        function set.patchPerSample(obj, value)
            assert((isscalar(value) && isreal(value)) || isempty(value));
            obj.patchPerSample = max(round(value), 1);
        end
        
        function value = get.patchCounter(obj)
            if not(isempty(obj.patchPerSample))
                value = mod(obj.patchCounter, obj.patchPerSample);
            else
                value = [];
            end
        end
        function set.patchCounter(obj, value)
            assert((isscalar(value) && isreal(value)) || isempty(value));
            obj.patchCounter = round(value);
        end
        
        function value = get.patchmode(obj)
            value = not(isempty(obj.patchSize));
        end
        
        function disablePatch(obj)
            obj.patchSize      = [];
            obj.patchPerSample = [];
            obj.patchCounter   = [];
        end
        
        function enablePatch(obj, patchSize, varargin)
            obj.patchSize      = patchSize;
            obj.patchPerSample = Config(varargin).get('patchPerSample', 1);
            obj.patchCounter   = 0;
        end
    end
    
    properties (Dependent)
        islabelled
    end
    methods
        function value = get.islabelled(obj)
            value = obj.db.islabelled;
        end
    end
end
