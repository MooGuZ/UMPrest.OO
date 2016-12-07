classdef SimpleAP < AccessPoint
    methods (Abstract)
        data = unpack(obj, package)
        package = packup(obj, data)
    end
    
    methods
        function obj = SimpleAP(parent, dsample, varargin)
            conf = Config(varargin);
            obj.parent  = parent;
            obj.cache   = PackageQueue('Capacity', ...
                conf.pop('capacity', UMPrest.parameter.get('AccessPointCapacity')), ...
                '-dropold');
            obj.state   = State(UMPrest.parameter.get('memoryLength'));
            obj.dsample = dsample;
        end
    end
    
    methods
        function clear(obj)
            obj.state.clear();
            obj.cache.init();
        end
    end
    
    properties (Abstract, SetAccess = protected)
        dsample
    end
    properties (SetAccess = protected, Transient)
        cache, state
    end
    methods
        function set.cache(obj, value)
            assert(isa(value, 'Queue'), 'ILLEGAL OPERATION');
            obj.cache = value;
        end
    end
end
