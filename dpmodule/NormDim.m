% NORMDIM rescale data to let variance of each dimension to be 1
classdef NormDim < DPModule & GPUModule & UtilityLib
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sample.data = bsxfun(@rdivide, sample.data, obj.stdVector);
        end

        function sample = invp(obj, sample)
            sample.data = bsxfun(@times, sample.data, obj.stdVector);
        end

        function sample = setup(obj, sample)
            assert(numel(size(sample.data)) == 2);
            obj.stdVector = obj.toGPU(std(sample.data, 0, 2));
            if nargout >= 1
                sample = obj.proc(sample);
            end
        end

        function tof = ready(obj)
            tof = not(isempty(obj.stdVector));
        end

        function n = dimin(obj)
            assert(obj.ready());
            n = numel(obj.stdVector);
        end

        function n = dimout(obj)
            n = obj.dimin();
        end
        
    end
    % ================= GPUMODULE IMPLEMENTATION =================
    methods
        function obj = activateGPU(obj)
            gpuVariable = {'stdVector'};
            for i = 1 : numel(gpuVariable)
                obj.(gpuVariable{i}) = obj.toGPU(obj.(gpuVariable{i}));
            end
        end
        function obj = deactivateGPU(obj)
            gpuVariable = {'stdVector'};
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
        stdVector
    end

    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function obj = NormDim(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
