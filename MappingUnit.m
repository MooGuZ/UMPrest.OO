classdef MappingUnit < EvolvingUnit
    % ======================= DATA PROCESSING =======================
    methods
        function varargout = forwardOperation(obj, varargin)
            varargout = cell(1, nargout);
            switch obj.apshare.class
              case {'DataPackage'}
                [varargout{:}] = obj.process(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeIn2Out(varargin{:});
                
              case {'ErrorPackage'}
                error('UMPrest:RuntimeError', 'This operation is not supported!');
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function varargout = backwardOperation(obj, varargin)
            varargout = cell(1, nargout);
            switch obj.apshare.class
              case {'DataPackage'}
                [varargout{:}] = obj.invproc(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeOut2In(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = obj.delta(varargin{:});
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
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
                    grad = vec(grad{1});
                else
                    grad = cellfun(@(x) x(:)', grad, 'UniformOutput', false);
                    grad = [grad{:}]';
                end
            end
        end
    end
    
    % ======================= EVOLVING LOGIC =======================
    methods
        function learn(obj, ipackage, opackage)
            if not(isempty(obj.likelihood))
                obj.backward(obj.likelihood.delta(obj.forward(ipackage), opackage));
                obj.update();
            else
                warning('UMPrest:RuntimeError', ...
                        'Learning process is aborded, likelihood is unset.');
            end
        end
    end
    
    methods (Abstract)
        data = process(obj, data)
        d    = delta(obj, d)
        outsize = sizeIn2Out(obj, insize)
        insize  = sizeOut2In(obj, outsize)
    end
end
