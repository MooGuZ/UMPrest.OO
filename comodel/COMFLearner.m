classdef COMFLearner < LearnerGroup
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function n = dimin(obj)
            n = obj.group{1}.dimin();
        end

        function n = dimout(obj)
            n = sum(cellfun(@dimout, obj.group));
        end
    end
    % ================= LEARNERGROUP IMPLEMENTATION =================
    methods
        function sample = composeInSample(~, sampleArray)
            sample.data.phase     = sampleArray{1}.data;
            sample.data.amplitude = sampleArray{2}.data;
            sample.ffindex        = sampleArray{2}.ffindex;
        end
        function sample = composeOutSample(~, sampleArray)
            sample.data.mcode = sampleArray{1}.data;
            sample.data.fcode = sampleArray{2}.data;
            sample.ffindex.mcode = sampleArray{1}.ffindex;
            sample.ffindex.fcode = sampleArray{2}.ffindex;
            sample.fframe = sampleArray{1}.fframe;
        end
    end
    properties
        group
    end
    % ================= UTILITY =================
    methods
        function obj = COMFLearner(mLearner, fLearner)
            assert(isa(mLearner, 'COMotionLearner'));
            assert(isa(fLearner, 'COFormLearner'));
            obj.group = {mLearner, fLearner};
        end
    end
end
