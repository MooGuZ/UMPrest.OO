classdef DataBlock < handle
    methods (Abstract)
        [dcell, lcell] = fetch(obj, n)
        [data, label]  = recent(obj)
        reset(obj)
        volumn(obj)
    end
end
