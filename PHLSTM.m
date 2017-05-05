classdef PHLSTM < RecurrentUnit
% LSTM with peephole connections
    methods
        function obj = PHLSTM(stateControl, stateUpdate, updateControl, outputControl)
            % create data-points for variables
            X = DataPoint();
            H = DataPoint();
            C = DataPoint();
            % create and connect data-proc units
            stateControl.appendto(X, H, C);
            stateUpdate.appendto(X, H);
            updateControl.appendto(X, H, C);
            stateKeep = DataSelector().appendto(C, stateControl);
            updateAct = Activation('tanh'); updateAct.appendto(stateUpdate);
            stateAddon = DataSelector().appendto(updateAct, updateControl);
            stateNew = PlusUnit().appendto(stateKeep, stateAddon);
            outputControl.appendto(X, H, stateNew);
            outputAct = Activation('tanh'); outputAct.appendto(stateNew);
            output = DataSelector().appendto(outputAct, outputControl);
            % build recurrent unit
            obj@RecurrentUnit(Model(X, H, C, updateControl, stateControl, stateUpdate, stateKeep, ...
                updateAct, stateAddon, stateNew, outputControl, outputAct, output), ...
                {stateNew.O{1}, C.I{1}, stateControl.smpsize('out')}, ...
                {output.dataout, H.I{1}, outputControl.smpsize('out')});
            % highlight evolvable units
            obj.stateControl  = stateControl;
            obj.stateUpdate   = stateUpdate;
            obj.updateControl = updateControl;
            obj.outputControl = outputControl;
        end
    end
    
    properties (SetAccess = protected)
        stateControl, stateUpdate, updateControl, outputControl
    end
    
    methods
        function unitdump = dump(obj)
            unitdump = {'PHLSTM', obj.stateControl.dump(), obj.stateUpdate.dump(), ...
                obj.updateControl.dump(), obj.outputControl.dump()};
        end
    end
    
    methods (Static)
        function unit = randinit(sizein, sizeout)
            unit = PHLSTM( ...
                MultiLT.randinit(sizeout, sizein, sizeout, sizeout), ...
                MultiLT.randinit(sizeout, sizein, sizeout), ...
                MultiLT.randinit(sizeout, sizein, sizeout, sizeout), ...
                MultiLT.randinit(sizeout, sizein, sizeout, sizeout));
        end
        
        function debug()
            sizein  = 32;
            sizeout = 16;
            nframes = 3;
            % create model and its reference
            refer = PHLSTM.randinit(sizein, sizeout);
            model = PHLSTM.randinit(sizein, sizeout);
            % set as last-frame mode
            refer.setupOutputMode('last');
            model.setupOutputMode('last');
            % create dataset
            dataset = DataGenerator('normal', sizein).enableTmode(nframes);
            % create objectives
            objective = Likelihood('mse');
            % initialize task
            task = SimulationTest(model, refer, dataset, objective);
            % run simulation test
            task.run(300, 16, 64);
        end
    end
end
