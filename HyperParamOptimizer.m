classdef HyperParamOptimizer < handle
    methods
        function obj = HyperParamOptimizer(jsonfile)
            arguments
                jsonfile = UMPrest.path('config', 'simplified.json')
            end
            % load default configuration
            obj.default = loadjson(jsonfile).conf;
            % initialize memory
            obj.memory = Container(inf);
            % load default gradient and step settings
            obj.gradSetup(obj.default.grad.mode);
            obj.stepSetup(obj.default.step.mode);
            % record this setting in memory
            obj.push();
        end

        function disp(obj)
            fprintf('[Gradient Calculation]\n\n');
            disp(obj.conf.grad);
            fprintf('[Stepsize Schedule]\n\n');
            disp(obj.conf.step);
            fprintf('[Configuration Stack]\n\n');
            disp(obj.memory);
        end

        function push(obj)
            obj.memory.push(obj.conf);
        end
        
        function pop(obj)
            obj.conf = obj.memory.pop();
        end
    end
    properties (SetAccess = private)
        conf, memory, default
    end

    methods
        function obj = gradSetup(obj, mode, varargin)
            config = Config(varargin);
            switch lower(mode)
                case {'basic', 'sgd'}
                    obj.conf.grad = struct('mode', 'basic');

                case {'adam'}
                    obj.conf.grad = struct( ...
                        'mode', 'adam', ...
                        'beta1', config.pop('beta1', obj.default.grad.adam.beta1), ...
                        'beta2', config.pop('beta2', obj.default.grad.adam.beta2));

                otherwise
                    error('UNRECOGNIZED MODE');
            end
        end
        
        function obj = stepSetup(obj, mode, varargin)
            config = Config(varargin);
            % setup step calculate method
            switch lower(mode)
                case {'static', 'constant'}
                    obj.conf.step = struct( ...
                        'mode', 'static', ...
                        'step', config.pop('step', obj.default.step.static.step));

                case {'decay', 'decline'}
                    obj.conf.step = struct( ...
                        'mode',     'decay', ...
                        'initstep', config.pop('initStep', obj.default.step.decay.initStep), ...
                        'minstep',  config.pop('minStep', obj.default.step.decay.minStep), ...
                        'dfactor',  config.pop('downFactor', obj.default.step.decay.downFactor), ...
                        'wsize',    config.pop('windowSize', obj.default.step.decay.windowSize));

                case {'adapt'}
                    obj.conf.step = struct( ...
                        'mode',    'adapt', ...
                        'step',    config.pop('step', obj.default.step.adapt.step), ...
                        'minstep', config.pop('minStep', obj.default.step.adapt.minStep), ...
                        'maxstep', config.pop('maxStep', obj.default.step.adapt.maxStep), ...
                        'dfactor', config.pop('downFactor', obj.default.step.adapt.downFactor), ...
                        'ufactor', config.pop('upFactor', obj.default.step.adapt.upFactor), ...
                        'objrcds', inf(1, 3), ...
                        'count', 0, ...
                        'index', 1);

                otherwise
                    assert(isa(mode, 'function_handle'));
                    obj.conf.step = struct( ...
                        'mode', 'custom', ...
                        'func', mode);
            end
        end
        
        function obj = record(obj, value)
            if strcmpi(obj.conf.step.mode, 'adapt')
                if isa(value, 'gpuArray')
                    value = double(gather(value));
                end
                % Evaluate Current Situation
                factor = value / min(obj.conf.step.objrcds);
                if factor >= 1
                    obj.conf.step.count = obj.conf.step.count + 1;
                    if obj.conf.step.count >= 3
                        obj.conf.step.step = ...
                            max(obj.conf.step.minstep, obj.conf.step.step * obj.conf.step.dfactor);
                        obj.conf.step.count = 0;
                    end
                elseif factor > 0.99
                    obj.conf.step.step = min(obj.conf.step.maxstep, ...
                        obj.conf.step.step * obj.conf.step.ufactor);
                end                    
                obj.conf.step.objrcds(obj.conf.step.index) = value;
                obj.conf.step.index = mod( ...
                    obj.conf.step.index, numel(obj.conf.step.objrcds)) + 1;
            end
        end
    end
end
