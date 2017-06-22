classdef PackageProcessor < Unit
% PACKAGEPROCESSOR is a virtual class representing units that process packages without
% unpacking them.
    methods
        function unitdump = dump(self)
            unitdump = {class(self)};
        end
    end
end
