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
                    'numDownStep',  param.get('numDecline',   3e4), ...
                    'initStepSize', param.get('initStep',     UMPrest.parameter.get('initStep')), ...
                    'minStepRatio', param.get('minStepRatio', 1e-4));
                
              case {'adapt'}
                conf = struct( ...
                    'method',     method, ...
                    'step',       [], ...
                    'maxStep',    [], ...
                    'maxScale',   param.get('maxScale',   30), ...
                    'upFactor',   param.get('upFactor',   1.02), ...
                    'downFactor', param.get('downFactor', 0.95), ...
                    'targetETA',  param.get('targetETA',  1e-2));
                
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
        
        function conf = adapt(grad, conf)
            if isempty(conf.step)
                conf.step = min(conf.targetETA / max(abs(grad(:))), 1e2);
                conf.maxStep = conf.step * conf.maxScale;
%                 fprintf('step init to %.2e (MAX:%.2e)\n', conf.step, conf.maxStep);
            else
                factor = max(abs(grad(:))) * conf.step / conf.targetETA;
%                 fprintf('Factor (MAX) %.2e (MEAN) %.2e : ', factor, ...
%                     mean(abs(grad(:))) * conf.step / conf.targetETA);
                if factor >= 100
%                     fprintf('step decrease from %.2e ', conf.step);
                    conf.step = conf.step / factor;
%                     fprintf('to %.2e\n', conf.step);
                elseif factor >= 10
%                     fprintf('step decrease from %.2e ', conf.step);
                    conf.step = conf.step / 2;
%                     fprintf('to %.2e\n', conf.step);
                elseif factor >= 1
%                     fprintf('step decrease from %.2e ', conf.step);
                    conf.step = conf.step * conf.downFactor;
%                     fprintf('to %.2e\n', conf.step);
                else
%                     fprintf('step increase from %.2e ', conf.step);
                    conf.step = conf.step * conf.upFactor;
%                     fprintf('to %.2e\n', conf.step);
                    if conf.step >= conf.maxStep
%                         fprintf('Adjust targetETA from %.2e ', conf.targetETA);
                        conf.targetETA = conf.targetETA / conf.maxScale;
%                         fprintf('to %.2e\n', conf.targetETA);
%                         fprintf('Adjust maxStep from %.2e ', conf.maxStep);
                        conf.maxStep = conf.maxStep * conf.maxScale;
%                         fprintf('to %.2e\n', conf.maxStep);
                    end
                end
            end
        end
        
        function step = assign()
            step = UMPrest.parameter.buffer.get('assignedStep');
        end
    end
end
