classdef DataPackage < Package
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = DataPackage(data, dsample, taxis)
            obj.dsample = dsample;
            obj.taxis   = taxis;
            % combine higher dimension into batch-axis if necessary
            batchUnitDim = dsample + double(taxis);
            if nndims(data) > batchUnitDim
                obj.data = vec(data, batchUnitDim, 'back');
            else
                obj.data = data;
            end
        end
    end
    
    methods
        function obj = vectorize(obj)
            if obj.dsample ~= 1
                if obj.taxis
                    obj.data = reshape(obj.data, ...
                        [prod(obj.smpsize), obj.nframe, obj.batchsize]);
                else
                    obj.data = reshape(obj.data, [prod(obj.smpsize), obj.nsample]);
                end
            end
            obj.dsample = 1;
        end
        
        function obj = reshape(obj, shape)
            if obj.taxis
                obj.data = reshape(obj.data, [shape, obj.nframe, obj.batchsize]);
            else
                obj.data = reshape(obj.data, [shape, obj.nsample]);
            end
            obj.dsample = numel(shape);
        end
        
        function obj = tconcate(obj)
            if obj.batchsize > 1 && obj.taxis
                obj.data = expanddim(obj.data, obj.dsample + 1);
            end
        end
        
        function obj = tcombine(obj)
            if obj.taxis
                obj.dsample = obj.dsample + 1;
                obj.taxis   = false;
            end
        end
        
        function obj = tsplit(obj)
            if not(obj.taxis) && obj.dsample > 0
                obj.dsample = obj.dsample - 1;
                obj.taxis   = true;
            end
        end
        
        function obj = dot(obj, mask)
            obj.data = bsxfun(@times, obj.data, mask);
        end
        
        function obj = treverse(obj)
            if obj.taxis
                obj.data = sltondim(obj.data, obj.dsample + 1, obj.nframe : -1 : 1);
            end
        end
        
        function obj = tselectRandom(obj, n)
            if obj.taxis && obj.nframe >= n
                obj.data = sltondim(obj.data, obj.dsample + 1, randi(obj.nframe - n, 1) + (1:n));
            else
                error('This operation can not be completed');
            end
        end
        
        function clone = copy(obj)
            clone = DataPackage(obj.data, obj.dsample, obj.taxis);
        end
    end
    
    methods (Static)
        function package = tcat(pkga, pkgb)
            assert(pkga.dsample == pkgb.dsample);
            assert(pkga.taxis && pkgb.taxis);
            assert(pkga.batchsize == pkgb.batchsize);
            da = pkga.data; db = pkgb.data;
            package = DataPackage(cat(pkga.dsample + 1, da, db), pkga.dsample, true);
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
    properties (SetAccess = protected)
        data, dsample, taxis
    end
    properties (Dependent, SetAccess = protected)
        smpsize, datasize
        nsample, nframe, batchsize
    end
    methods
        function value = get.smpsize(obj)
            value = size(obj.data);
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
            value = size(obj.data);
            if numel(value) == ndim
                return
            elseif numel(value) < ndim
                value = [value, ones(1, ndim - numel(value))];
            else
                error('BUG HERE');
            end
        end
        
        function value = get.nsample(obj)
            value = size(obj.data, obj.dsample + 1) * size(obj.data, obj.dsample + 2);
        end
        
        function value = get.nframe(obj)
            if obj.taxis
                value = size(obj.data, obj.dsample + 1);
            else
                value = 1;
            end
        end
        
        function value = get.batchsize(obj)
            if obj.taxis
                value = size(obj.data, obj.dsample + 2);
            else
                value = size(obj.data, obj.dsample + 1);
            end
        end
    end
end

