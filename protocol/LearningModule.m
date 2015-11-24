% LEARNINGMODULE is a protocol that all learning module should follow
% [Interfaces]
%   learn(obj, samole)
%   train(obj, dataset)
%   info(obj, [category])
%   H = status(obj)
%
% see also, DPModule, GPUModule, Stack, GenerativeModel
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015

% [Change Log]
% Nov 20, 2015 - initial commit

classdef LearningModule < hgsetget
    methods (Abstract)
        % ### sample ----> (learn) --update--> [obj]
        % LEARN involve module according to given data sample
        learn(obj, sample)
        % ### dataset ----> (train) --update--> [obj]
        % TRAIN involve module over a given dataset
        train(obj, dataset)
        % ### [obj] ----> (info) --update--> [console]
        % INFO should be able output all kinds of information to
        % console. 'category' is a string specifying the category
        % of information to output.
        info(obj, category)
        % ### [obj] ----> (status) --create--> [GUI]
        % STATUS generate a GUI for users to inspect the module
        H = status(obj)
    end
end
