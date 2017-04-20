classdef DistVar < Objective
    methods
        function value = evaluate(obj, data)
            if not(exist('data', 'var'))
                if isa(obj.host, 'AccessPoint')
                    data = obj.host.cache.fetch(-1).data;
                elseif isa(obj.host, 'HyperParam')
                    data = obj.host.get();
                else
                    error('ILLEGAL HOST');
                end
            end
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            value = -obj.scale * sum(vec(bsxfun(@minus, exp(data), mu).^2)) / n;
        end
        
        function d = delta(obj, data)
            if not(exist('data', 'var'))
                if isa(obj.host, 'AccessPoint')
                    data = obj.host.cache.fetch(-1).data;
                elseif isa(obj.host, 'HyperParam')
                    data = obj.host.get();
                else
                    error('ILLEGAL HOST');
                end
            end
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            d  = -2 * obj.scale * (n - 1) / n * bsxfun(@minus, exp(data), mu) .* exp(data);
        end
    end
    
    methods
        function obj = DistVar(host)
            obj.host = host;
            host.prior = obj;
        end
    end
    
    properties
        host, scale = 0.1
    end
end