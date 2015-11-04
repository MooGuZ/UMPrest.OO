function [dataMatrix, firstFrameIndex] = fetch(obj, indexList)
    assert(obj.nDataBlock > 0);
    % FETCH would load a random data units by default
    if ~exist('indexList', 'var'), indexList = randi(obj.nDataBlock); end
    % check legality of index
    if min(indexList) < 1 || any(indexList ~= floor(indexList))
        msgID = 'MotionMaterial:fetch:IllegalParameter';
        msg = 'Number of Data Units has to be a integear greater than 0';
        error(msgID, msg);
    elseif max(indexList) > obj.nDataBlock
        msgID = 'MotionMaterial:fetch:IllegalParameter';
        msg = 'Index exceed boundary of data block';
        error(msgID, msg);
    end
    % calculate frame quantity for each data unit
    if obj.isOutputInPatch && numel(obj.patchSize) == 3
        framePerUnit = obj.patchSize(3) * ones(1, numel(indexList));
    else
        framePerUnit = cellfun(@(b) size(b, 3), obj.dataBlockSet(indexList));
    end
    % initialize data matrix (collection of data units)
    dataMatrix = zeros(obj.dimout, sum(framePerUnit), 'uint8');
    % compose data matrix
    iframe = 0;
    if obj.isOutputInPatch
        for i = 1 : numel(indexList)
            dataMatrix(:, iframe + 1 : iframe + framePerUnit(i)) = reshape( ...
            randcrop(obj.dataBlockSet{indexList(i)}, obj.patchSize), ...
            obj.dimout, framePerUnit(i));
            iframe = iframe + framePerUnit(i);
        end
    else
        for i = 1 : numel(indexList)
            dataMatrix(:, iframe + 1 : iframe + framePerUnit(i)) = ...
            reshape(obj.dataBlockSet{indexList(i)}, obj.dimout, framePerUnit(i));
            iframe = iframe + framePerUnit(i);
        end
    end
    % generate index for first frame of each sequence
    firstFrameIndex = [1, framePerUnit(1 : end-1) + 1];
    % transform data into double for convenience of calculation
    dataMatrix = im2double(dataMatrix);
end
