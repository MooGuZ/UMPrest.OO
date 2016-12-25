classdef DatasetAP < AccessPoint
    methods
        function data = unpack(obj, package)
            data = package.data;
            obj.packagercd = package;
        end
        
        function package = packup(obj, data)
        % NOTE: this function may return cell of packages instead of a single package
            if numel(data) == 1
                package = DataPackage( ...
                    Tensor(data{1}).get(), obj.dsample, obj.parent.taxis);
                obj.packagercd = package;
            else
                try
                    data = cat(obj.dsample + double(obj.parent.taxis) + 1, data{:});
                    package = DataPackage( ...
                        Tensor(data).get(), obj.dsample, obj.parent.taxis);
                    obj.packagercd = package;
                catch
                    package = cellfun( ...
                        @(d) DataPackage(Tensor(d).get(), obj.dsample, obj.parent.taxis), ...
                        data, 'UniformOutput', false);
                    obj.packagercd = package{end};
                end
            end
        end
    end
    
    methods
        function obj = DatasetAP(parent, dsample)
            obj.parent  = parent;
            obj.dsample = dsample;
            obj.cache   = PackageContainer();
        end
    end
    
    properties (SetAccess = protected)
        parent  % handle of a SimpleUnit, the host of this AccessPoint
        dsample % dimension of data pass through this AccessPoint
    end
    properties (SetAccess = protected, Transient)
        cache   % a queue containing all unprocessed packages
    end
    properties (Access = private)
        saveprop
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
        
        function value = get.saveprop(obj)
            value.cache = obj.cache.dump();
        end
        function set.saveprop(obj, value)
            obj.cache = PackageContainer.loaddump(value.cache);
        end
    end
end
