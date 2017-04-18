classdef ConvOperator < MISOUnit & FeedforwardOperation
    methods
        function y = dataproc(~, x, f)
            y = MathLib.nnconv(x, f, zeros(1, size(f, 4)), 'same');
        end
        
        function [dX, dF] = deltaproc(obj, dY)
            [dX, dF] = MathLib.nnconvDifferential( dY, ...
                obj.datain.datarcd.pop(), obj.filter.datarcd.pop(), 'same');
        end
    end
    
    methods
        function sizeDataOut = sizeIn2Out(~, sizeDataIn, sizeFilter)
            sizeDataOut = sizeDataIn;
            sizeDataOut(3) = sizeFilter(4);
        end
        
        function [sizeDataIn, sizeFilter] = sizeOut2In(~, sizeDataOut)
            % PRM: undetermined
            sizeDataIn = [sizeDataOut(1:2), nan, sizeDataOut(4)];
            sizeFilter = [nan, nan, nan, sizeDataOut(3)];
        end
    end
    
    methods
        function obj = ConvOperator()
            obj.datain = UnitAP(obj, 3, '-recdata');
            obj.filter = UnitAP(obj, 4, '-recdata');
            obj.dataout = UnitAP(obj, 3);
            obj.I = {obj.datain, obj.filter};
            obj.O = {obj.dataout};
        end
    end
    
    properties
        datain, dataout, filter
    end
    
    properties (Constant)
        taxis = false;
    end
end
