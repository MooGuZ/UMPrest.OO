classdef SGD < handle
    % SGD implement stochastic gradient decent methods over LModels.
    
    % MooGu Z. <hzhu@case.edu>
    % Feb 19, 2016
    methods
        function grad = optimize(obj, grad)
            obj.wspace.opt.c = obj.wspace.opt.c + 1;
            
            grad = obj.adjustGrad(grad);
            
            if obj.momentum
                grad = grad + obj.inertia * obj.wspace.opt.v
                obj.wspace.opt.v = grad;
            end
        end
    end
    
    properties
        initStepSize  = 1e-3;           % initilial step size
        minStepRatio  = 1e-2;           % minimum step (ratio to initial)
        downStepCount = 1e5;            % number of step to achive minimum step
        inertia       = 0.5;            % inertia of velocity in Momentum
        momentum      = false;          % indicator of Momentum
        decayRate     = 0.9;            % decay rate in RMSProp
        adamPhoS      = 0.9;
        adamPhoR      = 0.999;
        adjustGrad    = @nullfunc;
    end
    
    properties
        minStepSize
        curStepSize
    end
    methods
        function value = get.minStepSize(obj)
            obj.minStepSize = obj.initStepSize * obj.minStepRatio;
        end
        
        function value = get.curStepSize(obj)
            if n < obj.downStepCount
                portion = n / obj.downStepCount;
                value   = (1 - portion) * obj.initStepSize + portion * obj.minStepSize;
            else
                value   = obj.minStepSize;
            end
        end
    end
    
    methods
        function grad = AdaGrad(obj, grad)
            obj.wspace.opt.r = obj.wspace.opt.r + grad.^2;
            grad = (obj.curStepSize * grad ) ./ (1e-7 + sqrt(obj.wspace.opt.r));
        end
        
        function grad = RMSProp(obj, grad)
            obj.wspace.opt.r = obj.decayRate * obj.wspace.opt.r ...
                + (1 - obj.decayRate) * (grad.^2);
            grad = (obj.curStepSize * grad ) ./ sqrt(1e-6 + obj.wspace.opt.r);
        end
        
        function grad = Adam(obj, grad)
            obj.wspace.opt.s = obj.adamPhoS * obj.wspace.opt.s ...
                + (1 - obj.adamPhoS) * grad;
            obj.wspace.opt.r = obj.adamPhoR * obj.wspace.opt.r ...
                + (1 - obj.adamPhoR) * (grad.^2);
            unbiasS = obj.wspace.opt.s / (1 - obj.adamPhoS^obj.wspace.opt.c);
            unbiasR = obj.wspace.opt.r / (1 - obj.adamPhoR^obj.wspace.opt.c);
            grad = obj.curStepSize * unbiasS ./ (sqrt(unbiasR) + 1e-8);
        end
    end
    
    methods
        function obj = SGD(stepsize)
            obj.wspace.opt.c = 0;       % iteration count
            obj.wspace.opt.v = 0;       % velocity in Momentum
            obj.wspace.opt.r = 0;       % gradient accumulation in AdaGrad
            obj.wspace.opt.s = 0;       % first order estimation in Adam
        end
    end
end


