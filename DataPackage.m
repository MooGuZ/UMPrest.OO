classdef DataPackage < Package
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = DataPackage(data, dsample, taxis)
            if nndims(data) > dsample + double(taxis) + 1
                data = vec(data, dsample + double(taxis) + 1, 'back');
            end
            obj.data    = data;
            obj.dsample = dsample;
            obj.taxis   = taxis;
        end
    end
    
    methods
        function obj = vectorize(obj)
            if obj.dsample ~= 1
                if obj.taxis
                    obj.data = reshape(obj.data, ...
                        [prod(obj.smpsize), obj.nframe, obj.nsequence]);
                else
                    obj.data = reshape(obj.data, [prod(obj.smpsize), obj.nsample]);
                end
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
    properties (SetAccess = protected)
        data, dsample, taxis
    end
    properties (Dependent, SetAccess = protected)
        smpsize, datasize
        nsample, nframe, nsequence
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
        
        function value = get.nsequence(obj)
            if obj.taxis
                value = size(obj.data, obj.dsample + 2);
            else
                value = size(obj.data, obj.dsample + 1);
            end
        end
    end
end

