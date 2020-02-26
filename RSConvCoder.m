% Recurrent Steerable Convolutional Coder
classdef RSConvCoder < RecurrentUnit
    methods
        function obj = RSConvCoder(framesize, ...
                stateControlP, stateUpdateP, updateControlP, ...
                stateControlA, updateControlA, dataMixer, ampEncoder, ...
                outputControlA, outputControlP, frameDecoder)
            X  = DataPoint();
            H  = DataPoint();
            Ca = DataPoint();
            Cp = DataPoint();
            % get size information
            szinfo = size(ampEncoder.alpha);
            framelayer = szinfo(3);
            statelayer = szinfo(4);
            statesize  = ceil(framesize ./ ampEncoder.mode.stride);
            % Phase State (Cp) Part
            stateControlP.appendto(X, H, Cp);
            stateUpdateP.appendto(X, H);
            updateControlP.appendto(X, H, Cp);
            stateKeepP  = DataSelector().appendto(Cp, stateControlP);
            updateActP  = SimpleActivation('tanh').appendto(stateUpdateP);
            stateAddonP = DataSelector().appendto(updateActP, updateControlP);
            stateNewP   = PlusUnit().appendto(stateKeepP, stateAddonP);
            % Amplitude State (Ca) Part
            stateControlA.appendto(X, H, Ca);
            updateControlA.appendto(X, H, Ca);
            dataMixer.appendto(X, H);
            datasize  = [framesize, framelayer];
            phasesize = [statesize, framelayer, statelayer];
            dataForUpdate  = Reshaper(datasize).appendto(dataMixer);
            stateAddonFixP = Scaler(pi).appendto(stateAddonP);
            phaseForUpdate = Reshaper(phasesize).appendto(stateAddonFixP);
            ampEncoder.appendto(dataForUpdate, phaseForUpdate);
            stateKeepA = DataSelector().appendto(Ca, stateControlA);
            ampEncodeFix = Reshaper().appendto(ampEncoder);
            updateActA = SimpleActivation('tanh').appendto(ampEncodeFix);
            stateAddonA = DataSelector().appendto(updateActA, updateControlA);
            stateNewA = PlusUnit().appendto(stateKeepA, stateAddonA);
            % Output Part
            outputControlA.appendto(X, H, stateNewA);
            outputControlP.appendto(X, H, stateNewP);
            outputActA = SimpleActivation('tanh').appendto(stateNewA);
            outputActP = SimpleActivation('tanh').appendto(stateNewP);
            outputA = DataSelector().appendto(outputActA, outputControlA);
            outputP = DataSelector().appendto(outputActP, outputControlP);
            ampsize   = [statesize, statelayer];
            phasesize = [statesize, statelayer, framelayer];
            ampForOutput = Reshaper(ampsize).appendto(outputA);
            outputFixP = Scaler(pi).appendto(outputP);
            phaseForOutput = Reshaper(phasesize).appendto(outputFixP);
            frameDecoder.appendto(ampForOutput, phaseForOutput);
            updateH = Reshaper().appendto(frameDecoder);
            % create model
            model = Model(X, H, Ca, Cp, ...
                stateControlP, stateUpdateP, updateControlP, stateKeepP, updateActP, ...
                stateAddonP, stateNewP, stateControlA, updateControlA, dataMixer, ...
                dataForUpdate, stateAddonFixP, phaseForUpdate, ampEncoder, stateKeepA, ...
                ampEncodeFix, updateActA, stateAddonA, stateNewA, outputControlA, ...
                outputControlP, outputActA, outputActP, outputA, outputP, ampForOutput, ...
                outputFixP, phaseForOutput, frameDecoder, updateH);
            % calculate parameter amount of cell state and hidden state
            nhidden = prod([framesize, framelayer]);
            nstate  = prod([statesize, statelayer]);
            % build recurrent unit
            obj@RecurrentUnit(model, ...
                {stateNewA.O{1}, Ca.I{1}, nstate}, ...
                {stateNewP.O{1}, Cp.I{1}, nstate}, ...
                {updateH.O{1},   H.I{1},  nhidden});
            % assign class members
            obj.nhidden = nhidden;
            obj.nstate  = nstate;
            obj.framesize = framesize;
            obj.statesize = statesize;
            obj.stateControlP = stateControlP;
            obj.stateUpdateP  = stateUpdateP;
            obj.updateControlP = updateControlP;
            obj.stateKeepP     = stateKeepP;
            obj.updateActP = updateActP;
            obj.stateAddonP = stateAddonP;
            obj.stateNewP = stateNewP;
            obj.stateControlA = stateControlA;
            obj.updateControlA = updateControlA;
            obj.dataMixer = dataMixer;
            obj.dataForUpdate = dataForUpdate;
            obj.phaseForUpdate = phaseForUpdate;
            obj.ampEncoder = ampEncoder;
            obj.stateKeepA = stateKeepA;
            obj.updateActA = updateActA;
            obj.stateAddonA = stateAddonA;
            obj.stateNewA = stateNewA;
            obj.outputControlA = outputControlA;
            obj.outputControlP = outputControlP;
            obj.outputActA = outputActA;
            obj.outputActP = outputActP;
            obj.outputA = outputA;
            obj.outputP = outputP;
            obj.ampForOutput = ampForOutput;
            obj.phaseForOutput = phaseForOutput;
            obj.frameDecoder = frameDecoder;
            obj.updateH = updateH;
        end
    end
    
    methods
        function unitdump = dump(obj)
            unitdump = {'RSConvCoder', obj.framesize, ...
                obj.stateControlP.dump(), obj.stateUpdateP.dump(), ...
                obj.updateControlP.dump(), obj.stateControlA.dump(), ...
                obj.updateControlA.dump(), obj.dataMixer.dump(), ...
                obj.ampEncoder.dump(), obj.outputControlA.dump(), ...
                obj.outputControlP.dump(), obj.frameDecoder.dump()};
        end
        
        function refresh(obj)
            obj.ampEncoder.refresh();
            obj.frameDecoder.refresh();
        end
    end
    
    properties (SetAccess = protected)
        nhidden, nstate, framesize, statesize
        stateControlP, stateUpdateP, updateControlP, stateKeepP, updateActP
        stateAddonP, stateNewP, stateControlA, updateControlA, dataMixer
        dataForUpdate, phaseForUpdate, ampEncoder, stateKeepA
        updateActA, stateAddonA, stateNewA, outputControlA
        outputControlP, outputActA, outputActP, outputA, outputP, ampForOutput
        phaseForOutput, frameDecoder, updateH
    end
    
    methods (Static)
        function unit = randinit(frmsize, nlayerFrm, basesize, nbase, grid)
            nhidden = prod([frmsize, nlayerFrm]);
            if exist('grid', 'var')
                statesize = ceil(frmsize ./ grid);
            end
            nstate  = prod([statesize, nlayerFrm, nbase]);
            % generate steerable convolution units
            ampEncoder = SConvEncoder.randinit(basesize, nlayerFrm, nbase);
            frameDecoder = SConvDecoder.randinit(basesize, nbase, nlayerFrm);
            if exist('grid', 'var') && any(grid ~= [1, 1])
                ampEncoder.setup('stride', grid);
                frameDecoder.setup('spacing', grid);
            end
            unit = RSConvCoder(frmsize, ...
                MultiLT.randinit(nstate, nhidden, nhidden, nstate), ...
                MultiLT.randinit(nstate, nhidden, nhidden), ...
                MultiLT.randinit(nstate, nhidden, nhidden, nstate), ...
                MultiLT.randinit(nstate, nhidden, nhidden, nstate), ...
                MultiLT.randinit(nstate, nhidden, nhidden, nstate), ...
                MultiLT.randinit(nhidden, nhidden, nhidden), ...
                ampEncoder, ...
                MultiLT.randinit(nstate, nhidden, nhidden, nstate), ...
                MultiLT.randinit(nstate, nhidden, nhidden, nstate), ...
                frameDecoder);                
        end
        
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            frmsize = probScale * [1, 1];
            nlayerFrm = 1;
            basesize = ceil(log2(probScale)) * [1, 1];
            nbase = ceil(sqrt(probScale));
            nframes = nbase;
            % reference model
            refer = RSConvCoder.randinit(frmsize, nlayerFrm, basesize, nbase, [2,2]);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            refer.refresh();
            % approximate model
            model = RSConvCoder.randinit(frmsize, nlayerFrm, basesize, nbase, [2,2]);
            % create dataset
            dataset = DataGenerator('normal', prod([frmsize, nlayerFrm])).enableTmode(nframes);
            % create objectives
            objective = Likelihood('mse');
            % initialize task
            task = SimulationTest(model, refer, dataset, objective);
            % run simulation test
            task.run(niter, batchsize, validsize);
        end
    end
end