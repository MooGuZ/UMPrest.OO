classdef RecurrentUnit < Unit & Evolvable
    methods
        function varargout = forward(obj, varargin)
            obj.apshare = struct();
            % load input into access points
            if not(isempty(varargin))
                % PRB: the order of APs is ambiguous, recurrent AP should
                %      be different from others
                arrayfun(@(i) obj.I(i).push(varargin{i}), 1 : numel(obj.I));
            end
            % prepare for temporal process
            arrayfun(@(rap) rap.enableTMode(true),  obj.I);
            arrayfun(@(rap) rap.enableTMode(false), obj.O);
            arrayfun(@(rap) rap.enableTMode(false), obj.S);
            % record number of frames in forward pass for last frame mode
            if obj.lastFrameMode.status
                obj.lastFrameMode.nframe = obj.apshare.nframe;
            end
            % deal with data one frame by one frame
            assert(obj.apshare.nframe <= UMPrest.parameter.get('MemoryLength'), ...
                   'BEYOND CAPABILITY');
            for i = 1 : obj.apshare.nframe
                % send package of current frame to kernel
                arrayfun(@(rap) rap.send(rap.pop()), obj.I);
                % kernel processing
                obj.kernel.forward();
            end
            % post-process of temporal process
            arrayfun(@(rap) rap.disableTMode(), obj.I);
            arrayfun(@(rap) rap.disableTMode(), obj.O);
            arrayfun(@(rap) rap.disableTMode(), obj.S);
            % send or gather package on output side
            if nargout == 0
                % send packages if no output argument
                arrayfun(@(rap) rap.send(rap.state.package), obj.O);
            else
                % otherwise, gather output packages
                varargout = arrayfun(@(rap) rap.state.package, obj.O, ...
                    'UniformOutput', false);
            end
        end

        function varargout = backward(obj, varargin)
            obj.apshare = struct();
            % load input into access points
            if not(isempty(varargin))
                % PRB: the order of APs is ambiguous, recurrent AP should
                %      be different from others
                arrayfun(@(i) obj.O(i).push(varargin{i}), 1 : numel(obj.O));
            end
            % restore number of frames in last frame mode
            if obj.lastFrameMode.status
                obj.apshare.nframe = obj.lastFrameMode.nframe;
            end
            % prepare for temporal process
            arrayfun(@(rap) rap.enableTMode(true),  obj.O);
            arrayfun(@(rap) rap.enableTMode(false), obj.S);
            arrayfun(@(rap) rap.enableTMode(false), obj.I);
            % deal with data one frame by one frame
            assert(obj.apshare.nframe <= UMPrest.parameter.get('MemoryLength'), ...
                   'BEYOND CAPABILITY');
            % backward first frame
            arrayfun(@(rap) rap.send(rap.pop()), obj.O);
            obj.kernel.backward();
            for i = 2 : obj.apshare.nframe
                % send package of current frame to kernel
                arrayfun(@(rap) rap.send(rap.pop()), obj.O);
                arrayfun(@(rap) rap.send(rap.pop()), obj.S);
                % kernel processing
                obj.kernel.backward();
            end
            % post-process of temporal process
            arrayfun(@(rap) rap.disableTMode(), obj.O);
            arrayfun(@(rap) rap.disableTMode(), obj.S);
            arrayfun(@(rap) rap.disableTMode(), obj.I);
            % send or gather package on output side
            if nargout == 0
                % send packages if no output argument
                arrayfun(@(rap) rap.send(rap.state.package), obj.I);
            else
                % otherwise, gather output packages
                varargout = arrayfun(@(rap) rap.state.package, obj.I, ...
                    'UniformOutput', false);
            end
        end
        
        function update(obj)
            if isa(obj.kernel, 'Evolvable')
                obj.kernel.update();
            end
        end
    end
    
    methods
        function enableLastFrameMode(obj)
            obj.lastFrameMode = struct( ...
                'status', true, ...
                'nframe', []);
        end
        
        function disableLastFrameMode(obj)
            obj.lastFrameMode = struct('status', false);
        end
    end
    
    methods
        function clear(obj)
            arrayfun(@clear, obj.I);
            arrayfun(@clear, obj.S);
            arrayfun(@clear, obj.O);
            obj.kernel.clear();
        end
    end
    
    methods
        function obj = RecurrentUnit(kernel, varargin)
            obj.kernel = kernel;
            % setup I/O access points
            obj.I = cell2array(arrayfun( ...
                @(ap) RecurrentAP(obj, ap), obj.kernel.I, 'UniformOutput', false));
            obj.O = cell2array(arrayfun( ...
                @(ap) RecurrentAP(obj, ap), obj.kernel.O, 'UniformOutput', false));
            % setup recurrent links
            obj.S = [];
            for i = 1 : nargin - 1
                % origin of a rlink can be output AP or not
                apOrg = varargin{i}{1};
                index = arrayfun(@apOrg.compare, obj.kernel.O);
                if any(index)
                    apOrg = obj.O(index);
                else
                    apOrg = RecurrentAP(obj, apOrg);
                    obj.S = [obj.S, apOrg];
                end
                
                % the other end of rlink has to be an input AP of kernel
                apTgt = varargin{i}{2};
                index = arrayfun(@apTgt.compare, obj.kernel.I);
                assert(any(index), 'ILLEGAL ARGUMENT');
                apTgt = obj.I(index);
                
                % create recurrent link
                apOrg.rconnect(apTgt);
            end
            % initialize without last frame mode
            obj.disableLastFrameMode();
        end
    end
    
    properties
        kernel, apshare % PRB: study the relationship between it and the one in UnitAP
        S % access point of state (next frame)
        lastFrameMode % structure for Last Frame Mode
    end
    
    methods (Static)
        function [refer, aprox] = debug()
            datasize  = 16;
            statesize = 16;
            nframe  = 3;
            nvalid  = 100;
            batchsize = 8;
            % create referent model
            refer = LSTM.randinit(datasize, statesize);
%             refer = SimpleRNN.randinit(datasize, statesize, 'sigmoid');
%             refer.blin = BilinearTransform.randinit(sizeinA, sizeinB, sizehid);
%             refer.model = RecurrentUnit(Model(refer.blin), {refer.blin.O, refer.blin.IA});
%             refer.model.enableLastFrameMode();
%             refer.actIn = Activation('ReLu');
%             refer.lin = LinearTransform.randinit(sizehid, sizeout);
%             refer.actOut = Activation('sigmoid');
%             refer.blin.O.connect(refer.actIn.I);
%             refer.actIn.O.connect(refer.lin.I);
%             refer.lin.O.connect(refer.actOut.I);
%             refer.model = RecurrentUnit( ...
%                 Model(refer.blin, refer.actIn, refer.lin, refer.actOut), ...
%                 {refer.actOut.O, refer.blin.IA});
            % create estimate model
            aprox = LSTM.randinit(datasize, statesize);
%             aprox = SimpleRNN.randinit(datasize, statesize, 'sigmoid');
%             aprox.blin = BilinearTransform.randinit(sizeinA, sizeinB, sizeout);
%             aprox.model = RecurrentUnit(Model(aprox.blin), {aprox.blin.O, aprox.blin.IA});
%             aprox.model.enableLastFrameMode();
%             aprox.actIn = Activation('ReLU');
%             aprox.lin = LinearTransform.randinit(sizehid, sizeout);
%             aprox.actOut = Activation('sigmoid');
%             aprox.blin.O.connect(aprox.actIn.I);
%             aprox.actIn.O.connect(aprox.lin.I);
%             aprox.lin.O.connect(aprox.actOut.I);
%             aprox.model = RecurrentUnit( ...
%                 Model(aprox.blin, aprox.actIn, aprox.lin, aprox.actOut), ...
%                 {aprox.actOut.O, aprox.blin.IA});
            % create validate data
            validsetInA = DataPackage(rand(datasize, nframe, nvalid), 1, true);
            validsetInB = DataPackage(rand(statesize, nvalid), 1, false);
            validsetInC = DataPackage(rand(statesize, nvalid), 1, false);
            validsetOut = refer.forward(validsetInA, validsetInB, validsetInC);
            % define likelihood as optimization objective
            likelihood = Likelihood('mse');
            % display current status of estimation
            objval = likelihood.evaluate( ...
                aprox.forward(validsetInA, validsetInB, validsetInC).data, ...
                validsetOut.data);
            fprintf('Initial objective value : %.2e\n', objval);
            % optimize estimation by SGD
            for i = 1 : UMPrest.parameter.get('iteration')
                apkg = DataPackage(randn(datasize, nframe, batchsize), 1, true);
                bpkg = DataPackage(randn(statesize, batchsize), 1, false);
                cpkg = DataPackage(randn(statesize, batchsize), 1, false);
                opkg = refer.forward(apkg, bpkg, cpkg);
                ppkg = aprox.forward(apkg, bpkg, cpkg);
                aprox.backward(likelihood.delta(ppkg, opkg));
                aprox.update();
                objval = likelihood.evaluate( ...
                    aprox.forward(validsetInA, validsetInB, validsetInC).data, ...
                    validsetOut.data);
                fprintf('Objective Value after [%04d] turns: %.2e\n', i, objval);
%                 pause();
            end
%             objval = likelihood.evaluate( ...
%                 aprox.model.forward(validsetInA, validsetInB).data, ...
%                 validsetOut.data);
%             fprintf('Objective Value after [%04d] turns: %.2e\n', i, objval);
%             % show estimation error
%             distinfo(abs(refer.blin.weightA - aprox.blin.weightA), 'WEIGHT IN A', false);
%             distinfo(abs(refer.blin.weightB - aprox.blin.weightB), 'WEIGHT IN B', false);
%             distinfo(abs(refer.blin.bias - aprox.blin.bias),  'BIAS IN', false);
%             distinfo(abs(refer.lin.weight - aprox.lin.weight), 'WEIGHT HID', false);
%             distinfo(abs(refer.lin.bias - aprox.lin.bias), 'BIAS HID', false);
            % FOR LSTM
            distinfo(abs(cat(2, refer.dump{:}) - cat(2, aprox.dump{:})), 'WEIGHTS', false);
        end
    end
end
