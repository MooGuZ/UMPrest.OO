classdef GhostAP < AccessPoint
    % override some connection functions
    methods
        function addlink(obj, ap)
            addlink@AccessPoint(obj, ap);
            % add link from host to the linking access point
            obj.host.addlink(ap);
        end
        
        function rmlink(obj, ap)
            rmlink@AccessPoint(obj, ap);
            % remove corresponding link from host
            obj.host.rmlink(ap);
        end
    end
    
    methods
        function obj = GhostAP(parent, host)
            obj.parent = parent;
            obj.host   = host;
        end
    end
    
    properties (SetAccess = protected)
        parent, host, cache, state
    end
    methods
        function set.parent(obj, value)
            % TODO: specify the unit type, such as enumerate all compound
            %       units that use GHOSTAP
            assert(isa(value, 'Unit'), 'ILLEGAL OPERATION');
            obj.parent = value;
        end
        
        function set.host(obj, value)
            assert(isa(value, 'AccessPoint'), 'ILLEGAL OPERATION');
            obj.host = value;
        end
        
        function value = get.cache(obj)
            value = obj.host.cache;
        end
        
        function value = get.state(obj)
            value = obj.host.state;
        end
    end
end
