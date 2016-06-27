classdef DataPackage < handle
    methods
        % Problem : cannot deal with handle classes as the input
        %           HOWEVER, majority classes in UMPrest provide interfaces
        %           that return non-handle objects. So, this may not be a
        %           problem in practical.
        function newpkg = derive(obj, varargin)
            conf = Config.parse(varargin);
            if obj.numel() == 1
                newpkg = DataPackage( ...
                    Config.getValue(conf, 'data', {obj.data}), ...
                    'label', Config.getValue(conf, 'label', {obj.label}), ...
                    'info',  Config.getValue(conf, 'info', obj.info));
            else
                newpkg = DataPackage( ...
                    Config.getValue(conf, 'data', obj.data), ...
                    'label', Config.getValue(conf, 'label', obj.label), ...
                    'info',  Config.getValue(conf, 'info', obj.info));
            end
        end
        
        function n = numel(obj)
            assert(obj.nlabel == 0 || obj.ndata == obj.nlabel, ...
                'UMPrest:RuntimeError', 'Number of data and label does not match');
            n = obj.ndata;
        end
        
        function dpkg = get(obj, index)
            assert(index <= obj.ndata && index > 0);
            
            if isempty(obj.X)
                D = [];
            elseif iscell(obj.X)
                D = obj.X{index}.get();
            else
                D = MathLib.slice(obj.data, obj.datadim + 1, index);
            end
            
            if isempty(obj.Y)
                L = [];
            elseif iscell(obj.Y)
                L = obj.Y{index}.get();
            else
                L = MathLib.slice(obj.label, obj.labeldim + 1, index);
            end
            
            dpkg = DataPackage({D}, 'label', {L}, 'info', obj.info);
        end
    end
    
    methods (Static)
        % NOTE : currently COMBINE function only deal with DATA and LABEL fields
        function c = combine(a, b)
            assert(isa(a, 'DataPackage') && isa(b, 'DataPackage'));

            if a.nlabel == 0 && b.nlabel == 0
                labelC = [];
            elseif not(a.nlabel == 0 || b.nlabel == 0)
                labelA = a.label;
                labelB = b.label;
                if iscell(labelA) && iscell(labelB)
                    labelC = [labelA(:), labelB(:)];
                elseif iscell(labelA)
                    labelC = [labelA(:), num2cell(labelB, 1 : b.labeldim)];
                elseif iscell(labelB)
                    labelC = [num2cell(labelA, 1 : a.labeldim), labelB(:)];
                else
                    labelC = [];
                    if a.labeldim == b.labeldim
                        labelC = MathLib.matconcate(labelA, labelB); % TBC
                    end
                    if isempty(labelC)
                        labelC = [num2cell(labelA, 1 : a.labeldim), ...
                            num2cell(labelB, 1 : b.labeldim)];
                    end
                end
            else
                assert(false, 'UMPrest:RuningError', ...
                    'Cannot combine labeled and not-labeled data');
            end
            
            dataA = a.data;
            dataB = b.data;
            if iscell(dataA) && iscell(dataB)
                dataC = [dataA(:), dataB(:)];
            elseif iscell(dataA)
                dataC = [dataA(:), num2cell(dataB, 1 : b.datadim)];
            elseif iscell(dataB)
                dataC = [num2cell(dataA, 1 : a.datadim), dataB(:)];
            else
                dataC = [];
                if a.datadim == b.datadim
                    dataC = MathLib.matconcate(dataA, dataB);
                end
                if isempty(dataC)
                    dataC = [num2cell(dataA, 1 : a.datadim), ...
                        num2cell(dataB, 1 : b.datadim)];
                end
            end
            
            c = DataPackage(dataC, 'label', labelC);
            if not(dataC)
                c.datadim = a.datadim;
            end
            if not(iscell(labelC) || isempty(labelC))
                c.labeldim = a.labeldim;
            end
        end
        
        % COMPACT create compact storage in Tensor for given VALUE, which
        % could be cell or matrix of numeric or binary values. The second
        % return value referring to dimension of each basic unit. The
        % minimum unit dimension is 1, which means multiple scalar value
        % should provided as a row vector. Besides, if the input VALUE only
        % contains one unit with dimension greater than 1, you should input
        % a cell with 1 element instead for COMPACT to correctly recognize
        % the dimension information.
        function [data, dim, n] = compact(value)
            assert(isnumeric(value) || islogical(value) || iscell(value));
            
            n   = 0;
            dim = [];
            
            if isempty(value)
                data = [];
                return
            end
            
            if iscell(value)
                if numel(value) == 1
                    value = value{1};
                    if isempty(value)
                        data = [];
                        return
                    else
                        dim = MathLib.ndims(value);
                        n = 1;
                    end
                else
                    try
                        value = MathLib.concatecell(value);
                        dim = MathLib.ndims(value) - 1;
                        n = size(value, dim + 1);
                    catch excpt
                        if not(strcmpi(excpt.identifier, 'MathLib:RuntimeError'))
                            error(excpt);
                        end
                    end
                end
            else
                dim = MathLib.ndims(value) - 1;
                n = size(value, dim + 1);
            end
            
            if isnumeric(value) || islogical(value)
                data = Tensor(value);
            elseif iscell(value)
                n    = numel(value);
                data = cell(1, n);
                for i = 1 : numel(data)
                    data{i} = Tensor(value{i});
                end
            else
                error('UMPrest:RuntimeError', 'Should not happend');
            end
        end
        
        function pkgset = separate(dpkg)
            pkgset(1, dpkg.ndata) = dpkg.get(dpkg.ndata); % TBC
            for i = 1 : dpkg.ndata - 1
                pkgset(1, i) = dpkg.get(i);
            end
        end
    end
    
    methods
        function obj = DataPackage(data, varargin)
            conf = Config.parse(varargin);
            obj.data  = data;
            obj.label = Config.getValue(conf, 'label', []);
            obj.info  = Config.getValue(conf, 'info', struct());
        end
    end
    
    properties
        info, ndata, nlabel, datadim, labeldim
    end
    methods
        function set.info(obj, value)
            assert(isstruct(value));
            obj.info = value;
        end
        
        function set.ndata(obj, value)
            assert(MathLib.isinteger(value) && value >= 0);
            obj.ndata = value;
        end
        
        function set.nlabel(obj, value)
            assert(MathLib.isinteger(value) && value >= 0);
            obj.nlabel = value;
        end
        
        function set.datadim(obj, value)
            assert(isempty(value) || MathLib.isinteger(value) && value >= 0);
            obj.datadim = value;
        end
        
        function set.labeldim(obj, value)
            assert(isempty(value) || MathLib.isinteger(value) && value >= 0);
            obj.labeldim = value;
        end
    end
    
    properties (Hidden)
        X, Y
    end
    
    properties (Dependent)
        data, label, isunified
    end
    methods
        function value = get.data(obj)
            if isempty(obj.X)
                value = [];
            else
                if iscell(obj.X)
                    value = {obj.X{:}.get()};
                else
                    value = obj.X.get();
                end
            end
        end
        function set.data(obj, value)
            [obj.X, obj.datadim, obj.ndata] = DataPackage.compact(value);
        end
        
        function value = get.label(obj)
            if isempty(obj.Y)
                value = [];
            else
                if iscell(obj.Y)
                    value = {obj.Y{:}.get()};
                else
                    value = obj.Y.get();
                end
            end
        end
        function set.label(obj, value)
            [obj.Y, obj.labeldim, obj.nlabel] = DataPackage.compact(value);
        end
        
        function tof = get.isunified(obj)
            tof = not(iscell(obj.X) || iscell(obj.Y));
        end
    end
end
