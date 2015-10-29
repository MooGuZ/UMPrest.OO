classdef MotionInGIF < MotionMaterial
    methods
        function obj = MotionInGIF(dataPath, varargin)
            obj = obj@MotionMaterial(dataPath, varargin{:});
        end
    end

    methods
        function dataFileIDSet = getDataList(obj)
            animExtSet = {'.gif'};
            % fetch all files information under the folder
            dataFileIDSet = dir(obj.path);
            % initialize animation file index
            findex = false(1,numel(dataFileIDSet));
            % search for files according to <animExtSet>
            for i = 1 : numel(dataFileIDSet)
                % ignore hidden file and folders, including '.' and '..'
                if dataFileIDSet(i).name(1) == '.', continue; end
                % skip directories (no recurvely search)
                if dataFileIDSet(i).isdir, continue; end
                % pick out animation files
                [~,~,ext] = fileparts(dataFileIDSet(i).name);
                if any(strcmpi(ext,animExtSet))
                    findex(i) = true;
                end
            end
            % filter file name list
            dataFileIDSet = {dataFileIDSet(findex).name};
        end

        function dataBlock = readData(obj, dataBlockID)
            dataBlock = gifread(fullfile(obj.path, dataBlockID));
        end
    end
end
