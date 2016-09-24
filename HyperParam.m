classdef HyperParam < Tensor
    methods
        function addgrad(obj, grad)
            obj.gradient.push(grad);
        end
        
        function update(obj)
            if isempty(obj.prior)
                grad = obj.gradient.pop();
                grad = obj.stepsize(grad) * grad;
            else
                grad = obj.gradient.pop() + obj.prior.errprop(obj.data);
                grad = obj.stepsize(grad) * grad;
            end
            
            if obj.useMomentum
                grad = obj.inertia * obj.momentum + grad;
                obj.momentum = grad;
            end
            obj.data = obj.data - grad;
        end
    end
    
    methods
        function step = stepsize(obj, grad)
            switch lower(obj.stepconf.method)
              case {'assign'}
                step = StepsizeCalculator.assign();
                
              case {'decline'}
                step = StepsizeCalculator.decline(obj.gradient.n, obj.stepconf);
                
              case {'adapt'}
                [step, obj.stepconf] = StepsizeCalculator.adapt(grad, obj.stepconf);
                
              otherwise
                error('HyperParam:UnknownArgument', ...
                      'Unrecognized method to calculate step size : %s', ...
                      upper(obj.stepsizeCalculateMethod));
            end
        end
    end
    
    methods
        function obj = HyperParam(data, varargin)
            obj = obj@Tensor(data);
            % parsing configuration from varying input arguments
            conf = Config(varargin);
            obj.stepconf = StepsizeCalculator.getConfig( ...
                conf.pop('stepMethod', UMPrest.parameter.get('stepMethod')));
            obj.gradient = GradientCalculator( ...
                conf.pop('gradientMethod', UMPrest.parameter.get('gradMethod')));
            conf.apply(obj);
        end
    end
    
    properties
        stepconf
        gradient
        momentum
        prior
    end
    methods
        function set.prior(obj, value)
            assert(isempty(value) || isa(value, 'Prior'));
            obj.prior = value;
        end
    end
    
    properties
        inertia = 0.9
    end
    
    properties (Dependent)
        useMomentum
    end
    methods
        function value = get.useMomentum(obj)
            value = not(isempty(obj.momentum));
        end
        function set.useMomentum(obj, value)
            assert(numel(value) == 1 && islogical(value));
            if obj.useMomentum && not(value)
                obj.momentum = [];
            elseif not(obj.useMomentum) && value
                obj.momentum = 0;
            end                
        end
    end
end
