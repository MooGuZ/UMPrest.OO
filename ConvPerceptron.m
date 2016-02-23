classdef ConvPerceptron < Perceptron
% ConvPerceptron is an abstraction of local connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 12, 2016

% TO-DO
% 1. finish dependent function of 'poolingType' and 'normalizeType'
    
    % ================= OVERRIDE PERCEPTRON API =================
    methods
        function output = proc(obj, input)
            input  = obj.norm.op(input);
            output = obj.op(input);
            output = obj.act.op(output);
            output = obj.pool.op(output);
            
            obj.I  = input;
            obj.O  = output;
        end
        
        function delta = bprop(obj, delta, optimizer)
            delta = obj.pool.bprop(delta);
            delta = delta .* obj.act.derv(obj.O);
            [delta, dW, dB] = obj.derv(delta);
            delta = obj.norm.bprop(delta);

            [dW, obj.wspace.w] = optimizer.proc(dW, obj.wspace.w);
            [dB, obj.wspace.b] = optimizer.proc(dB, obj.wspace.b);
            
            obj.W = obj.W - dW;
            obj.B = obj.B - dB;
        end
        
        function n = dimin(obj)
            if isempty(obj.inputSize)
                n = [0, 0, obj.nchannel];
            else
                n = [obj.inputSize, obj.nchannel];
            end
        end
        
        function n = dimout(obj, dimin)
            if exist('dimin', 'var') || ~isempty(obj.inputSize)
                switch obj.convArea
                  case 'valid'
                    n = [dimin(1:2) - obj.filterSize + 1, obj.nfilter];
                    
                  case 'same'
                    n = [dimin(1:2), obj.nfilter];
                    
                  case 'full'
                    n = [dimin(1:2) + obj.filterSize - 1, obj.nfilter];
                end
            else
                n = [0, 0, obj.nfilter];
            end
        end                    
    end
    
    % ================= ASSISTANT METHOD =================
    methods
        % main operation of convolutional perceptron
        function v = op(obj, x)
            [r, c, ~] = size(x);
            % initialization
            switch obj.convArea
              case 'valid'
                v = zeros([[r, c] - obj.filterSize + 1, obj.nfilter], 'like', x);
              
              case 'same'
                v = zeros([r, c, obj.nfilter], 'like', x);
                
              case 'full'
                v = zeros([[r, c] + obj.filterSize - 1, obj.nfilter], 'like', x);
            end
            % calculation
            for i = 1 : obj.nfilter
                for j = 1 : obj.nchannel
                    v(:, :, i) = v(:, :, i) ...
                        + conv2(x(:, :, j), obj.W(:, :, j, i), obj.convArea);
                end
                v(:, :, i) = v(:, :, i) + obj.B(i);
            end
        end
        
        % calculate derivatives given delta in output layer
        function [d, dW, dB] = derv(obj, delta)
            dB =  reshape(sum(sum(delta)), size(obj.B));
            % initialization
            d  = zeros(size(obj.I), 'like', obj.I);
            dW = zeros(size(obj.W), 'like', obj.W);
            % coordinate information
            [irow, icol, ~] = size(obj.I);
            fcenter = ceil((obj.filterSize + 1) / 2);
            % horizontal and vertical flip version of related data
            FI = matflip(obj.I);
            FW = matflip(obj.W);
            % mimic corelation with convolution specified in different convArea
            switch obj.convArea
              case 'valid'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        dW(:, :, j, i) = conv2(FI(:, :, j), delta(:, :, i), 'valid');
                        d(:, :, j) = d(:, :, j) + conv2(FW(:, :, j, i), delta(:, :, i), 'full');
                    end
                end
                
              case 'same'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        % derivative of filters
                        res = conv2(delta(:, :, i), FI(:, :, j), 'full');
                        tleft  = [irow, icol] - fcenter + 1; % top-left coordinate
                        bright = tleft + obj.filterSize - 1; % bottom-right coordinate
                        dW(:, :, j, i) = res(tleft(1) : bright(1), tleft(2) : bright(2));
                        % derivative of input
                        if all(mod(obj.filterSize, 2)) % size of filter is odd in both direction
                            d(:, :, j) = d(:, :, j) + conv2(delta(:, :, i), FW(:, :, j, i), 'same');
                        else
                            res = conv2(delta(:, :, i), FW(:, :, j, i), 'full');
                            tleft  = fcenter - 1;              % top-left coordinate
                            bright = tleft + [irow, icol] - 1; % bottom-right coordinate
                            d(:, :, j) = d(:, :, j) + res(tleft(1) : bright(1), tleft(2) : bright(2));
                        end
                    end
                end
                
              case 'full'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        dW(:, :, j, i) = conv2(delta(:, :, i), FI(:, :, j), 'valid');
                        d(:, :, j) = d(:, :, j) + conv2(delta(:, :, i), FW(:, :, j, i), 'valid');
                    end
                end
            end
        end
        
        function setInputSize(obj, sz)
            assert(numel(sz) == 2 || sz(3) == obj.nchannel)
            obj.inputSize = reshape(sz(1:2), [1, 2]);
        end
    end
    
    % ================= DEBUG =================
    methods
        function [delta, dW, dB, gI, gW, gB] = checkGrad(obj, input, precision)
            output = obj.proc(input);
            delta  = obj.act.derv(output);
            [delta, dW, dB] = obj.derv(delta);
            
            gW = zeros(size(dW));
            gB = zeros(size(dB));
            gI = zeros(size(delta));
            
            for i = 1 : numel(gW)
                obj.W(i) = obj.W(i) + precision;
                  output = obj.proc(input);
                   gW(i) = sum(output(:));
                obj.W(i) = obj.W(i) - 2*precision;
                  output = obj.proc(input);
                   gW(i) = gW(i) - sum(output(:));
                obj.W(i) = obj.W(i) + precision;
                   gW(i) = gW(i) / (2 * precision);
            end
            
            for i = 1 : numel(gB)
                obj.B(i) = obj.B(i) + precision;
                  output = obj.proc(input);
                   gB(i) = sum(output(:));
                obj.B(i) = obj.B(i) - 2*precision;
                  output = obj.proc(input);
                   gB(i) = gB(i) - sum(output(:));
                obj.B(i) = obj.B(i) + precision;
                   gB(i) = gB(i) / (2 * precision);
            end
            
            tmp = zeros(size(input));
            for i = 1 : numel(gI)
                tmp(i) = precision;
                output = obj.proc(input + tmp) - obj.proc(input - tmp);
                 gI(i) = sum(output(:)) / (2 * precision);
                tmp(i) = 0;
            end
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        inputSize
        
        pool = struct('type', 'off', 'op', @nullfunc, 'size', nan, 'bprop', @nullfunc);
        norm = struct('type', 'off', 'op', @nullfunc, 'bprop', @nullfunc);
    end
    properties (Constant)
        convArea = 'same'; % convolution operation type : {'full', 'same', 'valid'}
    end
    
    % ================= FUNCTIONAL PARAM =================
    properties (Dependent)
        nfilter, nchannel
        filterSize, filterHeight, filterWidth
        poolingType, poolSize, normalizeType
    end
    methods
        function value = get.nfilter(obj)
            value = size(obj.W, 4);
        end
        
        function value = get.nchannel(obj)
            value = size(obj.W, 3);
        end
        
        function value = get.filterHeight(obj)
            value = size(obj.W, 1);
        end
        
        function value = get.filterWidth(obj)
            value = size(obj.W, 2);
        end
        
        function value = get.filterSize(obj)
            value = [obj.filterHeight, obj.filterWidth];
        end
        
        function value = get.poolingType(obj)
            value = obj.pool.type;
        end
        function set.poolingType(obj, ptype)
            switch lower(ptype)
                case 'max'
                    obj.pool.type  = 'max';
                    obj.pool.op    = @obj.maxPool;
                    obj.pool.bprop = @obj.maxPool_bprop;
                case 'off'
                    obj.pool.type  = 'off';
                    obj.pool.op    = @nullfunc;
                    obj.pool.bprop = @nullfunc;
            end
        end
        
        function value = get.poolSize(obj)
            value = obj.pool.size;
        end
        function set.poolSize(obj, sz)
            assert(isscalar(sz) && sz > 0 ...
                && round(sz) == sz);
            obj.pool.size = sz;
        end
        
        function value = get.normalizeType(obj)
            value = obj.norm.type;
        end
        function set.normalizeType(obj, ntype)
            switch lower(ntype)
                case 'batch'
                    obj.norm.type  = 'batch';
                    obj.norm.op    = @obj.batchNorm;
                    obj.norm.bprop = @obj.batchNorm_bprop;
                case 'off'
                    obj.norm.type  = 'off';
                    obj.norm.op    = @nullfunc;
                    obj.norm.bprop = @nullfunc;
            end
        end
        
    end
    
    methods
%         function vi = findmax(~, B)
%             [v, r] = max(B.data, [], 1);
%             [v, c] = max(v);
%             rc = [r(c), c] + B.location - 1;
%             vi = [v, rc];
%         end
%             
%         function out = maxPool(obj, in)
%             % create map from index to coordinates to accelerate process
%             [r, c] = ind2sub(obj.pool.size, (1 : obj.pool.size^2)');
%             obj.wspace.pool.i2rc = [r, c] - 1; % set first element to [0,0]
%             max pool by BLOCKPROC
%             mat = blockproc(in(:, :, 1), obj.pool.size * [1, 1], @obj.findmax, 'UseParallel', true);
%             if size(in, 3) == 1
%                 out = mat(:, 1 : 3 : end);
%                 obj.wspace.pool.crdr = mat(:, 2 : 3 : end);
%                 obj.wspace.pool.crdc = mat(:, 3 : 3 : end);
%             else
%                 out = zeros(size(mat) ./ [1, 3]);
%                 crdr = out;
%                 crdc = out;
%                 
%                 out(:, :, 1)  = mat(:, 1 : 3 : end);
%                 crdr(:, :, 1) = mat(:, 2 : 3 : end);
%                 crdc(:, :, 1) = mat(:, 3 : 3 : end);
%                 
%                 for i = 2 : size(in, 3)
%                     mat = blockproc(in(:, :, i), obj.pool.size * [1, 1], @obj.findmax, 'UseParallel', true);
%                     out(:, :, i)  = mat(:, 1 : 3 : end);
%                     crdr(:, :, i) = mat(:, 2 : 3 : end);
%                     crdc(:, :, i) = mat(:, 3 : 3 : end);
%                 end
%                 
%                 obj.wspace.pool.crdr = crdr;
%                 obj.wspace.pool.crdc = crdc;
%             end
%             obj.wspace.pool.size = size(in);
%         end
%         
%         function out = maxPool_bprop(obj, in)
%             out = zeros(obj.wspace.pool.size);
%             for f = 1 : size(out, 3)
%                 v = in(:, :, f);
%                 i = obj.wspace.pool.crdr(:, :, f);
%                 j = obj.wspace.pool.crdc(:, :, f);
%                 out(:, :, f) = sparse(i(:), j(:), v(:), size(out,1), size(out, 2));
%             end
%         end
            
        function out = maxPool(obj, in)
            [r, c, f] = size(in); sz = obj.pool.size;
            out = zeros(floor(r / sz), floor(c / sz), f);
            [r, c] = ind2sub(sz, (1 : sz^2)');
            ind2rc = [r, c];
            obj.wspace.pool.idx = zeros(size(in));
            for i = 1 : size(out, 1)
                for j = 1 : size(out, 2)
                    for k = 1 : size(out, 3)
                        window = in(sz*(i-1) + 1 : sz*i, sz*(j-1) + 1 : sz*j, k);
                        out(i, j, k) = max(window(:));
                        rc = ind2rc(window(:) == out(i, j, k), :);
                        obj.wspace.pool.idx(sz*(i-1) + rc(1), sz*(j-1) + rc(2), k) = 1;
                    end
                end
            end
        end
        function delta = maxPool_bprop(obj, delta)
            [r, c, f] = size(obj.wspace.pool.idx);
            sz = obj.pool.size;
            if any(mod([r, c], obj.pool.size))
                [p, q, ~] = size(delta);
                v  = zeros(r, c, f);
                v(1 : sz*p, 1 : sz*q, :) = kron(delta, ones(sz));
            else
                v = kron(delta, ones(obj.pool.size));
            end
            delta = v .* obj.wspace.pool.idx;
        end
        
        function out = batchNorm(obj, in)
            obj.wspace.norm.mean = mean(in(:));
            obj.wspace.norm.var  = var(in(:));
            out = (in - obj.wspace.norm.mean) / sqrt(obj.wspace.norm.var);
        end
        function delta = batchNorm_bprop(obj, delta)
            delta = delta * obj.wspace.norm.var;
        end
    end
    
    % ================= CONSTRUCTOR =================
    methods
        function obj = ConvPerceptron(nfilter, filterSize, nchannel, ...
                                      activateType, poolingType, poolSize, ...
                                      normalizeType)
            % set default values
            if ~exist('nchannel', 'var'),      nchannel      = 3;         end
            if ~exist('activateType', 'var'),  activateType  = 'sigmoid'; end
            if ~exist('poolingType', 'var'),   poolingType   = 'off';     end
            if ~exist('poolingSize', 'var'),   poolSize      = 3;         end
            if ~exist('normalizeType', 'var'), normalizeType = 'off';     end
            
            % formalize FILTERSIZE
            if iscell(filterSize), filterSize = filterSize{1}; end
            assert(numel(filterSize) < 3 && ~isempty(filterSize));
            if numel(filterSize) == 1, filterSize = [filterSize, filterSize]; end
            
            obj.W = randn([filterSize, nchannel, nfilter]); % initialize filter bank
            obj.B = zeros(nfilter, 1);                      % initialize bias vector
            
            obj.activateType  = activateType;  % setup activate function
            obj.poolingType   = poolingType;   % setup pooling stage
            obj.poolSize      = poolSize;
            obj.normalizeType = normalizeType; % setup normalize stage
        end
    end
end
