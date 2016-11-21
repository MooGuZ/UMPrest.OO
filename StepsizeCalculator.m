classdef StepsizeCalculator < handle
    methods (Static)
        function conf = getConfig(method, varargin)
            param = Config(varargin);

            switch lower(method)
              case {'assigned'}
                conf = struct();
                
              case {'decline'}
                conf = struct( ...
                    'method',       method, ...
                    'numDownStep',  param.get('numDecline',   3e5), ...
                    'initStepSize', param.get('initStep',     UMPrest.parameter.get('initStep')), ...
                    'minStepRatio', param.get('minStepRatio', 1e-4));
                
              case {'adapt'}
                conf = struct( ...
                    'method',     method, ...
                    'step',       param.get('initStep',   UMPrest.parameter.get('initStep')), ...
                    'upFactor',   param.get('upFactor',   1.02), ...
                    'downFactor', param.get('downFactor', 0.95), ...
                    'targetETA',  param.get('targetETA',  5e-2));
                
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
        
        function [step, conf] = adapt(grad, conf)
            step   = conf.step;
            factor = max(abs(grad(:))) * step / conf.targetETA;
            if factor >= 100
                conf.step = conf.step / 8;
                step = step / factor;
            elseif factor >= 10
                conf.step = conf.step / 2;
            elseif factor >= 1
                conf.step = conf.step * conf.downFactor;
                % fprintf('Step update to %.2e\n', conf.step);
            else
                conf.step = conf.step * conf.upFactor;
                % fprintf('Step update to %.2e\n', conf.step);
            end                
        end
        
        function step = assign()
            step = UMPrest.parameter.buffer.get('assignedStep');
        end
    end
end
