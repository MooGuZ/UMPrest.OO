classdef GenerativeAP < AccessPoint & ProbabilityDescription
    methods (Static)
        function pkginfo = initPackageInfo()
            pkginfo = struct( ...
                'class',        [], ...
                'taxis',        [], ...
                'batchsize',    [], ...
                'updateHParam', []);
        end
    end
    
    methods
        function unpack(self, package)
            if not(exist('package', 'var'))
                package = self.cache.pop();
            end
            % fill-up package information
            if self.no && not(isempty(self.parent.pkginfo.class))
                assert(strcmp(class(package), self.parent.pkginfo.class));
                assert(package.taxis == self.parent.pkginfo.taxis);
                assert(package.batchsize == self.parent.pkginfo.batchsize);
                if isa(package, 'ErrorPackage')
                    assert(package.updateHParam == self.parent.pkginfo.updateHParam);
                end
            else
                self.parent.pkginfo.class     = class(package);
                self.parent.pkginfo.taxis     = package.taxis;
                self.parent.pkginfo.batchsize = package.batchsize;
                if isa(package, 'ErrorPackage')
                    self.parent.pkginfo.updateHParam = package.updateHParam;
                end
            end
            % load package contents to access-point
            switch self.parent.pkginfo.class
              case {'DataPackage', 'ErrorPackage'}
                self.data     = package.data;
                self.dsample  = package.dsample;
                self.datasize = package.datasize;
                
              case {'SizePackage'}                
                self.dsample  = package.dsample;
                self.datasize = package.datasize;
                
              otherwise
                error('UNSUPPORTED PACKAGE TYPE');
            end
        end
        
        function package = getPackage(self)
            package = self.hostio.pop();
        end
        
        function package = packupData(self)
            package = DataPackage(self.data, self.dsample, self.parent.pkginfo.taxis);
        end
        
        function package = packupError(self)
            package = ErrorPackage(self.data, self.dsample, ...
                self.parent.pkginfo.taxis, self.parent.pkginfo.updateHParam);
        end
    
        function sendSize(self)
            self.hostio.send( SizePackage( ...
                self.datasize, self.dsample, self.parent.pkginfo.taxis) );
        end
        
        function sendData(self)
            self.hostio.send(self.packupData());
        end
        
        function sendError(self)
            self.hostio.send(self.packupError());
        end
        
        function sendDelta(self, tof)
            self.hostio.send(ErrorPackage(self.delta, self.dsample, ...
                self.parent.pkginfo.taxis, tof));
        end
        
        function reshapeData(self, szpkg)
            self.data     = reshape(self.data, szpkg.datasize);
            self.dsample  = szpkg.dsample;
            self.datasize = szpkg.datasize;
        end
        
        function initData(self, szpkg)
            self.data     = Tensor(randn(szpkg.datasize)).get();
            self.dsample  = szpkg.dsample;
            self.datasize = szpkg.datasize;
        end
        
        function updateData(self, data)
            self.data = data;
        end
        
        function value = objfunc(self)
        % use negative log gaussian distribution as evaluation method by default
            package    = self.hostio.pop();
            self.delta = package.data - self.data;
            if not(isempty(self.objweight))
                self.delta = bsxfun(@times, self.delta, self.objweight);
            end
            batchsize   = self.parent.pkginfo.batchsize;
            probability = self.parent.valuefunc(self.delta, 0, self.parent.noiseStdvar);
            self.delta  = self.parent.deltafunc(self.delta, 0, self.parent.noiseStdvar) / batchsize;
            value       = sum(probability(:)) / batchsize;
            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
        
        function composeDelta(self)
            package    = self.hostio.pop();            
            self.delta = package.data + self.priorDelta(self.data);
        end
        
        function self = cooperate(self, no)
            self.no = no;
        end
    end
    
    % overwrite functions from ProbabilityDescription to remove influnence of batchsize
    methods
        function value = priorEval(self, varargin)
            value = priorEval@ProbabilityDescription(self, varargin{:}) / self.parent.pkginfo.batchsize;
        end
        
        function value = priorDelta(self, varargin)
            value = priorDelta@ProbabilityDescription(self, varargin{:}) / self.parent.pkginfo.batchsize;
        end
    end
    
    methods
        function self = GenerativeAP(parent, host, varargin)
            conf = Config(varargin);
            
            self.parent = parent;
            self.hostio = SimpleAP(self.parent, '-nomerge').connect(host);
            
            if conf.exist('capacity')
                self.cache = PackageContainer(conf.pop('capacity'), '-overwrite');
            else
                self.cache = PackageContainer();
            end
        end
    end
    
    properties
        objweight = []
    end
    properties (SetAccess = protected)
        parent, hostio, no = 0
        data, delta, dsample, datasize
    end
    properties (Dependent)
        host
    end
    methods
        function value = get.host(self)
            value = self.hostio.links{1};
        end
    end
end
