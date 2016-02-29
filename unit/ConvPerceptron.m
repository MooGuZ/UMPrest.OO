classdef ConvPerceptron < Unit & Optimizable & Activation & Pooling & Normalize & UtilityLib
% ConvPerceptron is an abstraction of local connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 12, 2016

% TO-DO
% 1. [x] finish dependent function of 'poolingType' and 'normalizeType'
    
    % ================= UNIT IMPLEMENTATION =================
    methods
        function output = proc(obj, input)
            input = datafmt(input, obj.dimin());
            
            data   = obj.conv(input);
            
            data   = obj.norm.proc(data);
            data   = obj.act.proc(data); 
            output = obj.pool.proc(data);
            
            obj.I  = input;
            obj.O  = output;
        end
        
        function delta = bprop(obj, delta)
            delta = datafmt(delta, obj.dimout());
            
            delta = obj.pool.bprop(delta);
            delta = obj.act.bprop(delta);
            delta = obj.norm.bprop(delta);
            
            [delta, dW, dB] = obj.convbp(delta);
            
            obj.addGradient(dW, @obj.updateWeight);
            obj.addGradient(dB, @obj.updateBias);
            
            obj.optimize();
        end
    end
    
    % ================= CONNECTABLE IMPLEMENTATION =================
    methods
        function dim = dimin(obj)
            dim = [obj.channelSize, obj.nchannel];
        end
        
        function dim = dimout(obj)
            dim = obj.poolDimout(obj.convDimout(obj.dimin()));
        end
    end
    
    % ================= ASSISTANT METHOD =================
    methods (Access = private)
        % assistant function to calculate dimension after convolution
        function dimout = convDimout(obj, dimin)
            switch obj.convArea
                case 'valid'
                    dimout = [dimin(1:2) - obj.filterSize + 1, obj.nfilter];
                    
                case 'same'
                    dimout = [dimin(1:2), obj.nfilter];
                    
                case 'full'
                    dimout = [dimin(1:2) + obj.filterSize - 1, obj.nfilter];
            end
        end
        
        % main operation of convolutional perceptron
        function v = conv(obj, x)
            v = zeros(obj.convin2out(size(x)), 'like', x);
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
        function [dI, dW, dB] = convbp(obj, delta)
            dB =  reshape(sum(sum(delta)), size(obj.B));
            % initialization
            dI = zeros(size(obj.I), 'like', obj.I);
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
                        dI(:, :, j) = dI(:, :, j) + conv2(FW(:, :, j, i), delta(:, :, i), 'full');
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
                            dI(:, :, j) = dI(:, :, j) + conv2(delta(:, :, i), FW(:, :, j, i), 'same');
                        else
                            res = conv2(delta(:, :, i), FW(:, :, j, i), 'full');
                            tleft  = fcenter - 1;              % top-left coordinate
                            bright = tleft + [irow, icol] - 1; % bottom-right coordinate
                            dI(:, :, j) = dI(:, :, j) + res(tleft(1) : bright(1), tleft(2) : bright(2));
                        end
                    end
                end
                
              case 'full'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        dW(:, :, j, i) = conv2(delta(:, :, i), FI(:, :, j), 'valid');
                        dI(:, :, j) = dI(:, :, j) + conv2(delta(:, :, i), FW(:, :, j, i), 'valid');
                    end
                end
            end
        end
        
        function updateBias(obj, delta)
            obj.B = obj.B - delta;
        end
        
        function updateWeight(obj, delta)
            obj.W = obj.W - delta;
        end
    end
    
    % ================= DEBUG =================
    methods
        function [dI, dW, dB, gI, gW, gB] = checkGrad(obj, input, precision)
            output = obj.proc(input);
            delta  = obj.pool.bprop(ones(size(output)));
            delta  = obj.act.bprop(delta);
            [delta, dW, dB] = obj.convbp(delta);
            dI = obj.norm.bprop(delta);
            
            gW = zeros(size(dW));
            gB = zeros(size(dB));
            gI = zeros(size(dI));
            
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
        W, B        % wights and bias
        channelSize % size of input on each Channel
    end
    properties %(Access = private)
        convArea = 'same'; % convolution operation type : {'full', 'same', 'valid'}
    end
    
    % ================= FUNCTIONAL PARAM =================
    properties (Dependent)
        nfilter, nchannel
        filterSize, filterHeight, filterWidth
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
    end

    % ================= CONSTRUCTOR =================
    methods
        function obj = ConvPerceptron(nfilter, filterSize, nchannel, channelSize, varargin)
            assert(any(numel(filterSize)  == (1 : 3)));
            assert(any(numel(channelSize) == (1 : 3)));
            
            if numel(filterSize) == 1
                filterSize = [filterSize, filterSize]; 
            end
            
            if numel(channelSize) == 1
                obj.channelSize = [channelSize, channelSize];
            else
                obj.channelSize = channleSize;
            end
            
            obj.setupByArg(varargin{:});            
            
            obj.W = randn([filterSize, nchannel, nfilter]);
            obj.B = zeros(nfilter, 1);
        end
    end
end
