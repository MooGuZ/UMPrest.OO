classdef StatisticTransform < SISOUnit & BidirectionOperation
    methods    
        function data = dataproc(obj, data)
            if not(obj.outsourced)
                obj.stat.commit(data);
            end
            
            kernel = obj.getKernel(size(data));
            switch obj.mode
                case {'debias'}
                    data = bsxfun(@minus, data, kernel.offset);
                    
                case {'normalize'}
                    data = bsxfun(@minus, data, kernel.offset);
                    data = bsxfun(@rdivide, data, kernel.scale);
                    
                case {'whiten'}
                    data = bsxfun(@minus, data, kernel.offset);
                    data = vec(data, obj.dsample, 'front');
                    data = mtimesnd(kernel.encode, data);
                    
                otherwise
                    error('UMPrest:ArgumentError', 'Unrecognized coding mode : %s', ...
                        upper(obj.mode));
            end
        end
        
        function data = datainvp(obj, data)
            kernel = obj.getKernel();
            switch obj.mode
                case {'debias'}
                    data = bsxfun(@plus, data, kernel.offset);
                    
                case {'normalize'}
                    data = bsxfun(@times, data, kernel.scale);
                    data = bsxfun(@plus, data, kernel.offset);
                    
                case {'whiten'}
                    data = mtimesnd(kernel.decode, data);
                    temp = size(data);
                    data = reshape(data, [kernel.sizein, temp(2:end)]);
                    data = bsxfun(@plus, data, kernel.offset);
                    
                otherwise
                    error('UMPrest:ArgumentError', 'Unrecognized coding mode : %s', ...
                        upper(obj.mode));
            end
        end
        
        function error = deltaproc(obj, error)
            kernel = obj.getKernel();
            switch obj.mode
                case {'debias'}
                    % DO NOTHING
                    
                case {'normalize'}
                    error = bsxfun(@rdivide, error, kernel.scale);
                    
                case {'whiten'}
                    error = mtimesnd(kernel.encode', error);
                    temp  = size(error);
                    error = reshape(data, [kernel.sizein, temp(2:end)]);
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
        
        function error = deltainvp(obj, error)
            kernel = obj.getKernel();
            switch obj.mode
                case {'debias'}
                    % DO NOTHING
                    
                case {'normalize'}
                    error = bsxfun(@times, error, kernel.scale);
                    
                case {'whiten'}
                    error = mtimesnd(kernel.decode', vec(error, obj.dsample, 'front'));
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
        
        function sizeout = sizeIn2Out(obj, sizein)
            switch obj.mode
                case {'debias', 'normalize'}
                    sizeout = sizein;
                    
                case {'whiten'}
                    numelSample = prod(sizein(1 : obj.dsample));
                    sizeout = [ceil(obj.whitenCompressRatio * numelSample), ...
                        sizein(obj.dsample + 1 : end)];
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
        
        function sizein = sizeOut2In(obj, sizeout)
            switch obj.mode
                case {'debias', 'normalize'}
                    sizein = sizeout;
                    
                case {'whiten'}
                    kernel = obj.getKernel();
                    assert(sizeout(1) == kernel.sizeout, 'ILLEGAL DATA SHAPE');
                    sizein = [kernel.sizein, sizeout(2 : end)];
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
    end
    
    methods
        function tof = cacheOutdated(obj)
            if isempty(obj.cache)
                obj.refreshCache();
            end
            
            if obj.frozen
                tof = false;
            else
                tof = (obj.stat.count - obj.cache('timestamp') >= obj.updateInterval);
            end
        end
        
        function kernel = getKernel(obj, inputSize)
            if exist('inputSize', 'var')
                assert(numel(inputSize) >= obj.dsample, 'UMPrest:RuntimeError', ...
                    'Input data does not match minimum dimension requirement');
                inputSize = inputSize(1 : obj.dsample);
            else
                assert(not(isempty(obj.lastSampleSize)), 'NOT INITIALIZED');
                inputSize = obj.lastSampleSize;
            end
            
            if obj.cacheOutdated()
                obj.refreshCache();
            end
            
            if obj.cache.isKey(mat2str(inputSize))
                kernel = obj.cache(mat2str(inputSize));
            else
                kernel = obj.updateCache(inputSize);
            end
            
            obj.lastSampleSize = inputSize;
        end
        
        function refreshCache(obj)
            obj.cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.cache('timestamp') = obj.stat.count;
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
            % >>> Method use quantity ratio
            % kernel.sizeout = ceil(prod(kernel.sizein(1 : obj.dsample)) ...
            %     * obj.whitenCompressRatio);
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
        function obj = StatisticTransform(mode, arg, varargin)
            obj.mode = mode;
            if isa(arg, 'StatisticCollector')
                obj.stat = arg;
                obj.outsourced = true;
            else
                assert(isscalar(arg) && MathLib.isinteger(arg) && arg > 0, ...
                    'ArgumentError', ...
                    'Illegal argument, unit dimension or statistic collector required');
                obj.stat = StatisticCollector(arg);
                obj.outsourced = false;
            end
            obj.I = {UnitAP(obj, obj.dsample)};
            switch obj.mode
                case {'debias', 'normalize'}
                    obj.O = {UnitAP(obj, obj.dsample)};
                    
                case {'whiten'}
                    obj.O = {UnitAP(obj, 1)};
            end
            obj = Config(varargin).apply(obj);
        end
        
        function unitdump = dump(self)
            unitdump = {'StatisticTransform', self.mode, self.stat};
        end
    end
    
    properties
        whitenCutoffRatio   = 0.99;
        whitenCompressRatio = 0.5; % TBC in parameter setup
        whitenRolloffFactor = 8;
        whitenNoiseRatio    = 0.01;
        updateInterval      = 1000;
    end
    methods
        function set.updateInterval(obj, value)
            assert(MathLib.isinteger(value) && value > 0, 'ArgumentError', ...
                'Interval of update should be a positive integer.');
            obj.updateInterval = value;
        end
    end
    
    properties (Constant)
        taxis      = false;
        expandable = true;
    end
    
    properties
        mode, frozen, lastSampleSize
    end
    methods
        function set.mode(obj, value)
            validatestring(lower(value), {'debias', 'normalize', 'whiten'});
            obj.mode = lower(value);
        end
    end
    
    properties (Dependent)
        dsample
    end
    methods
        function value = get.dsample(obj)
            value = obj.stat.dsample;
        end
    end
    
    properties (SetAccess = private, Hidden)
        stat, cache, outsourced
    end
    methods
        function set.stat(obj, value)
            assert(isa(value, 'StatisticCollector'));
            obj.stat = value;
        end
    end
end
