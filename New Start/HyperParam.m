classdef HyperParam < Tensor
    methods
        function addgrad(obj, grad)
            obj.gradient.push(grad);
        end
        
        function update(obj, ss)
            if not(exist('ss', 'var'))
                ss = obj.stepsize();
            end
            
            if isempty(obj.prior)
                grad = ss * obj.gradient.pop();
            else
                grad = ss * (obj.gradient.pop() + obj.prior.errprop(obj.data));
            end
            
            if obj.useMomentum
                grad = obj.inertia * obj.momentum + grad;
                obj.momentum = grad;
            end
            obj.data = obj.data - grad;
        end
    end
    
    methods
        function step = stepsize(obj)
            switch lower(obj.stepconf.method)
                case {'decline'}
                    step = StepsizeCalculator.decline(obj.gradient.n, obj.stepconf);
                    
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
            conf = Config.parse(varargin);
            obj.stepconf = StepsizeCalculator.getConfig( ...
                Config.getValue(conf, 'stepMethod', 'decline'));
            obj.gradient = GradientCalculator( ...
                Config.getValue(conf, 'gradientMethod', 'basic'));
            Config.apply(obj, conf);
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
