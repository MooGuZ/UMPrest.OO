classdef Recenter < DPModule & GPUModule & UtilityLib
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sample.data = bsxfun(@minus, sample.data, obj.biasVector);
        end

        function sample = invp(obj, sample)
            sample.data = bsxfun(@plus, sample.data, obj.biasVector);
        end

        function setup(obj, sample)
            assert(numel(size(sample.data)) == 2);
            obj.biasVector = obj.toGPU(mean(sample.data, 2));
        end

        function tof = ready(obj)
            tof = ~isempty(obj.biasVector);
        end

        function n = dimin(obj)
            assert(obj.ready());
            n = numel(obj.biasVector);
        end

        function n = dimout(obj)
            n = obj.dimin();
        end
    end
    % ================= GPUMODULE IMPLEMENTATION =================
    methods
        function obj = activateGPU(obj)
            gpuVariable = {'biasVector'};
            for i = 1 : numel(gpuVariable)
                obj.(gpuVariable{i}) = obj.toGPU(obj.(gpuVariable{i}));
            end
        end
        function obj = deactivateGPU(obj)
            gpuVariable = {'biasVector'};
            for i = 1 : numel(gpuVariable)
                obj.(gpuVariable{i}) = obj.toCPU(obj.(gpuVariable{i}));
            end
        end
        function copy = clone(obj)
            copy = feval(class(obj));
            plist = properties(obj);
            for i = 1 : numel(plist)
                copy.(plist{i}) = obj.(plist{i});
            end
        end
    end
    % ================= DATA STRUCTURE =================
    properties
        biasVector
    end

    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function obj = Recenter(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
