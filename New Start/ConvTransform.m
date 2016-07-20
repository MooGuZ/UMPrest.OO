classdef ConvTransform < MappingUnit
    methods
        function y = process(obj, x)
            dataSize = size(x);
            if numel(dataSize) < 3
                dataSize = [dataSize, ones(1, 3 - numel(dataSize))];
            end   
            y = zeros([obj.sizeIn2Out(dataSize(1:3)), size(x, 4)], 'like', x);
            % calculation
            for i = 1 : obj.nfilter
                for j = 1 : obj.nchannel
                    y(:, :, i) = y(:, :, i) ...
                        + conv2(x(:, :, j), obj.weight(:, :, j, i), obj.convShape);
                end
                y(:, :, i) = y(:, :, i) + obj.bias(i);
            end
        end
        
        function d = errprop(obj, d, ~)
            obj.B.addgrad(MathLib.margin(d, 1:2));
            % initialization
            dI = zeros(size(obj.I), 'like', obj.I);
            dW = zeros(size(obj.weight), 'like', obj.weight);
            % coordinate information
            [irow, icol, ~] = size(obj.I);
            fcenter = ceil((obj.filterSize + 1) / 2);
            % horizontal and vertical flip version of related data
            FI = matflip(obj.I);
            FW = matflip(obj.weight);
            % mimic corelation with convolution specified in different convShape
            switch obj.convShape
              case 'valid'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        dW(:, :, j, i) = conv2(FI(:, :, j), d(:, :, i), 'valid');
                        dI(:, :, j) = dI(:, :, j) + conv2(FW(:, :, j, i), d(:, :, i), 'full');
                    end
                end
                
              case 'same'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        % derivative of filters
                        res = conv2(d(:, :, i), FI(:, :, j), 'full');
                        tleft  = [irow, icol] - fcenter + 1; % top-left coordinate
                        bright = tleft + obj.filterSize - 1; % bottom-right coordinate
                        dW(:, :, j, i) = res(tleft(1) : bright(1), tleft(2) : bright(2));
                        % derivative of input
                        if all(mod(obj.filterSize, 2)) % size of filter is odd in both direction
                            dI(:, :, j) = dI(:, :, j) + conv2(d(:, :, i), FW(:, :, j, i), 'same');
                        else
                            res = conv2(d(:, :, i), FW(:, :, j, i), 'full');
                            tleft  = fcenter - 1;              % top-left coordinate
                            bright = tleft + [irow, icol] - 1; % bottom-right coordinate
                            dI(:, :, j) = dI(:, :, j) + res(tleft(1) : bright(1), tleft(2) : bright(2));
                        end
                    end
                end
                
              case 'full'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        dW(:, :, j, i) = conv2(d(:, :, i), FI(:, :, j), 'valid');
                        dI(:, :, j) = dI(:, :, j) + conv2(d(:, :, i), FW(:, :, j, i), 'valid');
                    end
                end
            end
            obj.W.addgrad(dW);
            d = dI;
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.W.update(stepsize);
                obj.B.update(stepsize);
            else
                obj.W.update();
                obj.B.update();
            end
        end
        
        function unit = inverseUnit(obj)
            unit = obj; % TEMPORAL
        end
    end
    
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = SizeDescription.format([nan, nan, obj.nchannel]);
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            switch obj.convShape
              case {'same'}
                descriptionOut = [descriptionIn(1 : 2), obj.nfilter];
              case {'valid'}
                descriptionOut = [ ...
                    descriptionIn(1) - size(obj.W, 1) + 1, ...
                    descriptionIn(2) - size(obj.W, 2) + 1, ...
                    obj.nfilter];
              case {'full'}
                descriptionOut = [ ...
                    descriptionIn(1) + size(obj.W, 1) - 1, ...
                    descriptionIn(2) + size(obj.W, 2) - 1, ...
                    obj.nfilter];
            end
        end
    end
    
    methods
        function obj = ConvTransform(filterSize, nfilter, nchannel)
            if numel(filterSize) == 1
                filterSize = filterSize * [1, 1];
            end
            obj.W = HyperParam(randn([filterSize, nchannel, nfilter]));
            obj.B = HyperParam(zeros(nfilter, 1));
        end
    end
    
    properties
        convShape = 'same';
    end
    
    properties (Access = private)
        W, B
    end
    
    properties (Dependent)
        weight, bias
        nchannel, nfilter
    end
    methods
        function value = get.weight(obj)
            value = obj.W.get();
        end
        function set.weight(obj, value)
            obj.W.set(value);
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
        
        function value = get.nchannel(obj)
            value = size(obj.W, 3);
        end
        
        function value = get.nfilter(obj)
            value = size(obj.W, 4);
        end
    end
end
