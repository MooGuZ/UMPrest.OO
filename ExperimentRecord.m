classdef ExperimentRecord < handle
% EXPERIMENTRECORD record experiment data and generate information as user
%   defined.

    methods
        function obj = ExperimentRecord(niter)
            obj.n   = niter;
            obj.wbh = waitbar(0, 'Experiment Start', 'WindowStyle', 'modal');
            obj.rcd = zeros(2,niter);
            obj.prcd = [];
            obj.index = 1;
        end

        function record(obj, niter, objval, param)
            if strcmpi(obj.optimizer.conf.step.mode, 'adapt')
                obj.optimizer.record(objval);
                waitbar(niter / obj.n, obj.wbh, ...
                    sprintf('ITER %05d: %.2e [STEPSIZE %.2e]', ...
                    niter, objval, obj.optimizer.conf.step.step));
            else
                waitbar(niter / obj.n, obj.wbh, ...
                    sprintf('ITER %05d: %.2e', niter, objval));
            end

            obj.rcd(:,obj.index) = [niter; objval];
            if exist('param', 'var')
                if isempty(obj.prcd)
                    obj.prcd = zeros(numel(param), obj.n);
                end
                obj.prcd(:, obj.index) = param(:);
            end

            obj.index = obj.index + 1;

            if niter >= obj.n
                obj.rcd = obj.rcd(:, 1 : obj.index-1);
                if not(isempty(obj.prcd))
                    obj.prcd = obj.prcd(:, 1 : obj.index-1);
                end
                delete(obj.wbh);
            end
        end

        function draw(obj)
            plot(obj.rcd(1,:), obj.rcd(2,:), '.-');
            yscale('log'), grid on
            xlabel('ITERATION');
            ylabel('LOSS FUNCTION (LOG)');
        end
    end
    properties
        n
        wbh
        rcd
        prcd
        index
    end
    properties (Constant)
        optimizer = UMPrest.getGlobalOptimizer()
    end
end