classdef Objective < handle
    methods
        value = evaluate(obj, datapkg)
        d = delta(obj, datapkg)
    end
end
