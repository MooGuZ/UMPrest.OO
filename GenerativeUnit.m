classdef GenerativeUnit < Unit & Evolvable
% Old fasioned generative units use minFunc to do optimization
    methods
        function varargout = forward(self, varargin)
            self.pkginfo = GenerativeAP.initPackageInfo();
            % unpack input package
            if isempty(varargin)
                for i = 1 : numel(self.I)
                    self.I{i}.unpack(self.I{i}.pop());
                end
            else
                for i = 1 : numel(self.I)
                    self.I{i}.unpack(varargin{i});
                end
            end
            % main process
            switch self.pkginfo.class
              case {'DataPackage'}
                % send size information
                cellfun(@sendSize, self.I);
                % forward pass of size package
                self.kernel.backward();
                % initialize representation
                cellfun(@(ap) ap.initData(ap.hostio.pop()), self.O);
                % self.outputVectorSize = ...
                %     sum(cellfun(@(ap) prod(ap.datasize), self.O));
                % send back size information
                cellfun(@sendSize, self.O);
                % backward pass of size package
                self.kernel.forward();
                % reshape data (target)
                cellfun(@(ap) ap.reshapeData(ap.hostio.pop()), self.I);
                % self.inputVectorSize = ...
                %     sum(cellfun(@(ap) prod(ap.datasize), self.I));
                % do inference by minFunc
                self.deployData(self.O, minFunc(@self.infer,...
                    self.collectData(self.O), self.inferOption));
                % normalization representation
                self.normalizeRepresentation();
                % do adaptation by back-propagation
                if not(self.frozen)
                    self.adapt();
                end
                % collect representations as packages
                varargout = cellfun(@packupData, self.O, 'UniformOutput', false);
                
              case {'ErrorPackage'}
                cellfun(@sendError, self.I);
                self.kernel.backward();
                varargout = cellfun(@packupError, self.O, 'UniformOutput', false);
                
              case {'SizePackage'}
                error('UNSUPPORTED OPERATION!');
                
              otherwise
                error('UNKNOWN PACKAGE TYPE!');
            end
            % send package if necessary
            if nargout == 0
                for i = 1 : numel(self.O)
                    self.O{i}.send(varargout{i});
                end
            end
        end
        
        function varargout = backward(self, varargin)
            self.pkginfo = GenerativeAP.initPackageInfo();
            % unpack input package
            if isempty(varargin)
                for i = 1 : numel(self.O)
                    self.O{i}.unpack(self.O{i}.pop());
                end
            else
                for i = 1 : numel(self.O)
                    self.O{i}.unpack(varargin{i});
                end
            end
            % main process
            switch self.pkginfo.class
              case {'DataPackage'}
                cellfun(@sendData, self.O);
                self.kernel.forward();
                varargout = cellfun(@getPackage, self.I, 'UniformOutput', false);
                
              case {'ErrorPackage', 'SizePackage'}
                error('UNSUPPORTED OPERATION!');
                
              otherwise
                error('UNKNOWN PACKAGE TYPE!');
            end
        end
        
        function [value, delta] = infer(self, data)
            self.deployData(self.O, data);
            cellfun(@sendData, self.O);
            self.kernel.forward();
            value = sum(cellfun(@objfunc, self.I));
            cellfun(@(ap) ap.sendDelta(false), self.I);
            self.kernel.backward();
            cellfun(@composeDelta, self.O);
            delta = self.collectDelta(self.O);
        end
        
        function adapt(self)
            cellfun(@sendData, self.O);
            self.kernel.forward();
            cellfun(@objfunc, self.I);
            cellfun(@(ap) ap.sendDelta(true), self.I);
            self.kernel.backward();
            self.kernel.update();            
        end
        
        function deployData(~, aplist, data)
            index = 0;
            for i = 1 : numel(aplist)
                ap = aplist{i};
                n  = prod(ap.datasize);
                ap.updateData( reshape( ...
                    data(index + (1 : n)), ap.datasize));
                index = index + n;
            end
        end
        
        function data = collectData(~, aplist)
            data = cellfun(@(ap) ap.data(:), aplist, 'UniformOutput', false);
            data = cat(1, data{:});
        end
        
        function delta = collectDelta(~, aplist)
            delta = cellfun(@(ap) ap.delta(:), aplist, 'UniformOutput', false);
            delta = cat(1, delta{:});
        end
        
        function normalizeRepresentation(self)
            if isa(self.normfunc, 'function_handle')
                rept = cellfun(@(ap) ap.data, self.O, 'UniformOutput', false);
                temp = cell(1, numel(rept));
                [temp{:}] = self.normfunc(rept{:});
                for i = 1 : numel(self.O)
                    self.O{i}.updateData(temp{i});
                end
            end
        end
        
        function hpcell = hparam(self)
            hpcell = self.kernel.hparam();
        end
        
        function unitdump = dump(self)
            unitdump = {class(self), self.kernel.dump()};
        end
    end
    
    methods
        function self = GenerativeUnit(kernel, normfunc)
            self.kernel = kernel;
            % initialize access-points
            self.I = cellfun(@(host) GenerativeAP(self, host), ...
                self.kernel.O, 'UniformOutput', false);
            self.O = cellfun(@(host) GenerativeAP(self, host), ...
                self.kernel.I, 'UniformOutput', false);
            % setup normalization function
            if exist('normfunc', 'var')
                self.normfunc = normfunc;
            end
        end
    end
    
    properties
        frozen = true
        inferOption = struct( ...
            'Method',      'cg',  ...
            'Display',     'iter', ...
            'MaxIter',     20,    ...
            'MaxFunEvals', 30);
        normfunc = []
    end
    properties (Hidden)
        pkginfo
    end
    properties (SetAccess = protected)
        I, O, kernel
    end
    % properties
    %     inputVectorSize, outputVectorSize
    % end
    methods
        function set.I(self, value)
            try
                assert(iscell(value));
                if isscalar(value)
                    assert(isa(value{1}, 'GenerativeAP'));
                else
                    for i = 1 : numel(value)
                        assert(isa(value{i}, 'GenerativeAP'));
                        value{i}.cooperate(i);
                    end
                end
                self.I = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.O(self, value)
            try
                assert(iscell(value));
                if isscalar(value)
                    assert(isa(value{1}, 'GenerativeAP'));
                else
                    for i = 1 : numel(value)
                        assert(isa(value{i}, 'GenerativeAP'));
                        value{i}.cooperate(i);
                    end
                end
                self.O = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end
