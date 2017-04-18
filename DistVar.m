classdef DistVar < Objective
    methods
        function value = evaluate(obj, data)
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            value = -obj.scale * sum(bsxfun(@minus, exp(data), mu).^2, 2) / n;
        end
        
        function d = delta(obj, data)
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            d  = -2 * obj.scale * (n - 1) / n * bsxfun(@minus, exp(data), mu) .* exp(data);
        end
    end
    
    properties
        scale = 0.1;
    end
end