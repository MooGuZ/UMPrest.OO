classdef ConvPerceptron < SequentialModel
%     methods
%         function y = process(obj, x)
%             y = obj.act.transform(obj.pool.transform(obj.conv.transform(x)));
%         end
%         
%         function d = errprop(obj, d, ~)
%             d = obj.conv.errprop(obj.pool.errprop(obj.act.errprop(d)));
%         end
%         
%         function update(obj, stepsize)
%             if exist('stepsize', 'var')
%                 obj.conv.update(stepsize);
%             else
%                 obj.conv.update();
%             end
%         end
%         
%         function unit = inverseUnit(obj)
%             unit = obj; % TEMPORAL
%         end
%     end
    
%     properties (Dependent)
%         inputSizeRequirement
%     end
%     properties
%         outputSizePattern
%     end
%     methods
%         function value = get.inputSizeRequirement(obj)
%             value = obj.conv.inputSizeDescription;
%         end
%         
%         function set.outputSizePattern(obj, value)
%             assert(isstruct(value) && all(isfield(value, {'in', 'out'})));
%             assert(SizeDescription.islegal(value.in) && ...
%                    SizeDescription.isconcrete(value.out));
%             obj.outputSizePattern = value;
%         end
%         
%         function descriptionOut = sizeIn2Out(obj, descriptionIn)
%             descriptionOut = SizeDescription.applyPattern( ...
%                 descriptionIn, obj.outputSizePattern);
%         end
%     end
    
%     methods
%         function obj = ConvPerceptron(filterSize, nfilter, nchannel, varargin)
%             propmap = Config.parse(varargin{:});
%             
%             obj.conv = ConvTransform(filterSize, nfilter, nchannel);
%             obj.pool = MaxPool(Config.getValue(propmap, 'poolSize', 2));
%             obj.act  = Activation(Config.getValue(propmap, 'actType', 'ReLU'));
%             
%             Config.apply(obj, propmap);
%             
%             % initialize size description of sub-units
%             obj.pool.inputSizeDescription = obj.conv.outputSizeDescription;
%             obj.act.inputSizeDescription  = obj.pool.outputSizeDescription;
%             obj.outputSizePattern = SizeDescription.getPattern( ...
%                 obj.conv.inputSizeDescription, obj.act.outputSizeDescription);
%         end
%     end

    methods
        function obj = ConvPerceptron(filterSize, nfilter, nchannel, varargin)
            conf = Config.parse(varargin{:});
            
            obj.conv = ConvTransform(filterSize, nfilter, nchannel);
            obj.appendUnit(obj.conv);
            if Config.getValue(conf, 'pooling', true)
                obj.pool = MaxPool(Config.getValue(conf, 'poolSize', 2));
                obj.appendUnit(obj.pool);
            end
            if Config.getValue(conf, 'activation', true)
                obj.act = Activation(Config.getValue(conf, 'actType', 'ReLU'));
                obj.appendUnit(obj.act);
            end            
        end
    end
    
    properties
        conv, pool, act
    end
    
    methods (Static)
        function debug()
            sizein = [32, 32, 3];
            filtersize = [5, 5];
            nfilter = 5;
            batchsize = 16;
            % Default Setting : ReLU + MaxPool(2)
            refunit = ConvPerceptron(filtersize, nfilter, sizein(3), ...
                'actType', 'sigmoid');
            refunit.conv.bias = randn(size(refunit.conv.bias));
            model = ConvPerceptron(filtersize, nfilter, sizein(3), ...
                'actType', 'sigmoid');
            model.likelihood = Likelihood('logistic');
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
