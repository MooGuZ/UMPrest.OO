classdef MotionInGIF < MotionMaterial
    properties
        frameResolution
    end

    methods
        function obj = MotionInGIF(dataPath, varargin)
            obj = obj@MotionMaterial(dataPath, varargin{:});
        end
    end

    methods
        function dataUnitIDSet = getDataList(obj)
            flist = dir(fullfile(obj.path, '*.gif'));
            dataUnitIDSet = {flist(:).name};
        end

        function dataUnit = readData(obj, dataUnitID)
            [dataUnit, resolution] = gif2anim(fullfile(obj.path, dataUnitID));
            if isempty(obj.frameResolution)
                obj.frameResolution = resolution;
            else
                assert(all(resolution == obj.frameResolution), ...
                    sprintf('Current GIF (%s) does not match resolution of others', dataUnitID));
            end
        end
    end
end
