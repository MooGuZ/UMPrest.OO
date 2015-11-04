function refreshDataBlock(obj)
    % reload data file to dataBlockSet if necessary
    if obj.isOutputInPatch && (rand() > (1.0 / obj.patchPerBlock))
        % do nothing here
    elseif obj.isloadedall
        obj.dataBlockSet  = obj.dataBlockSet(randperm(obj.nDataBlock));
        obj.flagTraversed = true;
    elseif obj.iterDataFile < obj.nDataFile
        n = min(obj.nDataFile - obj.iterDataFile, obj.nInitDataBlock);
        obj.loadData(obj.dataFileIDList(obj.iterDataFile + (1 : n)));
        obj.iterDataFile = obj.iterDataFile + n;
    else
        obj.initDataBlock();
        obj.flagTraversed = true;
    end
    % update iterator of data block
    obj.iterDataBlock = 0;
end
