classdef RecurrentUnit < Unit & Evolvable
    methods
        % NOTE: current implementation doesn't take into consideration the
        %       case that output interface don't connect with a recurrent
        %       link. In this case, if only require selfeed frames by next
        %       unit, it is necessary to distinguish subnet of
        %       input-to-state with the whole network. And both FORWARD and
        %       BACKWARD operations should be modified correspondingly.
        % NOTE: currently, FORWARD operation is specified for DataPackage,
        %       while BACKWARD for ErrorPackage.
        function varargout = forward(obj, varargin)
            obj.pkginfo = RecurrentAP.initPackageInfo();
            % clear hidden state
            for i = 1 : numel(obj.S)
                obj.S{i}.clear();
            end
            % extract frames from packages
            if isempty(varargin)
                for i = 1 : numel(obj.I)
                    obj.I{i}.extract();
                end
            else
                for i = 1 : numel(obj.I)
                    obj.I{i}.extract(varargin{i});
                end
            end
            % process all input frames
            for t = 1 : obj.pkginfo.nframe
                % send frame to kernel
                for i = 1 : numel(obj.I)
                    obj.I{i}.sendFrame();
                end
                % update state in kernel
                for i = 1 : numel(obj.S)
                    obj.S{i}.forward();
                end
                % process data by kernel
                obj.kernel.forward();
            end
            % do selfeed cycle if necessary
            if obj.selfeed.status
                % update prelead-frames quantity record
                obj.selfeed.numPreleadFrames = obj.pkginfo.nframe;
                % slefeed cycle
                for t = 1 : obj.selfeed.numSelfeedFrames
                    % get input frame from last output frame
                    for i = 1 : numel(obj.selfeed.linkUnits)
                        obj.selfeed.linkUnits{i}.forward();
                    end
                    % update state in kernel
                    for i = 1 : numel(obj.S)
                        obj.S{i}.forward();
                    end
                    % process data by kernel
                    obj.kernel.forward();
                end
            end
            % collect frames into package
            varargout = cellfun(@compress, obj.O, 'UniformOutput', false);
            if nargout == 0
                for i = 1 : numel(obj.O)
                    obj.O{i}.send(varargout{i});
                end
            end
        end
        
        % TODO: add '-overwrite' option to data records and make warning
        %       in backward propagate of ErrorPackage while truncate its
        %       process to specific depth.
        function varargout = backward(obj, varargin)
            obj.pkginfo = RecurrentAP.initPackageInfo();
            % clear hidden state
            for i = 1 : numel(obj.S)
                obj.S{i}.clear();
            end
            % extract frames from packages
            if isempty(varargin)
                for i = 1 : numel(obj.O)
                    obj.O{i}.extract();
                end
            else
                for i = 1 : numel(obj.O)
                    obj.O{i}.extract(varargin{i});
                end
            end
            % process selfeed frames
            if obj.selfeed.status
                for t = 1 : obj.selfeed.numSelfeedFrames
                    % send frame to kernel
                    for i = 1 : numel(obj.O)
                        obj.O{i}.sendFrame();
                    end
                    % update state in kernel
                    for i = 1 : numel(obj.S)
                        obj.S{i}.backward();
                    end
                    % process data by kernel
                    obj.kernel.backward();
                    % feedback package from input to output
                    for i = 1 : numel(obj.selfeed.linkUnits)
                        obj.selfeed.linkUnits{i}.backward();
                    end
                end
                % update frame quantity
                obj.pkginfo.nframe = obj.pkginfo.nframe - obj.selfeed.numSelfeedFrames;
            end
            % process ordinary frames
            for t = 1 : obj.pkginfo.nframe
                % send frame to kernel
                for i = 1 : numel(obj.O)
                    obj.O{i}.sendFrame();
                end
                % update state in kernel
                for i = 1 : numel(obj.S)
                    obj.S{i}.backward();
                end
                % process data by kernel
                obj.kernel.backward();
            end
            % compress frames into package
            varargout = cellfun(@compress, obj.I, 'UniformOutput', false);
            if nargout == 0
                for i = 1 : numel(obj.I)
                    obj.I{i}.send(varargout{i});
                end
            end
        end
    end
       
    methods
        function hpcell = hparam(obj)
            hpcell = obj.hpcache;
        end
        
        function unitdump = dump(obj)
            unitdump = obj.kernel.dump();
            unitdump{1} = class(obj);
        end
        
        % function rawdata = dumpraw(obj)
        %     rawdata = obj.kernel.dumpraw();
        % end
        % 
        % function update(obj)
        %     obj.kernel.update();
        %     % NOTE: following code would update initial value of hidden
        %     %       state in optimization process. However, this part has
        %     %       not been well examinated.
        %     % for i = 1 : numel(obj.S)
        %     %     obj.S{i}.update();
        %     % end
        % end
        % 
        % function freeze(obj)
        %     obj.kernel.freeze();
        % end
        % 
        % function unfreeze(obj)
        %     obj.kernel.unfreeze();
        % end
    end
    
    properties (SetAccess = protected)
        selfeed
    end
    methods
        function obj = enableSelfeed(obj, n, varargin)
            % NOTE: 1. create structure containing 'number of prediction',
            %          'number of input frame'
            %       2. check provide links to cover all input
            % NOTE: this function require IO have been initialized to work properly
            if numel(varargin) == 0
                assert(numel(obj.I) == numel(obj.O), 'SPECIFIC RECURRENT LINK REQUIRED');
                if numel(obj.I) ~= 1
                    warning('CONNECTION ESTABLISHED AUTOMATICALLY WITHOUT SPECIFICATION');
                end
                rlinks = cell(1, numel(obj.I));
                for i = 1 : numel(rlinks)
                    rlinks{i} = {obj.O{i}.hostio.links{1}, obj.I{i}.hostio.links{1}};
                end
            else
                inputTF = false(1, numel(obj.I));
                for i = 1 : numel(varargin)
                    tprev = varargin{i}{2};
                    for j = 1 : numel(obj.I)
                        if tprev.compare(obj.I{j}.hostio.links{1})
                            inputTF(j) = true;
                            break
                        end
                    end
                end
                assert(all(inputTF), 'INPUT INTERFACE NOT COVERRED');
                rlinks = varargin;
            end
            % create link units
            lnunits = cell(1, numel(rlinks));
            for i = 1 : numel(lnunits)
                lnunits{i} = Link(rlinks{i}{1}, rlinks{i}{2});
            end
            % initialize control structure
            obj.selfeed = struct( ...
                'status', true, ...
                'numSelfeedFrames', n, ...
                'numPreleadFrames', []);
            obj.selfeed.linkUnits = lnunits;
        end
        
        function obj = disableSelfeed(obj)
            if not(isempty(obj.selfeed))
                % isolate all link units
                for i = 1 : numel(obj.selfeed.linkUnits)
                    obj.selfeed.linkUnits{i}.isolate();
                end
            end
            % modify control structure
            obj.selfeed = struct('status', false);
        end
    end
    
    methods
        function obj = RecurrentUnit(kernel, varargin)
            obj.kernel = kernel.recrtmode(obj.memoryLength).seal();
            % initialize access-point list for input/output
            apin  = obj.kernel.I;
            apout = obj.kernel.O;
            % create hidden state
            obj.S = cell(1, numel(varargin));
            for i = 1 : numel(obj.S)
                tnext = varargin{i}{1};
                tprev = varargin{i}{2};
                shape = varargin{i}{3};
                obj.S{i} = RecurrentState(obj, tnext, tprev, shape);
                apin(cellfun(@tprev.compare, apin)) = [];
            end
            % create input/output access-points
            obj.I = cellfun(@(ap) RecurrentAP(obj, ap), apin, ...
                'UniformOutput', false);
            obj.O = cellfun(@(ap) RecurrentAP(obj, ap), apout, ...
                'UniformOutput', false);
            % initially disable selfeed
            obj.disableSelfeed();
            % get hyper-parameter list
            obj.hpcache = obj.kernel.hparam();
        end
    end
    
    properties (SetAccess = protected)
        kernel % instance of MODEL, who actually process the data
        I = {} % input access points set
        O = {} % output access points set
        S = {} % hidden states set
    end
    properties (Access = private)
        hpcache
    end
    properties (Hidden)
        pkginfo
    end
    properties (Constant)
        memoryLength = 40
    end
    methods
        function set.I(obj, value)
            try
                assert(iscell(value));
                if isscalar(value)
                    assert(isa(value{1}, 'RecurrentAP'));
                else
                    for i = 1 : numel(value)
                        assert(isa(value{i}, 'RecurrentAP'));
                        value{i}.cooperate(i);
                    end
                end
                obj.I = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.O(obj, value)
            try
                assert(iscell(value));
                if isscalar(value)
                    assert(isa(value{1}, 'RecurrentAP'));
                else
                    for i = 1 : numel(value)
                        assert(isa(value{i}, 'RecurrentAP'));
                        value{i}.cooperate(i);
                    end
                end
                obj.O = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
    
    methods (Static)
        function [refer, aprox] = debug()
            datasize  = 16;
            statesize = 16;
            nframe  = 1;
            nvalid  = 100;
            batchsize = 8;
            
            % create referent model
            refer = RecCO.randinit(datasize, statesize);
            % refer = LSTM.randinit(datasize, statesize);
            % refer = SimpleRNN.randinit(datasize, statesize, 'sigmoid');
            % refer.enableSelfeed(1);
            
            % create estimate model
            aprox = RecCO.randinit(datasize, statesize);
            % aprox = LSTM.randinit(datasize, statesize);
            % aprox = SimpleRNN.randinit(datasize, statesize, 'sigmoid');
            % aprox.enableSelfeed(1);
            
            % create validate data
            validsetInA = DataPackage(rand(datasize, nframe, nvalid), 1, true);
            validsetOut = refer.forward(validsetInA);

            % define likelihood as optimization objective
            likelihood = Likelihood('mse');
            
            % display current status of estimation
            objval = likelihood.evaluate(aprox.forward(validsetInA).data, validsetOut.data);
            disp('[Initial Error Distribution]');
            distinfo(abs(refer.dumpraw() - aprox.dumpraw()), 'WEIGHTS', true);
            disp(repmat('=', 1, 100));
            fprintf('Initial objective value : %.2e\n', objval);
            
            % optimize estimation by SGD
            for i = 1 : UMPrest.parameter.get('iteration')
                apkg = DataPackage(randn(datasize, nframe, batchsize), 1, true);
                opkg = refer.forward(apkg);
                ppkg = aprox.forward(apkg);
%                 bpkg = DataPackage(randn(statesize, batchsize), 1, false);
%                 cpkg = DataPackage(randn(statesize, batchsize), 1, false);
%                 opkg = refer.forward(apkg, bpkg, cpkg);
%                 ppkg = aprox.forward(apkg, bpkg, cpkg);
                aprox.backward(likelihood.delta(ppkg, opkg));
                aprox.update();
                objval = likelihood.evaluate(aprox.forward(validsetInA).data, validsetOut.data);
%                 objval = likelihood.evaluate( ...
%                     aprox.forward(validsetInA, validsetInB, validsetInC).data, ...
%                     validsetOut.data);
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
            distinfo(abs(refer.dumpraw() - aprox.dumpraw()), 'WEIGHTS', true);
        end
    end
end
