% ConvPerceptron is an abstraction of local connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 12, 2016
classdef ConvPerceptron < handle
    % ================= API =================
    methods
        function output = feedforward(obj, input)
            output = zeros(obj.calcOutputSize(input), 'like', input);
            if strcmp(obj.convType, 'valid')
                for i = 1 : obj.nfilter
                    output(:, :, i) = convn(input, obj.F{i}, 'valid') + obj.B(i);
                end
            else
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        output(:, :, i) = output(:, :, i) ...
                            + conv2(input(:, :, j), obj.F{i}(:, :, j), obj.convType);
                    end
                    output(:, :, i) = output(:, :, i) + obj.B(i);
                end
            end
            output = obj.afun(output);
            % record current state
            obj.I = input; obj.O = output;
        end
        
        function delta = backpropagate(obj, delta, stepSize)
            % derivatives counting in activation function
            dO = delta .* obj.dfun(obj.O);
            dB = sum(sum(dO));
            % initialize derivatives
            delta = zeros(size(obj.I));
            dF    = cell(obj.nfilter, 1);
            for i = 1 : numel(dF)
                dF{i} = zeros(obj.filterHeight, obj.filterWidth, obj.nchannel);
            end
            % useful informations
            [ih, iw, ~] = size(obj.I); % size of input
            % coordinate of filter center element
            fch = ceil((obj.filterHeight + 1) / 2); 
            fcw = ceil((obj.filterWidth + 1) / 2);
            % calculate derivatives
            switch obj.convType
              case {'same'}
                Iflip = matflip(obj.I);
                for i = 1 : obj.nfilter
                    Fflip = matflip(obj.F{i});
                    for j = 1 : obj.nchannel
                        tmp = conv2(dO(:, :, i), Iflip(:, :, j), 'full');
                        % coordinates
                        Xs = ih - fch + 1;
                        Xe = Xs + obj.filterHeight - 1;
                        Ys = iw - fcw + 1;
                        Ye = Ys + obj.filterWidth - 1;
                        % derivative of filter
                        dF{i}(:, :, j) = tmp(Xs : Xe, Ys : Ye);
                        % derivative of input
                        if all(mod(obj.filterHeight, obj.filterWidth))
                            delta(:, :, j) = delta(:, :, j) + ...
                                conv2(dO(:, :, i), Fflip(:, :, j), 'same');
                        else
                            tmp = conv2(dO(:, :, i), Fflip(:, :, j), 'full');
                            Xs = fch - 1;
                            Xe = Xs + ih - 1;
                            Ys = fcw - 1;
                            Ye = Ys + iw - 1;
                            delta(:, :, j) = delta(:, :, j) + tmp(Xs : Xe, Ys : Ye);
                        end
                    end
                end
                
              case {'valid'}
                for i = 1 : obj.nfilter
                    dF{i} = convn(matflip(obj.I), dO(:, :, i), 'valid');
                    delta = delta + convn(matflip(obj.F{i}), dO(:, :, i), 'full');
                end
                
              case {'full'}
                Iflip = matflip(obj.I);
                for i = 1 : obj.nfilter
                    Fflip = matflip(obj.F{i});
                    for j = 1 : obj.nchannel
                        obj.F{i} = conv2(dO(:, :, i), Iflip(:, :, j), 'valid');
                        delta(:, :, j) = delta(:, :, j) ...
                            + conv2(dO(:, :, i), Fflip(:, :, j), 'valid');
                    end
                end
            end
            % update filter and bias
            obj.B = obj.B - stepSize * dB(:);
            for i = 1 : numel(obj.F)
                obj.F{i} = obj.F{i} - stepSize * dF{i};
            end
        end
    end
    
    % ================= ASSISTANT METHOD =================
    methods
        function sz = calcOutputSize(obj, input)
            [r, c, ~] = size(input);
            switch obj.convType
                case {'valid'}
                    sz = [r - obj.filterHeight + 1, c - obj.filterWidth + 1, ...
                        obj.nfilter];
                    
                case {'same'}
                    sz = [r, c, obj.nfilter];
                    
                case {'full'}
                    sz = [r + obj.filterHeight -1, c + obj.filterWidth - 1, ...
                        obj.nfilter];                    
            end
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        F % filter bank <cell>
        B % bias vector
        I % input state
        O % output state
        atype % activation type
        afun  % activation function
        dfun  % derivative of activation function
    end
    properties (Constant)
        convType = 'valid'; % convolution operation type : {'full', 'same', 'valid'}
    end
    % ----------------- DEBUG -----------------
    properties (Access = private, Constant)
        debug = false;
    end
    
    % ================= FUNCTIONAL PARAM =================
    properties (Dependent)
        nfilter
        filterHeight
        filterWidth
        nchannel
        activateType
    end
    methods
        function value = get.nfilter(obj)
            value = numel(obj.F);
        end
        
        function value = get.filterHeight(obj)
            value = size(obj.F{1}, 1);
            if obj.debug
                for i = 2 : numel(obj.F)
                    assert(size(obj.F{i}, 1) == value);
                end
            end
        end
        
        function value = get.filterWidth(obj)
            value = size(obj.F{1}, 2);
            if obj.debug
                for i = 2 : numel(obj.F)
                    assert(size(obj.F{i}, 2) == value);
                end
            end
        end
        
        function value = get.nchannel(obj)
            value = size(obj.F{1}, 3);
            if obj.debug
                for i = 2 : numel(obj.F)
                    assert(size(obj.F{i}, 3) == value);
                end
            end
        end
        
        function value = get.activateType(obj)
            value = obj.atype;
        end
        function set.activateType(obj, value)
            switch lower(value)
                case {'sigmoid', 'logistic'}
                    obj.afun = @(x) 1 ./ (1 + exp(-x));
                    obj.dfun = @(x) x .* (1 - x);
                    obj.atype = value;
                otherwise
                    warning('Unrecognized activation type');
            end
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
                error(['Input arg[2] (filterSize) required to be 1 or 2 number ' ...
                       'array']);
            end
            % initialize filters
            obj.F = cell(nfilter, 1);
            for i = 1 : nfilter
                obj.F{i} = randn([filterSize, nchannel]);
            end
            % initialize bias
            obj.B = zeros(nfilter, 1);
            % set activate function
            obj.activateType = activateType;
        end
    end
end
