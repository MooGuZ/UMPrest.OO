function varargout = next(obj, n)
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
        [dataMatrixRest, firstFrameIndexRest] = obj.next(nRest);
        firstFrameIndexRest = firstFrameIndexRest + size(dataMatrix, 2);
        dataMatrix      = [dataMatrix, dataMatrixRest];
        firstFrameIndex = [firstFrameIndex, firstFrameIndexRest];
        clear dataMatrixRest firstFrameIndexRest
    end
    % return values according to number of output arguments
    if nargout == 1
        varargout{1} = struct( ...
            'data', dataMatrix, ...
            'ffindex', firstFrameIndex, ...
            'frmres', obj.resolution());
    elseif nargout == 2
        varargout{1} = dataMatrix;
        varargout{2} = firstFrameIndex;
    else
        error('[VIDEODATASET.NEXT] wrong number of output arguments.');
    end
end
