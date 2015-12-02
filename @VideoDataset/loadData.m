function loadData(obj, dataFileIDSet)
    obj.dataBlockSet = cell(1, numel(dataFileIDSet));
    for i = 1 : numel(dataFileIDSet)
        obj.dataBlockSet{i} = im2uint8(obj.readData(dataFileIDSet{i}));
        % get statistics and check consistency of dimensionality
        if obj.isOutputInPatch
            n = min(obj.magicNumber, ...
                ceil(obj.countFramePixel(obj.dataBlockSet{i}) / prod(obj.patchSize(1:2))));
            [dataMatrix, ~] = obj.fetch(repmat(i, 1, n));
            obj.calcStat(dataMatrix);
        else
            assert(obj.countFramePixel(obj.dataBlockSet{i}) == obj.dimin, ...
                '[%s] dimension of data does not match loaded ones', dataFileIDSet{i});
            obj.calcStat(obj.dataBlockSet{i});
        end
    end
end
