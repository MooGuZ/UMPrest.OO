classdef StepsizeCalculator < handle
    methods (Static)
        function conf = getConfig(method, varargin)
            plist = Config.parse(varargin);

            switch lower(method)
                case {'decline'}
                    conf = struct( ...
                        'method',       method, ...
                        'numDownStep',  Config.getValue(plist, 'numDownStep', 3e5), ...
                        'initStepSize', Config.getValue(plist, 'initStepSize', 1e-2), ...
                        'minStepRatio', Config.getValue(plist, 'minStepRatio', 1e-3));
                    
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
