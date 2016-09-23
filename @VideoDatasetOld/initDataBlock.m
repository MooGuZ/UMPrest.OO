function initDataBlock(obj)
    if isempty(obj.dataFileIDList)
        obj.dataFileIDList = obj.getDataList();
        assert(~isempty(obj.dataFileIDList), ...
            'no qualified data file found in specified path');
    end
    obj.dataFileIDList = obj.dataFileIDList(randperm(obj.nDataFile));
    obj.iterDataFile = obj.blockPerLoad;
    obj.loadData(obj.dataFileIDList(1 : obj.iterDataFile));
    % initialize temporal variables
    obj.iterDataBlock = 0;
    if obj.isOutputInPatch
        obj.patchPerBlockCount = obj.patchPerBlock;
    end
end
