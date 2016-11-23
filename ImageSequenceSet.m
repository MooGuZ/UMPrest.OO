classdef ImageSequenceSet < handle
    methods
        function varargout = next(obj, n)
            if not(exist('n', 'var')), n = 1; end
            % get data from datablock
            if obj.patchmode.status
                d = obj.db.fetch(ceil(n / obj.patchmode.patchPerSample));
                d = arrayfun(@(index) obj.getPatch(d{index}), randi(numel(d), n), ...
                    'UniformOutput', false);
            else
                d = obj.db.fetch(n);
            end
            % packup data to package
            if nargout == 0
                obj.packup(d);
            else
                varargout = cell(1, nargout);
                [varargout{:}] = obj.packup(d);
            end
        end
        
        function package = packup(obj, d)
            package = obj.data.packup(d);
            if nargout == 0
                obj.data.send(package);
            end
        end
        
        function patch = getPatch(obj, d)
            patch = randcrop(d, obj.patchmode.size);
        end
        
        function enablePatchMode(obj, conf)
            obj.patchmode = struct( ...
                'status', true, ...
                'size',   conf.pop('patchsize'), ...
                'patchPerSample', conf.pop('patchPerSample', 1));
        end
        
        function disablePatchMode(obj)
            obj.patchmode = struct('status', false);
        end
    end
    
    methods
        function obj = ImageSequenceSet(dbsource, varargin)
            conf = Config(varargin);
            if iscell(dbsource) || ischar(dbsource)
                obj.db = FileDataBlock(dbsource, ...
                    conf.pop('dataReadFcn', @videoread), ...
                    conf.pop('dataExt', '.gif'), ...
                    conf.pop('stat', StatisticCollector(obj.dsample)));
            elseif isa(dbsource, 'DataBlock')
                obj.db = dbsource;
            end
            if conf.exist('patchsize')
                obj.enablePatchMode(conf);
            else
                obj.disablePatchMode();
            end
            obj.data = DatasetAP(obj, obj.dsample);
        end
    end
    
    properties
        db, data, patchmode
    end
    properties (Constant)
        dsample = 2;
        taxis   = true;
    end
end
