classdef Queue < handle
    methods
        function unit = pop(obj)
            if obj.isempty
                error('ILLEGAL OPERATION');
            else
                unit = obj.X{obj.head};
                obj.head = obj.next(obj.head);
                % update ISFULL flag
                obj.isfull = false;
            end
        end
        
        function unit = stackpop(obj)
            if obj.isempty
                error('ILLEGAL OPERATION');
            else
                obj.tail = obj.prev(obj.tail);
                unit = obj.X{obj.tail};
                obj.isfull = false;
            end
        end
        
        function push(obj, unit)
            if obj.isfull
                if obj.dropold
                    obj.head = obj.next(obj.head);
                    obj.X{obj.tail} = unit;
                    obj.tail = obj.next(obj.tail);
                else
                    error('ILLEGAL OPERATION');
                end
            else
                obj.X{obj.tail} = unit;
                obj.tail = obj.next(obj.tail);
                if obj.tail == obj.head % become full
                    obj.isfull = true;
                    if isinf(obj.capacity)
                        index = [obj.head : numel(obj.X), 1 : obj.tail - 1];
                        % expand container
                        obj.X = [obj.X(index), cell(1, obj.expandSize)];
                        % update index
                        obj.head = 1;
                        obj.tail = numel(index) + 1;
                        % update ISFULL flag (require EXPANDSIZE > 0)
                        obj.isfull = false;
                    end
                end
            end
        end
        
        function init(obj)
            n = obj.capacity;
            if isinf(n)
                n = obj.expandSize;
            end
            if n > numel(obj.X)
                obj.X = cell(1, n);
            end
            obj.clean();
        end
        
        function clean(obj)
            obj.head   = 1;
            obj.tail   = 1;
            obj.isfull = false;
        end
    end
    
    methods (Access = protected)
        function index = prev(obj, index)
            if isinf(obj.capacity)
                if index <= 1
                    error('NOT EXIST');
                else
                    index = index - 1;
                end
            else
                index = mod(index - 2, obj.capacity) + 1;
            end
        end
        
        function index = next(obj, index)
            if isinf(obj.capacity)
                index = index + 1;
            else
                index = mod(index, obj.capacity) + 1;
            end
        end
    end
    
    methods
        function obj = Queue(varargin)
            conf = Config(varargin);
            obj.capacity = conf.get('capacity', inf);
            obj.dropold  = conf.get('dropold', false);
        end
    end
    
    properties
        capacity, dropold
    end
    properties (Constant, Hidden)
        expandSize = 100;
    end
    properties (Access = protected)
        X, head, tail
    end
    properties (SetAccess = protected)
        isfull
    end
    properties (Dependent)
        isempty, count
    end
    methods
        function set.capacity(obj, value)
            assert(value > 0);
            obj.capacity = value;
            obj.init();
        end
        
        function value = get.isempty(obj)
            value = not(obj.isfull) && (obj.head == obj.tail);
        end
        
        function value = get.count(obj)
            if obj.isfull
                value = obj.capacity;
            elseif isinf(obj.capacity)
                value = obj.tail - obj.head;
            else
                value = mod(obj.tail - obj.head, obj.capacity);
            end
        end
    end
end
