classdef HyperParamOptimizer < handle
    methods
        function conf = getconf(obj)
            conf = obj.cache;
        end
        
        function obj = gradmode(obj, mode, varargin)
            conf = Config(varargin);
            switch lower(mode)
              case {'basic', 'sgd'}
                obj.cache.gradmode = struct('mode', 'basic');
                
              case {'rmsprop'}
                obj.cache.gradmode = struct( ...
                    'mode',        'rmsprop', ...
                    'decay2ndOrd', conf.pop('decay2ndOrd', ...
                        obj.default.gradmode.rmsprop.decay2ndOrd));                
                
              case {'adam'}
                obj.cache.gradmode = struct( ...
                    'mode',        'adam', ...
                    'decay1stOrd', conf.pop('decay1stOrd', ...
                        obj.default.gradmode.adam.decay1stOrd), ...
                    'decay2ndOrd', conf.pop('decay2ndOrd', ...
                        obj.default.gradmode.adam.decay2ndOrd));
                
              otherwise
                error('UNRECOGNIZED MODE');
            end
            obj.resetRecord();
            obj.timestamp = now();
        end
        
        function obj = stepmode(obj, mode, varargin)
            conf = Config(varargin);
            % setup step calculate method
            switch lower(mode)
              case {'static'}
                obj.cache.stepmode = struct( ...
                    'mode', 'static', ...
                    'step', conf.pop('step', obj.default.stepmode.static.step));
                
              case {'decline'}
                obj.cache.stepmode = struct( ...
                    'mode',     'decline', ...
                    'initstep', conf.pop('initStep', ...
                        obj.default.stepmode.decline.initStep), ...
                    'dfactor',  conf.pop('downFactor', ...
                        obj.default.stepmode.decline.downFactor), ...
                    'wsize',    conf.pop('windowSize', ...
                        obj.default.stepmode.decline.windowSize));
                
              case {'adapt'}
                obj.cache.stepmode = struct( ...
                    'mode',     'adapt', ...
                    'estch',    conf.pop('estimatedChange', ...
                        obj.default.stepmode.adapt.estimatedChange), ...
                    'minestch', conf.pop('minimalEstimatedChange', ...
                        obj.default.stepmode.adapt.minimalEstimatedChange), ...
                    'maxstep',  conf.pop('maxInitStep', ...
                        obj.default.stepmode.adapt.maxInitStep), ...
                    'dfactor',  conf.pop('downFactor', ...
                        obj.default.stepmode.adapt.downFactor), ...
                    'ufactor',  conf.pop('upFactor', ...
                        obj.default.stepmode.adapt.upFactor));
                % apply minimal estimated change restiction
                obj.cache.stepmode.estch = ...
                    max(obj.cache.stepmode.estch, obj.cache.stepmode.minestch);
                
              otherwise
                error('UNRECOGNIZED MODE');
            end
            % reset record mode
            switch lower(mode)
              case {'static', 'decline'}
                obj.disableRcdmode();
                
              case {'adapt'}
                obj.resetRecord();
            end
            % update timestamp
            obj.timestamp = now();
        end
        
        function obj = enableMomentum(obj, varargin)
            conf = Config(varargin);
            obj.cache.momentum = struct( ...
                'status',  true, ...
                'inertia', conf.pop('inertia', obj.default.momentum.inertia));
            obj.resetRecord();
            obj.timestamp = now();
        end
        
        function obj = disableMomentum(obj)
            obj.cache.momentum = struct('status', false);
            obj.resetRecord();
            obj.timestamp = now();
        end
                
        function obj = enableRcdmode(obj, n)
            if isfield(obj.cache, 'stepmode') && strcmpi(obj.cache.stepmode.mode, 'adapt')
                obj.cache.rcdmode = struct( ...
                    'status', true, ...
                    'value',  inf(1, n), ...
                    'index',  1, ...
                    'count',  0);
            else
                warning('Record-Mode can only be activatied in ADAPT stepmode');
            end
        end
        
        function obj = disableRcdmode(obj)
            obj.cache.rcdmode = struct('status', false);
        end
        
        function obj = resetRecord(obj)
            if isfield(obj.cache, 'rcdmode') && obj.cache.rcdmode.status
                obj.enableRcdmode(numel(obj.cache.rcdmode.value));
            else                
                obj.disableRcdmode();
            end
        end
        
        function obj = record(obj, value, verbose)
            if not(exist('verbose', 'var'))
                verbose = false;
            end
            
            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
            
            if obj.cache.rcdmode.status
                factor = value / min(obj.cache.rcdmode.value);
                if verbose
                    fprintf('FACTOR : %8.2e : ', factor);
                end
                if factor >= 1
                    obj.cache.rcdmode.count = obj.cache.rcdmode.count + 1;
                    if obj.cache.rcdmode.count >= 3
                        obj.cache.stepmode.estch = ...
                            max(obj.cache.stepmode.minestch, obj.cache.stepmode.estch / 1.5);
                        obj.cache.rcdmode.count = 0;
                        if verbose
                            fprintf('decrease ESTCH to %8.2e\n', obj.cache.stepmode.estch);
                        end
                    else
                        if verbose
                            fprintf('counting to (%d/3)\n', obj.cache.rcdmode.count);
                        end
                    end
                elseif factor > 0.99
                    obj.cache.stepmode.estch = obj.cache.stepmode.estch * 1.1;
                    if verbose
                        fprintf('increase ESTCH to %8.2e\n', obj.cache.stepmode.estch);
                    end
                else
                    if verbose
                        fprintf('good condition\n');
                    end
                end                    
                obj.cache.rcdmode.value(obj.cache.rcdmode.index) = value;
                obj.cache.rcdmode.index = mod( ...
                    obj.cache.rcdmode.index, numel(obj.cache.rcdmode.value)) + 1;
            end
        end
        
        function push(obj)
            obj.memory.push(obj.cache);
        end
        
        function pop(obj)
            obj.cache = obj.memory.pop();
            obj.resetRecord();
            obj.timestamp = now();
        end
        
        function fetch(obj, index)
            obj.cache = obj.memory.fetch(index);
            obj.resetRecord();
            obj.timestamp = now();
        end
    end
        
    methods
        function disp(obj)
            fprintf('\n[Gradient]\n\n');
            disp(obj.cache.gradmode);
            fprintf('[Momentum]\n\n');
            disp(obj.cache.momentum);
            fprintf('[Stepsize]\n\n');
            disp(obj.cache.stepmode);
            fprintf('[Record Mode]\n\n');
            disp(obj.cache.rcdmode);
        end
    end
    
    methods
        function obj = HyperParamOptimizer(configFile)
            if exist('configFile', 'var')
                jsonfile = loadjson(configFile);
            else
                jsonfile = loadjson(UMPrest.path('config', 'hpconf.json'));
            end
            obj.default = jsonfile.conf;
            % initialize memory
            obj.memory = Container(10, '-overwrite');
            % load default gradient and step settings
            obj.gradmode(obj.default.gradmode.mode);
            obj.stepmode(obj.default.stepmode.mode);
            % setup moementum
            if obj.default.momentum.status
                obj.enableMomentum();
            else
                obj.disableMomentum();
            end
            % setup record mode
            if obj.default.recordmode.status
                obj.enableRcdmode(obj.default.recordmode.n);
            else
                obj.disableRcdmode();
            end
            % record this setting in memory
            obj.push();
        end
    end
    
    properties (SetAccess = private)
        cache, default, memory, timestamp
    end
    properties (Dependent)
        memoryLength
    end
    methods
        function value = get.memoryLength(obj)
            value = obj.memory.capacity;
        end
        
        function set.memoryLength(obj, value)
            temp = cell(1, obj.memory.count);
            for i = 1 : numel(temp)
                temp{i} = obj.memory.pop();
            end
            % reinitialize memory
            if value == 1
                obj.memory.simple();
            else
                obj.memory.init(value);
            end
            % restore memories
            for i = numel(temp) : -1 : 1
                obj.memory.push(temp{i});
            end
        end
    end
end
