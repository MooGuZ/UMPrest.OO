classdef Perceptron < MappingUnit
    methods
        function y = process(obj, x)
            y = obj.act.transform(obj.linproc.transform(x));
        end
        
        function d = errprop(obj, d, isEvolving)
            if exist('isEvolving', 'var')
                d = obj.linproc.errprop(obj.act.errprop(d), isEvolving);
            else
                d = obj.linproc.errprop(obj.act.errprop(d), true);
            end
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.linproc.update(stepsize);
            else
                obj.linproc.update();
            end
        end
    end
    
    methods
        function unit = inverseUnit(obj) % TEMPORARY SOLUTION
            unit = Perceptron( ...
                double(obj.outputSizeDescription), ...
                double(obj.inputSizeDescription), ...
                'actType', obj.act.actType);
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = obj.linproc.inputSizeDescription;
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = obj.act.sizeIn2Out( ...
                obj.linproc.sizeIn2Out(descriptionIn));
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Perceptron(inputSize, outputSize, varargin)
            conf = Config.parse(varargin{:});
            obj.linproc = LinearTransform(inputSize, outputSize);
            if not(Config.popItem(conf, 'noactivation', false))
                obj.act = Activation(Config.getValue(conf, 'actType', 'ReLU'));
            end
            Config.apply(obj, conf);
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        linproc, act = NullUnit()
    end
    
    properties (Dependent)
        actType
    end
    methods
        function value = get.actType(obj)
            value = obj.act.actType;
        end
        function set.actType(obj, value)
            obj.act.actType = value;
        end
    end
    
    % ======================= DEVELOPER TOOL =======================
    methods (Static)
        function debug()
            sizein  = 64;
            sizeout = 16;
            batchsize = 16;
            % Setting : Sigmoid
            refunit = Perceptron(sizein, sizeout, 'actType', 'sigmoid');
            refunit.linproc.bias = randn(size(refunit.linproc.bias));
            model = Perceptron(sizein, sizeout, 'actType', 'sigmoid');
            model.likelihood = Likelihood('logistic');
            % create validate set
            data = randn([sizein, 1e2]);
            validset = DataPackage(data, 'label', refunit.transform(data));
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : 1e3
                data  = randn([sizein, batchsize]);
                label = refunit.transform(data);
                dpkg  = DataPackage(data, 'label', label);
                model.learn(dpkg);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    model.likelihood.evaluate(model.forward(validset)));
            end
            % show result
            werr = refunit.linproc.weight - model.linproc.weight;
            berr = refunit.linproc.bias - model.linproc.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
end
