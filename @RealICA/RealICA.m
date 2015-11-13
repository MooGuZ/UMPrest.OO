classdef RealICA < GenerativeModel
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function initBase(obj, dataset)
            baseSize = [obj.preproc.dimout(), obj.nbase];
            if isnan(baseSize(1))
                baseSize(1) = dataset.dimout();
            end
            % initialization
            obj.base = randn(baseSize);
            % normalize in column direction
            obj.base = bsxfun(@rdivide, obj.base, sqrt(sum(obj.base.^2, 1)));
        end

        function respond = initRespond(obj, sample)
            respond = sample;
            % randomly initialization
            respond.data = randn(obj.nbase, size(sample.data, 2));
        end

        function respond = infer(obj, sample, start)
            if ~exist('start', 'var'), start = obj.initRespond(sample); end
            % copy assistant information
            respond = sample;
            % optimization by minFunc library
            respond.data = respdataDevectorize(minFunc(@obj.objFunInfer, ...
                obj.respdataVectorize(start.data), obj.inferOption, sample));
        end

        function sample = generate(obj, respond)
            sample = respond; % copy information
            sample.data = obj.base * respond.data;
        end

        function adapt(obj, sample, respond)
            % calculate recover error
            recover = obj.generate(respond);
            sample.error = sample.data - recover.data;
            % calculate gradient of model
            mgrad = obj.modelGradient(sample, respond);
            % update model
            obj.update(-obj.calcAdaptStep(mgrad) * mgrad);
        end

        % ------- INTERFACE NEED TO BE IMPLEMENTED -------
        % update(obj, delta)
        % objval = evaluate(obj, sample, respond)
        % mgrad = modelGradient(obj, sample, respond)
        % rgrad = respondGradient(obj, sample, respond)
    end

    % ================= COMPONENT FUNCTION =================
    methods
        function [objval, grad] = objFunInfer(obj, respdata, sample)
            respond = sample;
            respond.data = obj.respdataDevectorize(respdata);
            if ~isfield(sample, 'error')
                recover = obj.generate(respond);
                sample.error = sample.data - recover.data;
            end
            objval = obj.evaluate(sample, respond).value;
            if nargout > 1
                grad = obj.respdataVectorize(obj.respondGradient(sample, respond));
            end
        end

        function step = calcAdaptStep(obj, grad)
            step = obj.adaptStep;
            if max(abs(grad(:))) * obj.adaptStep > obj.etaTarget
                obj.adaptStep = obj.adaptStep * obj.stepUpFactor;
            else
                obj.adaptStep = obj.adaptStep * obj.stepDownFactor;
            end
        end

        function respdata = respdataVectorize(~, respdata)
            respdata = respdata(:);
        end

        function respdata = respdataDevectorize(obj, respdata)
            respdata = reshape(respdata, obj.nbase, numel(respdata) / obj.nbase);
        end
    end

    % ================= DATA STRUCTURE =================
    properties
        base % [MATRIX] complex bases
        nbase % number of base functions
    end
    properties (Abstract)
        % ------- INFER -------
        inferOption
        % ------- ADAPT -------
        adaptStep
        etaTarget
        stepUpFactor
        stepDownFactor
    end
end
