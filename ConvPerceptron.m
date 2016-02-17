% ConvPerceptron is an abstraction of local connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 12, 2016
classdef ConvPerceptron < Perceptron
    % ================= OVERRIDE API =================
    methods
        function output = feedforward(obj, input)
            output = obj.op(input);
            output = obj.act.op(output);            
            obj.I  = input;
            obj.O  = output;
        end
        
        function delta = backpropagate(obj, delta, stepSize)
            % back-propagate through activation function
            delta = delta .* obj.dfun(obj.O);
            % back-propagate through convolutional layer
            [delta, dW, dB] = obj.derv(delta);
            % update filter and bias
            obj.W = obj.W - stepSize * dW;
            obj.B = obj.B - stepSize * dB;
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
    end
    
    % ================= DATA & PARAM =================
    properties (Constant)
        convArea = 'valid'; % convolution operation type : {'full', 'same', 'valid'}
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
            value = size(obj.W{1}, 3);
            if obj.debug
                for i = 2 : numel(obj.W)
                    assert(size(obj.W{i}, 3) == value);
                end
            end
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
        function obj = ConvPerceptron(nfilter, filterSize, nchannel, activateType)
            % set default values
            if ~exist('nchannel', 'var'),     nchannel     = 3;         end
            if ~exist('activateType', 'var'), activateType = 'sigmoid'; end
            % formalize FILTERSIZE
            switch numel(filterSize)
              case {1}
                filterSize = [filterSize, filterSize];
              case {2}
                filterSize = filterSize(:)';
              otherwise
                error('Input arg[2] (filterSize) required to be 1 or 2 number array');
            end
            % initialization
            obj.W = randn([filterSize, nchannel, nfilter]);
            obj.B = zeros(nfilter, 1);
            % set activate function
            obj.activateType = activateType;
        end
    end
end
