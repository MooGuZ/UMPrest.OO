classdef AccessPoint < handle
    methods
        function send(obj, package)
            switch numel(obj.links)
              case {0}
                return
                  
              case {1}
                obj.links{1}.push(package);
                
              otherwise
                cellfun(@(ap) ap.push(package), obj.links);
            end
        end
        
        function push(obj, package)
            obj.cache.push(package);
        end
        
        function package = pop(obj)
            package = obj.cache.pop();
        end
    end
       
    methods
        function connect(obj, ap)
            obj.addlink(ap);
            ap.addlink(obj);
        end
        
        function disconnect(obj, ap)
            obj.rmlink(ap);
            ap.rmlink(obj);
        end
        
        function addlink(obj, ap)
            if isempty(obj.links)
                obj.links = {ap};
            elseif any(cellfun(@ap.compare, obj.links))
                return
            else
                obj.links{end + 1} = ap;
            end
        end
        
        function rmlink(obj, ap)
            switch numel(obj.links)
              case {0}
                return
                
              case {1}
                if ap.compare(obj.links{1})
                    obj.links = {};
                end
                
              otherwise
                tf = cellfun(@ap.compare, obj.links);
                obj.links(tf) = [];
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
            obj.id    = obj.idset.register();
            obj.links = {};
        end
        
        function delete(obj)
            obj.idset.deregister(obj.id);
        end
    end
    
    properties (Constant)
        idset = IDSet()
    end
    properties (SetAccess = protected)
        id, links
    end
    properties (Abstract, SetAccess = protected)
        parent, cache, state
    end
    properties (Dependent)
        isfull, isempty, count
    end
    methods
        function value = get.isfull(obj)
            value = obj.cache.isfull;
        end
        
        function value = get.isempty(obj)
            value = obj.cache.isempty;
        end
        
        function value = get.count(obj)
            value = obj.cache.count;
        end
    end
end
