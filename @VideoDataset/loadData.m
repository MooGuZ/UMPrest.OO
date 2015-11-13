function loadData(obj, dataFileIDSet)
    obj.dataBlockSet = cell(1, numel(dataFileIDSet));
    for i = 1 : numel(dataFileIDSet)
        obj.dataBlockSet{i} = im2uint8(obj.readData(dataFileIDSet{i}));
        if ~obj.isOutputInPatch
            assert(obj.countFramePixel(obj.dataBlockSet{i}) == obj.dimin, ...
                '[%s] dimension of data does not match loaded ones', dataFileIDSet{i});
        end
    end
end
