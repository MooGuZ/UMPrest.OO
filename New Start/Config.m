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
        
        function [value, key] = getValue(map, key, default, mode)
            if ~exist('mode', 'var')
                mode = 'default';
            end
            
            if not(isa(map, 'containers.Map'))
                map = Config.parse(map);
            end
            
            assert(ischar(key));
            
            done = false;
            switch lower(mode)
                case {'default', 'charwise'}
                    key = lower(key);
                    if map.isKey(key)
                        value = map(key);
                        done  = true;
                    end
                
%                 case {'exact'}
%                     if map.isKey(key)
%                         value = map(key);
%                         done  = true;
%                     end
% 
%                 case {'caseinsensitive', 'insensitive', 'unicase'}
%                     klist = map.keys();
%                     index = strcmpi(key, klist);
%                     if any(index)
%                         % PROBLEM : current program would choose last match
%                         % in the key list of map, which is in alpha-beta
%                         % order. Therefore, it has nothing to do with the
%                         % argument input order. Both the earlier and latter
%                         % input configuration can be choose in this way.
%                         key   = klist{find(index, 1, 'last')};
%                         value = map(key);
%                         done  = true;
%                     end
                                        
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
        
        function value = popItem(map, key, default, mode)
            if exist('mode', 'var')
                [value, key] = Config.getValue(map, key, default, mode);
            else
                [value, key] = Config.getValue(map, key, default);
            end
            if not(isempty(key))
                map.remove(key);
            end
        end
        
        function tof = keyExist(map, key)
            if not(isa(map, 'containers.Map'))
                map = Config.parse(map);
            end
            
            assert(ischar(key));
            
            tof = any(strcmpi(key, map.keys()));
        end
        
        function buffer = merge(base, mod)
            assert(isa(base, 'containers.Map') && isa(mod, 'containers.Map'));
            
            modkeys  = mod.keys();
            basekeys = base.keys();
            
            [~, imod, ibase] = union(lower(modkeys), lower(basekeys), 'stable');
            
            buffer = containers.Map();
            for i = 1 : numel(imod)
                key = modkeys{imod(i)};
                buffer(key) = mod(key);
            end
            for i = 1 : numel(ibase)
                key = basekeys{ibase(i)};
                buffer(key) = base(key);
            end
        end
        
        function clsobj = apply(clsobj, map, def)
            if not(isa(map, 'containers.Map'))
                map = Config.parse(map);
            end
            
            if exist('def', 'var')
                map = Config.merge(def, map);
            end                
            
            klist = map.keys();
            % plist = properties(class(clsobj));
            plist = fieldnames(clsobj);
            [~, ikey, iprop] = intersect(lower(klist), lower(plist), 'stable');
            for i = 1 : numel(ikey)
                clsobj.(plist{iprop(i)}) = map(klist{ikey(i)});
            end
        end
    end
end
