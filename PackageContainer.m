classdef PackageContainer < Container
% PACKAGECONTAINER is a container that would automatically combine ErrorPackages
    methods
        function push(obj, element)
        % NOTE: this implementation is based on the assumption that only 
        %       ERRORPACKAGE has MERGE methods
            switch class(element)
              case {'ErrorPackage'}
                try
                    obj.fetch(obj.count).merge(element);
                catch
                    push@Container(obj, element);
                end
                
              case {'DataPackage', 'SizePackage'}
                push@Container(obj, element);
                
              otherwise
                error('UNSUPPORTED');
            end
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
