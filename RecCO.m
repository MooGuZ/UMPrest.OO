classdef RecCO < RecurrentUnit
    methods
        function obj = RecCO(alphaSelect, thetaSelect, realExtract, imagExtract, ...
                alphaUpdateSelect, thetaUpdateSelect, outputProc, outputSelect)
            inputMixer = ConcateUnit(1).aheadof(alphaSelect).aheadof(thetaSelect).aheadof(...
                realExtract).aheadof(imagExtract).aheadof(alphaUpdateSelect).aheadof(...
                thetaUpdateSelect).aheadof(outputSelect);
            alphaGate = GateUnit(); alphaGate.appendto([], alphaSelect);
            thetaGate = GateUnit(); thetaGate.appendto([], thetaSelect);
            realAct = Activation('tanh'); realAct.appendto(realExtract);
            imagAct = Activation('tanh'); imagAct.appendto(imagExtract);
            cart2polar = Cart2Polar().appendto(realAct, imagAct);
            alphaUpdateGate = GateUnit(); alphaUpdateGate.appendto(cart2polar.O{1}, alphaUpdateSelect);
            thetaUpdateGate = GateUnit(); thetaUpdateGate.appendto(cart2polar.O{2}, thetaUpdateSelect);
            alphaMixer = PlusUnit().appendto(alphaGate, alphaUpdateGate);
            thetaMixer = PlusUnit().appendto(thetaGate, thetaUpdateGate);
            polar2cart = Polar2Cart().appendto(alphaMixer, thetaMixer).aheadof(...
                outputProc.I{1}, outputProc.I{2});
            outputGate = GateUnit(); outputGate.appendto(outputProc, outputSelect);
            % build recurrent unit
            obj@RecurrentUnit(Model( ...
                inputMixer, alphaSelect, thetaSelect, alphaGate, thetaGate, ...
                realExtract, realAct, imagExtract, imagAct, cart2polar, ...
                alphaUpdateSelect, thetaUpdateSelect, alphaUpdateGate, thetaUpdateGate, ...
                alphaMixer, thetaMixer, polar2cart, outputProc, outputSelect, outputGate), ...
                {alphaMixer.O{1}, alphaGate.I{1}, alphaSelect.smpsize('out')}, ...
                {thetaMixer.O{1}, thetaGate.I{1}, thetaSelect.smpsize('out')}, ...
                {outputGate.O{1}, inputMixer.I{2}, outputSelect.smpsize('out')});
            % assign properties
            obj.alphaSelect = alphaSelect;
            obj.thetaSelect = thetaSelect;
            obj.realExtract = realExtract;
            obj.imagExtract = imagExtract;
            obj.alphaUpdateSelect = alphaUpdateSelect;
            obj.thetaUpdateSelect = thetaUpdateSelect;
            obj.outputProc = outputProc;
            obj.outputSelect = outputSelect;
        end
    end
    
    methods (Static)
        function obj = randinit(datasize, cellsize)
            alphaSelect = LinearTransform.randinit(2 * datasize, cellsize);
            thetaSelect = LinearTransform.randinit(2 * datasize, cellsize);
            alphaUpdateSelect = LinearTransform.randinit(2 * datasize, cellsize);
            thetaUpdateSelect = LinearTransform.randinit(2 * datasize, cellsize);
            outputSelect = LinearTransform.randinit(2 * datasize, datasize);
            realExtract = LinearTransform.randinit(2 * datasize, cellsize);
            imagExtract = LinearTransform.randinit(2 * datasize, cellsize);
            outputProc = BilinearTransform.randinit(cellsize, cellsize, datasize);
            obj = RecCO(alphaSelect, thetaSelect, realExtract, imagExtract, alphaUpdateSelect, ...
                thetaUpdateSelect, outputProc, outputSelect);
        end
    end
    
    properties
        alphaSelect, thetaSelect, realExtract, imagExtract
        alphaUpdateSelect, thetaUpdateSelect
        outputProc, outputSelect
    end
    
end