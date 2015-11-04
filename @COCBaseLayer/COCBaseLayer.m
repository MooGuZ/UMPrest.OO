% CLASS : COModel
%
% Class derived from base class MotionLearner that implementing Cadieu &
% Olshausen's model in their 2012 paper. This program just implemented the
% first layer of this two layers model. The first layer is a generative
% model bases on complex bases.
%
% MooGu Z. <hzhu@case.edn>
%
% Oct 20, 2015 - Initial commit

classdef COCBaseLayer < GenerativeModel
    properties
        % bases
        A
        nbase

        % parameters of priors
        betaRespondSparse = 10;
        sigmaRespondSparse = 0.4;
        sigmaRespondSlow = 0.5;

        % current dataset
        dataset

        % setting
        naturalGradient = false;
    end

    properties (Access = private)
        cauchy  = @(x, beta, sigma) beta * sum(log(1 + (x(:) / sigma).^2));
        gauss   = @(x, sigma) 0.5 * sigma * sum(x(:).^2);
        dcauchy = @(x, beta, sigma) 2 * beta * (1 ./ (1 + (x / sigma).^2)) .* (x / sigma^2);
        dgauss  = @(x, sigma) sigma * x;
    end

    methods
        % constructor
        function obj = COCBaseLayer(savePath, nbase, varargin)
            obj = obj@GenerativeModel(savePath);
            % set number of base
            obj.nbase = nbase;
            % default value of structure fields
            obj.adaptOption.etaTarget = 0.05;
            obj.adaptOption.stepUpFactor = 1.02;
            obj.adaptOption.stepDownFactor = 0.95;
            % apply custom settings
            obj.paramSetup(varargin);
        end

        % COModel use stochastic optimization method
        % @@@
        % add more funcitonalities :
        % 1. base initialization when necessary, and make quantities become
        % dependent members.
        function learn(obj, dataset)
            obj.dataset = dataset;
            if isempty(obj.A)
                obj.initialBase();
            end
            assert(dataset.dimout == size(obj.A,1), ...
                'dimension of dataset does not match initialized model');
            obj.stochasticLearn(dataset);
        end

        function initialBase(obj)
            % assistant variable
            nrow = obj.dataset.dimout;
            ncol = obj.nbase;
            % assistant function
            colnorm = @(x) sqrt(sum(x.^2));
            % initialization
            obj.A = complex(randn(nrow, ncol), randn(nrow, ncol));
            % normalize in column direction
            obj.A = complex( ...
                real(obj.A) * diag(1 ./ colnorm(real(obj.A))), ...
                imag(obj.A) * diag(1 ./ colnorm(imag(obj.A))));
        end

        function respond = initialRespond(obj, data)
            nDataFrame = size(data, 2);
            % randomly initialization
            Z = .2 * complex(randn(obj.nbase, nDataFrame), randn(obj.nbase, nDataFrame));
            respond.amplitude = abs(Z);
            respond.phase = angle(Z);

            respond = obj.respondVectorize(respond);
        end

        function data = generate(obj, respond)
            respond = obj.respondDevectorize(respond);

            data = real(obj.A) * (respond.amplitude .* cos(respond.phase)) ...
                + imag(obj.A) * (respond.amplitude .* sin(respond.phase));
        end

        function objval = evaluate(obj, respond, data, ~, err)
            if ~exist('err', 'var')
                err = data - obj.generate(respond);
            end

            respond = obj.respondDevectorize(respond);

            mse    = obj.gauss(bsxfun(@times, err, sqrt(obj.dataset.whiteningNoiseFactor)), 1);
            sparse = obj.cauchy(respond.amplitude, obj.betaRespondSparse, obj.sigmaRespondSparse);
            slow   = obj.gauss(diff(respond.amplitude, 1, 2), obj.sigmaRespondSlow);

            objval = mse + sparse + slow;
        end

        function mgrad = modelGradient(obj, respond, ~, err)
            % weight each component according to whitening process and
            % compensate the effect of frame quantity of training samples
            respond = obj.respondDevectorize(respond);
            tmp = bsxfun(@times, -obj.dataset.whiteningNoiseFactor / size(err, 2), err);
            mgrad = complex(tmp * (respond.amplitude .* cos(respond.phase))', ...
                tmp * (respond.amplitude .* sin(respond.phase))');
        end

        function rgrad = respondGradient(obj, respond, ~, err)
            % devectorization
            respond = obj.respondDevectorize(respond);
            % weight error according to component power in whitening
            err = bsxfun(@times, -obj.dataset.whiteningNoiseFactor, err);
            % gradient of amplitude part
            rgrad.amplitude = (real(obj.A)' * err) .* cos(respond.phase) ...
                + (imag(obj.A)' * err) .* sin(respond.phase) ...
                + obj.dcauchy(respond.amplitude, obj.betaRespondSparse, obj.sigmaRespondSparse) ...
                - obj.dgauss(diff(padarray(respond.amplitude, [0,1], 'replicate', 'both'), 2, 2), obj.sigmaRespondSlow);
            % fake gradient of phase part (remove amplitude multiplication)
            rgrad.phase = (imag(obj.A)' * err) .* cos(respond.phase) ...
                - (real(obj.A)' * err) .* sin(respond.phase);
            if ~obj.naturalGradient
                rgrad.phase = respond.amplitude .* rgrad.phase;
            end
            % vectorization and compensate the effact of frame quantity of training samples
            rgrad = obj.respondVectorize(rgrad);
        end

        function modelModify(obj, modelDelta)
            obj.A = obj.A + modelDelta;
            % utilize GS orthogonalization
            obj.A = complex(real(obj.A), imag(obj.A) - real(obj.A) ...
                * diag(sum(real(obj.A) .* imag(obj.A)) ./ sum(real(obj.A).^2)));
            % flip real and imaginary part
            obj.A = complex(imag(obj.A), real(obj.A));
            % renormalize length of bases (separate real and image part)
            obj.A = complex( ...
                bsxfun(@rdivide, real(obj.A), sqrt(sum(real(obj.A).^2))), ...
                bsxfun(@rdivide, imag(obj.A), sqrt(sum(imag(obj.A).^2))));
        end

        function adjustAdaptStep(obj, mgrad, ~)
            if max(abs(mgrad(:))) * obj.adaptOption.step > obj.adaptOption.etaTarget
                obj.adaptOption.step = obj.adaptOption.stepDownFactor * obj.adaptOption.step;
            else
                obj.adaptOption.step = obj.adaptOption.stepUpFactor * obj.adaptOption.step;
            end
        end

        function showinfo(obj)
            disp('Sorry, nothing to show at this time.');
        end
    end

    methods (Access = private)
        function respond = respondVectorize(~, respond)
            assert(all(size(respond.amplitude) == size(respond.phase)), ...
                'COMODEL : size of responds does not match (amplitude and phase)');
            respond = [respond.amplitude(:); respond.phase(:)];
        end

        function respond = respondDevectorize(obj, respond)
            assert(mod(numel(respond), 2 * obj.nbase) == 0, ...
                'COMODEL : size of responds is wrong');
            nframe = numel(respond) / (2 * obj.nbase);
            tmp.amplitude = reshape(respond(1 : obj.nbase * nframe), obj.nbase, nframe);
            tmp.phase = wrapToPi(reshape(respond(obj.nbase * nframe + 1 : end), obj.nbase, nframe));
            respond = tmp;
        end
    end

end
