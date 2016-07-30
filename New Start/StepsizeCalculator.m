classdef StepsizeCalculator < handle
    methods (Static)
        function conf = getConfig(method, varargin)
            param = Config(varargin);

            switch lower(method)
                case {'decline'}
                    conf = struct( ...
                        'method',       method, ...
                        'numDownStep',  param.get('numDownStep', 3e5), ...
                        'initStepSize', param.get('initStepSize', 1e-1), ...
                        'minStepRatio', param.get('minStepRatio', 1e-4));
                    
                otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized stepsize calculating method : %s', upper(obj.method));
            end
        end
        
        function step = decline(n, conf)
            portion = n / conf.numDownStep;
            if portion < 1
                step = (1 + portion * (conf.minStepRatio - 1)) * conf.initStepSize;
            else
                step = conf.minStepRatio * conf.initStepSize;
            end
        end
    end
end
