classdef DistVar < Prior
    methods
        function value = evalproc(~, data)
            data  = exp(data);
            n     = size(data, 2);
            m     = bsxfun(@minus, data, mean(data, 2));
            value = m(:)' * m(:) / n;
        end
        
        function d = deltaproc(~, data)
            data = exp(data);
            n = size(data, 2);
            d = 2 / n * data .* bsxfun(@minus, data, mean(data, 2));
        end
    end
    
    methods
        function obj = DistVar(host, varargin)
            obj@Prior(host, varargin{:});
        end
    end
end