% RealICA < GenerativeModel
%   RealICA is a ICA learning model bases on real bases. It is actually a implementation
%   of abstract class GenreativeModel, while also leaves several interfaces for subclass
%   to implement. However, these interfaces directly relate to probability description of
%   a model, which is the only varying part in theory. Therefore, this class provides
%   developer a shortcut to implement different ICA model with real bases. (And, this is
%   an abstract class)
%
% [INTERFACE]
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
% see also, GenerativeModel, ComplexICA.
%
% MooGu Z. <hzhu@case.edu>
% Sept 30, 2015
%
% [Change Log]
% Sept 30, 2015 - initial commit
classdef RealICA < GenerativeModel
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function initBase(obj, sample)
            baseSize = [size(sample.data, 1), obj.nbase];
            % initialization
            obj.base = randn(baseSize);
            % normalize in column direction
            obj.base = obj.toGPU(bsxfun(@rdivide, obj.base, sqrt(sum(obj.base.^2, 1))));
        end

        function respond = initRespond(obj, sample)
            respond = sample;
            % randomly initialization
            respond.data = obj.toGPU(randn(obj.nbase, size(sample.data, 2)));
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

    % ================= DATA STRUCTURE =================
    methods
        function obj = RealICA(nbase)
            obj = obj@GenerativeModel();
            obj.nbase = nbase;
        end
    end
end
