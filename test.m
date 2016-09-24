classdef test < handle
    properties
        a
    end
    methods
        function value = get.a(obj)
            if isempty(obj.a)
                obj.a = nan;
            end
            if isstruct(obj.a)
                value = fields(obj.a);
            else
                value = obj.a;
            end
        end
        function set.a(obj, value)
        % assert(isnumeric(value));
            obj.a = value;
        end
    end
end
