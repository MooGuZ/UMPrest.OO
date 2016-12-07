classdef GenerativeUnit < Unit
    methods
        function varargout = forward(obj, varargin)
            if isempty(varargin)
                ipackage = arrayfun(@pop, obj.I, 'UniformOutput', false);
            else
                ipackage = varargin;
            end
            varargout = cell(1, nargout);
            if isa(ipackage{1}, 'DataPackage')
                [varargout{:}] = obj.infer(ipackage{:});
            else
                [varargout{:}] = obj.kernel.backward(ipackage{:});
            end
        end
        
        function varargout = backward(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.kernel.forward(varargin{:});
        end
        
        function init(obj, block)
            obj.kernel = block;
            % setup I/O access points
            obj.I = cell2array(arrayfun( ...
                @(ap) GhostAP(obj, ap), obj.kernel.O, 'UniformOutput', false));
            obj.O = cell2array(arrayfun( ...
                @(ap) GhostAP(obj, ap), obj.kernel.I, 'UniformOutput', false));
            % TODO: prevent modification of the kernel
            % kernel.freeze();
        end
        
        function varargout = infer(obj, varargin)
            outsize = cellfun(@size, varargin, 'UniformOutput', false);
            insize  = cell(1, numel(obj.I));
            [insize{:}] = obj.kernel.sizeOut2In(outsize{:}); % TODO: define sizeOut2In/sizeIn2Out in Model
            x = randn(sum(cellfun(@prod, insize)), 1);
            x = OptimLib.minimize( ...
                @obj.objfunc, x, OptimLib.config('default'), varargin, insize);
            if isscalar(insize)
                varargout = {reshape(x, insize{1})};
            else
                index = [0, cumsum(cellfun(@prod, insize))];
                varargout = arrayfun( ...
                    @(i) reshape(x(index(i) + 1 : index(i + 1)), insize{i}), ...
                    1 : numel(index) - 1, 'UniformOutput', false);
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
            value = obj.likelihood.evaluate(dataGet{:}, dataOut{:}); % TODO: define LIKELIHOOD in class
            % add priors to objective value
            for i = 1 : numel(obj.I)
                for j = 1 : numel(obj.I(i).prior)
                    value = value + obj.I(i).prior(j).evaluate(data{i});
                end
            end
            % deal with gpuArray
            if isa(value, 'gpuArray')
                value = gather(value);
            end
            % calculate gradient
            if nargout > 1
                grad = cell(1, numel(obj.I));
                [grad{:}] = ...
                    obj.delta(obj.likelihood.delta(dataGet{:}, dataOut{:}), false);
                for i = 1 : numel(obj.I)
                    for j = 1 : numel(obj.I(i).prior)
                        grad{i} = grad{i} + obj.I(i).prior(j).delta(data{i});
                    end
                end
                if isscalar(grad)
                    grad = vec(grad{:});
                else
                    grad = cellfun(@(x) vec(x)', grad, 'UniformOutput', false);
                    grad = [grad{:}]';
                end
            end
        end
    end
    
    properties (SetAccess = protected)
        kernel
    end
    methods
        function set.kernel(obj, value)
            assert(isa(value, 'Interface'), 'ILLEGAL OPERATION');
            obj.kernel = value;
        end
    end
end
