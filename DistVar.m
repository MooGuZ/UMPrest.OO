classdef DistVar < Prior
    methods
        function value = evalproc(~, data)
            mu    = mean(exp(data), 2);
            n     = size(data, 2);
            value = sum(vec(bsxfun(@minus, exp(data), mu).^2)) / n;
        end
        
        function d = deltaproc(~, data)
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            d  = 2 * (n - 1) / n * bsxfun(@minus, exp(data), mu) .* exp(data);
        end
    end
    
    methods
        function obj = DistVar(host, varargin)
            obj@Prior(host, varargin{:});
        end
    end
end