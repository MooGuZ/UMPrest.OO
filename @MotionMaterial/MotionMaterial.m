classdef MotionMaterial < handle
    properties
        path % data location in file system
        dataBuffer % loaded video data
    end
    
    properties (GetAccess = private)
        enableWhitening = false;
    end
    
    methods
        % constructor from data path
        function self = MotionMaterial(dataPath)
            self.path = dataPath;
        end
        
        % method signature
        [] = calcWhiteningParam(obj)
        
        % interfaces
        dataPiece = loadDataPiece(dataPath)
        loadDataBatch(num)
        dataBlock = getData(num)
        
    end
end
