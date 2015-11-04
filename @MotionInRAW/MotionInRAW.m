% added support to configure file under data path

classdef MotionInRAW < MotionMaterial
    properties
        videoSize
        activeArea
        readFormat = {'float'};
    end
    
    properties (Access = private)
        configFileName = 'umpooconfig.mat';
    end
    
    methods
        function obj = MotionInRAW(dataPath, varargin)
            obj = obj@MotionMaterial(dataPath, varargin{:});
        end
        
        function paramSetup(obj, varargin)
            paramSetup@MotionMaterial(obj, varargin{:});
            % load VIDEOSIZE from configuration file if necessary
            if isempty(obj.videoSize)
                assert(exist(fullfile(obj.path, obj.configFileName), 'file') == 2, ...
                    'program cannot load data when video size is unknown');
                conf = load(fullfile(obj.path, obj.configFileName));
                assert(isfield(conf, 'videoSize'), ...
                    'configuration file(%s) is incomplete', fullfile(obj.path, obj.configFileName));
                obj.videoSize = conf.videoSize;
            end
            % initialize ACTIVEAREA when necessary
            if isempty(obj.activeArea)
                % load from configuration file
                if exist('conf', 'var') && isfield(conf, 'activeArea')
                    obj.activeArea = conf.activeArea;
                else
                    obj.activeArea = obj.videoSize;
                end
            end
            % ensure READFORMAT encaptured in cell
            if ischar(obj.readFormat)
                obj.readFormat = {obj.readFormat};
            end
            % calculate pixel quantities in each data block
            obj.pixelPerBlock = obj.calcPixelPerBlock;
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