% TODO: apply prior gradient to ERRORPACKAGE in UNPACK process
classdef UnitAP < AccessPoint
% ======================= DATA PROCESSING =======================
    methods
        function data = unpack(obj, package)
            if obj.no && not(isempty(obj.parent.pkginfo.class))
                assert(strcmp(class(package), obj.parent.pkginfo.class));
                assert(package.taxis == obj.parent.pkginfo.taxis);
                % assert(package.batchsize == obj.parent.pkginfo.batchsize);
                if obj.expandable 
                    if package.dsample >= obj.dsample
                        assert(package.dsample - obj.dsample == obj.parent.pkginfo.dexpand);
                    else
                        assert(obj.parent.pkginfo.dexpand == 0);
                    end
                end
            else
                obj.parent.pkginfo.class = class(package);
                obj.parent.pkginfo.taxis = package.taxis;
                % obj.parent.pkginfo.batchsize = package.batchsize;
                if obj.expandable 
                    if package.dsample >= obj.dsample
                        obj.parent.pkginfo.dexpand = package.dsample - obj.dsample;
                    else
                        obj.parent.pkginfo.dexpand = 0;
                    end
                end
            end
            % calculate desired shape of data
            [datashape, needReshape] = obj.sizeOut2In( ...
                package.datasize, package.dsample, package.taxis);
            % unpack packge according to their class
            switch class(package)
              case {'DataPackage'}
                if needReshape
                    data = reshape(package.data, datashape);
                else
                    data = package.data;
                end
                if obj.recdata
                    obj.datarcd.push(data);
                end
                
              case {'ErrorPackage'}
                if needReshape
                    data = reshape(package.data, datashape);
                else
                    data = package.data;
                end
                                
              case {'SizePackage'}
                data = datashape;
                
              otherwise
                error('UNSUPPORTED');
            end
            % record states
            obj.packagercd = package;
        end
        
        function package = packup(obj, data)
            if obj.expandable
                dim = obj.dsample + obj.parent.pkginfo.dexpand;
            else
                dim = obj.dsample;
            end
            taxis = obj.parent.pkginfo.taxis;
            [datashape, needReshape] = obj.sizeIn2Out(size(data), dim, taxis);
            switch obj.parent.pkginfo.class
              case {'DataPackage'}
                if needReshape
                    data = reshape(data, datashape);
                end
                package = DataPackage(data, dim, taxis);
                if obj.recdata
                    obj.datarcd.push(data);
                end
                
              case {'ErrorPackage'}
                if needReshape
                    data = reshape(data, datashape);
                end
                package = ErrorPackage(data, dim, taxis);
                
              case {'SizePackage'}
                package = SizePackage(datashape, dim, taxis);
                
              otherwise
                error('UNSUPPORTED');
            end
            obj.packagercd = package;
        end
    end
    
    methods (Access = private)
        function [datasize, flag] = sizeOut2In(obj, datasize, dsample, taxis)
            taxisFlag = true;
            % CASE: data with TAXIS and unit has not
            if taxis && not(obj.parent.taxis)
                datasize = [datasize(1 : dsample), prod(datasize(dsample + end))];
            % CASE: data without TAXIS and unit has
            elseif not(taxis) && obj.parent.taxis
                datasize = [datasize(1 : dsample), 1, datasize(dsample + 1 : end)];
            else
                taxisFlag = false;
            end
            
            dimFlag = true;
            % CASE: sample of data doesn't have sufficient dimensions
            if dsample < obj.dsample
                datasize = [ ...
                    datasize(1 : dsample), ...
                    ones(1, obj.dsample - dsample), ...
                    datasize(dsample + 1 : end)];
            elseif not(obj.expandable) && obj.dsample == 1 && dsample > 1
                datasize = [prod(datasize(1 : dsample)), datasize(dsample + 1 : end)];
            else
                dimFlag = false;
            end
            
            flag = taxisFlag || dimFlag;
        end
        
        function [datasize, flag] = sizeIn2Out(obj, datasize, dsample, taxis)
            ndim = dsample + double(obj.parent.taxis) + 1;
            if numel(datasize) < ndim
                datasize = [datasize, ones(1, ndim - numel(datasize))];
            elseif numel(datasize) > ndim
                error('BUG HERE');
            end
            flag = true;
            % CASE: unit has TAXIS and data has not
            if obj.parent.taxis && not(taxis)
                datasize = [datasize(1 : dsample), prod(datasize(dsample + 1 : end))];
            % CASE: unit doesn't deal with TAXIS, while data has
            elseif not(obj.parent.taxis) && taxis
                datasize = [datasize(1 : dsample), 1, datasize(dsample + 1 : end)];
            else
                flag = false;
            end
        end
    end
    
    methods
        function obj = cooperate(obj, no)
            obj.no = no;
        end
    end
    
    methods (Static)
        function pkginfo = initPackageInfo()
            pkginfo = struct( ...
                'class',     [], ...
                'taxis',     [], ...
                'dexpand',   []);
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = UnitAP(parent, dsample, varargin)
            conf = Config(varargin);
            
            obj.no = 0;
            
            obj.parent     = parent;
            obj.dsample    = dsample;
            obj.expandable = conf.pop('expandable', false);
            obj.recdata    = conf.pop('recdata', false);
            
            if obj.recdata
                obj.datarcdlen = conf.pop('dataRecordLength', 1);
            end
            
            if conf.exist('capacity')
                obj.cache = PackageContainer(conf.pop('capacity'), '-overwrite');
            else
                obj.cache = PackageContainer();
            end
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (SetAccess = protected)
        parent     % handle of a SimpleUnit, the host of this AccessPoint
        dsample    % dimension of data pass through this AccessPoint
        expandable % TRUE/FALSE, indicating dimension of data can be expanded
        no         % series number, 0 represent independent, otherwise in cooperate mode
    end
    properties (Dependent)
        recdata    % TRUE/FALSE, indicating this AccessPoint would record passed data
        datarcdlen % length of data records, default 1
    end
    properties (SetAccess = protected)
        cache      % a queue containing all unprocessed packages
        datarcd    % a stack containing copy of data proccessed by host Unit
    end
    methods
        function set.parent(obj, value)
            assert(isa(value, 'SimpleUnit'), 'ILLEGAL OPERATION');
            obj.parent = value;
        end
        
        function set.dsample(obj, value)
            obj.dsample = max(floor(value), 0);
        end
        
        function set.expandable(obj, value)
            obj.expandable = logical(value);
        end
        
        function value = get.datarcdlen(obj)
            if obj.recdata
                value = obj.datarcd.capacity;
            else
                value = 0;
            end
        end
        function set.datarcdlen(obj, value)
            assert(obj.recdata, 'ILLEGAL OPERATION');
            if value ~= obj.datarcdlen
                if value == 1
                    obj.datarcd.simple();
                else
                    obj.datarcd.init(value);
                end
            end
        end
        
        function value = get.recdata(obj)
            value = not(isempty(obj.datarcd));
        end
        function set.recdata(obj, value)
            if value ~= obj.recdata
                if value
                    obj.datarcd = Container();
                else
                    obj.datarcd = [];
                end
            end
        end
        
        function set.no(obj, value)
            assert(MathLib.isinteger(value) && value >= 0, 'ILLEGAL OPERATION');
            obj.no = value;
        end
    end
end
