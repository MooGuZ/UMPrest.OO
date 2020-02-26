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
            nlayerOut = size(alpha, 4);
            
            % compose bases (real and imaginary)
            br = alpha .* cos(theta);
            bi = alpha .* sin(theta);
            
            tr = permute(tr, [1, 2, 3, 5, 4]);
            ti = permute(ti, [1, 2, 3, 5, 4]);
            
            if nlayerOut > 1
                y  = cell(nlayerOut, 1);
                tr = MatrixOperation.matsplit(tr, 4);
                ti = MatrixOperation.matsplit(ti, 4);
                br = MatrixOperation.matsplit(br, 3);
                bi = MatrixOperation.matsplit(bi, 3);
                for i = 1 : nlayerOut
                    y{i} = MatrixOperation.nnconv(tr{i}, br{i}, 'same') ...
                    - MatrixOperation.nnconv(ti{i}, bi{i}, 'same');
                end
                y = cat(3, y{i});
            else
                y = MatrixOperation.nnconv(tr, br, 'same') ...
                    - MatrixOperation.nnconv(ti, bi, 'same');
            end
        end
        
        function [dx, dphase] = datagrad(dy, x, phase, alpha, theta)
            nlayerOut = size(alpha, 4);
            
            % get flipped version of bases
            bfr = flip(flip(alpha .* cos(theta), 1), 2);
            bfi = flip(flip(alpha .* sin(theta), 1), 2);
            
            % make output-dimension the 3rd one
            bfr = permute(bfr, [1, 2, 4, 3]);
            bfi = permute(bfi, [1, 2, 4, 3]);
            
            if nlayerOut > 1
                tr = cell(nlayerOut, 1);
                ti = cell(nlayerOut, 1);
                for i = 1 : nlayerOut
                    tr{i} = MatrixOperation.nnconv(dy(:, :, i, :), bfr(:, :, i, :), 'same');
                    ti{i} = MatrixOperation.nnconv(dy(:, :, i, :), bfi(:, :, i, :), 'same');
                end
                tr = permute(cat(5, tr{:}), [1, 2, 3, 5, 4]);
                ti = permute(cat(5, ti{:}), [1, 2, 3, 5, 4]);
            else
                tr = MatrixOperation.nnconv(dy, bfr, 'same');
                ti = MatrixOperation.nnconv(dy, bfi, 'same');
                tr = MatrixOperation.diminsert(tr, 4);
                ti = MatrixOperation.diminsert(ti, 4);
            end
            
            dx = sum(cos(phase) .* tr - sin(phase) .* ti, 4);
            dx = MatrixOperation.dimcomb(dx, 4);
            
            x = MatrixOperation.diminsert(x, 4);
            dphase = -bsxfun(@times, x, (sin(phase) .* tr + cos(phase) .* ti));
        end
        
        function [dalpha, dtheta] = basegrad(dy, x, phase, alpha, theta)
            nlayerOut = size(alpha, 4);
            
            % get flipped phase-shifting input data
            x   = MatrixOperation.diminsert(x, 4);
            xr  = bsxfun(@times, x, cos(phase));
            xi  = bsxfun(@times, x, sin(phase));
            xfr = flip(flip(xr, 1), 2);
            xfi = flip(flip(xi, 1), 2);
            
            % add zero-paddings for gradients
            padsize = ([size(alpha,1), size(alpha,2)] - 1) / 2;
            if MathLib.isinteger(padsize)
                dy = padarray(dy, padsize, 0, 'both');
            else
                dy = padarray(dy, ceil(padsize), 0, 'pre');
                dy = padarray(dy, floor(padsize), 0, 'post');
            end
            
            % make batch-dimension the 3rd dimension
            xfr = permute(xfr, [1, 2, 5, 3, 4]);
            xfi = permute(xfi, [1, 2, 5, 3, 4]);
            dy  = permute(dy,  [1, 2, 4, 3]);
            
            if nlayerOut > 1
                tr  = cell(nlayerOut, 1);
                ti  = cell(nlayerOut, 1);
                xfr = MatrixOperation.matsplit(xfr, 4);
                xfi = MatrixOperation.matsplit(xfi, 4);
                dy  = MatrixOperation.matsplit(dy,  3);
                for i = 1 : nlayerOut
                    tr{i} = MatrixOperation.nnconv(dy{i}, xfr{i}, 'valid');
                    ti{i} = MatrixOperation.nnconv(dy{i}, xfi{i}, 'valid');
                end
                tr = cat(4, tr{:});
                ti = cat(4, ti{i});
            else
                tr = MatrixOperation.nnconv(dy, xfr, 'valid');
                ti = MatrixOperation.nnconv(dy, xfi, 'valid');
            end
            
            dalpha = cos(theta) .* tr - sin(theta) .* ti;
            dtheta = -alpha .* (sin(theta) .* tr + cos(theta) .* ti);
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