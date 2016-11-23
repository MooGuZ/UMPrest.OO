classdef UnitAP < AccessPoint
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
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = UnitAP(parent, dsample)
            obj = obj@AccessPoint(parent, dsample);
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        dsample
        prior
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
    end
end
