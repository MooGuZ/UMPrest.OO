classdef RecurrentInterface < handle
    methods
        function extract(obj, package)
            if not(exist('package', 'var'))
                package = obj.pkgap.pull();
            end
            frames = obj.pkgap.unpack(package);
            % fill up cache of frames
            obj.frmap.reset();
            for i = 1 : numel(frames)
                obj.frmap.push(frames{i});
            end
        end
        
        function package = compress(obj)
            frames = cell(1, obj.frmap.cache.count);
            for i = 1 : numel(frames)
                frames{i} = obj.frmap.pull();
            end
            package = obj.pkgap.packup(frames);
        end
        
        function sendFrame(obj)
            obj.frmap.send(obj.frmap.pull());
        end
    end
    
    methods
        function obj = RecurrentInterface(parent, hostap)
            obj.parent = parent;
            obj.pkgap  = RecurrentAP(parent).connect(hostap.isolate());
            obj.frmap  = SimpleAP(parent, parent.memoryLength).connect(hostap);
        end
    end
    
    properties
        parent % recurrent unit, this instance blongs to
        frmap  % access point containing frames send to kernel
        pkgap  % access point containing package from outside
    end
end
