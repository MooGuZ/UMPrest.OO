classdef Scaler < SISOUnit & FeedforwardOperation
    methods
        function y = dataproc(self, x)
            y = self.scale * x;
        end
        
        function dx = deltaproc(self, dy)
            dx = self.scale * dy;
        end
        
        function ysize = sizeIn2Out(~, xsize)
            ysize = xsize;
        end
        
        function xsize = sizeOut2In(~, ysize)
            xsize = ysize;
        end
        
        function unitdump = dump(self)
            unitdump = {'Scaler', self.scale};
        end
    end
    
    methods
        function self = Scaler(scale)
            self.scale = scale;
            self.I = {UnitAP(self, 0, '-expandable')};
            self.O = {UnitAP(self, 0, '-expandable')};
        end
    end
    
    properties
        scale
    end
    properties (Constant, Hidden)
        taxis = false
    end
    methods
        function set.scale(self, value)
            assert(isnumeric(value) && isscalar(value), 'ILLEGAL ASSIGNMENT');
            self.scale = value;
        end
    end
end
