classdef DatasetAP < AccessPoint
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
        function obj = DatasetAP(parent, dsample)
            obj = obj@AccessPoint(parent, dsample);
        end
    end
    
    properties
        dsample
    end
end
