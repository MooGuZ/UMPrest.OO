classdef DPStack < Stack & DPModule & LibUtility
    % ================= STACK IMPLEMENTATION =================
    methods
        function push(obj, DPUnit)
            assert(obj.isqualified(DPUnit), ...
                'unit push into stack should be a DPModule, however, not LearningModule');
            obj.stack{end + 1} = DPUnit;
        end

        function DPUnit = pop(obj)
            DPUnit = obj.stack{end};
            obj.stack = obj.stack(1 : end - 1);
        end

        function n = size(obj)
            n = numel(obj.stack);
        end
    end
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            for i = 1 : numel(obj.stack)
                sample = obj.stack{i}.proc(sample);
            end
        end

        function sample = invp(obj, sample)
            for i = 1 : numel(obj.stack)
                sample = obj.stack{i}.invp(sample);
            end
        end

        function setup(obj, dataset)
            assert(isa(dataset, 'Dataset'));
            % each module in the stack only setup once
            if isempty(obj.stack) || obj.ready()
                return
            end
            % setup level by level
            sample = dataset.next(dataset.volumn() * obj.setupSampleRatio);
            for i = 1 : numel(obj.stack)
                if ~obj.stack{i}.ready()
                    obj.stack{i}.setup(sample);
                end
                % generate data for next level
                if i ~= numel(obj.stack)
                    sample = obj.stack{i}.proc(sample);
                end
            end
        end

        function tof = ready(obj)
            tof = true;
            for i = 1 : numel(obj.stack)
                if ~obj.stack{i}.ready()
                    tof = false;
                    return
                end
            end
        end

        function n = dimin(obj)
            if isempty(obj.stack)
                n = nan;
            else
                n = obj.stack{1}.dimin();
            end
        end

        function n = dimout(obj)
            if isempty(obj.stack)
                n = nan;
            else
                n = obj.stack{end}.dimout();
            end
        end
    end
    % ================= COMPONENT FUNCTION =================
    methods (Access = protected)
        function tof = isqualified(~, unit)
            tof = isa(unit, 'DPModule') ;
        end
    end
    % ================= DATA STRUCTURE =================
    properties
        setupSampleRatio = 0.3;
    end
    properties (Hidden, SetAccess = private)
        stack = cell(0);
    end
    % ================= LANGUAGE UTILITY =================
    methods
        function obj = DPStack(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
