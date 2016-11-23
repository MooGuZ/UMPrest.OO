classdef AccessPoint < handle
    methods (Abstract)
        data = unpack(obj, package)
        package = packup(obj, data)
    end
    
    % ======================= CONNECTION =======================
    methods
        function send(obj, package)
            % package = obj.packup(data);
            for i = 1 : numel(obj.links)
                % TODO: skip links type check, make the links only privately
                %       setable and ensure legality of connection when
                %       conncection established.
                if isa(obj.links(i), 'AccessPoint')
                    obj.links(i).push(package);
                end
            end
        end
        
        function push(obj, package)
            obj.cache{obj.jcache} = package;
            % update cache index
            if isempty(obj.icache)
                obj.icache = obj.jcache;
            elseif obj.icache == obj.jcache
                obj.icache = mod(obj.jcache, obj.capacity) + 1;
            end
            obj.jcache = mod(obj.jcache, obj.capacity) + 1;
        end
        
        function package = pop(obj)
            if isempty(obj.icache)
                error('EMPTY');
            else
                package = obj.cache{obj.icache};
                % obj.cache{obj.icache} = [];
            end
            % update cache index
            obj.icache = mod(obj.icache, obj.capacity) + 1;
            if obj.icache == obj.jcache
                obj.icache = [];
            end
        end
        
        function value = count(obj)
            if isempty(obj.icache)
                value = 0;
            elseif obj.icache == obj.jcache
                value = obj.capacity;
            else
                value = mod(obj.jcache - obj.icache, obj.capacity);
            end
        end
        
        function addlink(obj, ap)
            obj.links = unique([obj.links, ap]);
        end
        
        function rmlink(obj, ap)
            obj.links(obj.links == ap) = [];
        end
    end
    
    methods
        function obj = AccessPoint(parent, dsample)
            obj.parent   = parent;
            obj.dsample  = dsample;
            obj.state    = struct('data', [], 'package', []);
            obj.capacity = UMPrest.parameter.get('AccessPointCapacity');
            obj.cache    = cell(1, obj.capacity);
            obj.icache   = [];
            obj.jcache   = 1;
        end
    end
    
    methods (Static)
        function connect(ap1, ap2)
            ap1.addlink(ap2);
            ap2.addlink(ap1);
        end
        
        function disconnect(ap1, ap2)
            ap1.rmlink(ap2);
            ap2.rmlink(ap1);
        end
        
        function connectOneWay(from, to)
            from.addlink(to);
        end
    end
    
    % PRP: create a QUEUE class for cache
    properties
        parent, state, links
        cache, capacity, icache, jcache
    end
    properties (Abstract)
        dsample
    end
    methods
        function set.links(obj, value)
            assert(isempty(value) || isa(value, 'AccessPoint'));
            obj.links = value;
        end
    end
end
