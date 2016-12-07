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
                grad = obj.gradient.pop() + obj.prior.delta(obj.data);
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
                obj.stepconf = StepsizeCalculator.adapt(grad, obj.stepconf);
                step = obj.stepconf.step;
                
              otherwise
                error('HyperParam:UnknownArgument', ...
                      'Unrecognized method to calculate step size : %s', ...
                      upper(obj.stepsizeCalculateMethod));
            end
        end
    end
    
    methods
        function obj = HyperParam(data, stepconf, gradient, varargin)
            obj = obj@Tensor(data);

            if not(exist('stepconf', 'var'))
                obj.stepconf = StepsizeCalculator.getConfig( ...
                    UMPrest.parameter.get('stepMethod'));
            else
                obj.stepconf = stepconf;
            end
            
            if not(exist('gradient', 'var'))
                obj.gradient = GradientCalculator(UMPrest.parameter.get('gradMethod'));
            else
                obj.gradient = gradient;
            end
            
            if not(isempty(varargin))
                Config(varargin).apply(obj);
            end
        end
    end
    
%     methods
%         function sobj = saveobj(obj)
%             sobj.data     = obj.getcpu();
%             sobj.stepconf = obj.stepconf;
%             sobj.gradient = obj.gradient;
%             sobj.momentum = obj.momentum;
%             sobj.prior    = obj.prior;
%             sobj.inertia  = obj.inertia;
%         end
%     end
%     methods (Static)
%         function obj = loadobj(sobj)
%             if isstruct(sobj)
%                 obj = HyperParam( ...
%                     sobj.data, sobj.stepconf, sobj.gradient, ...
%                     'momentum', sobj.momentum, ...
%                     'prior',    sobj.prior, ...
%                     'inertia',  sobj.inertia);
%             else
%                 obj = sobj;
%             end
%         end
%     end
    
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
