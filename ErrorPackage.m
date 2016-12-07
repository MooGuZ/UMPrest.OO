% PRP: add field for derivative from prior
classdef ErrorPackage < DataPackage
    methods
        function merge(obj, package)
            if all(obj.datasize == package.datasize)
                obj.data = obj.data + package.data;
            else
                error('ILLEAGAL OPERATION');
            end
        end
    end
    
    methods
        function obj = ErrorPackage(varargin)
            obj = obj@DataPackage(varargin{:});
        end
    end
end
