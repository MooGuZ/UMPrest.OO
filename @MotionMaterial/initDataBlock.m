function initDataBlock(obj)
    if isempty(obj.dataFileIDList)
        obj.dataFileIDList = obj.getDataList();
        assert(~isempty(obj.dataFileIDList), ...
        'no qualified data file found in specified path');
    end
    obj.dataFileIDList = obj.dataFileIDList(randperm(obj.nDataFile));
    obj.iterDataFile = obj.nInitDataBlock;
    obj.loadData(obj.dataFileIDList(1 : obj.iterDataFile));
    % if all data loaded at once, tag iterDataFile as Inf
    if obj.iterDataFile >= obj.nDataFile
        obj.iterDataFile = inf;
    end
    % initialize iterator of data block
    obj.iterDataBlock = 0;
end
