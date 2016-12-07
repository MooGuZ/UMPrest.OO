classdef FrameQueue < Queue
    methods
        function package = first(obj)
            if obj.isempty
                error('ILLEGAL OPERTAION');
            else
                package = obj.X{obj.head};
            end
        end
    end
    
    methods
        function nextframe(obj, package)
            if obj.isempty
                obj.push(package);
            else
                try
                    obj.first.merge(package);
                catch
                    error('OPERATION FAILED');
                end
            end                
        end
    end
end