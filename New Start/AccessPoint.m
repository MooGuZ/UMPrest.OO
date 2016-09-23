classdef AccessPoint < handle
    % ======================= DATA PROCESSING =======================
    methods
        function data = unpack(obj, package)
            if isfield(obj.parent.cdinfo, 'pkgtype')
                assert(isa(package, obj.parent.cdinfo.pkgtype));
            else
                obj.parent.cdinfo.pkgtype = class(package);
            end
            % unpack packge according to their class
            switch class(package)
              case {'DataPackage', 'ErrorPackage'}
                % check dimension of data
                if obj.parent.expandable && not(isfield(obj.parent.cdinfo, 'dexpend'))
                    assert(package.dsample >= obj.dsample, 'UMPrest:RuntimeError', ...
                           'Sample dimension mismatched!');
                    obj.parent.cdinfo.dexpend = package.dsample - obj.dsample;
                else
                    assert(package.dsample == obj.dsample, 'UMPrest:RuntimeError', ...
                           'Sample dimension mismatched!');
                end
                % check existence of time axis and batch size
                if isfield(obj.parent.cdinfo, 'taxis')
                    assert(package.taxis == obj.parent.cdinfo.taxis, 'UMPrest:RuntimeError', ...
                           'Existence of time axis does not match between packages!');
                    assert(package.nsample == obj.parent.cdinfo.nsample, 'UMPrest:RuntimeError', ...
                           'Batch size does not match between packages!');
                    assert(package.nsequence == obj.parent.cdinfo.nsequence, 'UMPrest:RuntimeError', ...
                           'Batch size does not match between packages!');
                else
                    obj.parent.cdinfo.taxis = package.taxis;
                    obj.parent.cdinfo.nsample = package.nsample;
                    obj.parent.cdinfo.nsequence = package.nsequence;
                end
                % reshape data if necessary
                if package.taxis && not(obj.parent.taxis)
                    obj.parent.cdinfo.nframe = package.nsample / package.nsequence;
                    data = MathLib.expandDim(package.data, package.dsample + 1);
                elseif not(package.taxis) && obj.parent.taxis
                    data = MathLib.splidDim(package.data, package.dsample + 1, 1);
                else
                    data = package.data;
                end
                
              case {'SizePackage'}
                data = pacakge.sizeinfo;
                % check suitability of size to AP
                assert(obj.szcheck(data), 'UMPrestRuntimeError', ...
                       'Sample size does not match access point!');
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function package = packup(obj, data)
            switch obj.parent.cdinfo.pkgtype
              case {'DataPackage'}
                % reshape data if necessary
                if obj.parent.cdinfo.taxis && not(obj.parent.taxis)
                    data = MathLib.splitDim(data, obj.dsample + 1, obj.parent.cdinfo.nframe);
                elseif not(obj.parent.cdinfo.taxis) && obj.parent.taxis
                    data = MathLib.expandDim(data, obj.dsample + 1);
                end
                % create package
                package = DataPackage(data, obj.dsample, obj.parent.cdinfo.taxis);
                
              case {'ErrorPackage'}
                % reshape data if necessary
                if obj.parent.cdinfo.taxis && not(obj.parent.taxis)
                    data = MathLib.splitDim(data, obj.dsample + 1, obj.parent.cdinfo.nframe);
                elseif not(obj.parent.cdinfo.taxis) && obj.parent.taxis
                    data = MathLib.expandDim(data, obj.dsample + 1);
                end
                % create package
                package = ErrorPackage(data, obj.dsample, obj.parent.cdinfo.taxis);
                
              case {'SizePackage'}
                package = SizePackage(data);
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function tf = szcheck(obj, value)
            if isempty(obj.sizeRequirement)
                tf = true;
                return
            end
            
            if obj.parent.expandable
                tf = (numel(value) >= numel(obj.sizeRequirement));
            else
                tf = (numel(value) == numel(obj.sizeRequirement));
            end
            index = not(isnan(obj.smpsz.requirement));
            tf = tf && all(value(index) == obj.sizeRequirement(index));
        end
    end
    
    % ======================= CONNECTION =======================
    methods
        function send(obj, package)
            % package = obj.packup(data);
            for i = 1 : numel(obj.link)
                if isa(obj.link(i), 'AccessPoint')
                    obj.link(i).push(package);
                end
            end
        end
        
        function push(obj, package)
            obj.cache = [obj.cache, {package}];
        end
        
        function package = pop(obj)
            if isempty(obj.cache)
                package = [];
            else
                package = obj.cache{1};
                obj.cache = obj.cache(2 : end);
            end
        end
        
        function tf = addlink(obj, ap)
            tf = false;
            if not(obj.islinked(ap))
                % ASSERT: ap need to be a AccessPoint
                obj.link = [obj.link, ap];
                tf = true;
            end
        end
        
        function tf = rmlink(obj, ap)
            index = obj.islinked(ap);
            if index
                obj.link = obj.link([1 : index - 1, index + 1 : end]);
            end
            tf = logical(index);
        end
        
        function index = islinked(obj, ap)
            index = numel(obj.link);
            while index > 0
                % TODO: need a better method to compare AP
                if ap == obj.link(index)
                    break
                end
            end
        end
    end
    
    % PROBLEM : shoule AccessPoint distinguish input and output?
    methods (Static)
        function connect(ap1, ap2)
            if not(AccessPoint.isconnected(ap1, ap2))
                ap1.addlink(ap2);
                ap2.addlink(ap1);
            end
        end
        
        function disconnect(ap1, ap2)
            if AccessPoint.isconnected(ap1, ap2)
                ap1.rmlink(ap2);
                ap2.rmlink(ap1);
            end
        end
        
        function tf = isconnected(ap1, ap2)
            tf = ap1.islinked(ap2) && ap2.islinked(ap1); 
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = AccessPoint(parent, szreq)
            obj.parent          = parent;
            obj.state           = [];
            obj.cache           = [];
            obj.link            = [];
            obj.szsample        = [];
            obj.sizeRequirement = szreq;
        end
    end

    % ======================= DATA STRUCTURE =======================
    properties
        state, szsample, prior
    end
    properties (SetAccess = private)
        parent, cache, link, sizeRequirement
    end
    properties (Dependent)
        dsample
    end
    methods
        function set.szsample(obj, value)
            if isempty(value) || obj.szcheck(value)
                obj.szsample = value;
            else
                error('UMPrest:RuntimeError', ...
                      'Given value is not an available size for this access point!');
            end
        end
        
        function set.parent(obj, value)
            assert(isa(value, 'Unit'));
            obj.parent = value;
        end
        
        % function set.cache(obj, value)
        %     assert(isa(value, 'Package') && isvector(value));
        %     obj.cache = value;
        % end
        
        function set.link(obj, value)
            assert(isempty(value) || isa(value, 'AccessPoint'));
            obj.link = value;
        end
        
        function value = get.dsample(obj)
            if obj.parent.expandable && isfield(obj.parent.cdinfo, 'dexpand')
                value = numel(obj.sizeRequirement) + obj.parent.cdinfo.dexpand;
            else
                value = numel(obj.sizeRequirement);
            end
        end
    end
end
