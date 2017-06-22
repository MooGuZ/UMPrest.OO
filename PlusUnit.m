classdef PlusUnit < MISOUnit & FeedforwardOperation
    methods
        function output = dataproc(~, inputA, inputB)
            output = inputA + inputB;
        end
        
        function [inputA, inputB] = deltaproc(~, output)
            inputA = output;
            inputB = output;
        end
        
        function datasize = sizeIn2Out(~, datasize, ~)
        end
        
        function [sizeinA, sizeinB] = sizeOut2In(~, sizeout)
            sizeinA = sizeout;
            sizeinB = sizeout;
        end
        
        function unitdump = dump(~)
            unitdump = {'PlusUnit'};
        end
    end
    
    methods
        function obj = PlusUnit()
            obj.IA = UnitAP(obj, 1);
            obj.IB = UnitAP(obj, 1);
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