classdef Entropy < Prior
    methods
        function value = evalproc(obj, data)
            data  = obj.format(data);
            value = log(det(data * data'));
        end
        
        function d = deltaproc(obj, data)
            [data, shape] = obj.format(data);
            d = reshape(2 * ((data * data') \ data), shape);
        end
    end
    
    methods
        function [data, shape] = format(obj, data)
            shape = size(data);
            if obj.host.expandable
                dim = obj.host.dsample + obj.host.parent.pkginfo.dexpand;
            else
                dim = obj.host.dsample;
            end
            data = vec(data, dim, 'both');
        end
    end
    
    methods
        function obj = Entropy(host, varargin)
            obj@Prior(host, varargin{:});
        end
    end
end
