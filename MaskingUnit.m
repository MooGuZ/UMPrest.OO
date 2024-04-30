classdef MaskingUnit < MISOUnit & FeedforwardOperation
    methods
        function output = dataproc(~, texture, mask)
            output = texture .* mask(1,:);
        end
        
        function [dTexture, dMask] = deltaproc(obj, d)
            texture  = obj.IT.datarcd.pop();
            mask     = obj.IM.datarcd.pop();
            dTexture = d .* mask(1,:);
            dMask    = d .* texture;
            dMask    = [dMask; -dMask];
        end
        
        function datasize = sizeIn2Out(~, datasize, ~)
        end
        
        function [textureSize, maskSize] = sizeOut2In(~, datasize)
            textureSize = datasize;
            maskSize    = datasize;
            maskSize(1) = 2;
        end
        
        function unitdump = dump(~)
            unitdump = {'MaskingUnit'};
        end
    end
    
    methods
        function obj = MaskingUnit()
            obj.IT = UnitAP(obj, 1, '-recdata');
            obj.IM = UnitAP(obj, 1, '-recdata');
            obj.I  = {obj.IT, obj.IM};
            obj.O  = {UnitAP(obj, 1)};
        end
    end
    
    properties
        IT, IM
    end
    
    properties (Constant, Hidden)
        expandable = true;
        taxis      = false;
    end
end