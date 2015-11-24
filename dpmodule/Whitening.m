classdef Whitening < DPModule & GPUModule & UtilityLib
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sample.data = obj.encodeMatrix * sample.data;
            % attach noise factor to sample
            sample.noiseFactor = obj.noiseFactor;
        end

        function sample = invp(obj, sample)
            sample.data = obj.decodeMatrix * sample.data;
        end

        function sample = setup(obj, sample)
            % variance : variance of noise values accross all frames
            noiseVar = var(sample.data(:)) * obj.noiseRatio;
            % covariance matrix of all frames
            covMatrix = sample.data * sample.data';
            % principle components analysis
            [eigVec, eigVal] = eig(covMatrix);
            [eigVal, index]  = sort(diag(eigVal), 'descend');
            eigVec = eigVec(:, index);
            % calculate cutoff value of variance
            varCutoff = obj.cutoffRatio * noiseVar;
            % select eligible components
            iCutoff = sum(eigVal > varCutoff);
            eigVal = eigVal(1 : iCutoff);
            eigVec = eigVec(:, 1 : iCutoff);
            % compose encode/decode matrix
            obj.encodeMatrix = diag(1 ./ sqrt(eigVal)) * eigVec';
            obj.decodeMatrix = eigVec * diag(eigVal);
            % calculate scale factor of each component with a rolloff mask
            iRolloff = sum(eigVal > varCutoff * obj.rolloffFactor);
            obj.noiseFactor = ones(iCutoff, 1);
            obj.noiseFactor(iRolloff + 1 : end) = ...
                0.5 * (1 + cos( linspace(0, pi, iCutoff - iRolloff)));
            obj.noiseFactor = obj.noiseFactor / obj.noiseRatio;
            % enable GPU acceleration
            obj.activateGPU();
            % generate processed sample
            if nargout >= 1
                sample = obj.proc(sample);
            end
        end

        function tof = ready(obj)
            tof = ~(isempty(obj.encodeMatrix) || isempty(obj.decodeMatrix) ...
                || isempty(obj.noiseFactor));
        end

        function n = dimin(obj)
            assert(obj.ready());
            n = size(obj.decodeMatrix, 1);
        end

        function n = dimout(obj)
            assert(obj.ready());
            n = size(obj.encodeMatrix, 1);
        end
    end
    % ================= GPUMODULE IMPLEMENTATION =================
    methods
        function obj = activateGPU(obj)
            gpuVariable = {'encodeMatrix', 'decodeMatrix', 'noiseFactor'};
            for i = 1 : numel(gpuVariable)
                obj.(gpuVariable{i}) = obj.toGPU(obj.(gpuVariable{i}));
            end
        end
        function obj = deactivateGPU(obj)
            gpuVariable = {'encodeMatrix', 'decodeMatrix', 'noiseFactor'};
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
        encodeMatrix
        decodeMatrix
        noiseFactor
        % ------- SETTING -------
        noiseRatio    = 0.01;
        cutoffRatio   = 1.25;
        rolloffFactor = 8;
    end
    % ================= LANGUAGE UTILITY =================
    methods
        function obj = Whitening(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
