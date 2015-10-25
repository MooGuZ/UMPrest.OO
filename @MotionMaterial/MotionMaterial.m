% To-Do List
% 1. added input argument parser for properties setting [X]
% 2. make 'whiteningIsActived' a dependent property with value returned by
%    a status check function

classdef MotionMaterial < hgsetget
    properties
        path                      % data location in file system
        dataBlock                 % loaded video data
        memoryLimit = 1e9;        % evaluate by Pixels
        enableWhitening = false;
        pixelPerFrame
        pixelPerUnit
        nSampleInSizeEstimation = 3;
    end
    
    properties (Dependent, SetAccess = protected )
        dataCount
    end
    
    properties (GetAccess = public)
        whiteningIsActivated = false;
        whiteningCutoffRatio = 1 / 80;
        whiteningEncodeMatrix
        whiteningDecodeMatrix
        whiteningNoiseFacotr
        biasVector
    end
    
    methods
        % constructor from data path
        function obj = MotionMaterial(dataPath, varargin)
            obj.path = dataPath;
            obj.paramSetup(varargin);
        end      
    end
    
    methods
        function value = get.dataCount(obj)
            value = 0;
            for i = 1 : numel(obj.dataBlock)
                value = value + numel(obj.dataBlock{i});
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
                        'Input materials are not consistant in pixel quantities.');
                end                
            end
        end
            
        function loadMaximumData(obj)
            dataList = obj.getDataList();
            nUnit = min(numel(dataList), ...
                floor(obj.memoryLimit / obj.dataUnitSizeEstimate()));
            dataUnitIndex = randpermext(numel(dataList), nUnit);
            obj.loadData(dataList(dataUnitIndex));
        end
                
        function pixelPerUnit = dataUnitSizeEstimate(obj)
            if isempty(obj.pixelPerUnit)
                obj.pixelPerUnit = 0;
                dataUnitIDSet = obj.getDataList();
                sampleIndex = randpermext(numel(dataUnitIDSet), obj.nSampleInSizeEstimation);
                for i = 1 : numel(sampleIndex)
                    obj.pixelPerUnit = obj.pixelPerUnit ...
                        + numel(obj.readData(dataUnitIDSet{sampleIndex(i)}));
                end
                obj.pixelPerUnit = obj.pixelPerUnit / obj.nSampleInSizeEstimation;
            end
            
            pixelPerUnit = obj.pixelPerUnit;
        end
        
        calcWhiteningParam(obj)
    end
    
    methods
        function [dataMatrix, firstFrameIndex] = fetchRawData(obj, n)
            if ~exist('n', 'var'), n = numel(obj.dataBlock); end
            if n < 1
                dataMatrix = [];
                firstFrameIndex = [];
                return
            end
            sampleIndex = randpermext(numel(obj.dataBlock), n);
            framePerBlock = cellfun(@(b) size(b, 2), obj.dataBlock(sampleIndex));
            dataMatrix = zeros(obj.pixelPerFrame, sum(framePerBlock), ...
                'like', obj.dataBlock{1});
            iframe = 1;
            for i = 1 : numel(sampleIndex)
                dataMatrix(:, iframe : iframe + framePerBlock(i) - 1) = ...
                    obj.dataBlock{sampleIndex(i)};
            end
            firstFrameIndex = [1, framePerBlock(1 : end-1) + 1];
        end
        
        function [dataMatrix, firstFrameIndex] = fetchData(obj, n)
            if ~exist('n', 'var'), n = numel(obj.dataBlock); end
            if n < 1
                dataMatrix = [];
                firstFrameIndex = [];
                return
            end
            [dataMatrix, firstFrameIndex] = obj.fetchRawData(n);
            dataMatrix = im2double(dataMatrix);
            if obj.whiteningIsActivated
                dataMatrix = obj.whiteningEncodeMatrix * ...
                    bsxfun(@minus, dataMatrix, obj.biasVector);
            end            
        end
    end
    
    methods (Abstract)
        dataUnitIDSet = getDataList(obj)
        dataUnit = readData(obj, dataUnitID)
    end
end
