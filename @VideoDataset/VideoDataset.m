classdef VideoDataset < Dataset
    % ================= DATASET IMPLEMENTATION =================
    methods
        function n = volumn(obj)
            if obj.isOutputInPatch
                n = obj.nDataFile * obj.patchPerBlock;
            else
                n = obj.nDataFile;
            end
        end

        sample = next(obj, n) % [external file]

        sample = traverse(obj, n) % [external file]

        function tof = istraversed(obj)
            tof = obj.flagTraversed;
            if tof
                obj.flagTraversed = false;
            end
        end

        function n = dimout(obj)
            if obj.isOutputInPatch
                n = prod(obj.patchSize(1:2));
            else
                n = obj.dimin;
            end
        end
    end

    % ================= INTERFACES FOR SUBCLASS =================
    methods (Abstract)
        % GETDATALIST return a cell array of strings that containing all
        % file ids (typically, file name) under specified dataset path.
        dataFileIDList = getDataList(obj)

        % READDATA return data block of the file specified by given file id
        dataBlock = readData(obj, dataFileID)
    end

    % ================= SUPPORT FUNCTIONS =================
    methods (Access = protected)
        [dataMatrix, firstFrameIndex] = fetch(obj, indexList) % [external file]
    end
    % ================= SUPPORT FUNCTIONS : AUTOLOAD SYSTEM =================
    methods (Access = protected)
        % LOADDATA load batch of files specified by DATAFILEIDSET
        loadData(obj, dataFileIDSet) % [external file]

        % ESTIMATEDATABLOCKSIZE estimate average size of data blocks
        % corresponding to data file of current dataset path
        estimateDataBlockSize(obj) % [external file]

        % INITDATABLOCK initialize DATABLOCK structure of object
        initDataBlock(obj) % [external file]

        % REFRESHDATABLOCK reload new data file to DATABLOCK structure
        refreshDataBlock(obj) % [external file]

        function tof = isloadedall(obj)
            tof = isinf(obj.iterDataFile);
        end
    end

    % ================= TEMPORARY&DEPENDENT FUNCTION =================
    properties (Access = private)
        % ------- AUTOLOAD SYSTEM -------
        countFramePixel = @(x) size(x,1) * size(x,2);
    end


    % ================= DATA STRUCTURE =================
    properties
        path                        % path of data files
        dataFileIDList = cell(0);   % array of data file names
        dataBlockSet   = cell(0);   % array of data blocks
        % ------- AUTOLOAD SYSTEM -------
        memoryLimit = 1e9; % memory limitation in pixels
        % ------- PATCH MODULE -------
        patchSize = nan;  % size of patch (2/3 elements vector)
    end
    properties (Access = protected)
        % ------- AUTOLOAD SYSTEM -------
        pixelPerBlock = nan; % average quantity of pixels in a data block
    end
    properties (Access = private)
        % ------- ISTRAVERSED -------
        flagTraversed = false; % flag assistant to record status of traverse
        % ------- AUTOLOAD SYSTEM -------
        iterDataFile  = 0; % iterator of data files
        iterDataBlock = 0; % iterator of data blocks
    end
    properties (Dependent, SetAccess = private, Hidden)
        nDataFile
        nDataBlock
        % ------- AUTOLOAD SYSTEM -------
        dimin % dimension of frames in data file
        nSampleInSizeEstimation
        nInitDataBlock
        % ------- PATCH MODULE -------
        isOutputInPatch
        patchPerBlock
    end
    methods
        function value = get.nDataFile(obj)
            value = numel(obj.dataFileIDList);
        end
        function value = get.nDataBlock(obj)
            value = numel(obj.dataBlockSet);
        end
        % ------- AUTOLOAD SYSTEM -------
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
        % ------- PATCH MODULE -------
        function tof = get.isOutputInPatch(obj)
            tof = ~any(isnan(obj.patchSize)) && ...
                any(numel(obj.patchSize) == [2,3]) && isnumeric(obj.patchSize);
        end
        function value = get.patchPerBlock(obj)
            assert(obj.isOutputInPatch);
            value = round(obj.dimin / prod(obj.patchSize(1:2)));
        end
    end

    % ================= UTILITY =================
    methods (Access = protected)
        function consistencyCheck(obj)
            assert(obj.memoryLimit > 0);
            assert(any(numel(obj.patchSize) == [2,3]) || any(isnan(obj.patchSize)));
        end
    end
end
