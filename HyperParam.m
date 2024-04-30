classdef HyperParam < Tensor & ProbabilityDescription
    methods
        function addgrad(obj, grad)
            if not(obj.frozen)
                obj.gradient(:) = obj.gradient(:) + grad(:);
            end
        end
        
        function update(obj)
            if not(obj.frozen)
                obj.t = obj.t + 1;
                % Gradient from Prior
                if not(isempty(obj.priorSet))
                    obj.addgrad(obj.priorDelta(obj.data));
                end
                % Gradient obtained from Optimization Algorithm
                grad = obj.gradcalc(obj.optimizer.conf.grad);
                % Apply Step Scheduling
                grad = obj.stepcalc(obj.optimizer.conf.step) * grad;
                % Update Parameters
                obj.data(:) = obj.data(:) - grad(:);
                % reset gradient
                obj.gradient(:) = 0;
            end
        end
        
        function addnoise(obj, stdvar)
            obj.data(:) = obj.data(:) + randn(numel(obj.data),1) * stdvar;
        end
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
            obj.laststep = [];
        end

        function set(obj, value)
            set@Tensor(obj, value);
            obj.cleanup();
        end
    end
    
    methods (Access = protected)
        function grad = gradcalc(obj, conf)
            switch conf.mode
                case {'basic', 'sgd'}

                case {'adam'}
                    obj.momentum(:) = conf.beta1 * obj.momentum(:) + (1 - conf.beta1) * obj.gradient(:);
                    obj.sigmasqr(:) = conf.beta2 * obj.sigmasqr(:) + (1 - conf.beta2) * (obj.gradient(:).^2);
                    alpha1 = 1 - conf.beta1^obj.t;
                    alpha2 = sqrt(1 - conf.beta2^obj.t);
                    obj.gradient(:) = (alpha2 * obj.momentum(:)) ./ (alpha1 * sqrt(obj.sigmasqr(:)) + 1e-8);

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
                        step = conf.step / gradmax;
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
