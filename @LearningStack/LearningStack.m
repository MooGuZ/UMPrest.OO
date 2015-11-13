classdef LearningStack < Stack & DPModule & LearningModule
    % interfaces inherent from super classes (protocols)
    methods
        n = size(obj)
        n = push(obj, unit)
        unit = pop(obj)

        data = proc(obj, data)
        data = invp(obj, data)

        learn(obj, dataset)
        info(obj)
        status(obj)
    end
end
