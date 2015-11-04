function [dataMatrix, firstFrameIndex] = next(obj, n)
    if ~exist('n', 'var'), n = 1; end
    % N has to be a positive integer
    assert(n > 0 && n == floor(n));
    % refresh data buffer if necessary
    if obj.iterDataBlock >= obj.nDataBlock
        obj.refreshDataBlock();
    end
    % check whether or not need to refresh buffer
    if n > obj.nDataBlock - obj.iterDataBlock
        nRest = n + obj.iterDataBlock - obj.nDataBlock;
        n = obj.nDataBlock - obj.iterDataBlock;
    end
    % get data available now
    [dataMatrix, firstFrameIndex] = obj.fetch(obj.iterDataBlock + (1 : n));
    obj.iterDataBlock = obj.iterDataBlock + n;
    % get rest data if necessary
    if exist('nRest', 'var')
        obj.refreshDataBlock();
        [dataMatrixRest, firstFrameIndexRest] = obj.next(nRest);
        dataMatrix      = [dataMatrix, dataMatrixRest];
        firstFrameIndex = [firstFrameIndex, firstFrameIndexRest];
        clear dataMatrixRest firstFrameIndexRest
    end
end
