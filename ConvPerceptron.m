% ConvPerceptron is an abstraction of local connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 12, 2016
classdef ConvPerceptron < handle & UtilityLib
    % ================= API =================
    methods
        function output = feedforward(obj, input)
            % convolution
            output = zeros(obj.calcOutputSize(input), class(input));
            for i = 1 : numel(obj.F)
                output(:, :, i) = obj.afun(convn(input, obj.F{i}, obj.convType) + obj.B(i));
            end
            obj.I = input; obj.O = output;
        end
        
        function delta = backpropagate(obj, delta, stepSize)
            tmp = delta .* obj.dfun(obj.O);
            
            % SITUATION : convType = 'same'
            % fhmid = ceil((obj.filterHeight + 1) / 2);
            % fwmid = ceil((obj.filterWidth + 1) / 2);
            % for i = 1 : obj.nfilter
            %     for h = 1 : obj.filterHeight
            %         for w = 1 : obj.filterWidth
            %             switch obj.convType
            %               case {'same'}
            %                 if h <= fhmid
            %                     ihrange = [1 - h + fhmid, size(obj.I, 1)];
            %                     ohrange = [1, size(obj.O, 1) + h - fhmid];
            %                 else
            %                     ihrange = [1, size(obj.I, 1) - h + fhmid];
            %                     ohrange = [1 + h - fhmid, size(obj.O, 1)];
            %                 end
            %                 if w <= fwmid
            %                     iwrange = [1 - w + fwmid, size(obj.I, 2)];
            %                     owrange = [1, size(obj.O, 2) + w - fwmid];
            %                 else
            %                     iwrange = [1, size(obj.I, 2) - w + fwmid];
            %                     owrange = [1 + w - fwmid, size(obj.O, 2)];
            %                 end
            %             end
            %             obj.F{i}(h, w, :) = sum(sum( ...
            %                 obj.I(ihrange(1):ihrange(2),iwrange(1):iwrange(2), :) .* ...
            %                 repmat(tmp(ohrange(1):ohrange(2), owrange(1):owrange(2), ...
            %                            i), [1, 1, obj.nchannel])));
            %         end
            %     end
            % end                 
            
            delta = zeros(size(obj.I));
            
            % SITUATION : convType = 'valid'
            for i = 1 : obj.nfilter
                obj.F{i} = convn(obj.I, repmat(obj.matflip(tmp(:, :, i)), [1, 1, ...
                                    obj.nchannel]), 'valid');
                for j = 1 : obj.nchannel
                    delta(:, :, j) = delta(:, :, j) + ...
                        conv2(tmp(:, :, i), obj.matflip(obj.F{i}(:, :, j)), 'full');
                end
            end
            
            % SITUATION : convType = 'full'
            for i = 1 : obj.nfilter
                obj.F{i} = convn(repmat(tmp(:, :, i), [1, 1, obj.nchannel]), ...
                                 obj.matflip(obj.I), 'valid');
                delta = delta + convn(repmat(tmp(:, :, i), [1, 1, obj.nchannel]), ...
                                      obj.matflip(obj.F{i}), 'valid');
            end
            
            dB  = sum(sum(tmp));
    end
    
    % ================= ASSISTANT METHOD =================
    methods
        function sz = calcOutputSize(obj, input)
            [r, c, ch] = size(input);
            switch obj.convType
              case {'valid'}
                sz = [r - obj.filterHeight + 1, c - obj.filterWidth + 1, ...
                      obj.nfilter];
                
              case {'same'}
                sz = [r, c, obj.nfilter];
                
              case {'full'}
                sz = [r + obj.filterHeight -1, c + obj.filterWidth - 1, ...
                      obj.nfilter];
                
              otherwise
                error('Convolution Type is invalid : %s', obj.convType);
            
            end
        end
        
        function fmat = matflip(~, mat)
            [r, c, ~] = size(mat);
            fmat = mat(r:-1:1, c:-1:1, :);
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
        convType = 'same' % convolution operation type : {'full', 'same', 'valid'}
    end
    % ----------------- DEBUG -----------------
    properties (Access = private)
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
end
