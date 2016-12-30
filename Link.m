classdef Link < Unit
    methods
        function forward(obj)
            obj.O{1}.send(obj.I{1}.pull());
        end
        
        function backward(obj)
            obj.I{1}.send(obj.O{1}.pull());
        end
    end
    
    methods
        function clear(obj)
            obj.I{1}.reset();
            obj.O{1}.reset();
        end
        
        function isolate(obj)
            obj.I{1}.isolate();
            obj.O{1}.isolate();
        end
    end
    
    methods
        function obj = Link(apfrom, apto)
            obj.I = {SimpleAP(obj).connect(apfrom)};
            obj.O = {SimpleAP(obj).connect(apto)};
        end
    end
    
    properties (SetAccess = protected)
        I, O
    end
end