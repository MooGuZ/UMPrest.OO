% To-Do List
% 1. added input argument parser for properties setting [X]
% 2. make 'whiteningIsActived' a dependent property with value returned by
%    a status check function

classdef MotionMaterial < hgsetget
    properties
        % fundamental information
        path                      % data location in file system
        dataBlock                 % loaded video data
        memoryLimit = 1e9;        % memory limitation in pixels
        dataUnitIDList = {};      % list of data units (video)
        
        % intermediate parameters
        nSampleInSizeEstimation = 12;
        pixelPerFrame
        pixelPerUnit
        
        % data processing modules
        enableWhitening = false;
    end
    
    properties (Access = private)
        iLoadedDataUnit = 0
        iterator = 0
    end
    
    properties (GetAccess = public, SetAccess = private)
        whiteningIsActivated = false;
        whiteningCutoffRatio = 1 / 80;
        whiteningEncodeMatrix
        whiteningDecodeMatrix
        whiteningNoiseFacotr
        biasVector
    end
    
    properties (Dependent, SetAccess = protected )
        dataCount
        nPreloadDataUnit
        nLoadedDataUnit
    end
    
    methods
        function value = get.dataCount(obj)
            value = 0;
            for i = 1 : obj.nLoadedDataUnit
                value = value + numel(obj.dataBlock{i});
            end
        end
        
        function value = get.nPreloadDataUnit(obj)
            value = floor(obj.memoryLimit / obj.dataUnitSizeEstimate());
        end
        
        function value = get.nLoadedDataUnit(obj)
            value = obj.nLoadedDataUnit;
        end
    end
    
    methods
        % constructor from data path
        function obj = MotionMaterial(dataPath, varargin)
            obj.path = dataPath;
            obj.paramSetup(varargin);
            obj.preloadData();
            % load data processing modules
            if obj.enableWhitening
                obj.calcWhiteningParam();
            end
        end      
    end
    
    methods (Access = protected)
        function paramSetup(obj, varargin)
            [keys, values] = propertyParse(varargin{:});
            for i = 1 : numel(keys)
                obj.set(keys{i}, values{i});
            end
        end
        
        function loadData(obj, dataUnitIDSet)
            obj.dataBlock = cell(1, numel(dataUnitIDSet));
            for i = 1 : numel(dataUnitIDSet)
                obj.dataBlock{i} = obj.readData(dataUnitIDSet{i});
                if isempty(obj.pixelPerFrame)
                    obj.pixelPerFrame = size(obj.dataBlock{i}, 1);
                else
                    assert(size(obj.dataBlock{i}, 1) == obj.pixelPerFrame, ...
                        'Input materials are not consistant in pixel quantities per frame.');
                end                
            end
        end
            
        function preloadData(obj)
            if isempty(obj.dataUnitIDList)
                obj.dataUnitIDList = obj.getDataList();
            end
            obj.dataUnitIDList = obj.dataUnitIDList(randperm(numel(obj.dataUnitIDList)));
            obj.iLoadedDataUnit = min(numel(obj.dataUnitIDList), obj.nPreloadDataUnit);
            obj.loadData(obj.dataUnitIDList(1 : obj.iLoadedDataUnit));
            % if all data loaded at once, tag iLoadedDataUnit as Inf
            if obj.iLoadedDataUnit >= numel(obj.dataUnitIDList)
                obj.iLoadedDataUnit = inf;
            end
        end
        
        function refreshData(obj)
            if isinf(obj.iLoadedDataUnit) % all data have been loaded in memory
                obj.dataBlock = obj.dataBlock(randperm(obj.nLoadedDataUnit));
            elseif obj.iLoadedDataUnit < numel(obj.dataUnitIDList) % load data from file system
                nUnit = min(numel(obj.dataUnitIDList) - obj.iLoadedDataUnit, obj.nPreloadDataUnit);
                obj.loadData(obj.dataUnitIDList(obj.iLoadDataUnit + 1 : obj.iLoadDataUnit + nUnit));
                obj.iLoadedDataUnit = obj.iLoadedDataUnit + nUnit;
            else
                obj.preloadData();
            end
            
            obj.iterator = 0;
        end
                
        function pixelPerUnit = dataUnitSizeEstimate(obj)
            if isempty(obj.pixelPerUnit)
                obj.pixelPerUnit = 0;
                if isempty(obj.dataUnitIDList)
                    obj.dataUnitIDList = obj.getDataList();
                end
                for i = 1 : obj.nSampleInSizeEstimation
                    obj.pixelPerUnit = obj.pixelPerUnit ...
                        + numel(obj.readData(obj.dataUnitIDList{i}));
                end
                obj.pixelPerUnit = obj.pixelPerUnit / obj.nSampleInSizeEstimation;
            end
            
            pixelPerUnit = obj.pixelPerUnit;
        end
        
        function [dataMatrix, firstFrameIndex] = fetch(obj, indexList)
            % FETCH would load all data units in buffer by default
            if ~exist('index', 'var'), indexList = 1 : obj.nLoadedDataUnit; end
            % check legality of index
            if min(indexList) < 1 || any(indexList ~= floor(indexList))
                msgID = 'MotionMaterial:fetch:IllegalParameter';
                msg = 'Number of Data Units has to be a integear greater than 0';
                error(msgID, msg);
            elseif max(indexList) > obj.nLoadedDataUnit
                msgID = 'MotionMaterial:fetch:IllegalParameter';
                msg = 'Index exceed boundary of data block';
                error(msgID, msg);
            end
            % initialize data matrix
            framePerBlock = cellfun(@(b) size(b, 2), obj.dataBlock(indexList));
            dataMatrix = zeros(obj.pixelPerFrame, sum(framePerBlock), ...
                'like', obj.dataBlock{1});
            % compose data matrix
            iframe = 1;
            for i = 1 : numel(indexList)
                dataMatrix(:, iframe : iframe + framePerBlock(i) - 1) = ...
                    obj.dataBlock{indexList(i)};
            end
            % generate index for first frame of each sequence
            firstFrameIndex = [1, framePerBlock(1 : end-1) + 1];
            % transform data into double for convenience of calculation
            dataMatrix = im2double(dataMatrix);
            % apply data processing modules
            if obj.whiteningIsActivated
                dataMatrix = obj.whiteningEncodeMatrix * bsxfun(@minus, dataMatrix, obj.biasVector);
            end
        end
        
        toRaw(obj)
        
        calcWhiteningParam(obj)
    end
    
    methods
        function [dataMatrix, firstFrameIndex] = next(obj, n)
            if ~exist('n', 'var'), n = 1; end
            % N has to be a positive integer
            assert(n > 0 && n == floor(n));
            % check whether or not need to refresh buffer
            if n > obj.nLoadedDataUnit - obj.iterator
                nRest = n + obj.iterator - obj.nLoadedDataUnit;
                n = obj.nLoadedDataUnit - obj.iterator;
            end
            % get data available now
            [dataMatrix, firstFrameIndex] = obj.fetch(obj.iterator + 1 : obj.iterator + n);
            obj.iterator = obj.iterator + n;
            % get rest data if necessary
            if exist('nRest', 'var')
                obj.refreshData();
                [dataMatrixRest, firstFrameIndexRest] = obj.next(nRest);
                dataMatrix = [dataMatrix, dataMatrixRest];
                firstFrameIndex = [firstFrameIndex, firstFrameIndexRest];
            end
        end
        
        function [dataMatrix, firstFrameIndex] = all(obj)
            if isinf(obj.iLoadedDataUnit)
                [dataMatrix, firstFrameIndex] = obj.fetch();
            else
                warning('MotionMatrial:all', ...
                    'This is a risky operation which may lead to memory and performance problems');
                dataBlockBackup = obj.dataBlock;
                obj.loadData(obj.dataUnitIDList);
                [dataMatrix, firstFrameIndex] = obj.fetch();
                obj.dataBlock = dataBlockBackup;
            end
        end
    end
    
    methods (Abstract)
        dataUnitIDSet = getDataList(obj)
        dataUnit = readData(obj, dataUnitID)
    end
end
