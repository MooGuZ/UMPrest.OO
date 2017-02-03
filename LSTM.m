classdef LSTM < RecurrentUnit
    methods
        function obj = LSTM(stateSelect, updateExtract, updateSelect, outputSelect)
            inputMixer = ConcateUnit(1).aheadof(stateSelect).aheadof(...
                updateSelect).aheadof(updateExtract).aheadof(outputSelect);
            stateGate  = GateUnit(); stateGate.appendto([], stateSelect);
            updateAct  = Activation('tanh'); updateAct.appendto(updateExtract);
            updateGate = GateUnit(); updateGate.appendto(updateAct, updateSelect);
            stateMixer = PlusUnit().appendto(stateGate, updateGate);
            outputProc = Activation('tanh'); outputProc.appendto(stateMixer);
            outputGate = GateUnit(); outputGate.appendto(outputProc, outputSelect);
            % build recurrent unit
            obj@RecurrentUnit(Model( ...
                inputMixer, stateSelect, stateGate, updateExtract, updateSelect, updateAct,...
                updateGate, stateMixer, outputSelect, outputProc, outputGate), ...
                {stateMixer.O{1}, stateGate.I{1}, stateSelect.smpsize('out')}, ...
                {outputGate.O{1}, inputMixer.I{2}, outputSelect.smpsize('out')});
            % assign properties
            obj.stateSelect   = stateSelect;
            obj.updateExtract = updateExtract;
            obj.updateSelect  = updateSelect;
            obj.outputSelect  = outputSelect;
        end
        
        % function param = dump(obj)
        %     param = cellcomb(arrayfun(@dump, ...
        %         [obj.stateSelect, obj.updateExtract, obj.updateSelect, obj.outputSelect], ...
        %         'UniformOutput', false));
        % end
        
        function view(obj)
            cellsize = size(obj.stateSelect.weight, 2) / 2;
            baseview(reshape(obj.stateSelect.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'State Select (Input Part)');
            baseview(reshape(obj.stateSelect.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'State Select (Output Part)');
            pause();
            
            baseview(reshape(obj.updateSelect.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'Update Select (Input Part)');
            baseview(reshape(obj.updateSelect.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'Update Select (Output Part)');
            pause();
            
            baseview(reshape(obj.updateExtract.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'Update Extractor (Input Part)');
            baseview(reshape(obj.updateExtract.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'Update Extractor (Output Part)');
            pause();
            
            baseview(reshape(obj.outputSelect.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'Output Select (Input Part)');
            baseview(reshape(obj.outputSelect.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'Output Select (Output Part)');
        end
    end
    
    methods (Static)
        function unit = randinit(datasize, cellsize)
            unit = LSTM( ...
                LinearTransform.randinit(datasize + cellsize, cellsize), ...
                LinearTransform.randinit(datasize + cellsize, cellsize), ...
                LinearTransform.randinit(datasize + cellsize, cellsize), ...
                LinearTransform.randinit(datasize + cellsize, cellsize));
        end
        
        function unit = loaddump(fw, fb, iw, ib, gw, gb, ow, ob)
            unit = LSTM(LinearTransform(fw, fb), LinearTransform(iw, ib), ...
                LinearTransform(gw, gb), LinearTransform(ow, ob));
        end
    end
    
    properties
        stateSelect, updateExtract, updateSelect, outputSelect
    end
end
