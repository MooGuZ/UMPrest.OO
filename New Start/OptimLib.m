% Colllection of functions those applies optimization
classdef OptimLib < handle
    methods (Static)
        function opt = minimize(objfunc, init, conf, varargin)
            opt = minFunc(objfunc, init, conf, varargin{:});
        end
        
        function conf = config(code)
            switch lower(code)
                case {'default'}
                    conf = struct( ...
                        'Method',      'bb',  ...
                        'Display',     'off', ...
                        'MaxIter',     17,    ...
                        'MaxFunEvals', 27);
                    
                case {'debug'}
                    conf = struct( ...
                        'Method',      'bb', ...
                        'Display',     'iter', ...
                        'MaxIter',     1e2, ...
                        'MaxFunEvals', 1e3);
            end
        end
    end
end
