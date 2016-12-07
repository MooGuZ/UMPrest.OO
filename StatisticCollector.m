classdef StatisticCollector < handle
    methods
        function commit(obj, data)
            % assert(obj.status, 'ApplicationError:Statistics', ...
            %     'Statistics module has not been initialized.');
            if obj.frozen
                warning('COMMIT TO FROZEN UNIT, IGNORED');
                return
            else
                % check size of input data
                datasize = size(data);
                try
                    if any(datasize(1 : obj.dsample) ~= obj.smpsize)
                        warning('Data dimension %s mismatch for statistics unit size %s', ...
                            mat2str(datasize), mat2str(obj.smpsize));
                        return
                    end
                catch ME
                    if not(strcmp(ME.identifier, 'UMPrest:UseBeforeInit'))
                        throw(ME);
                    end
                end
                
                % calculate statistics
                data = vec(data, obj.dsample, 'back');
                
                obj.statinfo.sum  = obj.statinfo.sum + sum(data, obj.dsample + 1);
                obj.statinfo.sum2 = obj.statinfo.sum2 + sum(data.^2, obj.dsample + 1);
                
                data = vec(data, obj.dsample, 'front');
                
                obj.statinfo.covmat = obj.statinfo.covmat + data * data';
                
                obj.count = obj.count + size(data, 2);
                obj.ncommit = obj.ncommit + 1;
                
                % clear cache if necessary
                if not(isempty(obj.cache))
                    obj.cache = containers.Map();
                end
            end
        end
        
        function s = fetch(obj, targetSize)
            % assert(obj.status, 'RuntimeError:Statistics', ...
            %     'STATGET cannot applied when statistic module is off.');
            
            if obj.count < 1
                s = struct( ...
                    'count',  0, ...
                    'sum',    0, ...
                    'sum2',   0, ...
                    'mean',   0, ...
                    'std',    1, ...
                    'covmat', eye(prod(targetSize)));
                return
            end
            
            if not(exist('targetSize', 'var'))
                targetSize = obj.smpsize;
            else
                assert(numel(targetSize) == obj.dsample, 'RuntimeError:Statistics', ...
                    'Provided size information [%s] has wrong dimension.', ...
                    mat2str(targetSize));
                assert(all(targetSize <= obj.smpsize), 'RuntimeError:Statistics', ...
                    'Provided size information [%s] exceed boundary of units.');
            end

            keyOfCache = mat2str(targetSize);
            if obj.cache.isKey(keyOfCache)
                s = obj.cache(keyOfCache);
            else
                if all(targetSize == obj.smpsize)
                    sinfo = obj.statinfo;
                    sinfo.count = obj.count;
                else
                    filter = ones(obj.smpsize - targetSize + 1);
                    
                    sinfo = struct();
                    sinfo.count = obj.count * numel(filter);
                    sinfo.sum   = convn(obj.statinfo.sum, filter, 'valid');
                    sinfo.sum2  = convn(obj.statinfo.sum2, filter, 'valid');
                    
                    sinfo.covmat = 0;
                    % pattern of patch index
                    pattern = patchidx(obj.smpsize, targetSize) - 1;
                    % index of first element of each patch
                    elindex = patchidx(obj.smpsize, size(filter));
                    % cumulate covariance matrix
                    for i = 1 : numel(elindex)
                        index = pattern(:) + elindex(i);
                        sinfo.covmat = sinfo.covmat + obj.statinfo.covmat(index, index);
                    end
                end
                
                s = struct( ...
                    'count', sinfo.count, ...
                    'sum',   sinfo.sum, ...
                    'sum2',  sinfo.sum2);
                s.mean   = sinfo.sum / sinfo.count;
                s.std    = sqrt(sinfo.sum2 / sinfo.count - s.mean.^2);
                s.covmat = sinfo.covmat / sinfo.count - s.mean(:) * s.mean(:)';
                
                obj.cache(keyOfCache) = s;
            end
        end
        
        function freeze(obj)
            obj.frozen = true;
        end
    end

    methods
        function obj = StatisticCollector(n)
            obj.dsample  = n;
            obj.frozen   = false;
            obj.count    = 0;
            obj.ncommit  = 0;
            obj.cache    = containers.Map( ...
                'KeyType',   'char', ...
                'ValueType', 'any');
            obj.statinfo = struct( ...
                'sum',    0, ...
                'sum2',   0, ...
                'covmat', 0);
        end
    end
    
    properties (SetAccess = protected)
        dsample, statinfo, cache, count, ncommit, frozen
    end
    methods
        function set.dsample(obj, value)
            assert(MathLib.isinteger(value) && value > 0);
            obj.dsample = value;
        end
    end

    properties (Dependent)
        smpsize
    end
    methods
        function value = get.smpsize(obj)
            assert(obj.count > 0, 'UMPrest:UseBeforeInit', ...
                'This information is unavailable at this time');
            value = size(obj.statinfo.sum);
            value = value(1 : obj.dsample);
        end
    end
end
