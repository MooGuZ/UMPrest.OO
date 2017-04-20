classdef DistVar < Objective
    methods
        function value = evaluate(obj, data)
            if not(exist('data', 'var'))
                data = obj.getdata();
            end
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            value = obj.scale * sum(vec(bsxfun(@minus, exp(data), mu).^2)) / n;
            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
        
        function d = delta(obj, data)
            if not(exist('data', 'var'))
                data = obj.getdata();
            end
            mu = mean(exp(data), 2);
            n  = size(data, 2);
            d  = 2 * obj.scale * (n - 1) / n * bsxfun(@minus, exp(data), mu) .* exp(data);
        end
    end
    
    methods
        function data = getdata(obj)
            switch class(obj.host)
              case {'UnitAP'}
                data = obj.host.datarcd.fetch(-1);
              case {'HyperParam'}
                data = obj.host.get();
              otherwise
                error('BUG HERE');
            end
        end
    end
    
    methods
        function obj = DistVar(host)
            obj.host = host;
        end
    end
    
    properties
        host, scale = 1
    end
    methods
        function set.host(obj, value)
            switch class(value)
              case {'HyperParam'}
                obj.host = value;
                obj.host.prior = obj;
                
              case {'UnitAP'}
                obj.host = value;
                obj.host.prior = obj;
                obj.host.recdata = true;
                
              otherwise
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end