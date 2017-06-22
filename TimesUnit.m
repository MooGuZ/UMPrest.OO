classdef TimesUnit < MISOUnit & FeedforwardOperation
    methods
        function output = dataproc(~, inputA, inputB)
            output = inputA .* inputB;
        end
        
        function [inputA, inputB] = deltaproc(obj, output)
            inputA = output .* obj.IB.datarcd.pop();
            inputB = output .* obj.IA.datarcd.pop();
        end
        
        function datasize = sizeIn2Out(~, datasize, ~)
        end
        
        function [sizeinA, sizeinB] = sizeOut2In(~, sizeout)
            sizeinA = sizeout;
            sizeinB = sizeout;
        end
        
        function unitdump = dump(~)
            unitdump = {'TimesUnit'};
        end
    end
    
    methods
        function obj = TimesUnit()
            obj.IA = UnitAP(obj, 1, '-recdata');
            obj.IB = UnitAP(obj, 1, '-recdata');
            obj.O = {UnitAP(obj, 1)};
            obj.I = {obj.IA, obj.IB};
        end
    end
    
    properties
        IA, IB
    end
    
    properties (Constant, Hidden)
        expandable = true;
        taxis      = false;
    end
end