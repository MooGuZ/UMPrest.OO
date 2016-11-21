classdef AccessPoint < handle
    % ======================= DATA PROCESSING =======================
    methods
        function data = unpack(obj, package)
            % consistency of package type accross different access point
            if isfield(obj.parent.apshare, 'class')
                assert(isa(package, obj.parent.apshare.class));
            else
                obj.parent.apshare.class = class(package);
            end
            % unpack packge according to their class
            switch class(package)
              case {'DataPackage', 'ErrorPackage'}
                % check dimension of data
                if obj.parent.expandable && not(isfield(obj.parent.apshare, 'dexpend'))
                    assert(package.dsample >= obj.dsample, 'UMPrest:RuntimeError', ...
                           'Sample dimension mismatched!');
                    obj.parent.apshare.dexpend = package.dsample - obj.dsample;
                else
                    assert(package.dsample == obj.dsample, 'UMPrest:RuntimeError', ...
                           'Sample dimension mismatched!');
                end
                % check existence of time axis and batch size
                if isfield(obj.parent.apshare, 'taxis')
                    assert(package.taxis == obj.parent.apshare.taxis, 'UMPrest:RuntimeError', ...
                           'Existence of time axis does not match between packages!');
                    assert(package.nsample == obj.parent.apshare.nsample, 'UMPrest:RuntimeError', ...
                           'Batch size does not match between packages!');
                    assert(package.nsequence == obj.parent.apshare.nsequence, 'UMPrest:RuntimeError', ...
                           'Batch size does not match between packages!');
                else
                    obj.parent.apshare.taxis = package.taxis;
                    obj.parent.apshare.nsample = package.nsample;
                    obj.parent.apshare.nsequence = package.nsequence;
                end
                % reshape data if necessary
                if package.taxis && not(obj.parent.taxis)
                    obj.parent.apshare.nframe = package.nsample / package.nsequence;
                    data = MathLib.expandDim(package.data, package.dsample + 1);
                elseif not(package.taxis) && obj.parent.taxis
                    data = MathLib.splitDim(package.data, package.dsample + 1, 1);
                else
                    data = package.data;
                end
                
              case {'SizePackage'}
                data = pacakge.sizeinfo;
                
              otherwise
                error('UNSUPPORTED');
            end
            % record states
            obj.state.data    = data;
            obj.state.package = package;
        end
        
        function package = packup(obj, data)
            switch obj.parent.apshare.class
              case {'DataPackage'}
                % reshape data if necessary
                if obj.parent.apshare.taxis && not(obj.parent.taxis)
                    data = MathLib.splitDim(data, obj.dsample + 1, obj.parent.apshare.nframe);
                elseif not(obj.parent.apshare.taxis) && obj.parent.taxis
                    data = MathLib.expandDim(data, obj.dsample + 1);
                end
                % create package
                package = DataPackage(data, obj.dsample, obj.parent.apshare.taxis);
                
              case {'ErrorPackage'}
                % reshape data if necessary
                if obj.parent.apshare.taxis && not(obj.parent.taxis)
                    data = MathLib.splitDim(data, obj.dsample + 1, obj.parent.apshare.nframe);
                elseif not(obj.parent.apshare.taxis) && obj.parent.taxis
                    data = MathLib.expandDim(data, obj.dsample + 1);
                end
                % create package
                package = ErrorPackage(data, obj.dsample, obj.parent.apshare.taxis);
                
              case {'SizePackage'}
                package = SizePackage(data);
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
            obj.state.data    = data;
            obj.state.package = package;
        end
    end
    
    % ======================= CONNECTION =======================
    methods
        function send(obj, package)
            % package = obj.packup(data);
            for i = 1 : numel(obj.links)
                % TODO: skip links type check, make the links only privately
                %       setable and ensure legality of connection when
                %       conncection established.
                if isa(obj.links(i), 'AccessPoint')
                    obj.links(i).push(package);
                end
            end
        end
        
        function push(obj, package)
            obj.cache{obj.jcache} = package;
            % update cache index
            if isempty(obj.icache)
                obj.icache = obj.jcache;
            elseif obj.icache == obj.jcache
                obj.icache = mod(obj.jcache, obj.capacity) + 1;
            end
            obj.jcache = mod(obj.jcache, obj.capacity) + 1;
        end
        
        function package = pop(obj)
            if isempty(obj.icache)
                error('EMPTY');
            else
                package = obj.cache{obj.icache};
                % obj.cache{obj.icache} = [];
            end
            % update cache index
            obj.icache = mod(obj.icache, obj.capacity) + 1;
            if obj.icache == obj.jcache
                obj.icache = [];
            end
        end
        
        function value = count(obj)
            if isempty(obj.icache)
                value = 0;
            elseif obj.icache == obj.jcache
                value = obj.capacity;
            else
                value = mod(obj.jcache - obj.icache, obj.capacity);
            end
        end
        
        function addlink(obj, ap)
            obj.links = unique([obj.links, ap]);
        end
        
        function rmlink(obj, ap)
            obj.links(obj.links == ap) = [];
        end
    end
    
    methods (Static)
        function connect(ap1, ap2)
            ap1.addlink(ap2);
            ap2.addlink(ap1);
        end
        
        function disconnect(ap1, ap2)
            ap1.rmlink(ap2);
            ap2.rmlink(ap1);
        end
        
        function connectOneWay(from, to)
            from.addlink(to);
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = AccessPoint(parent, dsample)
            obj.parent   = parent;
            obj.dsample  = dsample;
            obj.state    = struct('data', [], 'package', []);
            obj.capacity = UMPrest.parameter.get('AccessPointCapacity');
            obj.cache    = cell(1, obj.capacity);
            obj.icache   = [];
            obj.jcache   = 1;
        end
    end

    % ======================= DATA STRUCTURE =======================
    properties
        prior
    end
    properties % (SetAccess = private)
        parent, dsample, state, cache, links, capacity, icache, jcache
    end
    methods
        function value = get.dsample(obj)
            if obj.parent.expandable && isfield(obj.parent.apshare, 'dexpand')
                value = obj.dsample + obj.parent.apshare.dexpand;
            else
                value = obj.dsample;
            end
        end
        function set.dsample(obj, value)
            assert(MathLib.isinteger(value) && value > 0);
            obj.dsample = value;
        end
        
%         function set.parent(obj, value)
%             assert(isa(value, 'Unit'));
%             obj.parent = value;
%         end
        
        % function set.cache(obj, value)
        %     assert(isa(value, 'Package') && isvector(value));
        %     obj.cache = value;
        % end
        
        function set.links(obj, value)
            assert(isempty(value) || isa(value, 'AccessPoint'));
            obj.links = value;
        end
    end
end
