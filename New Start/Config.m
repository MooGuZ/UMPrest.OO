classdef Config < handle
    methods (Static)
        function cfg = parse(varargin)
            if nargin == 1 && iscell(varargin{1})
                kvpairs = varargin{1};
            else
                kvpairs = varargin;
            end
            
            cfg = containers.Map();
            
            index = 1;
            while index <= numel(kvpairs)
                key = kvpairs{index};
                assert(ischar(key), 'UMPrest:ArgumentError', ...
                    'Unrecognized property at index %d', index);
                key = lower(key); % make configuration map case-insensitive
                if key(1) == '-' % unary (switcher) property
                    cfg(key(2:end)) = true;
                    index           = index + 1;
                else % binary (key-value pair) property
                    assert(numel(kvpairs) >= index + 1, ...
                        sprintf('value of binary property [%s] is missing.', key));
                    cfg(key) = kvpairs{index + 1};
                    index    = index + 2;
                end
            end
        end
    end
       
    methods
        function [value, key] = get(obj, key, default, mode)
            if ~exist('mode', 'var')
                mode = 'default';
            end
            
            done = false;
            switch lower(mode)
              case {'default', 'charwise'}
                key = lower(key);
                if obj.map.isKey(key)
                    value = obj.map(key);
                    done  = true;
                end
                
              otherwise
                error('UMPrest:ArgumentError', 'Unrecognized mode : %s', upper(mode));
            end
            
            if not(done)
                if exist('default', 'var')
                    value = default;
                    key   = [];
                else
                    error('UMPrest:ArgumentRequired', ...
                        'Cannot find the property, please provide default value!');
                end
            end
        end
        
        function set(obj, key, value)
            obj.map(key) = value;
        end
        
        function value = pop(obj, key, default, mode)
            if not(exist('mode', 'var'))
                mode = 'default';
            end
            [value, key] = obj.get(key, default, mode);
            if not(isempty(key))
                obj.map.remove(key);
            end
        end
        
        function tof = exist(obj, key)
            tof = obj.map.isKey(lower(key));
        end
        
        function update(self, varargin)
            other = Config(varargin{:});
            keylist = other.keys();
            for i = 1 : numel(keylist)
                key = keylist{i};
                self.set(key, other.get(key));
            end
        end
        
        function instance = apply(obj, instance)
            keylist = fieldnames(instance);
            for i = 1 : numel(keylist)
                key = keylist{i};
                if obj.exist(key)
                    instance.(key) = obj.map(lower(key));
                end
            end
            % if not(isa(map, 'containers.Map'))
            %     map = Config.parse(map);
            % end
            % 
            % if exist('def', 'var')
            %     map = Config.merge(def, map);
            % end                
            % 
            % klist = map.keys();
            % % plist = properties(class(clsobj));
            % plist = fieldnames(clsobj);
            % [~, ikey, iprop] = intersect(lower(klist), lower(plist), 'stable');
            % for i = 1 : numel(ikey)
            %     clsobj.(plist{iprop(i)}) = map(klist{ikey(i)});
            % end
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Config(varargin)
            if nargin == 1
                if isa(varargin{1}, 'Config')
                    obj = varargin{1};
                    return
                elseif iscell(varargin{1})
                    kvpairs = varargin{1};
                else
                    kvpairs = varargin;
                end
            else
                kvpairs = varargin;
            end
            
            obj.map = containers.Map();
            
            index = 1;
            while index <= numel(kvpairs)
                key = kvpairs{index};
                assert(ischar(key), 'UMPrest:ArgumentError', ...
                    'Unrecognized property at index %d', index);
                key = lower(key); % make configuration map case-insensitive
                if key(1) == '-'  % unary (switcher) property
                    obj.map(key(2:end)) = true;
                    index = index + 1;
                else              % binary (key-value pair) property
                    assert(numel(kvpairs) >= index + 1, ...
                        sprintf('value of binary property [%s] is missing.', key));
                    obj.map(key) = kvpairs{index + 1};
                    index = index + 2;
                end
            end
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (Access = private)
        map
    end
    properties (Dependent)
        keys
    end
    methods
        function value = get.keys(obj)
            value = obj.map.keys();
        end
    end
    
    % ======================= DEVELOPER TOOL =======================
    methods (Static)
        function debug()
            conf = Config( ...
                'a', rand(), ...
                'b', randn(1, randi(10, 1)), ...
                'c', randn(randi(10, 1), randi(10, 1)), ...
                '-on', ...
                'd', 'test message');
            disp(conf.get('A'));
            disp(conf.get('b'));
            disp(conf.get('oN'));
            conf.update('c', 'replace by string', 'on', false, 'something new', nan);
            instance = struct('a', 1, 'B', 2, 'd', 3, 'on', true);
            instance = conf.apply(instance);
            disp(instance);
        end
    end
end
