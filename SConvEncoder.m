% Steerable Convolutional Encoder provides phase-shifting function to
% convolution operation.
%
% PROBLEMS:
%  1. cannot ensure alpha, theta and bias are consistent in size
classdef SConvEncoder < MISOUnit & FeedforwardOperation & Evolvable
    % Top-Level Methods
    methods
        function y = dataproc(obj, x, phase)
            % do convolutional part accroding to current mode
            switch obj.mode.type
                case {'spacing'}
                    tr = cell(obj.mode.spacing);
                    ti = cell(obj.mode.spacing);
                    for i = 1 : obj.mode.spacing(1)
                        for j = 1 : obj.mode.spacing(2)
                            [tr{i, j}, ti{i, j}] = ...
                                SConvEncoder.conv(x, obj.ASet{i, j}, obj.TSet{i,j});
                        end
                    end
                    t.real = MatrixOperation.combineStrideSet(tr);
                    t.imag = MatrixOperation.combineStrideSet(ti);
                    
                case {'stride'}                    
                    t.real = 0;
                    t.imag = 0;
                    % decompose input date according to stride
                    xset = MatrixOperation.getStrideSet(x, obj.mode.stride);
                    for i = 1 : obj.mode.stride(1)
                        for j = 1 : obj.mode.stride(2)
                            [tr, ti] = SConvEncoder.conv( ...
                                xset{i, j}, obj.ASet{i, j}, obj.TSet{i,j});
                            t.real = t.real + tr;
                            t.imag = t.imag + ti;
                        end
                    end
                    
                otherwise
                    [t.real, t.imag] = SConvEncoder.conv(x, obj.alpha, obj.theta);
                    
            end
            % save t for calculation of gradient
            obj.calcRcd.push(t);
            % steer with phase
            y = sum(cos(phase) .* t.real - sin(phase) .* t.imag, 3);
            y = MathLib.expandDim(y, 3);
            % add bias
            y = bsxfun(@plus, y, reshape(obj.bias, [1, 1, numel(obj.bias)]));
        end
        
        function [dx, dphase] = deltaproc(obj, dy)
            x     = obj.I{1}.datarcd.pop();
            phase = obj.I{2}.datarcd.pop();
            t     = obj.calcRcd.pop();
            % get gradient of bias if necessary
            if not(obj.isfrozen()) && obj.pkginfo.updateHParam
                obj.B.addgrad(MathLib.margin(dy, 3));
            end
            % update output gradient by steering with phase
            dy = MathLib.splitDim(dy, 3, 1);
            d.real = bsxfun(@times, dy, cos(phase));
            d.imag = bsxfun(@times, dy, sin(phase));
            % get gradient of phase
            dphase = -(d.imag .* t.real + d.real .* t.imag);
            % get gradient of input
            switch obj.mode.type
                case {'stride'}
                    dxset = cell(obj.mode.stride);
                    for i = 1 : obj.mode.stride(1)
                        for j = 1 : obj.mode.stride(2)
                            dxset{i, j} = SConvEncoder.datagrad( ...
                                d.real, d.imag, obj.ASet{i, j}, obj.TSet{i, j});
                        end
                    end
                    dx = MatrixOperation.combineStrideSet(dxset);
                    % remove padding zeros if necessary
                    if not(all(size(x) == size(dx)))
                        dx = dx(1 : size(x, 1), 2 : size(x, 2), :, :);
                    end
                    
                case {'spacing'}
                    dx = 0;
                    % decompose updated gradients
                    dset.real = MatrixOperation.getStrideSet(d.real, obj.mode.spacing);
                    dset.imag = MatrixOperation.getStrideSet(d.imag, obj.mode.spacing);
                    for i = 1 : obj.mode.spacing(1)
                        for j = 1 : obj.mode.spacing(2)
                            dx = dx + SConvEncoder.datagrad( ...
                                dset.real{i, j}, dset.imag{i, j}, obj.ASet{i, j}, obj.TSet{i, j});
                        end
                    end
                    
                otherwise
                    dx = SConvEncoder.datagrad(d.real, d.imag, obj.alpha, obj.theta);
            end
            % get gradient of bases if necessary
            if not(obj.isfrozen()) && obj.pkginfo.updateHParam
                switch obj.mode.type
                    case {'stride'}
                        dASet = cell(obj.mode.stride);
                        dTSet = cell(obj.mode.stride);
                        % decompose input data by stride
                        xset = MatrixOperation.getStrideSet(x, obj.mode.stride);
                        % calcuate gradient of bases for each subset
                        for i = 1 : obj.mode.stride(1)
                            for j = 1 : obj.mode.stride(2)
                                [dASet{i, j}, dTSet{i, j}] = SConvEncoder.basegrad( ...
                                    d.real, d.imag, xset{i, j}, obj.ASet{i, j}, obj.TSet{i,j});
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
                                [dASet{i, j}, dTSet{i, j}] = SConvEncoder.basegrad( ...
                                    dset.real{i, j}, dset.imag{i, j}, ...
                                    x, obj.ASet{i, j}, obj.TSet{i,j});
                            end
                        end
                        % compose gradients of bases from subset
                        dA = MatrixOperation.combineStrideSet(dASet, obj.basePadding);
                        dT = MatrixOperation.combineStrideSet(dTSet, obj.basePadding);
                        
                    otherwise
                        [dA, dT] = SConvEncoder.basegrad(d.real, d.imag, x, obj.alpha, obj.theta);
                end
                obj.A.addgrad(dA);
                obj.T.addgrad(dT);
            end
        end
    end
    
    % Meta (Mathematical) Operations
    methods (Static)
        function [yr, yi] = conv(x, alpha, theta)
            nlayerIn = size(alpha, 3);
            
            % compose bases (real and imaginary)
            br = alpha .* cos(theta);
            bi = alpha .* sin(theta);
            
            if nlayerIn > 1
                yr = cell(nlayerIn, 1);
                yi = cell(nlayerIn, 1);
                for i = 1 : nlayerIn
                    yr{i} = MatrixOperation.nnconv(x(:, :, i, :), br(:, :, i, :), 'same');
                    yi{i} = MatrixOperation.nnconv(x(:, :, i, :), bi(:, :, i, :), 'same');
                end
                yr = permute(cat(5, yr{:}), [1, 2, 5, 3, 4]);
                yi = permute(cat(5, yi{:}), [1, 2, 5, 3, 4]);
            else
                yr = MatrixOperation.nnconv(x, br, 'same');
                yi = MatrixOperation.nnconv(x, bi, 'same');
                yr = MatrixOperation.diminsert(yr, 3);
                yi = MatrixOperation.diminsert(yi, 3);
            end
        end
        
        function dx = datagrad(dyr, dyi, alpha, theta)
            nlayerIn = size(alpha, 3);
            
            % get flipped version of bases
            bfr = flip(flip(alpha .* cos(theta), 1), 2);
            bfi = flip(flip(alpha .* sin(theta), 1), 2);
            
            % make input layers as the last dimension
            dyr = permute(dyr, [1, 2, 4, 5, 3]);
            dyi = permute(dyi, [1, 2, 4, 5, 3]);
            bfr = permute(bfr, [1, 2, 4, 3]);
            bfi = permute(bfi, [1, 2, 4, 3]);
            
            if nlayerIn > 1
                dx = cell(nlayerIn, 1);
                bfr = MatrixOperation.matsplit(bfr, 3);
                bfi = MatrixOperation.matsplit(bfi, 3);
                dyr = MatrixOperation.matsplit(dyr, 4);
                dyi = MatrixOperation.matsplit(dyi, 4);
                for i = 1 : nlayerIn
                    dx{i} = MatrixOperation.nnconv(dyr{i}, bfr{i}, 'same') ...
                        - MatrixOperation.nnconv(dyi{i}, bfi{i}, 'same');
                end
                dx = cat(3, dx{:});
            else
                dx = MatrixOperation.nnconv(dyr, bfr, 'same') ...
                    - MatrixOperation.nnconv(dyi, bfi, 'same');
            end
        end
        
        function [dalpha, dtheta] = basegrad(dyr, dyi, x, alpha, theta)
            nlayerIn = size(alpha, 3);
            
            % get flipped input data
            xf = flip(flip(x, 1), 2);
            
            % add zero-padding to gradients
            padsize = ([size(alpha,1), size(alpha,2)] - 1) / 2;
            if MathLib.isinteger(padsize)
                dyr = padarray(dyr, padsize, 0, 'both');
                dyi = padarray(dyi, padsize, 0, 'both');
            else
                dyr = padarray(dyr, ceil(padsize), 0, 'pre');
                dyi = padarray(dyi, ceil(padsize), 0, 'pre');
                dyr = padarray(dyr, floor(padsize), 0, 'post');
                dyi = padarray(dyi, floor(padsize), 0, 'post');
            end
            
            % make batch-dimension to the 3rd one
            xf  = permute(xf,  [1, 2, 4, 3]);
            dyr = permute(dyr, [1, 2, 5, 4, 3]);
            dyi = permute(dyi, [1, 2, 5, 4, 3]);
            
            if nlayerIn > 1
                tr = cell(nlayerIn);
                ti = cell(nlayerIn);
                xf = MatrixOperation.matsplit(xf, 3);
                dyr = MatrixOperation.matsplit(dyr, 4);
                dyi = MatrixOperation.matsplit(dyi, 4);
                for i = 1 : nlayerIn
                    tr{i} = MatrixOperation.nnconv(dyr{i}, xf{i}, 'valid');
                    ti{i} = MatrixOperation.nnconv(dyi{i}, xf{i}, 'valid');
                end
                tr = cat(3, tr{:});
                ti = cat(3, ti{:});
            else
                tr = MatrixOperation.nnconv(dyr, xf, 'valid');
                ti = MatrixOperation.nnconv(dyi, xf, 'valid');
            end
            
            dalpha = cos(theta) .* tr - sin(theta) .* ti;
            dtheta = -alpha .* (sin(theta) .* tr + cos(theta) .* ti);
        end
        
        function [alpha, theta] = standardize(alpha, theta)
            % find negative alpha
            index = double(alpha < 0);
            % flip alpha and shift theta correspondingly
            alpha = abs(alpha);
            theta = theta + pi * index;
            % wrap theta into range [-pi, pi]
            theta = mod(theta, 2 * pi);
            index = double(theta > pi);
            theta = theta - 2 * pi * index;
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
        
        % override function to extend temporary memory as well, when
        % capacity of interfaces increase.
        function obj = recrtmode(obj, n)
            recrtmode@SimpleUnit(obj, n);
            obj.calcRcd.init(n);
        end
        
        function szinfo = sizeIn2Out(obj, szinfo)
            szinfo(3) = size(obj.A, 4);
        end
        
        function szinfo = sizeOut2In(obj, szinfo)
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
        function obj = SConvEncoder(alpha, theta, bias)
            % Hyper-Parameters
            obj.A = HyperParam(alpha);
            obj.T = HyperParam(theta);
            obj.B = HyperParam(bias);
            % Input-Output Interfaces
            obj.I = {UnitAP(obj, 3, '-recdata', '-cpu'), UnitAP(obj, 4, '-recdata', '-cpu')};
            obj.O = {UnitAP(obj, 3, '-cpu')};
            % Temporary Memory
            obj.calcRcd = Container();
            % initialize as normal mode
            obj.setup();
        end
    end
    methods (Static)
        function obj = randinit(baseSize, nlayerIn, nlayerOut)
            alpha = HyperParam.randct(baseSize, nlayerIn, nlayerOut);
            theta = HyperParam.randct(baseSize, nlayerIn, nlayerOut) * pi;
            bias  = zeros(nlayerOut, 1);
            obj = SConvEncoder(alpha, theta, bias);
        end
    end
    
    % Debugger
    methods (Static)
        function [model, refer] = debug(niter, probScale, batchsize, validsize)
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
            switch type
                case {'stride'}
                    sizeout = ceil(sizein ./ grid);
                    
                case {'spacing'}
                    sizeout = sizein .* grid;
                    
                otherwise
                    sizeout = sizein;
            end
            % reference model
            refer = SConvEncoder.randinit(baseSize, nlayerIn, nlayerOut);
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
            model = SConvEncoder.randinit(baseSize, nlayerIn, nlayerOut);
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
            pgen = DataGenerator('normal', [sizeout, nlayerIn, nlayerOut]);
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
            value = obj.A.getcpu();
        end
        function set.alpha(obj, value)
            obj.A.set(value);
            obj.refresh();
        end
        
        function value = get.theta(obj)
            value = obj.T.getcpu();
        end
        function set.theta(obj, value)
            obj.T.set(value);
            obj.refresh();
        end
        
        function value = get.bias(obj)
            value = obj.B.getcpu();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
end