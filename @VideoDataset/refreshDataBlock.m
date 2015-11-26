function refreshDataBlock(obj)
    % update iterator of data block
    obj.iterDataBlock = 0;
    % count on quantity of patches have been croped
    if obj.isOutputInPatch
        obj.patchPerBlockCount = obj.patchPerBlockCount - 1;
        if obj.patchPerBlockCount > 0
            return
        else
            obj.patchPerBlockCount = obj.patchPerBlock;
        end
    end
    % reload data file to dataBlockSet if necessary
    if obj.isloadedall
        obj.dataBlockSet  = obj.dataBlockSet(randperm(obj.nDataBlock));
        obj.flagTraversed = true;
    elseif obj.iterDataFile < obj.nDataFile
        n = min(obj.nDataFile - obj.iterDataFile, obj.blockPerLoad);
        obj.loadData(obj.dataFileIDList(obj.iterDataFile + (1 : n)));
        obj.iterDataFile = obj.iterDataFile + n;
    else
        obj.initDataBlock();
        obj.flagTraversed = true;
    end
end
