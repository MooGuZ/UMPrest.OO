classdef Listener < handle
    methods
        function package = collect(obj)
            frames = cell(1, obj.rec.cache.count);
            for i = 1 : numel(frames)
                frames{i} = obj.rec.pull();
            end
            if isscalar(frames)
                package = frames{1};
                package = DataPackage(splitdim(package.data, package.dsample + 1, 1), ...
                    package.dsample, true);
            else
                dsample = frames{1}.dsample;
                frames  = [frames{:}];
                data = cat(dsample + 2, frames.data);
                data = permute(data, [1 : dsample, dsample + [2, 1]]);
                package = DataPackage(data, dsample, true);
            end
        end
        
        function obj = detach(obj)
            obj.rec.isolate();
        end
        
        function obj = recrtmode(obj, n)
            if n == 1
                obj.rec.cache.simple();
            else
                obj.rec.cache.init(n);
            end
        end
    end
    
    methods
        function obj = Listener(ap)
            obj.rec = SimpleAP(obj, 'capacity', 100, '-nomerge');
            ap.connect(obj.rec);
        end
    end
    
    properties (SetAccess = protected)
        rec
    end
end