classdef RecurrentAP < AccessPoint
    methods
        function frames = unpack(obj, package)
            % obj.packagercd = package;
            if obj.no && not(isempty(obj.parent.pkginfo.class))
                assert(strcmp(class(package), obj.parent.pkginfo.class));
                assert(package.taxis == obj.parent.pkginfo.taxis);
                assert(package.nframe == obj.parent.pkginfo.nframe);
                assert(package.batchsize == obj.parent.pkginfo.batchsize);
            else
                obj.parent.pkginfo.class     = class(package);
                obj.parent.pkginfo.taxis     = package.taxis;
                obj.parent.pkginfo.nframe    = package.nframe;
                obj.parent.pkginfo.batchsize = package.batchsize;
            end
            % expand frames along time-axis
            if package.taxis
                switch class(package)
                  case {'DataPackage'}
                    % revert time-axis and batch-axis
                    data = permute(package.data, ...
                        [1 : package.dsample, package.dsample + [2, 1]]);
                    % expand time-axis into packages
                    frames = pack2cell(data, package.dsample + 1);
                    for i = 1 : numel(frames)
                        frames{i} = DataPackage(frames{i}, package.dsample, false);
                    end
                    
                  case {'ErrorPackage'}
                    % revert time-axis and batch-axis
                    data = permute(package.data, ...
                        [1 : package.dsample, package.dsample + [2, 1]]);
                    % expand time-axis into packages
                    frames = pack2cell(data, package.dsample + 1);
                    for i = 1 : numel(frames)
                        frames{i} = ErrorPackage(frames{i}, package.dsample, false);
                    end
                    frames = frames(end : -1 : 1);                    
                    
                  case {'SizePackage'}
                    datasize = [package.smpsize, package.batchsize];
                    frames   = {SizePackage(datasize, package.dsample, false)};
                                        
                  otherwise
                    error('UNSUPPORTED');
                end
            else
                frames = {package};
            end
        end
        
        function package = packup(obj, frames)
            switch obj.parent.pkginfo.class
              case {'DataPackage'}
                if isscalar(frames)
                    package = frames{1};
                    if obj.parent.pkginfo.taxis
                        package = DataPackage(splitdim(package.data, package.dsample + 1, 1), ...
                            package.dsample, true);
                    end
                else
                    dsample = frames{1}.dsample;
                    frames  = [frames{:}];
                    data = cat(dsample + 2, frames.data);
                    data = permute(data, [1 : dsample, dsample + [2, 1]]);
                    package = DataPackage(data, dsample, true);
                end
                
              case {'ErrorPackage'}
                if isscalar(frames)
                    package = frames{1};
                    if obj.parent.pkginfo.taxis
                        package = ErrorPackage(splitdim(package.data, package.dsample + 1, 1), ...
                            package.dsample, true);
                    end
                else
                    dsample = frames{1}.dsample;
                    frames  = [frames{end : -1 : 1}];
                    data = cat(dsample + 2, frames.data);
                    data = permute(data, [1 : dsample, dsample + [2, 1]]);
                    package = ErrorPackage(data, dsample, true);
                end
                
              case {'SizePackage'}
                if obj.parent.pkginfo.taxis
                    datasize = [frames{1}.smpsize, obj.parent.pkginfo.nframe, frames{1}.batchsize];
                    package  = SizePackage(datasize, frames{1}.dsample, true);
                else
                    package = frames{1};
                end
                
              otherwise
                error('UNSUPPORTED');
            end
            % obj.packagercd = package;
        end
        
        function extract(obj, package)
            if not(exist('package', 'var'))
                package = obj.cache.pull();
            end
            frames = obj.unpack(package);
            % fill up cache of frames
            obj.hostio.reset();
            for i = 1 : numel(frames)
                obj.hostio.push(frames{i});
            end
        end
        
        function package = compress(obj, lastonly)
            frames = cell(1, obj.hostio.cache.count);
            for i = 1 : numel(frames)
                frames{i} = obj.hostio.pull();
            end
            if exist('lastonly', 'var') && lastonly
                package = obj.packup(frames(end));
            else
                package = obj.packup(frames);
            end
        end
        
        function sendFrame(obj)
            try
                obj.hostio.send(obj.hostio.pull());
            catch
                % do nothing, should be empty
            end
        end

        function obj = cooperate(obj, no)
            obj.no = no;
        end
        
        function obj = reset(obj)
            obj.cache.reset();
            obj.hostio.reset();
        end
        
        function obj = recrtmode(obj, n)
            if n == 1
                obj.hostio.cache.simple();
            else
                obj.hostio.cache.init(n);
            end
        end
    end
    
    methods (Static)
        function pkginfo = initPackageInfo()
            pkginfo = struct( ...
                'class',     [], ...
                'taxis',     [], ...
                'nframe',    [], ...
                'batchsize', []);
        end
    end
    
    methods
        function obj = RecurrentAP(parent, host, varargin)
            conf = Config(varargin);
            
            obj.no = 0;
            
            obj.parent = parent;
            obj.hostio = SimpleAP(obj.parent, '-nomerge', ...
                'capacity', obj.parent.memoryLength).connect(host);
                        
            if conf.exist('capacity')
                obj.cache  = PackageContainer(conf.pop('capacity'), '-overwrite');
            else
                obj.cache = PackageContainer();
            end
        end
    end
    
    properties (SetAccess = protected)
        parent % handle of a SimpleUnit, the host of this AccessPoint
        hostio % IO interface to kernel access points
        no     % series number, 0 represent independent, otherwise in cooperate mode
    end
    methods
        function set.parent(obj, value)
            assert(isa(value, 'RecurrentUnit'), 'ILLEGAL OPERATION');
            obj.parent = value;
        end
        
        function set.hostio(obj, value)
            assert(isa(value, 'AccessPoint'), 'ILLEGAL OPERATION');
            obj.hostio = value;
        end
        
        function set.no(obj, value)
            assert(MathLib.isinteger(value) && value >= 0, 'ILLEGAL OPERATION');
            obj.no = value;
        end
    end
end