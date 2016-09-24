classdef StatisticTransform < handle
    methods
        function opackage = forward(obj, ipackage)
            opackage = DataPackage(obj.transform(ipackage.data), 1, ipackage.taxis);
            opackage.info.statrans = struct( ...
                'timestamp', obj.cache('timestamp'), ...
                'inputSize', ipackage.szsample);
        end
        
        function datapkg = backward(obj, datapkg)
            if datapkg.info.statrans.timestamp == obj.cache('timestamp')
                kernel = obj.getKernel(datapkg.info.statrans.inputSize);
                datapkg.data = obj.compose(datapkg.data, kernel);
            end
        end
    end
    
    methods    
        function data = transform(obj, data)
            kernel = obj.getKernel(size(data));
            if obj.status
                switch lower(obj.mode)
                    case {'debias'}
                        data = bsxfun(@minus, data, kernel.offset);
                        
                    case {'normalize'}
                        data = bsxfun(@minus, data, kernel.offset);
                        data = bsxfun(@rdivide, data, kernel.scale);
                        
                    case {'whiten'}
                        data = bsxfun(@minus, data, kernel.offset);
                        data = MathLib.vec(data, obj.unitdim, 'front');
                        data = mtimesnd(kernel.encode, data);
                        
                    otherwise
                        error('UMPrest:ArgumentError', 'Unrecognized coding mode : %s', ...
                            upper(obj.mode));
                end
            end
        end
        
        function data = compose(obj, data, kernel)
            if obj.status
                switch lower(obj.mode)
                    case {'debias'}
                        data = bsxfun(@plus, data, kernel.offset);
                        
                    case {'normalize'}
                        data = bsxfun(@times, data, kernel.scale);
                        data = bsxfun(@plus, data, kernel.offset);
                        
                    case {'whiten'}
                        data = mtimesnd(kernel.decode, data);
                        temp = size(data);
                        data = reshape(data, [kernel.insize, temp(2:end)]);
                        data = bsxfun(@plus, data, kernel.offset);
                        
                    otherwise
                        error('UMPrest:ArgumentError', 'Unrecognized coding mode : %s', ...
                            upper(obj.mode));
                end
            end
        end
        
%         function d = errprop(~, d)
%             warning('ERRPROP should not be called in StatisticTransform');
%         end
    end
    
    methods
        function tof = cacheOutdated(obj)
            if obj.stat.status
                if isempty(obj.cache)
                    obj.refreshCache();
                    tof = false;
                else
                    tof = (obj.cache('timestamp') ~= obj.stat.count);
                end
            else
                tof = false;
            end
        end
        
        function value = unitdim(obj)
            if obj.stat.status
                value = obj.stat.unitdim;
            else
                error('UMPrest:RuntimeError', ...
                    'UNITDIM is unavailable when StatisticCollector is turned off');
            end
        end
        
        function kernel = getKernel(obj, inputSize)
            assert(numel(inputSize) >= obj.unitdim, 'UMPrest:RuntimeError', ...
                'Input data does not match minimum dimension requirement');
            inputSize = inputSize(1 : obj.unitdim);
            
            if obj.cacheOutdated()
                obj.refreshCache();
            end
            
            if obj.cache.isKey(mat2str(inputSize))
                kernel = obj.cache(mat2str(inputSize));
            else
                kernel = obj.updateCache(inputSize);
            end
        end
        
        function refreshCache(obj)
            if obj.status
                obj.cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
                obj.cache('timestamp') = obj.stat.count;
            else
                obj.cache = [];
            end
        end
        
        function kernel = updateCache(obj, inputSize)
            sinfo = obj.stat.fetch(inputSize);
            
            kernel.sizein = inputSize;
            kernel.offset = sinfo.mean;
            kernel.scale  = sinfo.std;
            
            [vec, val] = eig(sinfo.covmat);
            [val, idx] = sort(diag(val), 'descend');
            vec = vec(:, idx);
            npixel = sinfo.count * numel(sinfo.sum);
            pixelvar = (sum(sinfo.sum2(:)) / npixel) ...
                - (sum(sinfo.sum(:)) / npixel).^2;
            % >>> Cadieu & Olshausen's method <<<
            % threshold = pixelvar * obj.whitenCutoffRatio;
            % kernel.sizeout = sum(val > threshold);
            % >>> Method based on percentage of Power <<<
            % - practise shows '0.95' is good point to choose, which is
            % - balance for performance and storage sufficience.
            cumval = cumsum(val);
            kernel.sizeout = sum((cumval / cumval(end)) < obj.whitenCutoffRatio);
            dim = kernel.sizeout;
            rodim = sum(val > pixelvar * obj.whitenRolloffFactor);
            kernel.pixelweight = ...
                MathLib.rolloff(dim, rodim) / obj.whitenNoiseRatio;
            val = val(1 : dim);
            vec = vec(:, 1 : dim);
            
            kernel.encode    = diag(1 ./ sqrt(val)) * vec';
            kernel.decode    = vec * diag(sqrt(val));
            kernel.zerophase = vec * diag(1 ./ sqrt(val)) * vec';
            
            obj.cache(mat2str(inputSize)) = kernel;
        end
    end
    
    methods
        function obj = StatisticTransform(stat, mode)
            obj.stat = stat;
            obj.mode = mode;
        end
    end
    
    properties
        whitenCutoffRatio   = 0.99;
        whitenRolloffFactor = 8;
        whitenNoiseRatio    = 0.01;
    end
    
    properties
        mode
    end
    methods
        function set.mode(obj, value)
            validatestring(value, {'off', 'debias', 'normalize', 'whiten'});
            obj.mode = value;
        end
    end
    
    properties (SetAccess = private, Hidden)
        stat, cache
    end
    methods
        function set.stat(obj, value)
            assert(isa(value, 'StatisticCollector'));
            obj.stat = value;
        end
    end
    
    properties (Dependent)
        status
    end
    methods
        function value = get.status(obj)
            if obj.stat.status
                value = not(strcmpi(obj.mode, 'off'));
            else
                value = false;
            end                
        end
    end
end
