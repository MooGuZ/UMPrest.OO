function estimateDataBlockSize(obj)

if isempty(obj.dataFileIDList)
    obj.dataFileIDList = obj.getDataList();
    assert(~isempty(obj.dataFileIDList), ...
        'no qualified data file found in specified path');
end
pixelCount = 0;
for i = 1 : obj.samplePerEstimation
    pixelCount = pixelCount + numel(obj.readData(obj.dataFileIDList{i}));
end
obj.pixelPerBlock = pixelCount / obj.samplePerEstimation;

end
