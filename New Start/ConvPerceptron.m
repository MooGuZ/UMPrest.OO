classdef ConvPerceptron < MappingUnit
    methods
        function y = process(obj, x)
            y = obj.act.transform(obj.pool.transform(obj.conv.transform(x)));
        end
        
        function d = errprop(obj, d, ~)
            d = obj.conv.errprop(obj.pool.errprop(obj.act.errprop(d)));
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.conv.update(stepsize);
            else
                obj.conv.update();
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
            value = obj.conv.inputSizeDescription;
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = obj.act.sizeIn2Out( ...
                obj.pool.sizeIn2Out(obj.conv.sizeIn2Out(descriptionIn)));
        end
    end
    
    methods
        function obj = ConvPerceptron(filterSize, nfilter, nchannel, varargin)
            conf = Config.parse(varargin{:});
            
            obj.conv = ConvTransform(filterSize, nfilter, nchannel);
            if not(Config.popItem(conf, 'noPooling', false))
                obj.pool = MaxPool(Config.popItem(conf, 'poolSize', 2));
            end
            if not(Config.popItem(conf, 'noActivation', false))
                obj.act = Activation(Config.popItem(conf, 'actType', 'ReLU'));
            end
            
            Config.apply(obj, conf);
        end
    end
    
    properties (SetAccess = private)
        conv, pool = NullUnit(), act= NullUnit()
    end
    
    methods (Static)
        function debug()
            sizein = [32, 32, 3];
            filtersize = [5, 5];
            nfilter = 5;
            batchsize = 16;
            % Default Setting : ReLU + MaxPool(2)
            refunit = ConvPerceptron(filtersize, nfilter, sizein(3), ...
                'actType', 'relu', '-noactivation');
            refunit.conv.bias = randn(size(refunit.conv.bias));
            model = ConvPerceptron(filtersize, nfilter, sizein(3), ...
                'actType', 'relu', '-noactivation');
            model.likelihood = Likelihood('mse');
            % create validate set
            data = randn([sizein, 1e2]);
            validset = DataPackage(data, 'label', refunit.transform(data));
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : 1e2
                data  = randn([sizein, batchsize]);
                label = refunit.transform(data);
                dpkg  = DataPackage(data, 'label', label);
                model.learn(dpkg);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    model.likelihood.evaluate(model.forward(validset)));
            end
            % show result
            werr = refunit.conv.weight - model.conv.weight;
            berr = refunit.conv.bias - model.conv.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
end
