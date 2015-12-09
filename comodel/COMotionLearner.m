% CHANGE Log
% Dec 08, 2015 - added support to multiple video in a sample
classdef COMotionLearner < RealICA & MathLib & UtilityLib
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function respond = initRespond(obj, sample) % [OVERRIDE] RealICA
            respond = struct( ...
                'data', obj.toGPU(randn(obj.nbase, size(sample.data, 2))), ...
                'ffindex', sample.ffindex, ...
                'fframe', sample.fframe);
        end

        function update(obj, delta)
            obj.base = obj.base + delta;
        end

        function objval = evaluate(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            objval.noise  = obj.noise(sample.error);
            objval.sparse = obj.sparse(respond.data);
            objval.stable = obj.stable(respond.data, sample.ffindex);
            objval.value  = objval.noise + objval.sparse + objval.stable;
        end

        function grad = modelGradient(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            grad = - obj.dnoise(sample.error) * respond.data';
        end

        function grad = respondGradient(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            grad = - obj.base' * obj.dnoise(sample.error) ...
                + obj.dsparse(respond.data) ...
                + obj.dstable(respond.data, sample.ffindex);
        end
    end

    % ================= PROBABILITY DESCRIPTION =================
    methods (Access = private)
        function prob = noise(obj, data)
            switch lower(obj.priorNoise)
            case {'vonmise'}
                prob = sum(obj.nlVonMise(data(:), obj.sigmaNoise)) / size(data, 2);
            case {'gauss', 'gaussian'}
                prob = sum(obj.nlGauss(data(:), obj.sigmaNoise)) / size(data, 2);
            end
        end
        function grad = dnoise(obj, data)
            switch lower(obj.priorNoise)
            case {'vonmise'}
                grad = obj.dNLVonMise(data, obj.sigmaNoise) / size(data, 2);
            case {'gauss', 'gaussian'}
                grad = obj.dNLGauss(data, obj.sigmaNoise) / size(data, 2);
            end
        end

        function prob = sparse(obj, data)
            prob = obj.betaSparse * sum(obj.nlCauchy(data(:), obj.sigmaSparse)) / size(data, 2);
        end
        function grad = dsparse(obj, data)
            grad = obj.betaSparse * obj.dNLCauchy(data, obj.sigmaSparse) / size(data, 2);
        end

        function prob = stable(obj, data, ffindex)
            prob = obj.nlGauss(segdiff(data, ffindex, 2), obj.sigmaStable);
            prob = sum(prob(:)) / size(data, 2);
        end
        function grad = dstable(obj, data, ffindex)
            grad = diff(data, 1, 2);
            grad(:, ffindex(2 : end) - 1) = 0;
            grad = -diff(padarray(grad, [0,1]), 1, 2);
            grad = - obj.dNLGauss(grad, obj.sigmaStable) / size(data, 2);
        end
    end
    % ================= SUPPORT FUNCTION =================
    methods (Access = private)
        function error = calcError(obj, sample, respond)
            error = sample.mask .* (sample.data - obj.generate(respond).data);
        end
    end

    % ================= DATA STRUCTURE =================
    properties
        % ------- INFER -------
        inferOption = struct( ...
            'Method', 'csd', ...
            'Display', 'off', ...
            'MaxIter', 17, ...
            'MaxFunEvals', 23);
        % ------- ADAPT -------
        adaptStep      = 1e-2;
        etaTarget      = 0.03;
        stepUpFactor   = 1.02;
        stepDownFactor = 0.95;
        % ------- PROBABILITY -------
        priorNoise  = 'vonMise';
        sigmaNoise  = 0.5;
        sigmaSparse = sqrt(0.5);
        betaSparse  = 0.5;
        sigmaStable = sqrt(0.2);
    end

    % ================= LANGUAGE UTILITY =================
    methods
        function obj = COMotionLearner(nbase, varargin)
            obj = obj@RealICA(nbase);
            obj.setupByArg(varargin{:});
            obj.preproc.push(MotionSeparation(varargin{:}));
        end
    end
end
