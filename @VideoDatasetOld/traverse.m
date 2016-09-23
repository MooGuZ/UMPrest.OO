% This function would modify current underlining status of the
% object. Normally, it would not effect your work. However, in
% special application, it maybe a trouble.
function sample = traverse(obj)
    obj.restateDataBlock();
    sample = obj.next(obj.volumn());
    obj.refreshDataBlock();
end
