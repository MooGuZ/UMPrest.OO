% Help information
classdef ComplexICA < GenerativeModel
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function initBase(obj, dataset)
            baseSize = [obj.preproc.dimout(), obj.nbase];
            if isnan(baseSize(1))
                baseSize(1) = dataset.dimout();
            end
            % initialization
            tmp.real = randn(baseSize);
            tmp.imag = randn(baseSize);
            % normalize in column direction
            tmp.real = bsxfun(@rdivide, tmp.real, sqrt(sum(tmp.real.^2, 1)));
            tmp.imag = bsxfun(@rdivide, tmp.imag, sqrt(sum(tmp.imag.^2, 1)));
            % compose complex base
            obj.base = complex(tmp.real, tmp.imag);
        end

        function respond = initRespond(obj, sample)
            % copy assistant information 
            respond = sample;
            % randomly initialization
            Z = .2 * complex(randn(obj.nbase, size(sample.data, 2)), ...
                randn(obj.nbase, size(sample.data, 2)));
            respond.data.amplitude = abs(Z);
            respond.data.phase = angle(Z);
        end

        function respond = infer(obj, sample, start)
            if ~exist('start', 'var'), start = obj.initRespond(sample); end
            % copy assistant information
            respond = sample;
            % optimization by minFunc library
            respond.data = obj.respdataDevectorize(minFunc(@obj.objFunInfer, ...
                obj.respdataVectorize(start.data), obj.inferOption, sample));
        end

        function sample = generate(obj, respond)
            sample = respond; % copy information
            sample.data = real(obj.base) * (respond.data.amplitude .* cos(respond.data.phase)) ...
                + imag(obj.base) * (respond.data.amplitude .* sin(respond.data.phase));
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
            assert(all(size(respdata.amplitude) == size(respdata.phase)), ...
                'COMODEL : size of responds does not match (amplitude and phase)');
            respdata = [respdata.amplitude(:); respdata.phase(:)];
        end

        function respdata = respdataDevectorize(obj, respdata)
            assert(mod(numel(respdata), 2 * obj.nbase) == 0, ...
                'COMODEL : size of responds is wrong');
            nframe = numel(respdata) / (2 * obj.nbase);
            tmp.amplitude = reshape(respdata(1 : obj.nbase * nframe), obj.nbase, nframe);
            tmp.phase = wrapToPi(reshape(respdata(obj.nbase * nframe + 1 : end), obj.nbase, nframe));
            respdata = tmp;
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
    
    % ================= UTILITY =================
    methods
        function consistencyCheck(obj)
            obj.consistencyCheck@GenerativeModel();
            assert(numel(obj.nbase) == 1 && isnumeric(obj.nbase));
        end
    end
end
