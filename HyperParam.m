classdef HyperParam < Tensor & ProbabilityDescription
    methods
        function addgrad(obj, grad)
            if not(obj.frozen)
                obj.gradient(:) = obj.gradient(:) + grad(:);
            end
            if any(isnan(grad), 'all')
                error('NaN is not allowed');
            end
        end
        
        function update(obj)
            if not(obj.frozen)
                obj.t = obj.t + 1;
                % Gradient obtained from Optimization Algorithm
                obj.gradcalc(obj.optimizer.conf.grad);
                % Regularize Parameters with Prior
                if not(isempty(obj.priorSet))
                    obj.addgrad(obj.priorDelta(obj.data));
                end
                % Update Parameters with Calculated Step
                obj.data(:) = obj.data(:) - ...
                    obj.stepcalc(obj.optimizer.conf.step) * obj.gradient(:);
                % reset gradient
                obj.gradient(:) = 0;
                % Apply hooked function if exist
                if not(isempty(obj.hookModify))
                    obj.data = obj.hookModify(obj.data);
                end
            end
        end
        
        function addnoise(obj, stdvar)
            obj.data(:) = obj.data(:) + randn(numel(obj.data),1) * stdvar;
        end
    end
    properties
        hookModify = []
    end
    
    methods
        function obj = normalize(obj, dim)
            obj.data(:) = vec(normalize(obj.data, dim));
        end
        
        function obj = cleanup(obj)
            obj.t        = 0;
            obj.gradient = zeros(size(obj.data), class(obj.data));
            obj.momentum = zeros(size(obj.data), class(obj.data));
            obj.sigmasqr = zeros(size(obj.data), class(obj.data));
            obj.beta1tCum = ones(size(obj.data), class(obj.data));
            obj.laststep = [];
        end

        function set(obj, value)
            if isempty(obj.hookModify)
                set@Tensor(obj, value);
            else
                set@Tensor(obj, obj.hookModify(value));
            end
            obj.cleanup();
        end
    end
    
    methods (Access = protected)
        function grad = gradcalc(obj, conf)
            switch conf.mode
                case {'basic', 'vanilla'}


                case {'sgd'}
                    obj.momentum(:) = conf.beta * obj.momentum(:) + (1 - conf.beta) * obj.gradient(:);
                    obj.gradient(:) = obj.momentum(:) / (1 - conf.beta^obj.t);

                case {'adam'}
                    obj.momentum(:) = conf.beta1 * obj.momentum(:) + (1 - conf.beta1) * obj.gradient(:);
                    obj.sigmasqr(:) = conf.beta2 * obj.sigmasqr(:) + (1 - conf.beta2) * (obj.gradient(:).^2);
                    alpha1 = 1 - conf.beta1^obj.t;
                    alpha2 = sqrt(1 - conf.beta2^obj.t);
                    obj.gradient(:) = (alpha2 * obj.momentum(:)) ./ (alpha1 * sqrt(obj.sigmasqr(:)) + conf.eta);

                case {'radam'}
                    obj.momentum(:) = conf.beta1 * obj.momentum(:) + (1 - conf.beta1) * obj.gradient(:);
                    obj.sigmasqr(:) = conf.beta2 * obj.sigmasqr(:) + (1 - conf.beta2) * (obj.gradient(:).^2);
                    alpha1 = 1 - conf.beta1^obj.t;
                    rhoInf = 2 / (1 - conf.beta2) - 1;
                    rho    = rhoInf - 2 * obj.t * (conf.beta2.^obj.t) / (1 - conf.beta2.^obj.t);
                    if rho > 4
                        alpha2 = sqrt(1 - conf.beta2^obj.t);
                        rectUp = sqrt((rho - 4) * (rho -2) * rhoInf);
                        rectDn = sqrt((rhoInf - 4) * (rhoInf -2) * rho);
                        obj.gradient(:) = (rectUp * alpha2 * obj.momentum(:)) ...
                            ./ (rectDn * alpha1 * sqrt(obj.sigmasqr(:)) + conf.eta);
                    else
                        obj.gradient(:) = obj.momentum(:) / alpha1;
                    end

                case {'adai'}
                    obj.sigmasqr(:) = conf.beta2 * obj.sigmasqr(:) + (1 - conf.beta2) * (obj.gradient(:).^2);
                    sigmaNorm = obj.sigmasqr / (1 - conf.beta2^obj.t);
                    sigmaNorm = sigmaNorm ./ mean(sigmaNorm(:));
                    beta1t = min(max(1 - conf.beta0 * sigmaNorm,0),conf.eta);
                    obj.beta1tCum = obj.beta1tCum .* beta1t;
                    obj.momentum(:) = beta1t(:) .* obj.momentum(:) ...
                        + (1 - beta1t(:)) .* obj.gradient(:);
                    obj.gradient(:) = obj.momentum(:) ./ (1 - obj.beta1tCum(:));

                otherwise
                    error('UNRECOGNIZED PARAMETER');
            end
            % return updated gradient
            grad = obj.gradient;
        end
        
        function step = stepcalc(obj, conf)
            switch conf.mode
                case {'static'}
                    step = conf.step;

                case {'decay', 'decline'}
                    step = conf.initstep * conf.dfactor^floor(obj.t / conf.wsize);
                    step = max(step, conf.minstep);

                case {'adapt'}
                    gradmax = max(abs(obj.gradient(:)));
                    if isempty(obj.laststep)
                        step = min(conf.step / gradmax, conf.maxstep);
                    else
                        step = obj.laststep;
                        ratio = gradmax * step / conf.step;
                        if ratio >= 30
                            step = step / ratio;
                        elseif ratio >= 10
                            step = step / 3;
                        elseif ratio >= 1
                            step = step * 0.95;
                        elseif ratio > 0
                            step = step * 1.02;
                        end
                    end
                    obj.laststep = step;

                case {'custom'}
                    step = conf.func(obj.t);

                otherwise
                    error('UNRECOGNIZED PARAMETER');
            end
        end
    end
    
    methods
        function obj = HyperParam(data)
            obj@Tensor(data);
            obj.cleanup();
        end
    end
    
    properties
        frozen = false
    end
    properties (Hidden)
        t
        gradient
        momentum
        sigmasqr
        beta1tCum
        laststep
    end
    properties (Constant)
        optimizer = UMPrest.getGlobalOptimizer()
    end
    
    % randomly initialization methods
    methods (Static)
        function M = randlt(row, col)
            M = (rand(row, col) - 0.5) * (2.0 / sqrt(col));
        end
        
        function F = randct(fltsize, nchannel, nfilter)
            F = HyperParam.randlt(nfilter, prod([fltsize, nchannel]));
            F = reshape(F, [fltsize, nchannel, nfilter]);
        end
    end
end
