classdef SizePackage < Package
    properties
        sizeinfo
    end
    methods
        function obj = SizePackage(sizeinfo)
            obj.sizeinfo = sizeinfo;
        end
    end
end