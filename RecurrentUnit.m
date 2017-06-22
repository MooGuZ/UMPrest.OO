classdef RecurrentUnit < Unit & Evolvable
    methods
        % NOTE: current implementation doesn't take into consideration the
        %       case that output interface don't connect with a recurrent
        %       link. In this case, if only require selfeed frames by next
        %       unit, it is necessary to distinguish state-cycle subnet of
        %       the entire network. And both FORWARD and BACKWARD operations 
        %       should be modified correspondingly.
        % NOTE: currently, FORWARD operation is specified for DataPackage,
        %       while BACKWARD for ErrorPackage.
        function varargout = forward(obj, varargin)
            obj.pkginfo = RecurrentAP.initPackageInfo();
            if isempty(varargin)
                for i = 1 : numel(obj.DI)
                    obj.DI{i}.extract();
                end
            else
                for i = 1 : numel(obj.DI)
                    obj.DI{i}.extract(varargin{i});
                end
            end
            % initialize states
            for i = 1 : numel(obj.S)
                obj.S{i}.initForwardState();
            end
            % process all input frames
            for t = 1 : obj.pkginfo.nframe
                % send frame to kernel
                for i = 1 : numel(obj.DI)
                    obj.DI{i}.sendFrame();
                end
                % iterating states
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
            switch obj.outputMode.mode
              case {'normal'}
                varargout = cellfun(@compress, obj.DO, 'UniformOutput', false);
                  
              case {'lastframe'}
                varargout = cellfun(@(ap) ap.compress(true), obj.DO, 'UniformOutput', false);
                obj.outputMode.nframe = obj.pkginfo.nframe;
                
              otherwise
                error('UNSUPPORTED');
            end
            % send output package if necessary
            if nargout == 0
                for i = 1 : numel(obj.DO)
                    obj.DO{i}.send(varargout{i});
                end
            end
            % forward state to connected unit
            for i = 1 : numel(obj.S)
                obj.S{i}.stateForward();
            end
        end
        
        % TODO: add '-overwrite' option to data records and make warning
        %       in backward propagate of ErrorPackage while truncate its
        %       process to specific depth.
        function varargout = backward(obj, varargin)
            obj.pkginfo = RecurrentAP.initPackageInfo();
            % % clear hidden state
            % for i = 1 : numel(obj.S)
            %     obj.S{i}.clear();
            % end
            % extract frames from packages
            if isempty(varargin)
                for i = 1 : numel(obj.DO)
                    obj.DO{i}.extract();
                end
            else
                for i = 1 : numel(obj.DO)
                    obj.DO{i}.extract(varargin{i});
                end
            end
            % initialize states
            for i = 1 : numel(obj.S)
                obj.S{i}.initBackwardState();
            end
            % process selfeed frames
            if obj.selfeed.status
                for t = 1 : obj.selfeed.numSelfeedFrames
                    % send frame to kernel
                    for i = 1 : numel(obj.DO)
                        obj.DO{i}.sendFrame();
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
            % determine number of iteration
            switch obj.outputMode.mode
              case {'normal'}
                niteration = obj.pkginfo.nframe;
                
              case {'lastframe'}
                niteration = obj.outputMode.nframe;
                
              otherwise
                error('UNSUPPORTED');
            end
            % process ordinary frames
            for t = 1 : niteration
                % send frame to kernel
                for i = 1 : numel(obj.DO)
                    obj.DO{i}.sendFrame();
                end
                % update state in kernel
                for i = 1 : numel(obj.S)
                    obj.S{i}.backward();
                end
                % process data by kernel
                obj.kernel.backward();
            end
            % compress frames into package
            varargout = cellfun(@compress, obj.DI, 'UniformOutput', false);
            if nargout == 0
                for i = 1 : numel(obj.DI)
                    obj.DI{i}.send(varargout{i});
                end
            end
            % pass state to connected unit
            for i = 1 : numel(obj.S)
                obj.S{i}.stateBackward();
            end
        end
    end
    
    methods
        function obj = stateAheadof(obj, runit)
            for i = 1 : numel(obj.S)
                obj.S{i}.SO.connect(runit.S{i}.SI);
            end
        end
        
        function obj = stateAppendto(obj, runit)
            for i = 1 : numel(obj.S)
                obj.S{i}.SI.connect(runit.S{i}.SO);
            end
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = obj.hpcache;
        end
        
        function unitdump = dump(self)
            modeldump = self.kernel.dump();
            statedump = cell(1, numel(self.S));
            for i = 1 : numel(statedump)
                apin  = self.S{i}.I{1}.links{1};
                apout = self.S{i}.O{1}.links{1};
                iUnitIn  = self.kernel.id2ind(apin.parent.id);
                iUnitOut = self.kernel.id2ind(apout.parent.id);
                iApIn  = find(cellfun(@apin.compare, apin.parent.O));
                iApOut = find(cellfun(@apout.compare, apout.parent.I));
                statedump{i} = { ...
                    [iUnitIn, iApIn, iUnitOut, iApOut], ...
                    self.S{i}.statesize};
            end
            unitdump = {'RecurrentUnit.loaddump', modeldump, {'Transparent', statedump}};
        end
    end
    methods (Static)
        function self = loaddump(model, statedump)
            state = cell(1, numel(statedump));
            for i = 1 : numel(statedump)
                link  = statedump{i}{1};
                shape = statedump{i}{2};
                state{i} = { ...
                    model.nodes{link(1)}.O{link(2)}, ...
                    model.nodes{link(3)}.I{link(4)}, ...
                    shape};
            end
            self = RecurrentUnit(model, state{:});
        end
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
                assert(numel(obj.DI) == numel(obj.DO), 'SPECIFIC RECURRENT LINK REQUIRED');
                if numel(obj.DI) ~= 1
                    warning('CONNECTION ESTABLISHED AUTOMATICALLY WITHOUT SPECIFICATION');
                end
                rlinks = cell(1, numel(obj.DI));
                for i = 1 : numel(rlinks)
                    rlinks{i} = {obj.DO{i}.hostio.links{1}, obj.DI{i}.hostio.links{1}};
                end
            else
                inputTF = false(1, numel(obj.I));
                for i = 1 : numel(varargin)
                    tprev = varargin{i}{2};
                    for j = 1 : numel(obj.I)
                        if tprev.compare(obj.DI{j}.hostio.links{1})
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
    
    properties
        outputMode
    end
    methods
        function obj = setupOutputMode(obj, mode)
            switch lower(mode)
              case {'normal', 'default'}
                obj.outputMode = struct('mode', 'normal');
                
              case {'last', 'lastframe'}
                obj.outputMode = struct( ...
                    'mode',   'lastframe', ...
                    'nframe', []);
                
              otherwise
                error('UNSUPPORTED');
            end
        end
    end
    
    methods
        function obj = recrtmode(obj, n)
            for i = 1 : numel(obj.DI)
                obj.DI{i}.recrtmode(n);
            end
            for i = 1 : numel(obj.DO)
                obj.DO{i}.recrtmode(n);
            end
            obj.kernel.recrtmode(n);
            obj.memoryLength = n;
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
            obj.DI = cellfun(@(ap) RecurrentAP(obj, ap), apin, ...
                'UniformOutput', false);
            obj.DO = cellfun(@(ap) RecurrentAP(obj, ap), apout, ...
                'UniformOutput', false);
            % get all access-points
            obj.I = [obj.DI, cellfun(@(s) s.SI, obj.S, 'UniformOutput', false)];
            obj.O = [obj.DO, cellfun(@(s) s.SO, obj.S, 'UniformOutput', false)];
            % initially disable selfeed
            obj.disableSelfeed();
            % get hyper-parameter list
            obj.hpcache = obj.kernel.hparam();
            % setup output mode
            obj.setupOutputMode('default');
        end
    end
    
    properties (SetAccess = protected)
        kernel % instance of MODEL, who actually process the data
        I = {} % input access points set
        O = {} % output access points set
        S = {} % hidden states set
        DI     % input access-points for data
        DO     % output access-points for data
    end
    properties (Access = private)
        hpcache
    end
    properties (Hidden)
        pkginfo
    end
    properties (SetAccess = private)
        memoryLength = 40
    end
    methods
        function set.DI(obj, value)
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
                obj.DI = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.DO(obj, value)
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
                obj.DO = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
    
    methods (Static)
        function debug()
            datasize  = 16;
            statesize = 16;
            nframe    = 1;
            nvalid    = 100;
            batchsize = 8;
            % create model and its reference
            refer = LSTM.randinit(datasize, statesize);
            model = LSTM.randinit(datasize, statesize);
            % create dataset
            dataset = DataGenerator('normal', datasize).enableTmode(nframe);
            % create objectives
            objective = Likelihood('mse');
            % initialize task
            task = SimulationTest(model, refer, dataset, objective);
            % run task
            task.run(300, batchsize, nvalid);
        end
    end
end
