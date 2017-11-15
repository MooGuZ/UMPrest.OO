classdef DPHLSTM < RecurrentUnit
% Dual LSTM with peephole connections, they are interferenced by cross-state connections.
    methods
        function unitdump = dump(self)            
            % add input/output transform
            if isempty(self.inputTransformA)
                inputdumpA = [];
            else
                inputdumpA = self.inputTransformA.dump();
            end
            if isempty(self.outputTransformA)
                outputdumpA = [];
            else
                outputdumpA = self.outputTransformA.dump();
            end
            if isempty(self.inputTransformB)
                inputdumpB = [];
            else
                inputdumpB = self.inputTransformB.dump();
            end
            if isempty(self.outputTransformB)
                outputdumpB = [];
            else
                outputdumpB = self.outputTransformB.dump();
            end
            % compose dump of unit
            unitdump = {'DPHLSTM', ...
                self.stateControlA.dump(), self.stateUpdateA.dump(), ...
                self.updateControlA.dump(), self.outputControlA.dump(), ...
                self.stateControlB.dump(), self.stateUpdateB.dump(), ...
                self.updateControlB.dump(), self.outputControlB.dump(), ...
                inputdumpA, outputdumpA, inputdumpB, outputdumpB};
        end
        
        function value = smpsize(obj, io)
            switch lower(io)
                case {'in', 'input'}
                    if isempty(obj.inputTransformA)
                        sizeinA = obj.nhidunitA;
                    else
                        sizeinA = obj.inputTransformA.smpsize('in');
                    end
                    if isempty(obj.inputTransformB)
                        sizeinB = obj.nhidunitB;
                    else
                        sizeinB = obj.inputTransformB.smpsize('in');
                    end
                    value = {sizeinA, sizeinB};
                    
                case {'out', 'output'}
                    if isempty(obj.outputTransformA)
                        sizeoutA = obj.nhidunitA;
                    else
                        sizeoutA = obj.outputTransformA.smpsize('out');
                    end
                    if isempty(obj.outputTransformB)
                        sizeoutB = obj.nhidunitB;
                    else
                        sizeoutB = obj.outputTransformB.smpsize('out');
                    end
                    value = {sizeoutA, sizeoutB};
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
    end
    
    methods
        function self = DPHLSTM( ...
            stateControlA, stateUpdateA, updateControlA, outputControlA, ...
            stateControlB, stateUpdateB, updateControlB, outputControlB, ...
            inputTransformA, outputTransformA, inputTransformB, outputTransformB)
            Xa = DataPoint();
            Ha = DataPoint();
            Ca = DataPoint();
            Xb = DataPoint();
            Hb = DataPoint();
            Cb = DataPoint();
            % New State Generation Process - Part A
            stateControlA.appendto(Xa, Ha, Ca);
            stateUpdateA.appendto(Xa, Ha, Hb);
            updateControlA.appendto(Xa, Ha, Ca);
            stateKeepA  = DataSelector().appendto(Ca, stateControlA);
            updateActA  = SimpleActivation('tanh').appendto(stateUpdateA);
            stateAddonA = DataSelector().appendto(updateActA, updateControlA);
            stateNewA   = PlusUnit().appendto(stateKeepA, stateAddonA);
            % New State Generation Process - Part B
            stateControlB.appendto(Xb, Hb, Cb);
            stateUpdateB.appendto(Xb, Hb, Ha);
            updateControlB.appendto(Xb, Hb, Cb);
            stateKeepB  = DataSelector().appendto(Cb, stateControlB);
            updateActB  = SimpleActivation('tanh').appendto(stateUpdateB);
            stateAddonB = DataSelector().appendto(updateActB, updateControlB);
            stateNewB   = PlusUnit().appendto(stateKeepB, stateAddonB);
            % Output Generation Process
            outputControlA.appendto(Xa, Ha, stateNewA, stateNewB);
            outputControlB.appendto(Xb, Hb, stateNewB, stateNewA);
            outputActA  = SimpleActivation('tanh').appendto(stateNewA);
            outputActB  = SimpleActivation('tanh').appendto(stateNewB);
            outputA     = DataSelector().appendto(outputActA, outputControlA);
            outputB     = DataSelector().appendto(outputActB, outputControlB);
            % create model
            model = Model(Xa, Ha, Ca, Xb, Hb, Cb, ...
                stateControlA, stateUpdateA, updateControlA, stateKeepA, updateActA, ...
                stateAddonA, stateNewA, stateControlB, stateUpdateB, updateControlB, ...
                stateKeepB, updateActB, stateAddonB, stateNewB, outputControlA, ...
                outputControlB, outputActA, outputActB, outputA, outputB);
            % add input/output transform
            % PRB: this operation may lead to reorder of input access-point in model
            if not(isempty(inputTransformA))
                inputTransformA.aheadof(Xa);
                model.add(inputTransformA);
            end
            if not(isempty(inputTransformB))
                inputTransformB.aheadof(Xb);
                model.add(inputTransformB);
            end
            if not(isempty(outputTransformA))
                outputTransformA.appendto(outputA);
                model.add(outputTransformA);
            end
            if not(isempty(outputTransformB))
                outputTransformB.appendto(outputB);
                model.add(outputTransformB);
            end
            % build recurrent unit
            self@RecurrentUnit(model, ...
                {stateNewA.O{1},  Ca.I{1}, stateControlA.smpsize('out')}, ...
                {outputA.dataout, Ha.I{1}, outputControlA.smpsize('out')}, ...
                {stateNewB.O{1},  Cb.I{1}, stateControlB.smpsize('out')}, ...
                {outputB.dataout, Hb.I{1}, outputControlB.smpsize('out')});
            % get number of hidden units
            self.nhidunitA = stateControlA.smpsize('in');
            self.nhidunitA = self.nhidunitA{1};
            self.nhidunitB = stateControlB.smpsize('in');
            self.nhidunitB = self.nhidunitB{1};
            % highlight evolvable units
            self.stateControlA    = stateControlA;
            self.stateControlB    = stateControlB;
            self.stateUpdateA     = stateUpdateA;
            self.stateUpdateB     = stateUpdateB;
            self.updateControlA   = updateControlA;
            self.updateControlB   = updateControlB;
            self.outputControlA   = outputControlA;
            self.outputControlB   = outputControlB;
            self.inputTransformA  = inputTransformA;
            self.inputTransformB  = inputTransformB;
            self.outputTransformA = outputTransformA;
            self.outputTransformB = outputTransformB;
            % record other units
            self.stateKeepA        = stateKeepA.mix;
            self.stateKeepB        = stateKeepB.mix;
            self.stateControlActA  = stateKeepA.act;
            self.stateControlActB  = stateKeepB.act;
            self.updateActA        = updateActA;
            self.updateActB        = updateActB;
            self.stateAddonA       = stateAddonA.mix;
            self.stateAddonB       = stateAddonB.mix;
            self.updateControlActA = stateAddonA.act;
            self.updateControlActB = stateAddonB.act;
            self.stateNewA         = stateNewA;
            self.stateNewB         = stateNewB;
            self.outputActA        = outputActA;
            self.outputActB        = outputActB;
            self.outputA           = outputA.mix;
            self.outputB           = outputB.mix;
            self.outputControlActA = outputA.act;
            self.outputControlActB = outputB.act;
        end
    end
    
    properties (SetAccess = protected)
        nhidunitA, nhidunitB
        stateControlA, stateUpdateA, updateControlA, outputControlA, inputTransformA, outputTransformA
        stateControlB, stateUpdateB, updateControlB, outputControlB, inputTransformB, outputTransformB
        stateKeepA, stateControlActA, updateActA, stateAddonA, updateControlActA, stateNewA
        stateKeepB, stateControlActB, updateActB, stateAddonB, updateControlActB, stateNewB
        outputActA, outputA, outputControlActA
        outputActB, outputB, outputControlActB
    end
    
    methods (Static)
        function unit = randinit(nhidden, sizein, sizeout)
            % create input transform
            if exist('sizein', 'var') && not(isempty(sizein))
                inputTransformA = LinearTransform.randinit(sizein, nhidden);
                inputTransformB = LinearTransform.randinit(sizein, nhidden);
            else
                inputTransformA = [];
                inputTransformB = [];
            end
            % create output transform
            if exist('sizeout', 'var') && not(isempty(sizeout))
                outputTransformA = LinearTransform.randinit(nhidden, sizeout);
                outputTransformB = LinearTransform.randinit(nhidden, sizeout);
            else
                outputTransformA = [];
                outputTransformB = [];
            end
            % create dual peephole-LSTM
            unit = DPHLSTM( ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden), ...
                MultiLT.randinit(nhidden, nhidden, nhidden, nhidden, nhidden), ...
                inputTransformA, outputTransformA, inputTransformB, outputTransformB);
        end
        
        function unit = combine(dumpA, dumpB)
            assert(strcmpi(dumpA{1}, 'PHLSTM'), 'ILLEGAL FIRST ARGUMENT');
            assert(strcmpi(dumpB{1}, 'PHLSTM'), 'ILLEGAL SECOND ARGUMENT');
            % obtain quantity of hidden units of each part
            nhidunitA = size(dumpA{2}{2}, 1);
            nhidunitB = size(dumpB{2}{2}, 1);
            % build element in Recurrent Unit
            stateControlA  = BuildingBlock.loaddump(dumpA{2});
            updateControlA = BuildingBlock.loaddump(dumpA{4});
            stateUpdateA   = MultiLT(dumpA{3}{2:3}, HyperParam.randlt(nhidunitA, nhidunitB), dumpA{3}{4});
            outputControlA = MultiLT(dumpA{5}{2:4}, HyperParam.randlt(nhidunitA, nhidunitB), dumpA{5}{5});
            stateControlB  = BuildingBlock.loaddump(dumpB{2});
            updateControlB = BuildingBlock.loaddump(dumpB{4});
            stateUpdateB   = MultiLT(dumpB{3}{2:3}, HyperParam.randlt(nhidunitB, nhidunitA), dumpB{3}{4});
            outputControlB = MultiLT(dumpB{5}{2:4}, HyperParam.randlt(nhidunitB, nhidunitA), dumpB{5}{5});
            % build input/output transforms
            if isempty(dumpA{6})
                inputTransformA = [];
            else
                inputTransformA = BuildingBlock.loaddump(dumpA{6});
            end
            if isempty(dumpA{7})
                outputTransformA = [];
            else
                outputTransformA = BuildingBlock.loaddump(dumpA{7});
            end
            if isempty(dumpB{6})
                inputTransformB = [];
            else
                inputTransformB = BuildingBlock.loaddump(dumpB{6});
            end
            if isempty(dumpB{7})
                outputTransformB = [];
            else
                outputTransformB = BuildingBlock.loaddump(dumpB{7});
            end
            % build unit
            unit = DPHLSTM( ...
                stateControlA, stateUpdateA, updateControlA, outputControlA, ...
                stateControlB, stateUpdateB, updateControlB, outputControlB, ...
                inputTransformA, outputTransformA, inputTransformB, outputTransformB);
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
            refer = DPHLSTM.randinit(nhidden, sizein, sizeout);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = DPHLSTM.randinit(nhidden, sizein, sizeout);
            % % set as last-frame mode
            % refer.setupOutputMode('last');
            % model.setupOutputMode('last');
            % create dataset
            datasetA = DataGenerator('normal', sizein).enableTmode(nframes);
            datasetB = DataGenerator('normal', sizein).enableTmode(nframes);
            % create objectives
            objectiveA = Likelihood('mse');
            objectiveB = Likelihood('mse');
            % initialize task
            task = SimulationTest(model, refer, {datasetA, datasetB}, {objectiveA, objectiveB});
            % run simulation test
            task.run(niter, batchsize, validsize);
        end
    end
end
