classdef KeepEnergy < Prior
    methods
        function value = evalproc(obj, data)
            data  = obj.format(data);
            n     = size(data, 2);
            m     = bsxfun(@minus, data, mean(data, 2));
            value = ((m(:)' * m(:)) / n - obj.targetE).^2;
        end
        
        function d = deltaproc(obj, data)
            [data, shape] = obj.format(data);
            n = size(data, 2);
            m = bsxfun(@minus, data, mean(data, 2));
            d = 4 / n * ((m(:)' * m(:)) / n - obj.targetE) * m;
            d = reshape(d, shape);
        end
    end
    
    methods
        function obj = KeepEnergy(host, targetE, varargin)
            obj@Prior(host, varargin{:});
            obj.targetE = targetE;
        end
    end
    
    properties
        targetE
    end
    methods
        function set.targetE(obj, value)
            assert(value > 0, 'ILLEGAL ENERGY VALUE');
            obj.targetE = value;
        end
    end
end
