classdef LearnerGroup < DPModule & LearningModule & LibExperiment
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        % PROC process data according to specified purpose
        % ### dataIn ----> (proc) ----> dataOut
        function sample = proc(obj, sample)
            sampleArray = cell(1, obj.size());
            for i = 1 : obj.size()
                sampleArray{i} = obj.group{i}.proc(sample);
            end
            sample = obj.composeOutSample(sampleArray);
        end
        % INVP apply inverse process to reconstruct data
        % ### dataOut ----> (invp) ----> dataIn
        function sample = invp(obj, sample)
            sampleArray = cell(1, obj.size());
            for i = 1 : obj.size()
                sampleArray{i} = obj.group{i}.invp(sample);
            end
            sample = obj.composeInSample(sampleArray);
        end
        % SETUP initialize data processing module according
        % to given data. This operation is useful to those
        % operations who need statistic information
        function setup(obj, dataset)
            assert(isa(dataset, 'Dataset'));
            % each module in the group only setup once
            if isempty(obj.group) || obj.ready()
                return
            end
            % setup unit by unit
            sample = dataset.next(dataset.volumn() * obj.setupSampleRatio);
            for i = 1 : numel(obj.group)
                if ~obj.group{i}.ready()
                    obj.group{i}.setup(sample);
                end
            end
        end
        % READY returns the status of data processing module
        % that whether or not it is ready for operating
        function tof = ready(obj)
            tof = true;
            for i = 1 : numel(obj.group)
                if not(obj.group{i}.ready())
                    tof = false;
                    return
                end
            end
        end
        % DIMIN returns the dimensionality of input data (frame)
        % NaN means it adapted to all size
        function n = dimin(obj)
            n = sum(cellfun(@dimin, obj.group));
        end
        % DIMOUT returns the dimensionality of output data (frame)
        % NaN means it is varying according to the input size
        function n = dimout(obj)
            n = sum(cellfun(@dimout, obj.group));
        end
    end
    % ================= LEARNINGMODULE IMPLEMENTATION =================
    methods
        % LEARN involve module by given data sample
        % ### sample ----> (learn) --update--> [obj]
        function learn(obj, sample)
            for i = 1 : numel(obj.group)
                obj.group{i}.learn(sample);
            end
        end
        
        % TRAIN train module over a given dataset
        % ### dataset ----> (train) --update--> [obj]
        function train(obj, dataset)
            % ensure necessary paramter have been setup
            if ~obj.ready(), obj.setup(dataset); end
            % train model by given dataset
            switch lower(obj.trainingMethod)
                case {'minibatch', 'stochastic'}
                    obj.miniBatch(dataset);
                otherwise
                    error('unrecognized training method : %s', obj.trainingMethod);
            end
        end
        
        % INFO should fundamental information, such as configurations
        % ### [obj] ----> (info) --update--> [console]
        function info(obj)
            for i = 1 : numel(obj.group)
                obj.group{i}.info();
            end
        end
        
        % STATUS shows the status of learning object
        % ### [obj] ----> (status) --create--> [GUI]
        status(obj)
    end
    % ================= OTHER API =================
    methods
        function n = size(obj)
            n = numel(obj.group);
        end
    end
    
    % ================= SUPPORT FUNCTION =================
    methods (Access = protected)
        function tof = isqualified(~, unit)
            tof = isa(unit, 'DPModule') && isa(unit, 'LearningModule');
        end
        
        function miniBatch(obj, dataset)
            for i = 1 : obj.traversePerTrain
                while not(dataset.istraversed())
                    % fetch data sample from dataset
                    sample = dataset.next(obj.samplePerBatch);
                    % involve model by learn sample
                    obj.learn(sample);
                    % count iteration
                    obj.count = obj.count + obj.samplePerBatch;
                    % show information and save current status
                    if obj.autosave(obj.count), obj.info(); end
                end
            end
            obj.autosave(true);
            obj.info();
        end
    end
    
    % ================= INTERFACE FOR SUBCLASS =================
    methods (Abstract)
        % COMPOSEINSAMPLE compose input sample from an array of samples
        sample = composeInSample(obj, sampleArray)
        % COMPOSEOUTSAMPLE compose output sample from an array of samples
        sample = composeOutSample(obj, sampleArray)
    end
    
    % ================= DATA STRUCTURE =================
    properties
        setupSampleRatio = 0.3;
    end
    properties (Abstract)
        group
    end
    
    % ================= UTILITY =================
    methods
        function consistencyCheck(obj)
            for i = 1 : numel(obj.group)
                assert(obj.isqualified(obj.group{i}));
            end
        end
    end
end
