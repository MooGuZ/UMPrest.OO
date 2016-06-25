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
            assert(obj.info.nlabel == 0 || obj.info.ndata == obj.info.nlabel, ...
                'UMPrest:RuntimeError', 'Number of data and label does not match');
            n = obj.info.ndata;
        end
    end
    
    methods (Static)
        % NOTE : currently COMBINE function only deal with DATA and LABEL fields
        function c = combine(a, b)
            assert(isa(a, 'DataPackage') && isa(b, 'DataPackage'));

            if a.info.nlabel == 0 && b.info.nlabel == 0
                labelC = [];
            elseif not(a.info.nlabel == 0 || b.info.nlabel == 0)
                labelA = a.label;
                labelB = b.label;
                if iscell(labelA) && iscell(labelB)
                    labelC = [labelA(:), labelB(:)];
                elseif iscell(labelA)
                    labelC = [labelA(:), num2cell(labelB, 1 : b.info.labeldim)];
                elseif iscell(labelB)
                    labelC = [num2cell(labelA, 1 : a.info.labeldim), labelB(:)];
                else
                    labelC = [];
                    if a.info.labeldim == b.info.labeldim
                        labelC = MathLib.matconcate(labelA, labelB); % TBC
                    end
                    if isempty(labelC)
                        labelC = [num2cell(labelA, 1 : a.info.labeldim), ...
                            num2cell(labelB, 1 : b.info.labeldim)];
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
                dataC = [dataA(:), num2cell(dataB, 1 : b.info.datadim)];
            elseif iscell(dataB)
                dataC = [num2cell(dataA, 1 : a.info.datadim), dataB(:)];
            else
                dataC = [];
                if a.info.datadim == b.info.datadim
                    dataC = MathLib.matconcate(dataA, dataB);
                end
                if isempty(dataC)
                    dataC = [num2cell(dataA, 1 : a.info.datadim), ...
                        num2cell(dataB, 1 : b.info.datadim)];
                end
            end
            
            c = DataPackage(dataC, 'label', labelC);
            if not(dataC)
                c.info.datadim = a.info.datadim;
            end
            if not(iscell(labelC) || isempty(labelC))
                c.info.labeldim = a.info.labeldim;
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
            if iscell(value)
                if numel(value) == 1
                    value = value{1};
                    dim = ndims(value);
                    n = 1;
                else
                    try
                        value = MathLib.concatecell(value);
                        dim = ndims(value) - 1;
                        n = size(value, dim + 1);
                    catch excpt
                        if not(strcmpi(excpt.identifier, 'MathLib:RuntimeError'))
                            error(excpt);
                        end
                    end
                end
            else
                dim = ndims(value) - 1;
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
    end
    
    methods
        function obj = DataPackage(data, varargin)
            conf = Config.parse(varargin);
            obj.info  = Config.getValue(conf, 'info', struct());
            obj.label = Config.getValue(conf, 'label', []);
            obj.data  = data;
        end
    end
    
    properties
        info
    end
    methods
        function set.info(obj, value)
            assert(isstruct(value));
            obj.info = value;
        end
    end
    
    properties (Hidden)
        X, Y
    end
    
    properties (Dependent)
        data, label
    end
    methods
        function value = get.data(obj)
            if iscell(obj.X)
                value = {obj.X{:}.get()};
            else
                value = obj.X.get();
            end
        end
        function set.data(obj, value)
            [obj.X, obj.info.datadim, obj.info.ndata] = DataPackage.compact(value);
        end
        
        function value = get.label(obj)
            if iscell(obj.Y)
                value = {obj.Y{:}.get()};
            else
                value = obj.Y.get();
            end
        end
        function set.label(obj, value)
            [obj.Y, obj.info.labeldim, obj.info.nlabel] = DataPackage.compact(value);
        end
    end
end