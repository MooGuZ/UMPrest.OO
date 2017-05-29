classdef AccessPoint < handle
    methods
        function send(obj, package)
            for i = 1 : numel(obj.links)
                obj.links{i}.push(package);
            end
            obj.packagercd = package;
        end
        
        function push(obj, package)
            obj.cache.push(package);
        end
        
        function package = pop(obj)
            try
                package = obj.cache.pop();
            catch ME
                if obj.absent
                    package = [];
                else
                    throw(ME);
                end
            end
        end
        
        function package = pull(obj)
            try
                package = obj.cache.pull();
            catch ME
                if obj.absent
                    package = [];
                else
                    throw(ME);
                end
            end
        end
        
        function package = fetch(obj, index)
            package = obj.cache.fetch(index);
        end
        
        function reset(obj)
            obj.cache.reset();
        end
    end
    
    methods
        function obj = connect(obj, varargin)
            for i = 1 : numel(varargin)
                apoint = varargin{i};
                obj.addlink(apoint);
                apoint.addlink(obj);
            end
        end
        
        function obj = disconnect(obj, varargin)
            for i = 1 : numel(varargin)
                apoint = varargin{i};
                obj.rmlink(apoint);
                apoint.rmlink(obj);
            end
        end
        
        function aplist = isolate(obj)
            aplist = obj.links;
            for i = 1 : numel(aplist)
                obj.disconnect(aplist{i});
            end
        end
        
        function addlink(obj, ap)
            for i = 1 : numel(obj.links)
                if ap.compare(obj.links{i})
                    return
                end
            end
            obj.links{end + 1} = ap;
        end
        
        function rmlink(obj, ap)
            for i = 1 : numel(obj.links)
                if ap.compare(obj.links{i})
                    obj.links(i) = [];
                    return
                end
            end
        end
    end
    
    methods
        function tf = compare(obj, ap)
            tf = strcmp(obj.id, ap.id);
        end
    end
    
    methods
        function obj = AccessPoint()
            obj.id = obj.idset.register();
        end
        
        function delete(obj)
            obj.idset.deregister(obj.id);
        end
    end
    
    properties (Constant)
        idset = IDSet()
    end
    properties (SetAccess = protected)
        id, cache, links = {}, absent = false
    end
    properties (Transient)
        packagercd = []
    end
    properties (Abstract, SetAccess = protected)
        parent
    end
    properties (Dependent)
        isempty
    end
    methods
        function set.cache(obj, value)
            assert(isa(value, 'Container'), 'ILLEGAL ASSIGNMENT');
            obj.cache = value;
        end
        
        function value = get.isempty(obj)
            value = obj.cache.isempty;
        end
    end
end
