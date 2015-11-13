% LEARNER is a protocol that all learning module should follow
classdef LearningModule < hgsetget
    methods (Abstract)
        % LEARN involve module by given data sample
        % ### sample ----> (learn) --update--> [obj]
        learn(obj, sample)
        
        % TRAIN train module over a given dataset
        % ### dataset ----> (train) --update--> [obj]
        train(obj, dataset)
        
        % INFO should fundamental information, such as configurations
        % ### [obj] ----> (info) --update--> [console]
        info(obj)
        
        % STATUS shows the status of learning object
        % ### [obj] ----> (status) --create--> [GUI]
        status(obj)
    end
end
