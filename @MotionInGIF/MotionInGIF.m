classdef MotionInGIF < MotionMaterial
    methods
        function obj = MotionInGIF(dataPath, varargin)
            obj = obj@MotionMaterial(dataPath, varargin{:});
        end
    end

    methods
        function dataFileIDSet = getDataList(obj)
            dataFileIDSet = listFileWithExt(obj.path, '.gif');
        end

        function dataBlock = readData(obj, dataBlockID)
            dataBlock = gifread(fullfile(obj.path, dataBlockID));
        end
    end
end
