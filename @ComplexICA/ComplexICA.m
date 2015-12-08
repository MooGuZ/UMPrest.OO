% ComplexICA < GenerativeModel
%   COMPLEXICA is the abstraction of ICA model with complex bases. This class
%   provides general functions that support the operation of ICA learning process.
%   Subclass should add definition of probability description to get a Completed
%   learning module.
%
% [METHOD INTERFACE]
%   update(obj, delta)
%   objval = evaluate(obj, sample, respond)
%   mgrad = modelGradient(obj, sample, respond)
%   rgrad = respondGradient(obj, sample, respond)
%
% [CONFIGURABLE PROPERTY]
%   base    % essential data Structure
%   nbase   % needed to be specified in construction
%
% [PROPERTY INTERFACE]
%   inferOption
%   adaptStep
%   etaTarget
%   stepUpFactor
%   stepDownFactor
%
% [NOTE]
%   Constructor of this class require a input parameter specify the number of
%   bases of this ICA model.
%
% see also, DPModule, LearningModule, GPUModule, UtilityLib
%
% MooGu Z. <hzhu@case.edu>
% Nov 21, 2015
%
% [Change Log]
% Nov 21, 2015 - initial commit
% Dec 08, 2015 :
%   1. update definition of 'setup'
%   2. redifine the output dimenstion to just one number, not an array
%   3. specify output sample's structure in initRespond
%   4. update 'infer' to enfore respond structure
%   5. update 'infer' to restrict number of samples proceed at once
classdef ComplexICA < GenerativeModel
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function initBase(obj, frmdim)
            baseSize = [frmdim, obj.nbase];
            % initialization
            tmp.real = randn(baseSize);
            tmp.imag = randn(baseSize);
            % normalize in column direction
            tmp.real = bsxfun(@rdivide, tmp.real, sqrt(sum(tmp.real.^2, 1)));
            tmp.imag = bsxfun(@rdivide, tmp.imag, sqrt(sum(tmp.imag.^2, 1)));
            % compose complex base
            obj.base = obj.toGPU(complex(tmp.real, tmp.imag));
        end

        function respond = initRespond(obj, sample)
            Z = .2 * complex(randn(obj.nbase, size(sample.data, 2)), ...
                randn(obj.nbase, size(sample.data, 2)));
            respond = struct( ...
                'data', struct('amplitude', obj.toGPU(abs(Z)), 'phase', obj.toGPU(angle(Z))), ...
                'ffindex', sample.ffindex);
        end

        function respond = infer(obj, sample, respond)
            if ~exist('respond', 'var')
                respond = obj.initRespond(sample);
            end
            % optimization by minFunc library
            nsample = numel(sample.ffindex);
            if nsample <= obj.maxSampleAtOnce
                respond.data = obj.respdataDevectorize(minFunc(@obj.objFunInfer, ...
                    obj.respdataVectorize(respond.data), obj.inferOption, sample));
            else
                tmpsmp  = sample;
                tmpdata = struct('amplitude', [], 'phase', []);
                for i = 1 : ceil(nsample / obj.maxSampleAtOnce)
                    head = (i - 1) * obj.maxSampleAtOnce + 1;
                    tail = min(i * obj.maxSampleAtOnce, nsample);
                    % get index of Frames
                    if tail < nsample
                        frmind = respond.ffindex(head) : respond.ffindex(tail + 1) - 1;
                    else
                        frmind = respond.ffindex(head) : size(respond.data, 2);
                    end
                    % compose temporal sample
                    tmpsmp.data = sample.data(:, frmind);
                    tmpsmp.ffindex = sample.ffindex(head : tail) - sample.ffindex(head) + 1;
                    % compose temporal respond
                    tmpdata.amplitude = respond.data.amplitude(:, frmind);
                    tmpdata.phase     = respond.data.phase(:, frmind);
                    % calculate responds
                    tmpdata = obj.respdataDevectorize(minFunc( ...
                        @obj.objFunInfer, obj.respdataVectorize(tmpdata), ...
                        obj.inferOption, tmpsmp));
                    respond.data.amplitude(:, frmind) = tmpdata.amplitude;
                    respond.data.phase(:, frmind)     = tmpdata.phase;
                end
            end
            % flip negative amplitude generated in optimization process
            mask = respond.data.amplitude < 0;
            respond.data.amplitude(mask) = - respond.data.amplitude(mask);
            respond.data.phase(mask) = wrapToPi(respond.data.phase(mask) + pi);
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
    % ================= GPUMODEL IMPLEMENTATION =================
    methods
        function obj = activateGPU(obj)
            obj.activateGPU@GenerativeModel();
            obj.base = obj.toGPU(obj.base);
        end
        function obj = deactivateGPU(obj)
            obj.deactivateGPU@GenerativeModel();
            obj.base = obj.toCPU(obj.base);
        end
        function copy = clone(obj)
            copy = feval(class(obj), obj.nbase);
            plist = properties(copy);
            for i = 1 : numel(plist)
                if isa(obj.(plist{i}), 'GPUModule')
                    copy.(plist{i}) = obj.(plist{i}).clone();
                else
                    copy.(plist{i}) = obj.(plist{i});
                end
            end
        end
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
                obj.adaptStep = obj.adaptStep * obj.stepDownFactor;
            else
                obj.adaptStep = obj.adaptStep * obj.stepUpFactor;
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
        maxSampleAtOnce = 100;
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
        function obj = ComplexICA(nbase)
            obj = obj@GenerativeModel();
            obj.nbase = nbase;
        end

        function consistencyCheck(obj)
            assert(numel(obj.nbase) == 1 && isnumeric(obj.nbase));
        end
    end
end
