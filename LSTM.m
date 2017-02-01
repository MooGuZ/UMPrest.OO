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
            cellsize = size(obj.stateGate.weight, 2) / 2;
            baseview(reshape(obj.stateGate.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'State Gate (Input Part)');
            baseview(reshape(obj.stateGate.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'State Gate (Output Part)');
            pause();
            
            baseview(reshape(obj.updateGate.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'Update Gate (Input Part)');
            baseview(reshape(obj.updateGate.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'Update Gate (Output Part)');
            pause();
            
            baseview(reshape(obj.updateGen.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'Update Generator (Input Part)');
            baseview(reshape(obj.updateGen.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'Update Generator (Output Part)');
            pause();
            
            baseview(reshape(obj.outputGate.weight(:, 1 : cellsize), [32, 32, cellsize]), ...
                'figureName', 'Output Gate (Input Part)');
            baseview(reshape(obj.outputGate.weight(:, cellsize + 1 : end), [32, 32, cellsize]), ...
                'figureName', 'Output Gate (Output Part)');
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
        
        % function unit = loaddump(fw, fb, iw, ib, gw, gb, ow, ob)
        %     unit = LSTM(LinearTransform(fw, fb), LinearTransform(iw, ib), ...
        %         LinearTransform(gw, gb), LinearTransform(ow, ob));
        % end
        
        function unit = loaddump(datamat)
            stateSelect   = LinearTransform(datamat{1}{:});
            updateExtract = LinearTransform(datamat{2}{:});
            updateSelect  = LinearTransform(datamat{3}{:});
            outputSelect  = LinearTransform(datamat{4}{:});
            unit = LSTM(stateSelect, updateExtract, updateSelect, outputSelect);
        end
    end
    
    properties
        stateSelect, updateExtract, updateSelect, outputSelect
    end
end
