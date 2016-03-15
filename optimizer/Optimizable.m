classdef Optimizable < handle
% OPTMIZABLE is a module that enable sub-class's object be able to optimized
% by given method.

% MooGu Z. <hzhu@case.edu>
% Feb 19, 2016
    methods
        function optimize(obj)
            [grad, info] = Optimizable.vectorize(obj.wspace.opt.grads);
            
            grad = obj.optAlgo(grad);            
            
            if obj.opt.momentum
                obj.wspace.opt.v = obj.inertia * obj.wspace.opt.v + grad;
                grad = obj.wspace.opt.v;
            end
            
            grads = Optimizable.devectorize(grad, info);
            
            assert(numel(grads) == numel(obj.wspace.opt.updatefunc));
            for i = 1 : numel(grads)
                obj.wspace.opt.updatefunc{i}(grads{i});
            end
            
            obj.wspace.opt.grads = {};
            obj.wspace.opt.updatafunc = {};
            
            obj.wspace.opt.c = obj.wspace.opt.c + 1;
        end
        
        function addGradient(obj, grad, updatefunc)
            assert(nargin == 3);
            obj.wspace.opt.grads = [obj.wspace.opt.grads, {grad}];
            obj.wspace.opt.updatefunc = [obj.wspace.opt.updatefunc, {updatefunc}];
        end
    end
    
    methods (Static)
        function [vec, info] = vectorize(valueSet)
            info = cell(numel(valueSet), 1);
            
            vecdim = zeros(nargin, 1);
            for i = 1 : nargin
                info{i}   = size(valueSet{i});
                vecdim{i} = prod(info{i});
            end
            
            vec = zeros(sum(vecdim), 1);
            
            vecdim = [1, cumsum(vecdim)];
            
            for i = 1 : numel(info)
                vec(vecdim(i) : vecdim(i+1)) = valueSet{i}(:);
            end                
        end
        
        function valueSet = devectorize(vec, info)
            valueSet = cell(numel(info), 1);
            
            index = 1;
            for i = 1 : nargout
                n = prod(info{1});
                valueSet{i} = reshape(vec(index + 1 : index + n), info{i});
                index = index + n;
            end
        end
    end
    
    properties
        opt = struct( ...
            'method', 'undefined', ...
            'momentum', false, ...
            'initStepSize', 1e-3, ...
            'minStepRatio', 1e-2, ...
            'downStepCount', 1e5, ...
            'inertia', 0.9, ...
            'decayFstOrd', 0.9, ...
            'decaySndOrd', 0.999);
    end
    
    properties (Access = private)
        optAlgo = @nullfunc;
    end
    
    properties (Abstract)
        wspace
    end
    
    methods (Abstract)
        grad = gradient(obj, input)
        update(obj, delta)
    end
    
    properties (Dependent)
        minStepSize
        curStepSize
        optMethod
    end
    methods
        function value = get.minStepSize(obj)
            value = obj.opt.initStepSize * obj.opt.minStepRatio;
        end
        
        function value = get.curStepSize(obj)
            if n < obj.opt.downStepCount
                portion = n / obj.opt.downStepCount;
                value   = (1 - portion) * obj.opt.initStepSize + portion * obj.minStepSize;
            else
                value   = obj.minStepSize;
            end
        end
        
        function set.optMethod(obj, value)
            switch lower(value)
              case {'sgd', 'stochastic', 'gradientdecent'}
                obj.optAlgo      = @obj.SGD;
                obj.opt.momentum = false;
                
              case {'adagrad'}
                obj.optAlgo      = @obj.AdaGrad;
                obj.opt.momentum = false;
                
              case {'rmsprop'}
                obj.optAlgo      = @obj.RMSProp;
                obj.opt.momentum = true;
                
              case {'adam'}
                obj.optAlgo      = @obj.Adam;
                obj.opt.momentum = false;
                
              otherwise
                warning('[%s] Unknow optmization method', class(obj));
            end
        end
        
        function value = get.Momentum(obj)
            value = obj.opt.momentum;
        end
        function set.Momentum(obj, value)
            assert(islogical(value), '[MOMENTUM] TRUE or FALSE only');
            obj.opt.momentum = value;
        end            
    end
    
    methods
        function grad = SGD(obj, grad)
            grad = obj.curStepSize * grad;
        end
        
        function grad = AdaGrad(obj, grad)
            obj.wspace.opt.r = obj.wspace.opt.r + grad.^2;
            grad = (obj.curStepSize * grad ) ./ (1e-7 + sqrt(obj.wspace.opt.r));
        end
        
        function grad = RMSProp(obj, grad)
            obj.wspace.opt.r = obj.opt.decaySndOrd * obj.wspace.opt.r ...
                + (1 - obj.opt.decaySndOrd) * (grad.^2);
            grad = (obj.curStepSize * grad ) ./ sqrt(1e-6 + obj.wspace.opt.r);
        end
        
        function grad = Adam(obj, grad)
            obj.wspace.opt.s = obj.opt.decayFstOrd * obj.wspace.opt.s ...
                + (1 - obj.opt.decayFstOrd) * grad;
            obj.wspace.opt.r = obj.opt.decaySndOrd * obj.wspace.opt.r ...
                + (1 - obj.opt.decaySndOrd) * (grad.^2);
            unbiasS = obj.wspace.opt.s / (1 - obj.opt.decaySndOrd^obj.wspace.opt.c);
            unbiasR = obj.wspace.opt.r / (1 - obj.opt.decaySndOrd^obj.wspace.opt.c);
            grad = obj.curStepSize * unbiasS ./ (sqrt(unbiasR) + 1e-8);
        end
    end
    
    methods
        function obj = Optimizer(method)
            obj.wspace.opt.c = 0;       % iteration count
            obj.wspace.opt.v = 0;       % velocity in Momentum
            obj.wspace.opt.r = 0;       % gradient accumulation in AdaGrad
            obj.wspace.opt.s = 0;       % first order estimation in Adam
            
            obj.wspace.opt.grads = {};
            obj.wspace.opt.updatafunc = {};
            
            if exist('method', 'var')
                obj.optMethod = method;
            else
                obj.optMethod = 'sgd';
            end
        end
    end
end


