classdef MappingUnit < EvolvingUnit
    % ======================= DATA PROCESSING =======================
    % methods
    %     function y = transform(obj, x)
    %         y = obj.process(x);
    %     end
    %     
    %     function x = compose(obj, y)
    %         x = obj.infer(y);
    %     end
    % end
    %     
    % methods (Abstract)
    %     y = process(obj, x)
    % end
    
    methods
        function varargout = invproc(obj, varargin)
            outsize = cellfun(@size, varargin, 'UniformOutput', false);
            insize  = cell(1, numel(obj.I));
            [insize{:}] = obj.sizeOut2In(outsize{:});
            x = randn(sum(cellfun(@prod, insize)), 1);
            x = OptimLib.minimize( ...
                @obj.objfunc, x, OptimLib.config('default'), varargin, insize);
            if isscalar(insize)
                varargout{1} = reshape(x, insize{1});
            else
                index = [0, cumsum(cellfun(@prod, insize))];
                varargout = cell(1, numel(insize));
                for i = 1 : numel(index) - 1
                    varargout{i} = ...
                        reshape(x(index(i) + 1 : index(i + 1)), insize{i});
                end
            end
        end
        
        function [value, grad] = objfunc(obj, dataIn, dataOut, sizeIn)
            if isscalar(obj.I)
                data = {reshape(dataIn, sizeIn{:})};
            else
                index = [0, cumsum(cellfun(@prod, sizeIn))];
                data = cell(1, numel(sizeIn));
                for i = 1 : numel(index) - 1
                    data{i} = ...
                        reshape(dataIn(index(i) + 1 : index(i + 1)), sizeIn{i});
                end
            end
            dataGet = cell(1, numel(dataOut));
            [dataGet{:}] = obj.process(data{:});
            value = obj.likelihood.evaluate(dataGet{:}, dataOut{:});
            % add priors to objective value
            for i = 1 : numel(obj.I)
                for j = 1 : numel(obj.I(i).prior)
                    value = value + obj.I(i).prior(j).evaluate(data{i});
                end
            end
            % calculate gradient
            if nargout > 1
                grad = cell(numel(obj.I), 1);
                [grad{:}] = ...
                    obj.delta(obj.likelihood.delta(dataGet{:}, dataOut{:}), false);
                for i = 1 : numel(obj.I)
                    for j = 1 : numel(obj.I(i).prior)
                        grad{i} = grad{i} + obj.I(i).prior(j).delta(data{i});
                    end
                end
                if isscalar(grad)
                    grad = MathLib.vec(grad{:});
                else
                    grad = cell2mat(cellfun(@MathLib.vec, grad, 'UniformOutput', false));
                end
            end
        end
    end
    
    % ======================= EVOLVING LOGIC =======================
    methods
        function learn(obj, ipackage, opackage)
            if not(isempty(obj.likelihood))
                obj.errprop(obj.likelihood.delta(obj.transform(ipackage), opackage));
                obj.update();
            else
                warning('UMPrest:RuntimeError', ...
                        'Learning process is aborded, likelihood is unset.');
            end
        end
    end
end
