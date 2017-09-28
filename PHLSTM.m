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
        
        function debug()
            nhidden = 32;
            sizein  = 32;
            sizeout = 32;
            nframes = 7;
            % calculate data size
            if isempty(sizein)
                datasize = nhidden;
            else
                datasize = sizein;
            end
            % create model and its reference
            refer = PHLSTM.randinit(nhidden, sizein, sizeout);
            model = PHLSTM.randinit(nhidden, sizein, sizeout);
            % % set as last-frame mode
            % refer.setupOutputMode('last');
            % model.setupOutputMode('last');
            % create dataset
            dataset = DataGenerator('normal', datasize).enableTmode(nframes);
            % create objectives
            objective = Likelihood('mse');
            % initialize task
            task = SimulationTest(model, refer, dataset, objective);
            % setup optimizer
            opt = HyperParam.getOptimizer();
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-2);
            opt.enableRcdmode(3);
            % opt.stepmode('static', 'step', 1e-3);
            % opt.gradmode('rmsprop', 'decay2ndOrder', 0.999);
            % opt.gradmode('adam', 'decay1stOrder', 0.9, 'decay2ndOrder', 0.999);
            % opt.gradmode('basic');
            % run simulation test
            task.run(3e2, 16, 128);
        end
    end
end
