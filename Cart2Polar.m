classdef Cart2Polar < MIMOUnit & FeedforwardOperation
    methods
        function [r, theta] = dataproc(~, x, y)
            r = sqrt(x.^2 + y.^2);
            theta = atan(y ./ x);
            % case 2nd & 3rd quadrant
            xnegmask = x < 0;
            quad2nd = (theta < 0) & xnegmask;
            quad3rd = (theta > 0) & xnegmask;
            theta(quad2nd) = theta(quad2nd) + pi;
            theta(quad3rd) = theta(quad3rd) - pi;
            % special case : (0, 0) -> (0, 0)
            theta(isnan(theta)) = 0;
        end
        
        function [dx, dy] = deltaproc(obj, dr, dtheta)
            x = obj.X.datarcd.pop();
            y = obj.Y.datarcd.pop();
            r = obj.R.datarcd.pop();
            theta = obj.Theta.datarcd.pop();
            
            % special case : r == 0
            r(r == 0) = eps;
            
            dtheta = dtheta ./ r.^2;
            
            dx = dr .* cos(theta) - dtheta .* y;
            dy = dr .* sin(theta) + dtheta .* x;
        end
        
        function [szr, sztheta] = sizeIn2Out(~, szx, szy)
            szr     = szx;
            sztheta = szy;
        end
        
        function [szx, szy] = sizeOut2In(~, szr, sztheta)
            szx = szr;
            szy = sztheta;
        end
        
        function dumpunit = dump(~)
            dumpunit = {'Cart2Polar'};
        end        
    end
    
    methods
        function obj = Cart2Polar()
            obj.X     = UnitAP(obj, 0, '-expandable', '-recdata');
            obj.Y     = UnitAP(obj, 0, '-expandable', '-recdata');
            obj.R     = UnitAP(obj, 0, '-expandable', '-recdata');
            obj.Theta = UnitAP(obj, 0, '-expandable', '-recdata');
            obj.I     = {obj.X, obj.Y};
            obj.O     = {obj.R, obj.Theta};
        end
    end
    
    properties
        X, Y, R, Theta
    end
    
    properties (Constant)
        taxis = false;
    end
end