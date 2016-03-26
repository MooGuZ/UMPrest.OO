classdef Statistics < handle
    % STATISTICS provides subclasses the ability to collecting data statistics
    % and applied linear transformations according to it through a statistic
    % coder.
    
    % MooGu Z. <hzhu@case.edu>
    % Mar 22, 2016
    
    % TODO
    % 1. Overflow of statistics cannot be avoid in current implementation, however, it
    %    should not be a problem in normal setting though.
    % 2. Always envolving would be a problem for transformation
    
    % ================= STATISTIC MANTAINER =================
    methods
        function statInit(obj, dim)
            obj.stat = struct(  ...
                'status', true, ...
                'dim',    dim,  ...
                'count',  0,    ...
                'sum',    0,    ...
                'sum2',   0,    ...
                'covmat', 0);
            
            obj.statCache = struct(   ...
                'status', 'outdated', ...
                'size',   []);
            
            obj.statCoder = struct(   ...
                'status', 'outdated', ...
                'mode',   'off',      ...
                'insize', []);
        end
        
        function statUpdate(obj, data)
            assert(obj.stat.status, 'ApplicationError:Statistics', ...
                'Statistics module has not been initialized.');
            
            data = MathLib.vec(data, obj.stat.dim, 'back');
            
            obj.stat.sum  = obj.stat.sum + sum(data, obj.stat.dim + 1);
            obj.stat.sum2 = obj.stat.sum2 + sum(data.^2, obj.stat.dim + 1);
            
            data = MathLib.vec(data, obj.stat.dim, 'front');
            
            obj.stat.covmat = obj.stat.covmat + data * data';
            obj.stat.count  = obj.stat.count + size(data, 2);
            
            % set flags of cache and coder
            obj.statCache.status = 'outdated';
            obj.statCoder.status = 'outdated';
        end
        
        function s = statGet(obj, inputSize)
            assert(obj.stat.status, 'RuntimeError:Statistics', ...
                'STATGET cannot applied when statistic module is off.');
            
            if obj.stat.count < 1
                warning('Statistic is not available at this time');
                return
            end
            
            assert(numel(inputSize) == obj.stat.dim, 'ArgumentError:Statistics', ...
                'Provided size information has wrong dimension.');
            
            assert(all(inputSize < size(obj.statUnitSize)), 'RuntimeError:Statistics', ...
                'Provided size information is unavailable for statistics');
            
            if strcmpi(obj.statCache.status, 'outdated') ...
                    || any(inputSize ~= obj.statCache.size)
                if all(inputSize == obj.statUnitSize)
                    sinfo = obj.stat;
                else
                    framesize = size(obj.stat.sum);
                    
                    filter = ones(framesize - inputSize + 1);
                    
                    sinfo = struct();
                    sinfo.count = obj.stat.count * numel(filter);
                    sinfo.sum   = convn(obj.stat.sum, filter, 'valid');
                    sinfo.sum2  = convn(obj.stat.sum2, filter, 'valid');
                    
                    sinfo.covmat = 0;
                    % pattern of patch index
                    pattern = patchidx(framesize, inputSize) - 1;
                    % index of first element of each patch
                    elindex = patchidx(framesize, size(filter));
                    % cumulate covariance matrix
                    for i = 1 : numel(elindex)
                        index = pattern(:) + elindex(i);
                        sinfo.covmat = sinfo.covmat + obj.stat.covmat(index, index);
                    end
                end
                
                % update cache
                obj.statCache.size   = inputSize;
                obj.statCache.mean   = sinfo.sum / sinfo.count;
                obj.statCache.std    = sqrt(sinfo.sum2 / sinfo.count - obj.statCache.mean.^2);
                obj.statCache.covmat = sinfo.covmat / sinfo.count ...
                    - obj.statCache.mean * obj.statCache.mean';
                obj.statCache.status = 'updated';
            end
            
            s = struct( ...
                'count',  obj.stat.count, ...
                'sum',    obj.stat.sum, ...
                'sum2',   obj.stat.sum2, ...
                'mean',   obj.statCache.mean, ...
                'std',    obj.statCache.std,  ...
                'covmat', obj.statCache.covmat);
        end
    end
    
    % ================= STATISTIC CODER =================
    methods
        function data = encode(obj, data)
            if strcmpi(obj.statCoder.status, 'outdated')
                inputSize = size(data);
                obj.statCoderUpdate(inputSize(1 : obj.stat.dim));
            end
            
            switch lower(obj.statCoder.mode)
                case {'off'}
                    
                case {'debias'}
                    data = bsxfun(@minus, data, obj.statCoder.offset);
                    
                case {'normalize'}
                    data = bsxfun(@minus, data, obj.statCoder.offset);
                    data = bsxfun(@rdivide, data, obj.statCoder.scale);
                    
                case {'whiten'}
                    data = bsxfun(@minus, data, obj.statCoder.offset);
                    data = MathLib.vec(data, obj.stat.dim, 'front');
                    data = mtimesnd(obj.statCoder.encode, data);
                    
                otherwise
                    error('ConfigError:Statistic', 'Unrecognized coding mode : %s', ...
                        upper(obj.statCoder.mode));
            end
        end
        
        function data = decode(obj, data)
            switch lower(obj.statCoder.mode)
                case {'off'}
                    
                case {'debias'}
                    data = bsxfun(@plus, data, obj.statCoder.offset);
                    
                case {'normalize'}
                    data = bsxfun(@times, data, obj.statCoder.scale);
                    data = bsxfun(@plus, data, obj.statCoder.offset);
                    
                case {'whiten'}
                    data = mtimesnd(obj.statCoder.decode, data);
                    temp = size(data);
                    data = reshape(data, [obj.statCoder.insize, temp(2:end)]);
                    
                otherwise
                    error('ConfigError:Statistic', 'Unrecognized coding mode : %s', ...
                        upper(obj.statCoder.mode));
            end
        end
        
        function statCoderUpdate(obj, inputSize)
            s = obj.statGet(inputSize);
            
            obj.statCoder.insize = inputSize;
            
            if any(strcmpi(obj.statCoder.mode, {'debias', 'normalize', 'whiten'}))
                obj.statCoder.offset = s.mean;
            end
            
            if strcmpi(obj.statCoder.mode, 'normalize')
                obj.statCoder.scale = s.std;
            end
            
            if strcmpi(obj.statCoder.mode, 'whiten')
                [vec, val] = eig(s.covmat);
                [val, idx] = sort(diag(val), 'descend');
                vec = vec(:, idx);
                
                npixel = s.count * numel(s.sum);
                pixelvar = (sum(s.sum(:)) / npixel) ...
                    - (sum(s.frmsum(:)) / npixel).^2;
                
                if isempty(obj.whitenOutDimension)
                    threshold = pixelvar * obj.whitenCutoffRatio;
                    obj.whitenOutDimension = sum(val > threshold);
                end
                
                dim = obj.whitenOutDimension;
                rodim = sum(val > pixelvar * obj.whitenRolloffFactor);
                obj.statCoder.pixelweight = ...
                    MathLib.rolloff(dim, rodim) / obj.whitenNoiseRatio;
                
                val = val(1 : dim);
                vec = vec(:, 1 : dim);
                
                obj.statCoder.encode = diag(1 ./ sqrt(val)) * vec';
                obj.statCoder.decode = vec * diag(sqrt(val));
                obj.statCoder.zerophase = vec * diag(1 ./ sqrt(val)) * vec';
            end
            
            obj.statCoder.status = 'updated';
        end
    end
    
    % ================= DYNAMIC ATTRIBUTES =================
    properties (Dependent)
        statistics
        statUnitSize
    end
    methods
        function value = get.statistics(obj)
            value = obj.stat.status;
        end
        
        function value = get.statUnitSize(obj)
            assert(obj.stat.status && obj.stat.count > 0, ...
                'This information is unavailable at this time');
            value = size(obj.stat.sum);
        end
    end
    
    % ================= CONFIGUATION =================
    properties
        whitenCutoffRatio   = 1.25;
        whitenRolloffFactor = 8;
        whitenNoiseRatio    = 0.01;
        whitenOutDimension
    end
    
    % ================= CORE DATA =================
    properties
        stat      = struct('status', false);
        statCoder = struct('mode', 'off');
        statCache
    end
end
