classdef SizePackage < Package
    properties
        data, dsample, taxis
    end
    methods
        function obj = SizePackage(data, dsample, taxis)
            obj.data    = data;
            obj.dsample = dsample;
            obj.taxis   = taxis;
            ndim = obj.dsample + double(obj.taxis) + 1;
            if numel(obj.data) == ndim
                return
            elseif numel(obj.data) < ndim
                obj.data = [obj.data, ones(1, ndim - numel(obj.data))];
            else
                warning('PROVIDED SIZE INFO IS NOT STANDARD');
                obj.data = [obj.data(1 : ndim - 1), prod(obj.data(ndim : end))];
            end
        end
    end
end