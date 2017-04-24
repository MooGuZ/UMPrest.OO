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
        function obj = Entropy(host, varargin)
            obj@Prior(host, varargin{:});
        end
    end
end
