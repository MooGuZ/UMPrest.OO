classdef COMotionLearner < RealICA
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function update(obj, delta)
            obj.base = obj.base + delta;
        end

        function objval = evaluate(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            objval.noise  = obj.noise(sample.error);
            objval.sparse = obj.sparse(respond.data);
            objval.stable = obj.stable(respond.data);
            objval.value  = objval.noise + objval.sparse + objval.stable;
        end

        function grad = modelGradient(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            grad = - obj.dnoise(sample.error) * sample.data';
        end

        function grad = respondGradient(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            grad = - obj.base' * obj.dnoise(sample.error) ...
                + obj.dsparse(respond.data) ...
                + obj.dstable(respond.data);
        end
    end

    % ================= PROBABILITY DESCRIPTION =================
    methods (Access = private)
        function prob = noise(obj, data)
            prob = obj.nlGauss(data, obj.sigmaNoise) / size(data, 2);
        end
        function grad = dnoise(obj, data)
            grad = obj.dNLGauss(obj, data) / size(data, 2);
        end

        function prob = sparse(obj, data)
            prob = obj.betaSparse * obj.nlCauchy(data, obj.sigmaSparse) / size(data, 2);
        end
        function grad = dsparse(obj, data)
            grad = obj.betaSparse * obj.dNLCauchy(data, obj.sigmaSparse) / size(data, 2);
        end

        function prob = stable(obj, data)
            prob = obj.nlGauss(diff(data, 1, 2), obj.sigmaStable) / size(data, 2);
        end
        function grad = dstable(obj, data)
            grad = - obj.dNLGauss( ...
                diff(padarray(data, [0,1], 'replicate', 'both'), 2, 2), ...
                obj.sigmaStable) / size(data, 2);
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
        sigmaNoise  = 0.5;
        sigmaSparse = sqrt(0.5);
        betaSparse  = 0.5;
        sigmaStable = sqrt(0.2);
    end

    % ================= LANGUAGE UTILITY =================
    methods
        function obj = COMotionLearner(nbase, varargin)
            obj.nbase = nbase;
            obj.setupByArg(varargin{:});
            obj.preproc.setupByArg(varargin{:});
            obj.preproc.push(MotionSeparation());
            obj.consistencyCheck();
        end

        function consistencyCheck(obj)
            obj.consistencyCheck@RealICA();
        end
    end
end
