classdef ConvTransform < MappingUnit
    methods
        function y = process(obj, x)
            dataSize = size(x);
            if numel(dataSize) < 3
                dataSize = [dataSize, ones(1, 3 - numel(dataSize))];
            end   
            y = zeros([obj.sizeIn2Out(dataSize(1:3)), size(x, 4)], 'like', x);
            % calculation
            for k = 1 : size(x, 4)
            for i = 1 : obj.nfilter
                for j = 1 : obj.nchannel
                    y(:, :, i, k) = y(:, :, i, k) ...
                        + conv2(x(:, :, j, k), obj.weight(:, :, j, i), obj.convShape);
                end
                y(:, :, i, k) = y(:, :, i, k) + obj.bias(i);
            end
            end
        end
        
        function d = errprop(obj, d, ~)
            obj.B.addgrad(MathLib.margin(d, 3));
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
                        for k = 1 : size(d, 4)
                            dW(:, :, j, i) = dW(:, :, j, i) + ...
                                conv2(FI(:, :, j. k), d(:, :, i, k), 'valid');
                            dI(:, :, j, k) = dI(:, :, j, k) + ...
                                conv2(FW(:, :, j, i), d(:, :, i, k), 'full');
                        end
                    end
                end
                
              case 'same'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        for k = 1 : size(d, 4)
                            % derivative of filters
                            res = conv2(d(:, :, i, k), FI(:, :, j, k), 'full');
                            tleft  = [irow, icol] - fcenter + 1; % top-left coordinate
                            bright = tleft + obj.filterSize - 1; % bottom-right coordinate
                            dW(:, :, j, i) = dW(:, :, j, i) + ...
                                res(tleft(1) : bright(1), tleft(2) : bright(2));
                            % derivative of input
                            if all(mod(obj.filterSize, 2)) % size of filter is odd in both direction
                                dI(:, :, j, k) = dI(:, :, j, k) ...
                                    + conv2(d(:, :, i, k), FW(:, :, j, i), 'same');
                            else
                                res = conv2(d(:, :, i,  k), FW(:, :, j, i), 'full');
                                tleft  = fcenter - 1;              % top-left coordinate
                                bright = tleft + [irow, icol] - 1; % bottom-right coordinate
                                dI(:, :, j, k) = dI(:, :, j, k) ...
                                    + res(tleft(1) : bright(1), tleft(2) : bright(2));
                            end
                        end
                    end
                end
                
              case 'full'
                for i = 1 : obj.nfilter
                    for j = 1 : obj.nchannel
                        for k = 1 : size(d, 4)
                            dW(:, :, j, i) = dW(:, :, j, i) + ...
                                conv2(d(:, :, i, k), FI(:, :, j, k), 'valid');
                            dI(:, :, j, k) = dI(:, :, j, k) + ...
                                conv2(d(:, :, i, k), FW(:, :, j, i), 'valid');
                        end
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
            obj.W = HyperParam((rand([filterSize, nchannel, nfilter]) - 0.5) * ...
                (2 / sqrt(prod([filterSize, nchannel]))));
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
        nchannel, nfilter, filterSize
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
        
        function value = get.filterSize(obj)
            value = [size(obj.W, 1) size(obj.W, 2)];
        end
    end
    
    methods (Static)
        function debug()
            sizein = [32, 32, 3];
            filtersize = [5, 5];
            nfilter = 5;
            batchsize = 16;
            refunit = ConvTransform(filtersize, nfilter, sizein(3));
            refunit.bias = randn(size(refunit.bias));
            model = ConvTransform(filtersize, nfilter, sizein(3));
            model.likelihood = Likelihood('mse');
            % create validate set
            data = randn([sizein, 1e2]);
            validset = DataPackage(data, 'label', refunit.transform(data));
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : 3e1
                data  = randn([sizein, batchsize]);
                label = refunit.transform(data);
                dpkg  = DataPackage(data, 'label', label);
                model.learn(dpkg);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    model.likelihood.evaluate(model.forward(validset)));
            end
            % show result
            werr = refunit.weight - model.weight;
            berr = refunit.bias - model.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
end
