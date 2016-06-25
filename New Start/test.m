classdef test < handle
    properties
        a = 2;
    end
    methods
        function set.a(obj, value)
            obj.a.status = value;
            obj.a.conf   = 2;
        end
        function varargout = series(obj)
            varargout = cell(1, nargout);
            for i = 1 : nargout-1
                varargout{i} = obj.a^i;
            end
        end
    end
end
