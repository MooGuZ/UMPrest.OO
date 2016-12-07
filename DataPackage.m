classdef DataPackage < Package
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = DataPackage(data, dsample, taxis)
            if nndims(data) > dsample + double(taxis) + 1
                data = vec(data, dsample + double(taxis) + 1, 'back');
            end
            obj.X       = Tensor(data);
            obj.dsample = dsample;
            obj.taxis   = taxis;
        end
    end
    
    methods
        function vectorize(obj)
            dsize = size(obj.X);
            if numel(dsize) >= obj.dsample
                obj.X.reshape([prod(dsize(1 : obj.dsample)), ...
                    dsize(obj.dsample + 1 : end)]);
            else
                obj.X.reshape(prod(dsize), 1);
            end
            obj.dsample = 1;
        end
    end
    
    methods (Static)
        function dpkg = create(data, dsample, taxis)
            if iscell(data)
                try
                    data = cat(dsample + double(taxis) + 1, data{:});
                    dpkg = DataPackage(data, dsample, taxis);
                catch
                    dpkg = cell2array(cellfun( ...
                        @(d) DataPackage(d, dsample, taxis), data, ...
                        'UniformOutput', false));
                end
            else
                dpkg = DataPackage(data, dsample, taxis);
            end
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (SetAccess = private)
        dsample, taxis
    end
    properties (Access = private)
        X
    end
    properties (Dependent, SetAccess = protected)
        data, szsample, datasize
        nsample, nframe, nsequence
    end
    properties
        info % TBC: reserve field for future usage
    end
    methods
        function value = get.data(obj)
            value = obj.X.get();
        end
        function set.data(obj, value)
            obj.X.set(value);
        end
        
        function value = get.szsample(obj)
            value = size(obj.X);
            if numel(value) == obj.dsample
                return
            elseif numel(value) < obj.dsample
                value = [value, ones(1, obj.dsample - numel(value))];
            else
                value = value(1 : obj.dsample);
            end
        end
        
        function value = get.datasize(obj)
            ndim = obj.dsample + double(obj.taxis) + 1;
            value = size(obj.X);
            if numel(value) == ndim
                return
            elseif numel(value) < ndim
                value = [value, ones(1, ndim - numel(value))];
            else
                error('BUG HERE');
            end
        end
        
        function value = get.nsample(obj)
            value = size(obj.X, obj.dsample + 1) * size(obj.X, obj.dsample + 2);
        end
        
        function value = get.nframe(obj)
            if obj.taxis
                value = size(obj.X, obj.dsample + 1);
            else
                value = 1;
            end
        end
        
        function value = get.nsequence(obj)
            if obj.taxis
                value = size(obj.X, obj.dsample + 2);
            else
                value = size(obj.X, obj.dsample + 1);
            end
        end
    end
end

