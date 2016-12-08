classdef RecurrentAP < AccessPoint
    methods
        function addrlink(obj, rap)
            if not(isempty(obj.rlink))
                obj.rlink.cleanrlink();
                obj.cleanrlink();
            end
            obj.rlink = rap;
        end
        
        function cleanrlink(obj)
            obj.rlink = [];
        end
        
        function rconnect(obj, rap)
            obj.addrlink(rap);
            rap.addrlink(obj);
        end
        
        % overide SEND function
        function send(obj, package)
            if obj.tmode.status
                obj.host.push(package);
            else
                send@AccessPoint(obj, package);
            end
        end
        
        % override PUSH function
        function push(obj, package)
            % CASE: recurrent access point on output side
            if obj.tmode.status && not(isempty(obj.rlink))
                obj.rlink.cache.nextframe(package);
            end
            obj.cache.push(package);
        end
    end
    
    methods
        function clear(obj)
            obj.state.clear();
            obj.frameCache.init();
            obj.packageCache.init();
        end
    end
    
    methods
        % PRB: this function is duplicate of the one in UnitAP
        function consistencyCheck(obj, field, value)
            if isfield(obj.parent.apshare, field)
                if ischar(value)
                    assert(strcmpi(value, obj.parent.apshare.(field)), 'INCONSISTENT');
                else
                    assert(value == obj.parent.apshare.(field), 'INCONSISTENT');
                end
            else
                obj.parent.apshare.(field) = value;
            end
        end
    end
    
    methods
        function enableTMode(obj, expand)
            obj.tmode = struct('status', true, 'expand', logical(expand));
            % clean frame cache
            obj.frameCache.clean();
            % expand package if necessary
            if obj.tmode.expand
                obj.state.package = obj.cache.pop();
                obj.frameExpand(obj.state.package);
            end
            % switch to FRAMECACHE
            obj.cache = obj.frameCache;
        end
        
        function disableTMode(obj)
            % switch to PACKAGECACHE
            obj.cache = obj.packageCache;
            % collect packge if necessary
            if not(obj.tmode.expand)
                obj.state.package = obj.frameCollect();
            end
            obj.tmode = struct('status', false);
        end
        
        function frameExpand(obj, package)
            obj.consistencyCheck('class', class(package));
            % process package according to type
            switch class(package)
                case {'DataPackage'}
                    if isempty(obj.rlink)
                        obj.consistencyCheck('taxis',  package.taxis);
                        obj.consistencyCheck('nframe', package.nframe);
                        if package.taxis
                            % revert time-axis and batch-axis
                            data = permute(package.data, ...
                                [1 : package.dsample, package.dsample + [2, 1]]);
                            % expand time-axis into packages
                            cellfun(@(d) obj.frameCache.push( ...
                                DataPackage(d, package.dsample, false)), ...
                                pack2cell(data, package.dsample + 1));
                        else
                            obj.frameCache.push(package);
                        end
                    else
                        if package.taxis
                            assert(package.nframe == 1, 'WRONG DATA SHAPE');
                            package = DataPackage(expanddim(package.data, package.dsample + 1), ...
                                package.dsample, false);
                        end
                        obj.frameCache.push(package);
                    end
                    
                case {'ErrorPackage'}
                    obj.consistencyCheck('taxis',  package.taxis);
                    if obj.parent.lastFrameMode.status
                        assert(package.nframe == 1, 'SHAPE MISMATCH');
                        if package.taxis
                            package = ErrorPackage(expanddim(package.data, package.dsample + 1), ...
                                package.dsample, false);
                        end
                        zeropkg = ErrorPackage(zeros(package.datasize), package.dsample, false);
                        obj.frameCache.push(package);
                        for i = 1 : obj.parent.lastFrameMode.nframe - 1
                            obj.frameCache.push(zeropkg);
                        end                            
                    else
                        obj.consistencyCheck('nframe', package.nframe);
                        if package.taxis
                            % revert time-axis and batch-axis
                            data = permute(package.data, ...
                                [1 : package.dsample, package.dsample + [2, 1]]);
                            % expand time-axis into packages
                            data = pack2cell(data, package.dsample + 1);
                            cellfun(@(d) obj.frameCache.push( ...
                                ErrorPackage(d, package.dsample, false)), ...
                                data(end : -1 : 1));
                        else
                            obj.frameCache.push(package);
                        end
                    end
                    
                case {'SizePackage'} % TBC
                    error('UNSUPPORTTED');
                    
                otherwise
                    error('UNKNOWN PACKAGE CLASS');
            end
        end
        
        % PRB: code needs revise
        function package = frameCollect(obj)
            switch obj.parent.apshare.class
                case {'DataPackage'}
                    if obj.parent.lastFrameMode.status
                        packages = obj.frameCache.stackpop();
                    else
                        packages = cell2array(arrayfun( ...
                            @(i) obj.frameCache.pop(), 1 : obj.frameCache.count, ...
                            'UniformOutput', false));
                    end
                    if isscalar(packages)
                        if obj.parent.apshare.taxis
                            package = DataPackage( ...
                                splitdim(packages.data, packages.dsample + 1, 1), ...
                                packages.dsample, true);
                        end
                    else
                        dsample = packages(1).dsample;
                        data = cat(dsample + 2, packages.data);
                        data = permute(data, [1 : dsample, dsample + [2, 1]]);
                        package = DataPackage(data, dsample, true);
                    end
                    
                case {'ErrorPackage'}
                    packages = cell2array(arrayfun( ...
                        @(i) obj.frameCache.pop(), 1 : obj.frameCache.count, ...
                        'UniformOutput', false));
                    if isscalar(packages)
                        if obj.parent.apshare.taxis
                            package = DataPackage( ...
                                splitdim(packages.data, packages.dsample + 1, 1), ...
                                packages.dsample, true);
                        end
                    else
                        dsample = packages(1).dsample;
                        data = cat(dsample + 2, packages(end : -1 : 1).data);
                        data = permute(data, [1 : dsample, dsample + [2, 1]]);
                        package = DataPackage(data, dsample, true);
                    end
                    
                case {'SizePackage'} % TBC
                    error('UNSUPPORTED');
                    
                otherwise
                    error('UNKNOWN PACKAGE CLASS');
            end
        end
    end
    
    methods
        function obj = RecurrentAP(parent, host, varargin)
            conf = Config(varargin);
            obj.parent = parent;
            obj.host   = host;
            % TODO: seal the model when creating Recurrent Unit
%             % take over all links from host
%             cellfun(@(ap) obj.connect(ap), obj.host.links);
%             cellfun(@(ap) obj.host.disconnect(ap), obj.links);
            obj.host.addlink(obj);
            obj.state = State();
            obj.packageCache = PackageQueue('Capacity', ...
                conf.pop('capacity', UMPrest.parameter.get('AccessPointCapacity')), ...
                '-dropold');
            obj.frameCache = FrameQueue();
            obj.cache = obj.packageCache;
            obj.tmode = struct('status', false);
        end
    end
    
    properties (SetAccess = protected)
        parent, host, rlink, tmode, cache
    end
    properties (SetAccess = protected, Transient)
        state, packageCache, frameCache
    end
    properties (Access = private)
        propertyForSave
    end
    methods
        function set.rlink(obj, value)
            assert(isa(value, 'RecurrentAP'), 'ILLEGAL OPERATION');
            obj.rlink = value;
        end
        
        function value = get.propertyForSave(obj)
            value = struct( ...
                'state',   obj.state.capacity, ...
                'frame',   obj.frameCache.capacity, ...
                'package', obj.packageCache.capacity);
        end
        function set.propertyForSave(obj, value)
            obj.state = State(value.state);
            obj.frameCache = FrameQueue('capacity', value.frame);
            obj.packageCache = PackageQueue('capacity', value.package);
        end
    end
end
