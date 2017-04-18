classdef DatasetAP < AccessPoint
    methods
        function data = unpack(~, package)
            data = package.data;
            % obj.packagercd = package;
        end
        
        function package = packup(obj, data)
        % NOTE: this function may return cell of packages instead of a single package
            if numel(data) == 1
                package = DataPackage( ...
                    Tensor(data{1}).get(), obj.dsample, obj.taxis);
                % hide temporal axis
                if obj.hideTAxis
                    package.tcombine();
                end
                % % record package
                % obj.packagercd = package;
            else
                try
                    data = cat(obj.dsample + double(obj.taxis) + 1, data{:});
                    % if error-free create data package
                    package = DataPackage( ...
                        Tensor(data).get(), obj.dsample, obj.taxis);
                    % hide temporal axis
                    if obj.hideTAxis
                        package.tcombine();
                    end
                    % % record package
                    % obj.packagercd = package;
                catch
                    if obj.hideTAxis
                        package = cellfun( @(d) DataPackage( ...
                            Tensor(d).get(), obj.dsample, obj.taxis).tcombine(), ...
                            data, 'UniformOutput', false);
                    else
                        package = cellfun( ...
                            @(d) DataPackage(Tensor(d).get(), obj.dsample, obj.taxis), ...
                            data, 'UniformOutput', false);
                    end
                    % obj.packagercd = package{end};
                end
            end
        end
    end
    
    methods
        function obj = DatasetAP(parent, dsample, taxis)
            obj.parent  = parent;
            obj.dsample = dsample;
            obj.taxis   = taxis;
            obj.cache   = PackageContainer();
        end
    end
    
    properties (SetAccess = protected)
        parent  % handle of a SimpleUnit, the host of this AccessPoint
        dsample % dimension of data pass through this AccessPoint
        taxis   % indicator of temporal axes
        cache   % a queue containing all unprocessed packages
    end
    properties
        hideTAxis = false % option for hide temporal axis when output
    end
    methods
        function set.parent(obj, value)
            % assert(isa(value, 'Dataset'), 'ILLEGAL OPERATION');
            obj.parent = value;
        end
        
        function set.dsample(obj, value)
            assert(MathLib.isinteger(value) && value > 0);
            obj.dsample = value;
        end
        
        function set.taxis(obj, value)
            assert(islogical(value));
            obj.taxis = value;
        end
        
        function set.hideTAxis(obj, value)
            assert(islogical(value));
            obj.hideTAxis = value;
        end
    end
end
