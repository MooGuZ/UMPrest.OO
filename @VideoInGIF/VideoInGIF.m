classdef VideoInGIF < VideoDataset
    methods
        function obj = VideoInGIF(dataPath, varargin)
            obj = obj@VideoDataset(dataPath, varargin{:});
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
