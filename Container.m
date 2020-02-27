classdef Container < handle
    methods
        function push(obj, element)
            if obj.issimple
                obj.C       = element;
                obj.isfull  = true;
                obj.isempty = false;
            elseif obj.isfull
                if obj.overwrite
                    obj.C{obj.tail} = element;
                    obj.tail = obj.seek(obj.tail, 1);
                    obj.head = obj.seek(obj.head, 1);
                else
                    error('CONTAINER IS FULL');
                end
            elseif not(isinf(obj.capacity))
                obj.C{obj.tail} = element;
                obj.tail = obj.seek(obj.tail, 1);
                if obj.tail == obj.head
                    obj.isfull = true;
                end
                obj.isempty = false;
            else
                if obj.tail > numel(obj.C)
                    obj.expand();
                end
                obj.C{obj.tail} = element;
                obj.isempty = false;
            end
        end
        
        function element = pull(obj)
            if obj.isempty
                error('CONTAINER IS EMPTY');
            elseif obj.issimple
                element     = obj.C;
                obj.isfull  = false;
                obj.isempty = true;
            else
                element  = obj.C{obj.head};
                obj.head = obj.seek(obj.head, 1);
                if obj.head == obj.tail
                    obj.isempty = true;
                end
                obj.isfull = false;
            end
        end
        
        function element = pop(obj)
            if obj.isempty
                error('CONTAINER IS EMPTY');
            elseif obj.issimple
                element   = obj.C;
                obj.isfull  = false;
                obj.isempty = true;
            else
                obj.tail = obj.seek(obj.tail, -1);
                element  = obj.C{obj.tail};
                if obj.tail == obj.head
                    obj.isempty = true;
                end
                obj.isfull = false;
            end
        end
        
        function element = fetch(obj, index)
            if index > 0 && index <= obj.count
                if obj.issimple
                    element = obj.C;
                else
                    element = obj.C{obj.seek(obj.head, index - 1)};
                end
            elseif index < 0 && index >= -obj.count
                if obj.issimple
                    element = obj.C;
                else
                    element = obj.C{obj.seek(obj.tail, index)};
                end
            else
                error('OUT OF RANGE');
            end
        end
        
        function obj = reset(obj)
            obj.head     = 1;
            obj.tail     = 1;
            obj.isempty  = true;
            obj.isfull   = false;
        end
    end
    
    methods (Access = protected)
        function index = seek(obj, base, inc)
            if not(isinf(obj.capacity))
                index = mod(base + inc - 1, obj.capacity) + 1;
            else                
                index = base + inc;
            end
        end
        
        function obj = expand(obj)
        % this function only works on infinite container, 
        % otherwise, would lead to some bug.
            n = (floor(obj.count / obj.expandSize) + 1) * obj.expandSize;
            obj.C = [obj.C(obj.head : obj.tail - 1), cell(1, n - obj.count)];
            obj.tail = obj.count + 1;
            obj.head = 1;  
        end
    end
    
    methods
        function obj = simple(obj)
        % make container works in simple mode as an variable
            obj.issimple  = true;
            obj.overwrite = true;
            obj.capacity  = 1;
            obj.C = [];
            obj.reset();
        end
        
        function obj = init(obj, n)
            if isinf(n)
                obj.C = cell(1, obj.expandSize);
            elseif n == 1
                obj.simple()
            else
                assert(MathLib.isinteger(n) && n > 0, 'ILLEGAL ARGUMENT');
                obj.C = cell(1, n);
            end
            obj.issimple = false;
            obj.capacity = n;
            obj.reset();
        end
    end
    
    methods
        function sstruct = saveobj(obj)
            sstruct = struct( ...
                'issimple',  obj.issimple, ...
                'capacity',  obj.capacity, ...
                'overwrite', obj.overwrite);
        end
    end
    methods (Static)
        function obj = loadobj(sstruct)
            if sstruct.issimple
                obj = Container();
            elseif sstruct.overwrite
                obj = Container(sstruct.capacity, '-overwrite');
            else
                obj = Container(sstruct.capacity);
            end
        end
    end
    
    methods
        function obj = Container(n, varargin)
            if exist('n', 'var')
                obj.init(n);
                obj.overwrite = Config(varargin).pop('overwrite', false);
            else
                obj.simple();
            end
        end
    end
    
    properties (Access = protected)
        C
        head
        tail
    end
    properties (SetAccess = protected, Hidden)
        issimple
        isempty
        isfull
    end
    properties (Access = private, Constant)
        expandSize = 20
    end
    properties (SetAccess = private)
        capacity
    end
    properties
        overwrite
    end
    properties (Dependent)
        count
    end
    methods
        function set.overwrite(obj, tf)
            if obj.issimple && not(tf)
                warning('PROPERTY [OVERWRITE] CANNOT SET TO FALSE IN SIMPLE MODE');
            else
                obj.overwrite = logical(tf);
            end
        end
        
        function n = get.count(obj)
            if obj.isfull
                n = obj.capacity;
            elseif obj.isempty
                n = 0;
            elseif isinf(obj.capacity)
                n = obj.tail - obj.head;
            else
                n = mod(obj.tail - obj.head, obj.capacity);
            end
        end
    end
end

