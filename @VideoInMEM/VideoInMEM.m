classdef VideoInMEM < VideoDataset
    % ================= VIDEODATASET IMPLEMENTATION =================
    methods
        function dataFileIDList = getDataList(obj)
            dataFileIDList = arrayfun(@(x) {x}, 1 : numel(obj.dataBlockSet));
        end
        
        function dataBlock = readData(obj, dataFileID)
            dataBlock = obj.dataBlockSet{dataFileID};
        end
    end
   
    % ================= UTILITY =================
    methods
        function obj = VideoInMEM(data, ffindex)
            % initialize data block
            obj.dataBlockSet = cell(1, numel(ffindex));
            % load data blocks from given data and information
            dataSize = size(data);
            switch numel(dataSize)
                case {3}
                    % prevent overflow in following process
                    ffindex = [ffindex(:)', dataSize(3) + 1];
                    for i = 1 : numel(obj.dataBlockSet)
                        obj.dataBlockSet = im2uint8(data(:, :, ffindex(i) : ffindex(i+1) - 1));
                    end
                    
                case {2}
                    % prevent overflow in following process
                    ffindex = [ffindex(:)', dataSize(2) + 1];
                    for i = 1 : numel(obj.dataBlockSet)
                        tmp = im2uint8(data(:, ffindex(i) : ffindex(i+1) - 1));
                        if round(sqrt(dataSize(1)))^2 == dataSize(1)
                            obj.dataBlockSet{i} = reshape(tmp, ...
                                sqrt(dataSize(1)), sqrt(dataSize(1)), numel(tmp) / dataSize(1));
                        else
                            obj.dataBlockSet{i} = reshape(tmp, dataSize(1), 1, numel(tmp) / dataSize(1));
                        end
                    end
                    
                otherwise
                    error('[%s] unrecognized data type', class(obj));
            end
            % setup parameters to match videodataset interface
            obj.dataFileIDList = obj.getDataList();
        end
    end
end
