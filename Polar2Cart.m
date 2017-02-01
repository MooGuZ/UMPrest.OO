classdef Polar2Cart < MIMOUnit & FeedforwardOperation
    methods
        function [x, y] = dataproc(~, r, theta)
            x = r .* cos(theta);
            y = r .* sin(theta);
        end
        
        function [dr, dtheta] = deltaproc(obj, dx, dy)
            r = obj.R.datarcd.pop();
            theta = obj.Theta.datarcd.pop();
            
            costh = cos(theta);
            sinth = sin(theta);
            
            dr = dx .* costh + dy .* sinth;
            dtheta = dy .* r .* costh - dx .* r .* sinth;
        end
        
        function [szx, szy] = sizeIn2Out(~, szr, sztheta)
            szx = szr;
            szy = sztheta;
        end
        
        function [szr, sztheta] = sizeOut2In(~, szx, szy)
            szr     = szx;
            sztheta = szy;
        end
    end
    
    methods
        function obj = Polar2Cart()
            obj.X     = UnitAP(obj, 0, '-expandable');
            obj.Y     = UnitAP(obj, 0, '-expandable');
            obj.R     = UnitAP(obj, 0, '-expandable', '-recdata');
            obj.Theta = UnitAP(obj, 0, '-expandable', '-recdata');
            obj.I     = {obj.R, obj.Theta};
            obj.O     = {obj.X, obj.Y};
        end
    end
    
    properties
        X, Y, R, Theta
    end
    
    properties (Constant)
        taxis = false;
    end
end