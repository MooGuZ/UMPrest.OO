classdef PHLSTM < RecurrentUnit
% LSTM with peephole connections
    methods
        function value = smpsize(obj, io)
            switch lower(io)
                case {'in', 'input'}
                    if isempty(obj.inputTransform)
                        value = obj.nhidunit;
                    else
                        value = obj.inputTransform.smpsize('in');
                    end
                    
                case {'out', 'output'}
                    if isempty(obj.outputTransform)
                        value = obj.nhidunit;
                    else
                        value = obj.outputTransform.smpsize('out');
                    end
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
        
        function unitdump = dump(obj)
            unitdump = {'PHLSTM', obj.stateControl.dump(), obj.stateUpdate.dump(), ...
                obj.updateControl.dump(), obj.outputControl.dump()};
            % add input transform
            if isempty(obj.inputTransform)
                unitdump = [unitdump, {[]}];
            else
                unitdump = [unitdump, {obj.inputTransform.dump()}];
            end
            % add output transform
            if isempty(obj.outputTransform)
                unitdump = [unitdump, {[]}];
            else
                unitdump = [unitdump, {obj.outputTransform.dump()}];
            end
        end
    end
    
    properties (SetAccess = protected)
        stateControl, stateUpdate, updateControl, outputControl, inputTransform, outputTransform
        stateKeep, stateControlAct, updateAct, stateAddon, updateControlAct, stateNew, outputAct
        output, outputControlAct, nhidunit
        recordMode = false
    end
    
    methods
        function obj = PHLSTM(stateControl, stateUpdate, updateControl, outputControl, ...
                inputTransform, outputTransform)
            % create data-points for variables
            X = DataPoint();
            H = DataPoint();
            C = DataPoint();
            % create and connect data-proc units
            stateControl.appendto(X, H, C);
            stateUpdate.appendto(X, H);
            updateControl.appendto(X, H, C);
            stateKeep  = DataSelector().appendto(C, stateControl);
            updateAct  = Activation('tanh'); updateAct.appendto(stateUpdate);
            stateAddon = DataSelector().appendto(updateAct, updateControl);
            stateNew   = PlusUnit().appendto(stateKeep, stateAddon);
            outputControl.appendto(X, H, stateNew);
            outputAct  = Activation('tanh'); outputAct.appendto(stateNew);
            output     = DataSelector().appendto(outputAct, outputControl);
            % create model
            model = Model(X, H, C, updateControl, stateControl, stateUpdate, stateKeep, ...
                updateAct, stateAddon, stateNew, outputControl, outputAct, output);
            % add input transform
            if not(isempty(inputTransform))
                inputTransform.aheadof(X);
                model.add(inputTransform);
            end
            % add output transform
            if not(isempty(outputTransform))
                outputTransform.appendto(output);
                model.add(outputTransform);
            end
            % build recurrent unit
            obj@RecurrentUnit(model, ...
                {stateNew.O{1}, C.I{1}, stateControl.smpsize('out')}, ...
                {output.dataout, H.I{1}, outputControl.smpsize('out')});
            % get number of hidden units
            obj.nhidunit = stateControl.smpsize('in');
            obj.nhidunit = obj.nhidunit{1};
            % highlight evolvable units
            obj.stateControl    = stateControl;
            obj.stateUpdate     = stateUpdate;
            obj.updateControl   = updateControl;
            obj.outputControl   = outputControl;
            obj.inputTransform  = inputTransform;
            obj.outputTransform = outputTransform;
            % records other units
            obj.stateKeep        = stateKeep.mix;
            obj.stateControlAct  = stateKeep.act;
            obj.updateAct        = updateAct;
            obj.stateAddon       = stateAddon.mix;
            obj.updateControlAct = stateAddon.act;
            obj.stateNew         = stateNew;
            obj.outputAct        = outputAct;
            obj.output           = output.mix;
            obj.outputControlAct = output.act;
        end
    end
    
    properties (Hidden, SetAccess = private)
        listeners
    end
    methods
        function obj = startRecording(obj)
            if not(obj.recordMode)
                obj.listeners = struct( ...
                    'cstate', Listener(obj.S{1}.O{1}), ...
                    'hstate', Listener(obj.S{2}.O{1}), ...
                    'stkeep', Listener(obj.stateKeep.O{1}), ...
                    'stnew',  Listener(obj.stateNew.O{1}), ...
                    'output', Listener(obj.output.O{1}), ...
                    'stctrl', Listener(obj.stateControl.O{1}), ...
                    'update', Listener(obj.updateAct.O{1}), ...
                    'upctrl', Listener(obj.updateControl.O{1}), ...
                    'staddon', Listener(obj.stateAddon.O{1}), ...
                    'st2out', Listener(obj.outputAct.O{1}), ...
                    'outctrl', Listener(obj.outputControl.O{1}));
                obj.recordMode = true;
            end
        end
        
        function obj = stopRecording(obj)
            if obj.recordMode
                fldnames = fieldnames(obj.listeners);
                for i = 1 : numel(fldnames)
                    obj.listeners.(fldnames{i}).detach();
                end
                obj.listeners  = [];
                obj.recordMode = false;
            end
        end
        
        function records = getRecords(obj)
            if obj.recordMode
                fldnames = fieldnames(obj.listeners);
                buffer  = cell(1, numel(fldnames));
                for i = 1 : numel(fldnames)
                    buffer{i} = obj.listeners.(fldnames{i}).collect();
                end
                buffer = [fldnames'; buffer];
                records = struct(buffer{:});
            else
                warning('Model is not recording, use startRecording() at first.');
            end
        end
    end
    
    methods (Static)
        function unit = randinit(nhidden, sizein, sizeout)
            % create input transform
            if exist('sizein', 'var') && not(isempty(sizein))
                inputTransform = LinearTransform.randinit(sizein, nhidden);
            else
                inputTransform = [];
            end
            % create output transform
            if exist('sizeout', 'var') && not(isempty(sizeout))
                outputTransform = LinearTransform.randinit(nhidden, sizeout);
            else
                outputTransform = [];
            end
            % create peephole-LSTM
            unit = PHLSTM( ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                inputTransform, outputTransform);
        end
        
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            nhidden = probScale;
            sizein  = probScale;
            sizeout = probScale;
            nframes = ceil(log2(probScale));
            % reference model
            refer = PHLSTM.randinit(nhidden, sizein, sizeout);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % apporximate model
            model = PHLSTM.randinit(nhidden, sizein, sizeout);
            % % set as last-frame mode
            % refer.setupOutputMode('last');
            % model.setupOutputMode('last');
            % data generator
            dataset = DataGenerator('normal', sizein).enableTmode(nframes);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, dataset, objective);
            task.run(niter, batchsize, validsize);
        end
    end
end
