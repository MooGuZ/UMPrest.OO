classdef ConcateUnit < MIMOUnit & FeedforwardOperation
    methods
        function output = dataproc(obj, inputA, inputB)
            output = cat(obj.catdim, inputA, inputB);
            obj.sizercd.A = size(inputA, obj.catdim);
            obj.sizercd.B = size(inputB, obj.catdim);
        end
        
        function [inputA, inputB] = deltaproc(obj, output)
            [inputA, inputB] = sltondim(output, obj.catdim, 1 : obj.sizercd.A);
        end
        
        function sizeout = sizeIn2Out(sizeinA, sizeinB)
            sizeout = sizeinA;
            sizeout(obj.catdim) = sizeinA(obj.catdim) + sizeinB(obj.catdim);
        end
        
        function [sizeinA, sizeinB] = sizeOut2In(sizeout)
            sizeinA = sizeout;
            sizeinB = sizeout;
            sizeinA(obj.catdim) = obj.sizercd.A;
            sizeinB(obj.catdim) = obj.sizercd.B;
        end
    end
    
    methods
        function obj = ConcateUnit(catdim)
            obj.catdim = catdim;
            obj.sizercd = struct();
            obj.IA = UnitAP(obj, 1);
            obj.IB = UnitAP(obj, 1);
            obj.I = [obj.IA, obj.IB];
            obj.O = UnitAP(obj, 1);
        end
    end
    
    properties
        IA, IB
        sizercd
        catdim
    end
    
    properties (Constant, Hidden)
        expandable = true;
        taxis      = false;
    end
end