classdef SimpleAP < AccessPoint
    methods
        function obj = SimpleAP(parent, varargin)
            obj.parent = parent;
            % analyze input arguments
            conf = Config(varargin);
            capacity = conf.pop('capacity', 0);
            nomerge  = conf.pop('nomerge', false);
            % build cache container
            if capacity && nomerge
                obj.cache = Container(capacity);
            elseif capacity
                obj.cache = PackageContainer(capacity);
            elseif nomerge
                obj.cache = Container();
            else
                obj.cache = PackageContainer();
            end
        end
    end
    
    properties (SetAccess = protected)
        parent
    end
    methods
        % function set.parent(obj, value)
        %     assert(isa(value, 'Unit'), 'ILLEGAL ASSIGNMENT');
        %     obj.parent = value;
        % end
    end
end
