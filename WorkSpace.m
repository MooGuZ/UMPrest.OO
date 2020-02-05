classdef WorkSpace < handle
    % Methods for Objects Construction and Save
    methods
        function obj = WorkSpace()
            obj.iteration = 0;
        end
    end
    methods (Abstract)
        d = dump(obj)
    end

    % Methods for Management
    methods (Abstract)
        obj = connectDataset(obj, dataset, varargin)
    end

    % Methods of Operation
    methods (Abstract)
        obj = train(obj, taskid, nepoch, nbatch, varargin)
        smp = sample(obj, n, varargin)
    end

    % Properties
    properties
        iteration        % Counter for Training Iterations
        core, prev, post % Essential Models
        dataset          % Dataset
    end
end
