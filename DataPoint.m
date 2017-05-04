classdef DataPoint < PackageProcessor
    methods
        function opackage = forward(obj, ipackage)
            if not(exist('ipackage', 'var'))
                opackage = obj.I{1}.pop();
            else
                opackage = ipackage
            end
            
            if nargout == 0
                obj.O{1}.send(opackage);
            end
        end
        
        function ipackage = backward(obj, opackage)
            if not(exist('opackage', 'var'))
                ipackage = obj.O{1}.pop();
            else
                ipackage = opackage;
            end
            
            if nargout == 0
                obj.I{1}.send(ipackage);
            end
        end
    end
    
    properties (SetAccess = protected)
        I, O
    end
    
    methods
        function obj = DataPoint()
            obj.I = {SimpleAP(obj)};
            obj.O = {SimpleAP(obj)};
        end
    end
end
