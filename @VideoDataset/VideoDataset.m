% VideoDataset < DPModule & LearningModule & GPUModule
%   VIDEODATASET is an abstraction of all data source of videos. This class provide
%   convenient funtion handles to users to get access data. It support automatical
%   memory management with an auto-reload cache system, which makes a trade-off
%   between performance and memory utilization. VideoDataset provides semetical
%   interfaces without considering implementation details. However, this is an
%   abstract class. Developers can create concrete class with only two functions
%   that follow interface provided by VideoDataset.
%
% [FUNCTION HANDLE]
%   volumn()
%   next([n])
%   traverse()
%   statsample()
%   istraversed()
%   dimout()
%   statistic()
%
% [INTREFACE]
%   dataFileIDList = getDataList(obj)
%   dataBlock = readData(obj, dataFileID)
%
% see also, DPModule, LearningModule, GPUModule, VideoInGIF, VideoInRAW, VideoInMEM.
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
% Dec 08, 2015 - remove 'traverse' related functions and variables
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

        varargout = next(obj, n) % [external file]

        % sample = traverse(obj) % [external file]

        function sample = statsample(obj)
            if obj.isOutputInPatch
                n = 0.03 * obj.nDataBlock * obj.patchPerBlock;
            else
                n = 0.3 * obj.nDataBlock;
            end
            sample = obj.next(n);
        end

        % function tof = istraversed(obj)
        %     tof = obj.flagTraversed;
        %     if tof
        %         obj.flagTraversed = false;
        %     end
        % end

        function n = dimout(obj)
            if obj.isOutputInPatch
                n = prod(obj.patchSize(1:2));
            else
                n = obj.dimin;
            end
        end
    end
    % ================= STATISTIC SYSTEM =================
    methods
        function stat = statistic(obj)
            stat = obj.stat;
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

        % RESTATEDATABLOCK reinitialize the parameters to make the state of
        % dataset seems as just initialized without load new data file
        restateDataBlock(obj) % [external file]

        function tof = isloadedall(obj)
            tof = obj.nDataFile <= obj.nDataBlock;
        end

        function value = countFramePixel(~, data)
            value = size(data,1) * size(data,2);
        end
    end
    % ================= SUPPORT FUNCTIONS : STATISTIC SYSTEM =================
    methods (Access = protected)
        % CALCSTAT accumulate statistic information from given data
        calcStat(obj, data) % [external files]
    end

    % ================= DATA STRUCTURE =================
    properties
        path                        % path of data files
        dataFileIDList = cell(0);   % array of data file names
        dataBlockSet   = cell(0);   % array of data blocks
        % ------- AUTOLOAD SYSTEM -------
        memoryLimit = 1e9; % memory limitation in pixels
        % ------- PATCH MODULE -------
        patchSize = nan; % size of patch (2/3 elements vector)
        % ------- STATISTIC SYSTEM -------
        stat % structure that containing statistic information
    end
    properties (Access = protected)
        % ------- AUTOLOAD SYSTEM -------
        pixelPerBlock = nan; % average quantity of pixels in a data block
    end
    properties (Access = private)
        magicNumber = 13; % the number used in the occasion needs luck
        % ------- ISTRAVERSED -------
        % flagTraversed = false; % flag assistant to record status of traverse
        % ------- AUTOLOAD SYSTEM -------
        iterDataFile  = 0; % iterator of data files
        iterDataBlock = 0; % iterator of data blocks
        % ------- PATCH MODULE -------
        patchPerBlockCount = 0;
    end
    properties (Dependent, SetAccess = private, Hidden)
        nDataFile
        nDataBlock
        resolution
        % ------- AUTOLOAD SYSTEM -------
        dimin % dimension of frames in data file
        samplePerEstimation
        blockPerLoad
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
        function value = get.resolution(obj)
            if obj.isOutputInPatch()
                value = obj.patchSize;
            elseif obj.nDataBlock == 0
                value = nan;
            else
                tmp = size(obj.dataBlockSet{1});
                value = tmp(1:2);
            end
        end
        % ------- AUTOLOAD SYSTEM -------
        function value = get.dimin(obj)
            if isempty(obj.dataBlockSet)
                value = nan;
            elseif obj.isOutputInPatch
                value = 0;
                for i = 1 : min(numel(obj.dataBlockSet), obj.magicNumber);
                    value = value + obj.countFramePixel(obj.dataBlockSet{i});
                end
                value = ceil(value / i);
            else
                value = obj.countFramePixel(obj.dataBlockSet{1});
            end
        end
        function value = get.samplePerEstimation(obj)
            assert(~isempty(obj.dataFileIDList));
            value = min(13, ceil(obj.nDataFile / 4));
        end
        function value = get.blockPerLoad(obj)
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
            value = round(obj.dimin / sqrt(prod(obj.patchSize(1:2))));
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
