% SEGDIFF returns difference of given data grouped in specified dimension
% by specified index of first frame of each group. This function only works
% in first order difference.
function [d, ffindex] = segdiff(data, ffindex, dim)
    if not(exist('dim', 'var'))
        dim = find(size(data) ~= 1, 1);
    end

    d = diff(data, 1, dim);
    if numel(ffindex) == 1 % shortcut
        return
    else % normal procedure
        dataSize = size(data);
        rangeArray = cell(1, numel(size(data)));
        for i = 1 : numel(rangeArray)
            if i == dim
                rangeArray{i} = true(1, dataSize(i) - 1);
                rangeArray{i}(ffindex(2:end) - 1) = false;
            else
                rangeArray{i} = true(1, dataSize(i));
            end
        end
        d = d(rangeArray{:});
        ffindex = ffindex - (0 : numel(ffindex) - 1);
    end
end
