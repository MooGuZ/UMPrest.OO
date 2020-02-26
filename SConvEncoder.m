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
            nbatch    = size(x, 4);
            nlayerIn  = size(alpha, 3);
            nlayerOut = size(alpha, 4);
            % calculate bases
            br = MatrixOperation.matsplit(alpha .* cos(theta), 2);
            bi = MatrixOperation.matsplit(alpha .* sin(theta), 2);
%             br = alpha .* cos(theta);
%             bi = alpha .* sin(theta);
            % initialize outputs
            yr = cell(nlayerIn, nlayerOut, nbatch);
            yi = cell(nlayerIn, nlayerOut, nbatch);
            for ib = 1 : nbatch
                for i = 1 : nlayerIn
                    x_slice = x(:, :, i, ib);
                    for j = 1 : nlayerOut
                        yr{i, j, ib} = conv2(x_slice, br{i, j}, 'same');
                        yi{i, j, ib} = conv2(x_slice, bi{i, j}, 'same');
%                         yr{i, j, ib} = conv2(x_slice, br(:, :, i, j), 'same');
%                         yi{i, j, ib} = conv2(x_slice, bi(:, :, i, j), 'same');
                    end
                end
            end
            yr = MatrixOperation.cellcombine(yr, 3);
            yi = MatrixOperation.cellcombine(yi, 3);
        end
        
        function dx = datagrad(dyr, dyi, alpha, theta)
            nbatch    = size(dyr, 5);
            nlayerIn  = size(alpha, 3);
            nlayerOut = size(alpha, 4);
            % calculate filpped bases
            bfr = MatrixOperation.matsplit(flip(flip(alpha .* cos(theta), 1), 2), 2);
            bfi = MatrixOperation.matsplit(flip(flip(alpha .* sin(theta), 1), 2), 2);
%             bfr = flip(flip(alpha .* cos(theta), 1), 2);
%             bfi = flip(flip(alpha .* sin(theta), 1), 2);
            % split gradients into cells
            dyr = MatrixOperation.matsplit(dyr, 2);
            dyi = MatrixOperation.matsplit(dyi, 2);
            % initialize dx
            dx = cell(nlayerIn, nbatch);
            for ib = 1 : nbatch
                for i = 1 : nlayerIn
                    temp = 0;
                    for j = 1 : nlayerOut
                        temp =  temp + conv2(dyr{i, j, ib}, bfr{i, j}, 'same') ...
                            - conv2(dyi{i, j, ib}, bfi{i, j}, 'same');
%                         temp =  temp + conv2(dyr(:, :, i, j, ib), bfr(:, :, i, j), 'same') ...
%                             - conv2(dyi(:, :, i, j, ib), bfi(:, :, i, j), 'same');
                    end
                    dx{i, ib} = temp;
                end
            end
            dx = MatrixOperation.cellcombine(dx, 3);
        end
        
        function [dalpha, dtheta] = basegrad(dyr, dyi, x, alpha, theta)
            nbatch    = size(dyr, 5);
            nlayerIn  = size(alpha, 3);
            nlayerOut = size(alpha, 4);
            % get flipped input data
            xf = MatrixOperation.matsplit(flip(flip(x, 1), 2), 2);
%             xf = flip(flip(x, 1), 2);
            % add zero-padding to gradients
            padpre  = ceil(([size(alpha,1), size(alpha,2)] - 1) / 2);
            dyr     = padarray(dyr, padpre, 0, 'pre');
            dyi     = padarray(dyi, padpre, 0, 'pre');
            padpost = floor(([size(alpha,1), size(alpha,2)] - 1) / 2);
            dyr     = padarray(dyr, padpost, 0, 'post');
            dyi     = padarray(dyi, padpost, 0, 'post');
            % split gradients into cells
            dyr = MatrixOperation.matsplit(dyr, 2);
            dyi = MatrixOperation.matsplit(dyi, 2);
            % initialize temporary value
            tr = cell(nlayerIn, nlayerOut);
            ti = cell(nlayerIn, nlayerOut);
            for i = 1 : nlayerIn
                for j = 1 : nlayerOut
                    tr{i, j} = 0;
                    ti{i, j} = 0;
                    for ib = 1 : nbatch
                        tr{i, j} = tr{i, j} + conv2(dyr{i, j, ib}, xf{i, ib}, 'valid');
                        ti{i, j} = ti{i, j} + conv2(dyi{i, j, ib}, xf{i, ib}, 'valid');
%                         tr{i, j} = tr{i, j} + conv2(dyr(:, :, i, j, ib), xf(:, :, i, ib), 'valid');
%                         ti{i, j} = ti{i, j} + conv2(dyi(:, :, i, j, ib), xf(:, :, i, ib), 'valid');
                    end
                end
            end
            tr = MatrixOperation.cellcombine(tr, 3);
            ti = MatrixOperation.cellcombine(ti, 3);
            % calculate gradients of bases
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
            obj.I = {UnitAP(obj, 3, '-recdata'), UnitAP(obj, 4, '-recdata')};
            obj.O = {UnitAP(obj, 3)};
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