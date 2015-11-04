% This function would modify current underlining status of the
% object. Normally, it would not effect your work. However, in
% special application, it maybe a trouble.
function [dataMatrix, firstFrameIndex] = all(obj)
    if obj.isloadedall
        obj.iterDataBlock = 0;
    elseif (obj.iterDataFile ~= obj.nDataBlock) || (obj.iterDataBlock ~= 0)
        obj.initDataBlock();
    end
    % load data by function NEXT
    if obj.isOutputInPatch
        [dataMatrix, firstFrameIndex] = obj.next(obj.nDataFile * obj.patchPerBlock);
    else
        [dataMatrix, firstFrameIndex] = obj.next(obj.nDataFile);
    end
end
