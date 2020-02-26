% Steerable Convolutional Decoder
%
% PROBLEMS:
%  1. cannot ensure alpha, theta and bias are consistent in size
classdef SConvDecoder < MISOUnit & FeedforwardOperation & Evolvable
    % Top-Level Methods
    methods
        function y = dataproc(obj, x, phase)
            % mix x and phase to get real and imaginary part data
            x = MathLib.splitDim(x, 4, 1);
            t.real = bsxfun(@times, x, cos(phase));
            t.imag = bsxfun(@times, x, sin(phase));
            % do convolutional part accroding to current mode
            switch obj.mode.type
                case {'spacing'}
                    y = cell(obj.mode.spacing);
                    for i = 1 : obj.mode.spacing(1)
                        for j = 1 : obj.mode.spacing(2)
                            y{i, j} = SConvDecoder.conv( ...
                                t.real, t.imag, obj.ASet{i, j}, obj.TSet{i,j});
                        end
                    end
                    y = MatrixOperation.combineStrideSet(y);
                    
                case {'stride'}                    
                    y = 0;
                    % decompose input date according to stride
                    tr = MatrixOperation.getStrideSet(t.real, obj.mode.stride);
                    ti = MatrixOperation.getStrideSet(t.imag, obj.mode.stride);
                    for i = 1 : obj.mode.stride(1)
                        for j = 1 : obj.mode.stride(2)
                            y = y + SConvDecoder.conv( ...
                                tr{i, j}, ti{i, j}, obj.ASet{i, j}, obj.TSet{i,j});
                        end
                    end
                    
                otherwise
                    y = SConvDecoder.conv(t.real, t.imag, obj.alpha, obj.theta);
                    
            end
            % add bias
            y = bsxfun(@plus, y, reshape(obj.bias, [1, 1, numel(obj.bias)]));
        end
        
        function [dx, dphase] = deltaproc(obj, dy)
            x     = obj.I{1}.datarcd.pop();
            phase = obj.I{2}.datarcd.pop();
            % get gradient of bias if necessary
            if not(obj.isfrozen()) && obj.pkginfo.updateHParam
                obj.B.addgrad(MathLib.margin(dy, 3));
            end
            % get gradient of input and phase
            switch obj.mode.type
                case {'stride'}
                    dxset  = cell(obj.mode.stride);
                    dphset = cell(obj.mode.stride);
                    % decompose x and phase
                    [xset,  xpadding]  = MatrixOperation.getStrideSet(x, obj.mode.stride);
                    [phset, phpadding] = MatrixOperation.getStrideSet(phase, obj.mode.stride);
                    for i = 1 : obj.mode.stride(1)
                        for j = 1 : obj.mode.stride(2)
                            [dxset{i, j}, dphset{i, j}] = SConvDecoder.datagrad( ...
                                dy, xset{i, j}, phset{i, j}, obj.ASet{i, j}, obj.TSet{i, j});
                        end
                    end
                    dx     = MatrixOperation.combineStrideSet(dxset,  xpadding);
                    dphase = MatrixOperation.combineStrideSet(dphset, phpadding);
                    
                case {'spacing'}
                    dx     = 0;
                    dphase = 0;
                    % decompose output gradients
                    dyset = MatrixOperation.getStrideSet(dy, obj.mode.spacing);
                    for i = 1 : obj.mode.spacing(1)
                        for j = 1 : obj.mode.spacing(2)
                            [tdx, tdph] = SConvDecoder.datagrad( ...
                                dyset{i, j}, x, phase, obj.ASet{i, j}, obj.TSet{i, j});
                            dx     = dx + tdx;
                            dphase = dphase + tdph;
                        end
                    end
                    
                otherwise
                    [dx, dphase] = SConvDecoder.datagrad(dy, x, phase, obj.alpha, obj.theta);
            end
            % get gradient of bases if necessary
            if not(obj.isfrozen()) && obj.pkginfo.updateHParam
                switch obj.mode.type
                    case {'stride'}
                        dASet = cell(obj.mode.stride);
                        dTSet = cell(obj.mode.stride);
                        % calcuate gradient of bases for each subset
                        for i = 1 : obj.mode.stride(1)
                            for j = 1 : obj.mode.stride(2)
                                [dASet{i, j}, dTSet{i, j}] = SConvDecoder.basegrad( ...
                                    dy, xset{i, j}, phset{i, j}, obj.ASet{i, j}, obj.TSet{i,j});
                            end
                        end
                        % compose gradients of bases from subset
                        dA = MatrixOperation.combineStrideSet(dASet, obj.basePadding, 'reverse');
                        dT = MatrixOperation.combineStrideSet(dTSet, obj.basePadding, 'reverse');
                        
                    case {'spacing'}
                        dASet = cell(obj.mode.spacing);
                        dTSet = cell(obj.mode.spacing);
                        % calcuate gradient of bases for each subset
                        for i = 1 : obj.mode.spacing(1)
                            for j = 1 : obj.mode.spacing(2)
                                [dASet{i, j}, dTSet{i, j}] = SConvDecoder.basegrad( ...
                                    dyset{i, j}, x, phase, obj.ASet{i, j}, obj.TSet{i,j});
                            end
                        end
                        % compose gradients of bases from subset
                        dA = MatrixOperation.combineStrideSet(dASet, obj.basePadding);
                        dT = MatrixOperation.combineStrideSet(dTSet, obj.basePadding);
                        
                    otherwise
                        [dA, dT] = SConvDecoder.basegrad(dy, x, phase, obj.alpha, obj.theta);
                end
                obj.A.addgrad(dA);
                obj.T.addgrad(dT);
            end
        end
    end
    
    % Meta (Mathematical) Operations
    methods (Static)
        function y = conv(tr, ti, alpha, theta)
            nbatch    = size(tr, 5);
            nlayerIn  = size(alpha, 3);
            nlayerOut = size(alpha, 4);
            % calculate bases
            br = MatrixOperation.matsplit(alpha .* cos(theta), 2);
            bi = MatrixOperation.matsplit(alpha .* sin(theta), 2);
            % split input data
            tr = MatrixOperation.matsplit(tr, 2);
            ti = MatrixOperation.matsplit(ti, 2);
            % initialize outputs
            y = cell(nlayerOut, nbatch);
            for ib = 1 : nbatch
                for j = 1 : nlayerOut
                    temp = 0;
                    for i = 1 : nlayerIn
                        temp = temp + conv2(tr{i, j, ib}, br{i, j}, 'same') ...
                            - conv2(ti{i, j, ib}, bi{i, j}, 'same');
                    end
                    y{j, ib} = temp;
                end
            end
            y = MatrixOperation.cellcombine(y, 3);
        end
        
        function [dx, dphase] = datagrad(dy, x, phase, alpha, theta)
            nbatch    = size(dy, 4);
            nlayerIn  = size(alpha, 3);
            nlayerOut = size(alpha, 4);
            % calculate filpped bases
            bfr = MatrixOperation.matsplit(flip(flip(alpha .* cos(theta), 1), 2), 2);
            bfi = MatrixOperation.matsplit(flip(flip(alpha .* sin(theta), 1), 2), 2);
            % split gradients into cells
            dy    = MatrixOperation.matsplit(dy, 2);
            % initialize temporary values
            tr = cell(nlayerIn, nlayerOut, nbatch);
            ti = cell(nlayerIn, nlayerOut, nbatch);
            for ib = 1 : nbatch
                for i = 1 : nlayerIn
                    for j = 1 : nlayerOut
                        tr{i, j, ib} = conv2(dy{j, ib}, bfr{i, j}, 'same');
                        ti{i, j, ib} = conv2(dy{j, ib}, bfi{i, j}, 'same');
                    end
                end
            end
            tr = MatrixOperation.cellcombine(tr, 3);
            ti = MatrixOperation.cellcombine(ti, 3);
            % calculate gradient of input
            dx = sum(cos(phase) .* tr - sin(phase) .* ti, 4);
            dx = MathLib.expandDim(dx, 4);
            % calculate gradient of phase
            x = MathLib.splitDim(x, 4, 1);
            dphase = -bsxfun(@times, x, (sin(phase) .* tr + cos(phase) .* ti));
        end
        
        function [dalpha, dtheta] = basegrad(dy, x, phase, alpha, theta)
            nbatch    = size(dy, 4);
            nlayerIn  = size(alpha, 3);
            nlayerOut = size(alpha, 4);
            % calculate temporary value
            x = MathLib.splitDim(x, 4, 1);
            tr = bsxfun(@times, x, cos(phase));
            ti = bsxfun(@times, x, sin(phase));
            % get flipped input data
            tfr = MatrixOperation.matsplit(flip(flip(tr, 1), 2), 2);
            tfi = MatrixOperation.matsplit(flip(flip(ti, 1), 2), 2);
            % add zero-padding to gradients
            padpre  = ceil(([size(alpha,1), size(alpha,2)] - 1) / 2);
            dy      = padarray(dy, padpre, 0, 'pre');
            padpost = floor(([size(alpha,1), size(alpha,2)] - 1) / 2);
            dy      = padarray(dy, padpost, 0, 'post');
            % split gradients into cells
            dy = MatrixOperation.matsplit(dy, 2);
            % initialize temporary value
            pr = cell(nlayerIn, nlayerOut);
            pi = cell(nlayerIn, nlayerOut);
            for i = 1 : nlayerIn
                for j = 1 : nlayerOut
                    pr{i, j} = 0;
                    pi{i, j} = 0;
                    for ib = 1 : nbatch
                        pr{i, j} = pr{i, j} + conv2(dy{j, ib}, tfr{i, j, ib}, 'valid');
                        pi{i, j} = pi{i, j} + conv2(dy{j, ib}, tfi{i, j, ib}, 'valid');
                    end
                end
            end
            pr = MatrixOperation.cellcombine(pr, 3);
            pi = MatrixOperation.cellcombine(pi, 3);
            % calculate gradients of bases
            dalpha = cos(theta) .* pr - sin(theta) .* pi;
            dtheta = -alpha .* (sin(theta) .* pr + cos(theta) .* pi);
        end
    end
    
    % Mode Setup (Stride and Spacing)
    methods
        function obj = setup(obj, mode, info)
            if not(exist('mode', 'var'))
                mode = 'normal';
            end
            
            if exist('info', 'var')
                assert(MathLib.isinteger(info), 'Size Information has to be integers!');
                assert(all(info > 0), 'Size Information has to be positive!');
                assert(numel(info) > 0 && numel(info) < 3, ...
                    'Size Information must contains 1 / 2 elements!');
                if numel(info) == 1 
                    info = [info, info];
                end
            end
            
            switch lower(mode)
                case {'stride'}
                    obj.mode = struct('type', 'stride', 'stride', info);
                    
                case {'spacing'}
                    obj.mode = struct('type', 'spacing', 'spacing', info);
                    
                case {'normal', 'clear'}
                    obj.mode = struct('type', 'normal');
            end
            
            obj.refresh();
        end
        
        function obj = refresh(obj)
            % standardize bases
            [amplitude, phase] = SConvEncoder.standardize(obj.alpha, obj.theta);
            obj.A.set(amplitude);
            obj.T.set(phase);
            
            
            % decompose bases if necessary
            switch obj.mode.type
                case {'stride'}
                    refpoint = MatrixOperation.getRefPoint(size(obj.A));
                    [obj.ASet, obj.basePadding] = MatrixOperation.getStrideSet( ...
                        obj.alpha, obj.mode.stride, refpoint, 'reverse');
                    obj.TSet = MatrixOperation.getStrideSet( ...
                        obj.theta, obj.mode.stride, refpoint, 'reverse');
                    
                case {'spacing'}
                    refpoint = MatrixOperation.getRefPoint(size(obj.A));
                    [obj.ASet, obj.basePadding] = MatrixOperation.getStrideSet( ...
                        obj.alpha, obj.mode.spacing, refpoint);
                    obj.TSet = MatrixOperation.getStrideSet( ...
                        obj.theta, obj.mode.spacing, refpoint);
            
                otherwise
                    obj.ASet = [];
                    obj.TSet = [];
                    obj.basePadding = [];
            end
        end
    end
    
    % Class Interfaces Implementation
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.A, obj.T, obj.B};
        end
        
        function update(obj)
            update@Evolvable(obj);
            obj.refresh();
        end
        
        function szinfo = sizeIn2Out(obj, szinfo, ~)
            szinfo(3) = size(obj.A, 4);
        end
        
        function szinfo = sizeOut2In(obj, szinfo, ~)
            szinfo(3) = size(obj.A, 3);
        end
        
        function smpsize(~, ~)
            error('SAMPLE SIZE UNDEFINED!');
        end
    end
    properties (Constant, Hidden)
        taxis = false;
    end
    
    % Constructors
    methods
        function obj = SConvDecoder(alpha, theta, bias)
            % Hyper-Parameters
            obj.A = HyperParam(alpha);
            obj.T = HyperParam(theta);
            obj.B = HyperParam(bias);
            % Input-Output Interfaces
            obj.I = {UnitAP(obj, 3, '-recdata'), UnitAP(obj, 4, '-recdata')};
            obj.O = {UnitAP(obj, 3)};
            % initialize as normal mode
            obj.setup();
        end
    end
    methods (Static)
        function obj = randinit(baseSize, nlayerIn, nlayerOut)
            alpha = HyperParam.randct(baseSize, nlayerIn, nlayerOut);
            theta = HyperParam.randct(baseSize, nlayerIn, nlayerOut) * pi;
            bias  = zeros(nlayerOut, 1);
            obj = SConvDecoder(alpha, theta, bias);
        end
    end
    
    % Debugger
    methods (Static)
        function debug(niter, probScale, batchsize, validsize)
            if not(exist('niter',     'var')), niter     = 5e2; end
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            type = 'spacing';
            grid = [2, 2];
            
            sizein    = [probScale, probScale];
            nlayerIn  = ceil(log2(probScale));
            nlayerOut = nlayerIn + 1;
            baseSize  = ceil(sqrt(sizein));
            % reference model
            refer = SConvDecoder.randinit(baseSize, nlayerIn, nlayerOut);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            switch type
                case {'stride'}
                    refer.setup('stride', grid);
                    
                case {'spacing'}
                    refer.setup('spacing', grid);
                    
                otherwise
                    refer.refresh();
            end
            % approximate model
            model = SConvDecoder.randinit(baseSize, nlayerIn, nlayerOut);
            switch type
                case {'stride'}
                    model.setup('stride', grid);
                    
                case {'spacing'}
                    model.setup('spacing', grid);
                    
                otherwise
                    model.refresh();
            end
            % data generator
            xgen = DataGenerator('normal', [sizein, nlayerIn]);
            pgen = DataGenerator('normal', [sizein, nlayerIn, nlayerOut]);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, {xgen, pgen}, objective);
            task.run(niter, batchsize, validsize);
        end
    end
    
    properties (SetAccess = protected)
        mode     % structure indicating mode (stride/spacing/normal) and associated parameters
    end
    properties (Access = protected)
        calcRcd  % records for intermediate values in calcuation
        A, T, B
        ASet, TSet, basePadding
    end
    properties (Dependent)
        alpha, theta, bias
    end
    methods
        function value = get.alpha(obj)
            value = obj.A.get();
        end
        function set.alpha(obj, value)
            obj.A.set(value);
            obj.refresh();
        end
        
        function value = get.theta(obj)
            value = obj.T.get();
        end
        function set.theta(obj, value)
            obj.T.set(value);
            obj.refresh();
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
end