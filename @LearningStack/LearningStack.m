classdef LearningStack < Stack & DPModule & LearningModule
    % interfaces inherent from super classes (protocols)
    methods
        n = size(obj)
        n = push(obj, unit)
        unit = pop(obj)

        sample = proc(obj, sample)
        sample = invp(obj, sample)

        learn(obj, dataset)
        info(obj)
        status(obj)
    end
end
