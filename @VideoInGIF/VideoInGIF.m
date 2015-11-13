classdef VideoInGIF < VideoDataset & LibUtility
    % ================= VIDEODATASET IMPLEMENTATION =================
    methods
        function dataFileIDSet = getDataList(obj)
            dataFileIDSet = listFileWithExt(obj.path, '.gif');
        end

        function dataBlock = readData(obj, dataBlockID)
            dataBlock = gifread(fullfile(obj.path, dataBlockID));
        end
    end
    
    % ================= UTILITY =================
    methods
        function obj = VideoInGIF(dataPath, varargin)
            obj.path = dataPath;
            obj.setupByArg(varargin{:});
            obj.consistencyCheck();
            obj.initDataBlock();
        end
    end
end
