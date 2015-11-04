classdef VideoDataset < hgsetget
    % kernel datastructure
    % ====================
    properties (SetAccess = protected)
        path                        % path of data files
        dataFileIDList = cell(0);   % array of data file names
        dataBlockSet   = cell(0);   % array of data blocks
    end
    % --------------------
    properties (Dependent, SetAccess = private)
        nDataFile
        nDataBlock
    end
    methods
        function value = get.nDataFile(obj)
            value = numel(obj.dataFileIDList);
        end

        function value = get.nDataBlock(obj)
            value = numel(obj.dataBlockSet);
        end
    end

    % input system [interface for subclass]
    % =====================================
    methods (Abstract)
        dataFileIDList = getDataList(obj)
        dataBlock      = readData(obj, dataFileID)
    end

    % output system [API]
    % ===================
    methods
        [dataMatrix, firstFrameIndex] = next(obj, n)
        [dataMatrix, firstFrameIndex] = all(obj)
    end
    methods (Access = protected)
        [dataMatrix, firstFrameIndex] = fetch(obj, indexList)
    end
    % -------------------
    properties (Dependent, SetAccess = private)
        dimout
    end
    methods
        function value = get.dimout(obj)
            if obj.isOutputInPatch
                value = prod(obj.patchSize(1:2));
            else
                value = obj.dimin;
            end
        end
    end

    % auto-load system with cache
    % ===========================
    methods (Access = protected)
        loadData(obj, dataFileIDSet)
        estimateDataBlockSize(obj)
        initDataBlock(obj)
        refreshDataBlock(obj)
    end
    % ---------------------------
    properties
        memoryLimit = 1e9; % memory limitation in pixels
    end
    % ---------------------------
    properties (Access = protected)
        pixelPerBlock = nan; % average quantity of pixels in a data block
    end
    % ---------------------------
    properties (Access = private)
        iterDataFile  = 0;
        iterDataBlock = 0;
        flagTraversed = false;
    end
    % ---------------------------
    methods
        function tof = istraversed(obj)
            if obj.flagTraversed
                tof = true;
                obj.flagTraversed = false;
            else
                tof = false;
            end
        end

        function tof = isloadedall(obj)
            tof = isinf(obj.iterDataFile);
        end
    end
    % ---------------------------
    properties (Access = private)
        countFramePixel = @(x) size(x,1) * size(x,2);
    end
    % ---------------------------
    properties (Dependent, SetAccess = private)
        dimin % dimension of frames in data file
        nSampleInSizeEstimation
        nInitDataBlock
    end
    methods
        function value = get.dimin(obj)
            if isempty(obj.dataBlockSet)
                value = nan;
            else
                value = obj.countFramePixel(obj.dataBlockSet{1});
            end
        end

        function value = get.nSampleInSizeEstimation(obj)
            assert(~isempty(obj.dataFileIDList));
            value = min(13, ceil(obj.nDataFile / 4));
        end

        function value = get.nInitDataBlock(obj)
            if isnan(obj.pixelPerBlock), obj.estimateDataBlockSize(); end
            value = min(obj.nDataFile, floor(obj.memoryLimit / obj.pixelPerBlock) + 1);
        end
    end

    % patch module
    % ============
    properties
        patchSize = nan;  % size of patch (2/3 elements vector)
    end
    properties (Dependent, SetAccess = private)
        isOutputInPatch
        patchPerBlock
    end
    methods
        function tof = get.isOutputInPatch(obj)
            tof = ~any(isnan(obj.patchSize)) && ...
                any(numel(obj.patchSize) == [2,3]) && isnumeric(obj.patchSize);
        end

        function value = get.patchPerBlock(obj)
            assert(obj.isOutputInPatch);
            value = round(0.3 * obj.dimin / prod(obj.patchSize(1:2)));
        end
    end

    % Language Fundamental Utility
    % ============================
    methods
        function obj = VideoDataset(dataPath, varargin)
            obj.path = dataPath;
            obj.paramSetup(varargin{:});
            obj.consistencyCheck();
            obj.initDataBlock();
        end

        function paramSetup(obj, varargin)
            [keys, values] = propertyParse(varargin);
            for i = 1 : numel(keys)
                obj.set(keys{i}, values{i});
            end
        end

        function consistencyCheck(obj)
            assert(obj.memoryLimit > 0);
        end
    end
end
