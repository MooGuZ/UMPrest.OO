classdef DatasetAP < SimpleAP
    methods
        function data = unpack(obj, package)
            data = package.data;
            % update state
            obj.state.package = package;
            obj.state.data    = data;
        end
        
        function package = packup(obj, data)
            package = DataPackage.create(data, obj.dsample, obj.parent.taxis);
            % update state
            obj.state.package = package;
            obj.state.data    = data;
        end
    end
    
    methods
        function obj = DatasetAP(varargin)
            obj@SimpleAP(varargin{:});
        end
    end
    
    properties (SetAccess = protected)
        parent, dsample
    end
    methods
        function set.parent(obj, value)
            assert(isa(value, 'Dataset'), 'ILLEGAL OPERATION');
            obj.parent = value;
        end
        
        function set.dsample(obj, value)
            assert(MathLib.isinteger(value) && value > 0);
            obj.dsample = value;
        end
    end
end
