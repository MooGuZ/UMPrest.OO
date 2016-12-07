classdef ImageSequenceSet < Dataset
    methods
        function varargout = next(obj, n)
            if not(exist('n', 'var')), n = 1; end
            
            if obj.patchmode.status
                d = obj.db.fetch(ceil(n / obj.patchmode.patchPerSample));
            else
                d = obj.db.fetch(n);
            end
            
            if obj.db.islabelled
                if not(obj.framemode.status)
                    l = cellfun(@(x) x.label, d, 'UniformOutput', false);
                end
                d = cellfun(@(x) x.data, d, 'UniformOutput', false);
            end
            
            if obj.patchmode.status
                d = arrayfun(@(index) obj.getPatch(d{index}), ...
                    randi(numel(d), 1, n), 'UniformOutput', false);
            end
            
            if obj.framemode.status
                switch obj.framemode.type
                    case {'truncate'}
                        [d, l] = cellfun(@obj.truncateFrame, d, 'UniformOutput', false);
                        
                    case {'shift'}
                        [d, l] = cellfun(@obj.shiftFrame, d, 'UniformOutput', false);
                end
            end
            
            % packup data to package
            if obj.islabelled
                varargout = {obj.data.packup(d), obj.label.packup(l)};
            else
                varargout = {obj.data.packup(d)};
            end
            
            if nargout == 0
                obj.data.send(varargout{1});
                if obj.islabelled
                    obj.label.send(varargout{2});
                end
            end
        end
        
        function [d, l] = truncateFrame(obj, data)
            index = 1 : size(data, obj.dsample + 1) - obj.framemode.n;
            [d, l] = sltondim(data, obj.dsample + 1, index);
        end
        
        function [d, l] = shiftFrame(obj, data)
            index = 1 : size(data, obj.dsample + 1) - obj.framemode.n;
            d = sltondim(data, obj.dsample + 1, index);
            l = sltondim(data, obj.dsample + 1, index + obj.framemode.n);
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
        
        function enableFrameMode(obj, type, n)
            obj.framemode = struct( ...
                'status', true, ...
                'type',   type, ...
                'n',      n);
            obj.label = DatasetAP(obj, obj.dsample);
        end
        
        function disableFrameMode(obj)
            obj.framemode = struct('status', false);
            if obj.islabelled % PRB: dimension of label is unsure
                obj.label = DatasetAP(obj, 1);
            else
                obj.label = [];
            end
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
            
            obj.data = DatasetAP(obj, obj.dsample);
            
            if conf.exist('patchsize')
                obj.enablePatchMode(conf);
            else
                obj.disablePatchMode();
            end
            
            if conf.exist('frameTruncate')
                obj.enableFrameMode('truncate', conf.pop('frameTruncate'));
            elseif conf.exist('frameShift')
                obj.enableFrameMode('shift', conf.pop('frameshift'));
            else
                obj.disableFrameMode();
            end
        end
    end
    
    properties
        db % DataBlock that manage the data
        patchmode % structure contains all information about patch corping
        framemode % structure contains all information about
    end
    properties (Constant)
        dsample = 2;
        taxis   = true;
    end
    properties (Dependent)
        volumn
        islabelled
    end
    methods
        function value = get.volumn(obj)
            value = obj.db.volumn;
        end
        
        function value = get.islabelled(obj)
            value = obj.db.islabelled || obj.framemode.status;
        end
    end
end
