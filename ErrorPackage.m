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
        
        function clone = copy(obj)
            clone = ErrorPackage(obj.data, obj.dsample, obj.taxis, obj.updateHParam);
        end
    end
    
    methods
        function obj = ErrorPackage(error, dsample, taxis, updateHParam)
            obj = obj@DataPackage(error, dsample, taxis);
            if exist('updateHParam', 'var')
                obj.updateHParam = updateHParam;
            else
                obj.updateHParam = true;
            end
        end
    end
    
    properties
        updateHParam
    end
    methods
        function set.updateHParam(self, value)
            assert(islogical(value), 'ILLEGAL ASSIGNMENT');
            self.updateHParam = value;
        end
    end
end
