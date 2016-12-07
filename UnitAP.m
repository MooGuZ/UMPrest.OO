% TODO: apply prior gradient to ERRORPACKAGE in UNPACK process
classdef UnitAP < SimpleAP
    % ======================= DATA PROCESSING =======================
    methods
        function data = unpack(obj, package)
            obj.consistencyCheck('class', class(package));            
            obj.consistencyCheck('taxis', package.taxis);
            % unpack packge according to their class
            switch class(package)
                % Processing of DataPackage made following assumptions:
                %  1. Package received by any SIMPLEUNIT should be
                %     consistantly in the state of TAXIS. Theoritically,
                %     this is not an absolute restriction. However, here
                %     make it for convenience.
                %  2. Packages have the same size on TAXIS, if exist, and
                %     BATCH dimension. Here excludes the situation that
                %     batch data coorperating with a single sample.
                %     However, this may not be a necessary feature for
                %     learning program.
                case {'DataPackage'}
                    obj.consistencyCheck('nsample', package.nsample);
                    obj.consistencyCheck('nsequence', package.nsequence);
                    % reshape data if necessary
                    data = reshape(package.data, obj.sizeOut2In( ...
                        package.datasize, package.dsample, package.taxis));
                    obj.state.data = data;
                    % if package.taxis && not(obj.parent.taxis)
                    %     obj.parent.apshare.nframe = package.nsample / package.nsequence;
                    %     data = MathLib.expandDim(package.data, package.dsample + 1);
                    % elseif not(package.taxis) && obj.parent.taxis
                    %     data = MathLib.splitDim(package.data, package.dsample + 1, 1);
                    % else
                    %     data = package.data;
                    % end
                    
                case {'ErrorPackage'}
                    obj.consistencyCheck('nsample', package.nsample);
                    obj.consistencyCheck('nsequence', package.nsequence);
                    % reshape data if necessary
                    data = reshape(package.data, obj.sizeOut2In( ...
                        package.datasize, package.dsample, package.taxis));
                    
                case {'SizePackage'}
                    data = obj.sizeOut2In(package.data, package.dsample, package.taxis);
                    
                otherwise
                    error('UNSUPPORTED');
            end
            % record states
            obj.state.package = package;
        end
        
        function package = packup(obj, data)
            switch obj.parent.apshare.class
                case {'DataPackage'}
                    % reshape data if necessary
                    data = reshape(data, obj.sizeIn2Out(size(data), obj.parent.apshare.taxis));
                    % if obj.parent.apshare.taxis && not(obj.parent.taxis)
                    %     data = MathLib.splitDim(data, obj.dsample + 1, obj.parent.apshare.nframe);
                    % elseif not(obj.parent.apshare.taxis) && obj.parent.taxis
                    %     data = MathLib.expandDim(data, obj.dsample + 1);
                    % end
                    % create package
                    obj.state.data = data;
                    package = DataPackage(data, obj.dsample, obj.parent.apshare.taxis);
                    
                case {'ErrorPackage'}
                    % reshape data if necessary
                    data = reshape(data, obj.sizeIn2Out(size(data), obj.parent.apshare.taxis));
                    % if obj.parent.apshare.taxis && not(obj.parent.taxis)
                    %     data = MathLib.splitDim(data, obj.dsample + 1, obj.parent.apshare.nframe);
                    % elseif not(obj.parent.apshare.taxis) && obj.parent.taxis
                    %     data = MathLib.expandDim(data, obj.dsample + 1);
                    % end
                    % create package
                    package = ErrorPackage(data, obj.dsample, obj.parent.apshare.taxis);
                    
                case {'SizePackage'}
                    package = SizePackage(obj.sizeIn2Out(data), obj.parent.apshare.taxis);
                    
                otherwise
                    error('Other Package types are not supported at current time.');
            end
            obj.state.package = package;
        end
    end
    
    methods (Access = private)
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
        
        function datasize = sizeOut2In(obj, datasize, dsample, taxis)
            % CASE: data with TAXIS and unit has not
            if taxis && not(obj.parent.taxis)
                datasize = [datasize(1 : dsample), prod(datasize(dsample + 1 : end))];
            % CASE: data without TAXIS and unit has
            elseif not(taxis) && obj.parent.taxis
                datasize = [datasize(1 : dsample), 1, datasize(dsample + 1 : end)];
            end

            % CASE: sample of data doesn't have sufficient dimensions
            if dsample < obj.dsample
                datasize = [datasize(1 : dsample), ones(1, obj.dsample - dsample), ...
                    datasize(dsample + 1 : end)];
            elseif not(obj.parent.expandable)
                % CASE: sample of data has too many dimensions, while this is
                %       and element-wise unit
                if dsample > 1 && obj.dsample == 1  
                    datasize = [prod(datasize(1 : dsample)), datasize(dsample + 1 : end)];
                elseif dsample > obj.dsample
                    error('SHAPE MISMATCH');
                end
            elseif isfield(obj.parent.apshare, 'dexpand')
                assert(dsample == obj.dsample, 'SHAPE MISMATCH');
            else
                obj.parent.apshare.dexpand = dsample - obj.dsample;
            end
        end
        
        function datasize = sizeIn2Out(obj, datasize, taxis)
            ndim = obj.dsample + double(obj.parent.taxis) + 1;
            if numel(datasize) < ndim
                datasize = [datasize, ones(1, ndim - numel(datasize))];
            elseif numel(datasize) > ndim
                error('BUG HERE');
            end
            % CASE: unit has TAXIS and data has not
            if obj.parent.taxis && not(taxis)
                datasize = [datasize(1 : obj.dsample), prod(datasize(obj.dsample + 1 : end))];
            % CASE: unit doesn't deal with TAXIS, while data has
            elseif not(obj.parent.taxis) && taxis
                datasize = [datasize(1 : obj.dsample), 1, datasize(obj.dsample + 1 : end)];
            end
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = UnitAP(varargin)
            obj@SimpleAP(varargin{:});
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (SetAccess = protected)
        parent, dsample, prior % PRB: PRIOR should restrict to EvolvingUnits
    end
    methods
        function set.parent(obj, value)
            assert(isa(value, 'SimpleUnit'), 'ILLEGAL OPERATION');
            obj.parent = value;
        end
        
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
        
        function set.prior(obj, value)
            assert(all(arrayfun(@(o) isa(o, 'Prior'), value)), ...
                'ILLEGAL OPERATION');
            obj.prior = value;
        end
    end
end
