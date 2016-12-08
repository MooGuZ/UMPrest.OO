classdef DatasetAP < SimpleAP
    methods
        function data = unpack(obj, package)
            data = package.data;
            % update state
            obj.state.package = package;
            obj.state.data    = data;
        end
        
        function package = packup(obj, data)
            if numel(data) == 1
                package = DataPackage( ...
                    Tensor(data{1}).get(), obj.dsample, obj.parent.taxis);
            else
                try
                    data = cat(obj.dsample + double(obj.parent.taxis) + 1, data{:});
                    package = DataPackage( ...
                        Tensor(data).get(), obj.dsample, obj.parent.taxis);
                catch
                    package = cellfun( ...
                        @(d) DataPackage(Tensor(d).get(), obj.dsample, obj.parent.taxis), ...
                        data, 'UniformOutput', false);
                end
            end
            
            obj.state.package = package;
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
