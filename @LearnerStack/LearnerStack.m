% LearnerStack < DPStack & LearningModule
%   This class add learning capability to a data processing stack. It
%   is a good abstraction of heirarchy learning module. For instance,
%   heirarchy generative model.
%
% [NOTE]
%   This class does not add any new components, just implemented all
%   required interfaces.
%
% see also, DPStack, LearningModule
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
% Dec 08, 2015 - override definition of 'setup'
classdef LearnerStack < DPStack & LearningModule & AutoSave
    % ================= STACK IMPLEMENTATION =================
    methods (Access = protected)
        function tof = isqualified(~, unit) % [OVERRIDE] DPStack
            tof = isa(unit, 'DPModule') && isa(unit, 'LearningModule');
        end
    end
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        % this implementation of SETUP function is very inefficient, especially
        % when setup multiple levels. In some cases, utilize in-memory dataset
        % would be a better option.
        function setup(obj, dataset) % [OVERRIDE] DPStack
            for i = 1 : numel(obj.stack)
                if not(obj.stack{i}.ready())
                    obj.stack{i}.setup(VirtualDataset(dataset, obj.stack(1 : i-1)));
                end
            end
        end
    end
    % ================= LEARNINGMODULE IMPLEMENTATION =================
    methods
        function learn(obj, sample)
            for i = 1 : numel(obj.stack)
                obj.stack{i}.learn(sample);
                sample = obj.stack{i}.proc(sample);
            end
        end

        function train(obj, dataset, ilevel)
            if exist('ilevel', 'var')
                if ilevel == 1
                    obj.stack{1}.train(dataset);
                else
                    obj.stack{ilevel}.train( ...
                        VirtualDataset(dataset, obj.stack(1 : ilevel-1)));
                end
            else
                % train model by given dataset
                switch lower(obj.trainingMethod)
                case {'minibatch', 'stochastic'}
                    obj.miniBatch(dataset);
                case {'levelbylevel', 'lbl'}
                    obj.lbl(dataset);
                otherwise
                    error('unrecognized training method : %s', obj.trainingMethod);
                end
            end
            obj.autosave(true);
        end

        info(obj)

        status(obj)
    end
    % ================= LEARNING METHOD =================
    methods (Access = protected)
        % learn through mini-batch to adapt model sample by sample
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
                    if obj.autosave(obj.count)
                        obj.info();
                    end
                end
            end
            obj.autosave(true);
            obj.info();
        end
        % learn stack level by level
        function lbl(obj, dataset)
            for i = 1 : numel(obj.stack)
                obj.stack{i}.train(VirtualDataset(dataset, obj.stack(1 : i-1)));
            end
        end
    end
end
