% CombICA < GenerativeModel
%   COMBICA is the abstraction of combinational ICA model. This model have
%   two set of bases, one represents for amplitude and the other refering
%   phase information. The traversal combination between two sets of bases
%   act as a virtual complex base, which is similar to bases in ComplexICA.
%   Basically, combinational ICA model is a factorization of complex ICA
%   model. As ComplexICA, this class provides general functions that
%   support the operation of ICA learning process. Subclass only need to
%   add definition of probability description to get a complete functional
%   ICA learner.
%
% [METHOD INTERFACE]
%   update(obj, delta)
%   objval = evaluate(obj, sample, respond)
%   mgrad = modelGradient(obj, sample, respond)
%   rgrad = respondGradient(obj, sample, respond)
%
% [CONFIGURABLE PROPERTY]
%   base.amp    % amplitude bases set
%   base.phase  % phase bases set
%   nbase.amp   % quantity of amplitude bases
%   nbase.phase % quantity of phase bases
%
% [PROPERTY INTERFACE]
%   inferOption
%   adaptStep
%   etaTarget
%   stepUpFactor
%   stepDownFactor
%
% [NOTE]
%   Constructor of this class require two input parameters tp specify the number 
%   of amplitude and phase bases in the model.
%
% see also, DPModule, LearningModule, GPUModule, UtilityLib
%
% MooGu Z. <hzhu@case.edu>
% Jan 12, 2016
classdef CombICA < GenerativeModel
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function tof = ready(obj) % [OVERRIDE] @GenerativeModel
            tof = not(empty(obj.ampnorm)) && ready@GenerativeModel(obj);
        end
        
        function initBase(obj, frmdim)
            obj.ampnorm = 0.3 * frmdim;            
            % amplitude bases
            obj.base.amp = rand(frmdim, obj.nbase.amp);
            obj.base.amp = obj.toGPU(obj.ampnorm * ...
                bsxfun(@rdivide, obj.base.amp, sum(obj.base.amp)));
            % phase bases
            obj.base.phase = obj.toGPU(wrapToPi(pi * randn(frmdim, obj.nbase.phase)));
        end

        function respond = initRespond(obj, sample)
            [~, nframe] = size(sample.data);
            % respond : form part
            respond.data.form = randn(obj.nbase.amp, obj.nbase.phase, nframe);
            % respond : motion part
            respond.data.motion = randn(obj.nbase.amp, obj.nbase.phase, nframe);
            % respond : bias part
            respond.data.bias = randn(obj.nbase.amp, nframe);
        end
        % ------- Bookmark -------
        function respond = infer(obj, sample, respond)
            
        end

        function sample = generate(obj, respond)
            
        end

        function adapt(obj, sample, respond)
            
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
            
        end
        function obj = deactivateGPU(obj)
            
        end
        function copy = clone(obj)
            
        end
    end

    % ================= COMPONENT FUNCTION =================
    methods
        function [objval, grad] = objFunInfer(obj, respdata, sample)
            
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
            
        end

        function respdata = respdataDevectorize(obj, respdata)
            
        end
    end

    % ================= DATA STRUCTURE =================
    properties
        base  % [STRUCTURE] complex bases
        nbase % [STRUCTURE] number of base functions
        ampnorm % unified norm of amplitude base
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
        function obj = ComplexICA()

        end
    end
end
