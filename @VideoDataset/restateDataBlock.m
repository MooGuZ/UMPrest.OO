function restateDataBlock(obj)
    % turn off traversed flag
    flagTraversed = false;
    % reorder the data file list if only partial data file loaded
    if not(obj.isloadedall())
        % index of blocked file
        ibf = obj.iterDataFile - obj.nDataBlock + 1 : obj.iterDataFile;
        % index of other files
        iof = [1 : ibf(1) - 1, ibf(end) + 1 : obj.nDataFile];
        % generate new index with blocked file in the beginning
        index = [ibf, iof(randperm(numel(iof)))];
        % re-order dataFileIDList
        obj.dataFileIDList = obj.dataFileIDList(index);
        % reset iterators
        obj.iterDataFile = obj.nDataBlock;
    end
    % reset iterator of data block
    obj.iterDataBlock = 0;
end
