% To-Do List
% 1. added input argument parser for properties setting [X]
% 2. make 'whiteningIsActived' a dependent property with value returned by
%    a status check function
% 3. add support for cache mechanism [x]
% 4. re-organize program structure

classdef MotionMaterial < hgsetget
    properties (Access = public)
        % FUNDAMENTAL SETTING
        memoryLimit = 1e9;          % memory limitation in pixels
        
        % FILE SYSTEM
        path                        % data location in file system
        
        

        % MODULE : WHITENING
        enableWhitening = false;    % data preprocessing : whitening
        whiteningCutoffRatio = 1 / 80;  % cutoff ratio of eigen value in whitening process
        
        % MODULE : CROP
        enableCrop    = false;      % data formation : frame crop
        patchSize     = nan;        % size of crop patch (2/3 elements vector)
        patchPerBlock = 13;         % average patches fetched from data block before refresh
    end
    
    properties (Hidden)
        % DATA BLOCK
        maxSampleInSizeEstimation = 13; % number of sample files used to estimate data size
    end
    
    % properties keep temperory status
    properties (Access = private)
        iterDataFile  = 0           % iterator of data files
        iterDataBlock = 0           % iterator of data blocks
    end

    % properties works as underlying structure
    properties (SetAccess = protected, Hidden)
        % FILE SYSTEM
        dataFileIDList = {};        % list of data units (video)
        
        % DATA BLOCK
        dataBlock                   % loaded video data
        pixelPerBlock = nan;        % result storage of function 'dataBlockSizeEstimate'
        
        % MODULE : WHITENING
        whiteningIsActivated = false;
        whiteningEncodeMatrix
        whiteningDecodeMatrix
        whiteningNoiseFacotr
        biasVector
    end

    % properties need realtime calculation
    properties (Dependent, Hidden, SetAccess = private)
        pixelPerFrame               % quantity of pixels in a frame of data matrix
        nInitDataBlock              % quantity of files load in initialization of data block
        nLoadedDataBlock            % quantity of files have already loaded in data block
    end 

    % get and set methods of dependent properties
    methods
        function value = get.pixelPerFrame(obj)
            if obj.enableCrop
                value = obj.patchSize(1) * obj.patchSize(2);
            else
                value = size(obj.dataBlock{1}, 1) * size(obj.dataBlock{1}, 2);
            end
        end

        function value = get.nInitDataBlock(obj)
            value = floor(obj.memoryLimit / obj.dataBlockSizeEstimate());
            if value <= 0
                warning('[MOTIONMATERIAL] memory is not sufficient for the program running');
                value = 1;
            end
        end

        function value = get.nLoadedDataBlock(obj)
            value = numel(obj.dataBlock);
        end
    end

    methods
        function obj = MotionMaterial(dataPath, varargin)
            obj.path = dataPath;
            obj.paramSetup(varargin{:});
            obj.initDataBlock();
            obj.initModule();
            obj.consistancyCheck();
        end
    end

    methods (Access = protected)
        function paramSetup(obj, varargin)
            [keys, values] = propertyParse(varargin);
            for i = 1 : numel(keys)
                obj.set(keys{i}, values{i});
            end
        end
        
        function initModule(obj)
            if obj.enableWhitening
                obj.calcWhiteningParam();
            end
        end

        function consistancyCheck(obj)
            if obj.enableCrop
                assert(~all(isnan(obj.patchSize)) && any(numel(obj.patchSize) == [2,3]));
            end
        end

        function loadData(obj, dataFileIDSet)
            obj.dataBlock = cell(1, numel(dataFileIDSet));
            for i = 1 : numel(dataFileIDSet)
                obj.dataBlock{i} = im2uint8(obj.readData(dataFileIDSet{i}));
                if ~obj.enableCrop
                    assert(obj.pixelPerFrame == ...
                        size(obj.dataBlock{i}, 1) * size(obj.dataBlock{i}, 2), ...
                        '[%s] dimension of data does not match loaded ones', dataFileIDSet{i});
                end
            end
        end

        function initDataBlock(obj)
            if isempty(obj.dataFileIDList)
                obj.dataFileIDList = obj.getDataList();
                assert(~isempty(obj.dataFileIDList), ...
                    'no qualified data file found in specified path');
            end
            obj.dataFileIDList = obj.dataFileIDList(randperm(numel(obj.dataFileIDList)));
            obj.iterDataFile = min(numel(obj.dataFileIDList), obj.nInitDataBlock);
            obj.loadData(obj.dataFileIDList(1 : obj.iterDataFile));
            % if all data loaded at once, tag iterDataFile as Inf
            if obj.iterDataFile >= numel(obj.dataFileIDList)
                obj.iterDataFile = inf;
            end
        end

        function refreshDataBlock(obj)
            if obj.enableCrop && rand() > (1.0 / obj.patchPerBlock)
                % do nothing in this situation
            elseif isinf(obj.iterDataFile) % all data have been loaded in memory
                obj.dataBlock = obj.dataBlock(randperm(obj.nLoadedDataBlock));
            elseif obj.iterDataFile < numel(obj.dataFileIDList) % load data from file system
                n = min(numel(obj.dataFileIDList) - obj.iterDataFile, obj.nInitDataBlock);
                obj.loadData(obj.dataFileIDList(obj.iterDataFile + (1 : n)));
                obj.iterDataFile = obj.iterDataFile + n;
            else
                obj.initDataBlock();
            end

            obj.iterDataBlock = 0;
        end

        function pixelPerBlock = dataBlockSizeEstimate(obj)
            if isnan(obj.pixelPerBlock)
                obj.pixelPerBlock = 0;
                if isempty(obj.dataFileIDList)
                    obj.dataFileIDList = obj.getDataList();
                    assert(~isempty(obj.dataFileIDList), ...
                        'no qualified data file found in specified path');
                end
                nSample = min(obj.maxSampleInSizeEstimation, round(numel(obj.dataFileIDList)/2)+1);
                for i = 1 : nSample
                    obj.pixelPerBlock = obj.pixelPerBlock ...
                        + numel(obj.readData(obj.dataFileIDList{i}));
                end
                obj.pixelPerBlock = obj.pixelPerBlock / obj.nSampleInSizeEstimation;
            end

            pixelPerBlock = obj.pixelPerBlock;
        end

        function [dataMatrix, firstFrameIndex] = fetch(obj, indexList)
            assert(obj.nLoadedDataBlock > 0);
            % FETCH would load all data units in buffer by default
            if ~exist('indexList', 'var'), indexList = 1 : obj.nLoadedDataBlock; end
            % check legality of index
            if min(indexList) < 1 || any(indexList ~= floor(indexList))
                msgID = 'MotionMaterial:fetch:IllegalParameter';
                msg = 'Number of Data Units has to be a integear greater than 0';
                error(msgID, msg);
            elseif max(indexList) > obj.nLoadedDataBlock
                msgID = 'MotionMaterial:fetch:IllegalParameter';
                msg = 'Index exceed boundary of data block';
                error(msgID, msg);
            end
            % calculate frame quantity for each data unit
            if obj.enableCrop && numel(obj.patchSize) >= 3
                framePerUnit = obj.patchSize(3) * ones(1, numel(indexList));
            else
                framePerUnit = cellfun(@(b) size(b, 3), obj.dataBlock(indexList));
            end
            % initialize data matrix (collection of data units)
            dataMatrix = zeros(obj.pixelPerFrame, sum(framePerUnit), 'uint8');
            % compose data matrix
            iframe = 1;
            if obj.enableCrop
                for i = 1 : numel(indexList)
                    dataMatrix(:, iframe : iframe + framePerUnit(i) - 1) = reshape( ...
                        randcrop(obj.dataBlock{indexList(i)}, obj.patchSize), ...
                        obj.pixelPerFrame, framePerUnit(i));
                    iframe = iframe + framePerUnit(i);
                end
            else
                for i = 1 : numel(indexList)
                    dataMatrix(:, iframe : iframe + framePerUnit(i) - 1) = ...
                        reshape(obj.dataBlock{indexList(i)}, obj.pixelPerFrame, framePerUnit(i));
                    iframe = iframe + framePerUnit(i);
                end
            end
            % generate index for first frame of each sequence
            firstFrameIndex = [1, framePerUnit(1 : end-1) + 1];
            % transform data into double for convenience of calculation
            dataMatrix = im2double(dataMatrix);
            % apply data processing modules
            if obj.whiteningIsActivated
                dataMatrix = obj.whiteningEncodeMatrix * bsxfun(@minus, dataMatrix, obj.biasVector);
            end
        end

        calcWhiteningParam(obj)
    end

    methods
        function [dataMatrix, firstFrameIndex] = next(obj, n)
            if ~exist('n', 'var'), n = 1; end
            % N has to be a positive integer
            assert(n > 0 && n == floor(n));
            % refresh data buffer if necessary
            if obj.iterDataBlock >= obj.nLoadedDataBlock
                obj.refreshDataBlock();
            end
            % check whether or not need to refresh buffer
            if n > obj.nLoadedDataBlock - obj.iterDataBlock
                nRest = n + obj.iterDataBlock - obj.nLoadedDataBlock;
                n = obj.nLoadedDataBlock - obj.iterDataBlock;
            end
            % get data available now
            [dataMatrix, firstFrameIndex] = obj.fetch(obj.iterDataBlock + (1 : n));
            obj.iterDataBlock = obj.iterDataBlock + n;
            % get rest data if necessary
            if exist('nRest', 'var')
                obj.refreshDataBlock();
                [dataMatrixRest, firstFrameIndexRest] = obj.next(nRest);
                dataMatrix = [dataMatrix, dataMatrixRest];
                firstFrameIndex = [firstFrameIndex, firstFrameIndexRest];
            end
        end

        function [dataMatrix, firstFrameIndex] = all(obj)
            if isinf(obj.iterDataFile)
                [dataMatrix, firstFrameIndex] = obj.fetch();
            else
                warning('MotionMatrial:all', ...
                    'This is a risky operation which may lead to memory and performance problems');
                dataBlockBackup = obj.dataBlock;
                obj.loadData(obj.dataFileIDList);
                [dataMatrix, firstFrameIndex] = obj.fetch();
                obj.dataBlock = dataBlockBackup;
            end
        end
    end

    methods (Abstract)
        dataFileIDSet = getDataList(obj)
        dataBlock = readData(obj, dataFileID)
    end
end
