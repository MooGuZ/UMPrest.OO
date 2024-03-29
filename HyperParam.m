classdef HyperParam < Tensor & ProbabilityDescription
    methods
       function addgrad(obj, grad)
            if not(obj.frozen)
                obj.gradient = obj.gradient + grad;
            end
        end
        
        function update(obj)
            if not(obj.frozen)
                obj.t = obj.t + 1;
                % get latest configuration
                if obj.timestamp < obj.optimizer.timestamp
                    obj.conf = obj.optimizer.getconf();
                end
                % apply prior if exist
                if not(isempty(obj.priorSet))
                    obj.addgrad(obj.priorDelta(obj.data));
                end
                % calculate gradient
                % NOTE: correctness of following line is based on the fact that
                %       MATLAB evaluate expresion from left to the right. Because,
                %       some step size calculation require updated gradient.
                grad = obj.gradcalc(obj.conf.gradmode) * obj.stepcalc(obj.conf.stepmode);
                % apply momentum if feasible
                if obj.conf.momentum.status
                    grad = grad + obj.momentum * obj.conf.momentum.inertia;
                    obj.momentum = grad;
                end
                % update hyper parameter
                obj.data = obj.data - grad;
                % reset gradient
                obj.gradient = 0;
            end
        end
        
        function addnoise(obj, stdvar)
            obj.data = obj.data + randn(size(obj.data)) * stdvar;
        end
    end
    
    methods
        function obj = normalize(obj, dim)
            mat = obj.data;
            obj.data = bsxfun(@rdivide, mat, sqrt(sum(mat.^2, dim)));
        end
        
        function obj = cleanup(obj)
            obj.t            = 0;
            obj.timestamp    = -inf;
            obj.gradient     = 0;
            obj.momentum     = 0;
            obj.moment1stOrd = 0;
            obj.moment2ndOrd = 0;
            obj.conf         = [];
            obj.laststep     = [];
        end

        function set(obj, value)
            set@Tensor(obj, value);
            obj.cleanup();
        end
    end
    
    methods
        function grad = gradcalc(obj, conf)
            switch conf.mode
              case {'basic', 'sgd'}
                % do nothing
                
              case {'rmsprop'}
                obj.moment2ndOrd = conf.decay2ndOrd * obj.moment2ndOrd + ...
                    (1 - conf.decay2ndOrd) * (obj.gradient.^2);
                obj.gradient = obj.gradient ./ sqrt(1e-6 + obj.moment2ndOrd);
                                
              case {'adam'}
                obj.moment1stOrd = conf.decay1stOrd * obj.moment1stOrd + ...
                    (1 - conf.decay1stOrd) * obj.gradient;
                obj.moment2ndOrd = conf.decay2ndOrd * obj.moment2ndOrd + ...
                    (1 - conf.decay2ndOrd) * (obj.gradient.^2);
                moment1stOrdBC = obj.moment1stOrd / (1 - conf.decay1stOrd^obj.t);
                moment2ndOrdBC = obj.moment2ndOrd / (1 - conf.decay2ndOrd^obj.t);
                obj.gradient = moment1stOrdBC ./ (sqrt(moment2ndOrdBC) + 1e-8);
                
              otherwise
                error('UNRECOGNIZED PARAMETER');
            end
            grad = obj.gradient;
        end
        
        function step = stepcalc(obj, conf)
            switch conf.mode
              case {'static'}
                step = conf.step;
                
              case {'decline'}
                step = conf.initstep * conf.dfactor^floor(obj.t / conf.wsize);
                
              case {'adapt'}
                gradmax = max(abs(obj.gradient(:)));
                if isempty(obj.laststep)
                    step = min(conf.estch / gradmax, conf.maxstep);
                else
                    step = obj.laststep;
                    ratio = gradmax * step / conf.estch;
                    if ratio >= 30
                        step = step / ratio;
                    elseif ratio >= 10
                        step = step / 3;
                    elseif ratio >= 1
                        step = step * conf.dfactor;
                    elseif ratio > 0
                        step = step * conf.ufactor;
                    end
                end
                obj.laststep = step;
                
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
        t, timestamp
        gradient, momentum, moment1stOrd, moment2ndOrd
        conf, laststep
    end
    properties (Constant)
        optimizer = HyperParam.getOptimizer();
    end
    
    methods (Static)
        function opt = getOptimizer()
            persistent cache
            if isempty(cache)
                cache = HyperParamOptimizer();
            end
            opt = cache;
        end
    end
    
    % randomly initialization methods
    methods (Static)
        function M = randlt(row, col)
            M = (rand(row, col) - 0.5) * (2 / sqrt(col));
        end
        
        function F = randct(fltsize, nchannel, nfilter)
            F = HyperParam.randlt(nfilter, prod([fltsize, nchannel]));
            F = reshape(F, [fltsize, nchannel, nfilter]);
        end
    end
end
