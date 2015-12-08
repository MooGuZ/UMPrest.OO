% CALCSTAT accumulate statistic information from given data
function calcStat(obj, data)
    if isempty(obj.stat) % the first time get data
        obj.stat = struct( ...
            'frmcount', size(data, 2), ...
            'sum',      sum(data, 2), ...
            'seqsum',   sum(data.^2, 2), ...
            'covmat',   data * data');
    else % accumulate data
        obj.stat.sum      = obj.stat.sum + sum(data, 2);
        obj.stat.seqsum   = obj.stat.seqsum + sum(data.^2, 2);
        obj.stat.covmat   = obj.stat.covmat + data * data';
        obj.stat.frmcount = obj.stat.frmcount + size(data, 2);
    end
end
