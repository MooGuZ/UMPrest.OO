classdef MotionInRAW < MotionMaterial
    properties
        videoSize
        activeArea
        readFormat = {'float'};
    end
    
    % constructor
    methods
        function obj = MotionInRAW(dataPath, videoSize, activeArea, varargin)
            obj = obj@MotionMaterial(dataPath, videoSize, activeArea, varargin{:});
        end
    end
    
    % modification of superclass method
    methods (Access = protected)
        function paramSetup(obj, varargin)
            obj.videoSize = varargin{1};
            obj.activeArea = varargin{2};
            paramSetup@MotionMaterial(obj, varargin{3 : end});
            obj.pixelPerBlock = obj.calcPixelPerBlock;
            if ischar(obj.readFormat)
                obj.readFormat = {obj.readFormat};
            end
        end
        
        function consistancyCheck(obj)
            consistancyCheck@MotionMaterial(obj);
            assert(isnumeric(obj.videoSize) && numel(obj.videoSize) == 3, ...
                'VIDEOSIZE need to be a 3 element vector to specify size of video in pixels');
            assert(iscell(obj.readFormat), ...
                'READFORMAT should be a string or cell array of strings as defined in FREAD');
        end
        
        function value = calcPixelPerBlock(obj)
            dims = size(obj.videoSize);
            cropdims = diff(reshape(obj.activeArea, 2, numel(obj.activeArea) / 2));
            dims(1 : numel(cropdims)) = cropdims(:);
            value = prod(dims);
        end
    end
    
    % implementation of interface
    methods        
        % @@@ deal with single file situation
        function dataFileIDSet = getDataList(obj)
            animExtSet = {''};
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
        
        function dataBlock = readData(obj, dataFileID)
            fid = fopen(fullfile(obj.path, dataFileID), 'r', 'b');
            dataBlock = reshape(fread(fid, prod(obj.videoSize), obj.readFormat{:}), obj.videoSize);
            dataBlock = crop(dataBlock, obj.activeArea) + 0.5;
        end
    end
end