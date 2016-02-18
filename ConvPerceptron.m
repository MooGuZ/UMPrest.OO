% ConvPerceptron is an abstraction of local connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 12, 2016

% TO-DO
% 1. finish dependent function of 'poolingType' and 'normalizeType'

classdef ConvPerceptron < Perceptron
    % ================= OVERRIDE API =================
    methods
        function output = feedforward(obj, input)
            input  = obj.norm_proc(input);  % normalization stage
            output = obj.op(input);         % convolution stage
            output = obj.act.op(output);    % activate stage
            output = obj.pool_proc(output); % pool stage
            
            obj.I  = input;                 % record input state
            obj.O  = output;                % record output state
        end
        
        function delta = backpropagate(obj, delta, optimp)
            delta = obj.pool_invp(delta);         % pool stage
            delta = delta .* obj.act.derv(obj.O); % activate stage
            [delta, dW, dB] = obj.derv(delta);    % convolution stage
            delta = obj.norm_invp(delta);         % normalization stage

            obj.W = obj.W - optimp * dW;          % update filter bank
            obj.B = obj.B - optimp * dB;          % update bias vector
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
        
        % normalization process and its inverse
        function v = norm_proc(obj, x)
            [v, obj.P.norm] = obj.norm.op(x);
        end
        function delta = norm_invp(obj, delta)
            delta = obj.norm.derv(delta, obj.P.norm);
        end
        
        % pool process and its inverse
        function v = pool_proc(obj, x)
            [v, obj.P.pool] = obj.pool.op(x);
        end
        function delta = pool_invp(obj, delta)
            delta = obj.pool.derv(delta, obj.P.pool);
        end
    end
    
    % ================= DATA & PARAM =================
    properties (Access = private)
        pool = struct('type', 'off', 'op', nan, 'derv', nan); % pooling
        norm = struct('type', 'off', 'op', nan, 'derv', nan); % normalization
    end
    properties (Constant)
        convArea = 'valid'; % convolution operation type : {'full', 'same', 'valid'}
    end
    
    % ================= FUNCTIONAL PARAM =================
    properties (Dependent)
        nfilter, nchannel
        filterSize, filterHeight, filterWidth
        poolingType, normalizeType
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
        function obj = ConvPerceptron(nfilter, filterSize, nchannel, ...
                                      activateType, poolingType, normalizeType)
            % set default values
            if ~exist('nchannel', 'var'),     nchannel     = 3;         end
            if ~exist('activateType', 'var'), activateType = 'sigmoid'; end
            
            % formalize FILTERSIZE
            if iscell(filterSize), filterSize = filterSize{1}; end
            assert(numel(filterSize) < 3 && ~isempty(filterSize));
            if numel(filterSize) == 1, filterSize = [filterSize, filterSize]; end
            
            obj.W = randn([filterSize, nchannel, nfilter]); % initialize filter bank
            obj.B = zeros(nfilter, 1);                      % initialize bias vector
            
            obj.activateType  = activateType;  % setup activate function
            obj.poolingType   = poolingType;   % setup pooling stage
            obj.normalizeType = normalizeType; % setup normalize stage
        end
    end
end
