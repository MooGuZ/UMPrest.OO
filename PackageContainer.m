classdef PackageContainer < Container
% PACKAGECONTAINER is a container that would automatically combine ErrorPackages
    methods
        function push(obj, element)
            if obj.count && isa(element, 'ErrorPackage')
                stacktop = obj.fetch(obj.count);
                if isa(stacktop, 'ErrorPackage')
                    try
                        stacktop.merge(element);
                        return
                    catch
                        % do nothing
                    end
                end
            end
            push@Container(obj, element);
        end
    end
    
    methods (Static)
        function obj = loadobj(sstruct)
            if sstruct.issimple
                obj = PackageContainer();
            elseif sstruct.overwrite
                obj = PackageContainer(sstruct.capacity, '-overwrite');
            else
                obj = PackageContainer(sstruct.capacity);
            end
        end
    end
    
    methods
        function obj = PackageContainer(varargin)
            obj@Container(varargin{:});
        end
    end
end
