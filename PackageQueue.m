classdef PackageQueue < Queue
    methods (Access = protected)
        function package = last(obj)
            if obj.isempty
                error('ILLEAGAL OPERATION');
            else
                package = obj.X{obj.prev(obj.tail)};
            end
        end
    end
    
    methods
        function push(obj, package)
            if isa(package, 'ErrorPackage')
                try
                    lastunit = obj.last();
                    if isa(lastunit, 'ErrorPackage')
                        lastunit.merge(package);
                    end
                catch
                    push@Queue(obj, package);
                end
            elseif isa(package, 'Package')
                push@Queue(obj, package);
            else
                error('NOT ACCEPTED');
            end
        end
    end
    
    methods
        function obj = PackageQueue(varargin)
            obj@Queue(varargin{:});
        end
    end
end