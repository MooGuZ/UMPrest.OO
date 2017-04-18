classdef ImageSequenceSet < Dataset
    methods
        function varargout = next(obj, n)
            if not(exist('n', 'var')), n = 1; end
            
            d = obj.db.fetch(ceil(n / obj.dataPerSample));
            if obj.db.islabelled
                l = cellfun(@(x) x.label, d, 'UniformOutput', false);
                d = cellfun(@(x) x.data, d, 'UniformOutput', false);
            end
            
            if obj.patchmode.status || obj.slicemode.status
                idata = randi(numel(d), 1, n);
                % obtain data by cropping/slicing
                if obj.patchmode.status && obj.slicemode.status
                    cropsize = [obj.patchmode.size, obj.slicemode.n];
                    d = arrayfun(@(index) randcrop(d{index}, cropsize), idata, ...
                        'UniformOutput', false);
                elseif obj.patchmode.status
                    d = arrayfun(@(index) randcrop(d{index}, obj.patchmode.size), idata, ...
                        'UniformOutput', false);
                elseif obj.slicemode.status
                    d = arrayfun(@(index) randslice(d{index}, obj.dsample + 1, obj.slicemode.n), ...
                        idata, 'UniformOutput', false);
                end
                % reorder labels
                if obj.islabelled
                    l = l(idata);
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
        
        function obj = enablePatchMode(obj, patchsize, patchPerSample)
            assert(MathLib.isinteger(patchsize) && numel(patchsize) == 2, ...
                'ILLEGAL PATCH SIZE');
            if not(exist('patchPerSample', 'var'))
                patchPerSample = 1;
            end
            obj.patchmode = struct( ...
                'status', true, ...
                'size',   patchsize, ...
                'patchPerSample', patchPerSample);
        end
        
        function obj = disablePatchMode(obj)
            obj.patchmode = struct('status', false);
        end
        
        function obj = enableSliceMode(obj, slicelen, slicePerSample)
            if not(exist('slicePerSample', 'var'))
                slicePerSample = 1;
            end
            obj.slicemode = struct( ...
                'status', true, ...
                'n', slicelen, ...
                'slicePerSample', slicePerSample);
        end
        
        function obj = disableSliceMode(obj)
            obj.slicemode = struct('status', false);
        end
    end

    methods
        function obj = ImageSequenceSet(dbsource, varargin)
            conf = Config(varargin);
            % create accespoints 
            obj.data  = DatasetAP(obj, obj.dsample, obj.taxis);
            obj.label = DatasetAP(obj, obj.dlabel, false);
            % setup patch mode
            if conf.exist('patchsize')
                if conf.exist('patchPerSample')
                    obj.enablePatchMode(conf.pop('patchsize'), conf.pop('patchPerSample'));
                else
                    obj.enablePatchMode(conf.pop('patchsize'));
                end
            else
                obj.disablePatchMode();
            end
            % setup frame mode
            if conf.exist('slicelength')
                if conf.exist('slicePerSample')
                    obj.enableSliceMode(conf.pop('slicelength'), conf.pop('slicePerSample'));
                else
                    obj.enableSliceMode(conf.pop('slicePerSample'));
                end
            else
                obj.disableSliceMode();
            end
            % create data block
            if iscell(dbsource) || ischar(dbsource)
                % interpret properties list
                dataReadFcn = conf.pop('dataReadFcn', @videoread);
                dataExt = conf.pop('dataExt', '.gif');
                if conf.exist('stat')
                    conf.update('stat', obj.dsample);
                end
                others = conf.expand();
                % build file data block
                obj.db = FileDataBlock(dbsource, dataReadFcn, dataExt, others{:});
            elseif isa(dbsource, 'DataBlock')
                obj.db = dbsource;
            else
                error('ILLEGAL FIRST ARGUMENT');
            end
        end
    end
    
    properties
        db        % abstract data pool (automatically loading and shuffling)
        patchmode % control structure of patch corping
        slicemode % control structure for frame slicing
    end
    properties (Constant)
        dsample = 2;
        dlabel  = 1;
        taxis   = true;
    end
    properties (Dependent)
        volumn
        islabelled
        dataPerSample
        hideTAxis % option for hiding temporal axis in output data package
        stat
    end
    methods
        function value = get.volumn(obj)
            value = obj.db.volumn;
        end
        
        function value = get.islabelled(obj)
            value = obj.db.islabelled;
        end
        
        function value = get.dataPerSample(obj)
            value = 1;
            if obj.patchmode.status
                value = value * obj.patchmode.patchPerSample;
            end
            if obj.slicemode.status
                value = value * obj.slicemode.slicePerSample;
            end
        end
        
        function value = get.hideTAxis(obj)
            value = obj.data.hideTAxis;
        end
        
        function set.hideTAxis(obj, value)
            obj.data.hideTAxis = value;
        end
        
        function value = get.stat(obj)
            if obj.db.stat.status
                value = obj.db.stat.collector;
            else
                value = [];
            end
        end
    end
end
