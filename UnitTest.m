classdef UnitTest
    methods (Static)
        function MLP()
            inputSize = 400;
            psizeList = [512, 1024, 376, 128, 10];
            hactType  = 'ReLU';
            oactType  = 'Sigmoid';
            
            % main work flow
            model = MLP(inputSize, psizeList, ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            datasource = load(UMPrest.path('data', 'tinytest'));
            ds = LabelledDataSet(LabelledMemoryDataBlock( ...
                MathLib.pack2cell(datasource.X'), ...
                MathLib.pack2cell(MathLib.ind2tf(datasource.y, 1, 10))));
            AccessPoint.connectOneWay(ds.data, model.I);
            objective = Likelihood('logistic', model.O, ds.label);
            trainer = Trainer();
            log = trainer.suptrain(model, ds, objective);
            log.display();
        end
        
        function topologicalSort()
            % create units
            a = LinearTransform(2,3);
            b = LinearTransform(2,4);
            c = LinearTransform(2,5);
            d = LinearTransform(2,6);
            e = LinearTransform(2,7);
            f = LinearTransform(2,8);
            g = LinearTransform(2,9);
            % add ids
            a.id = 'a';
            b.id = 'b';
            c.id = 'c';
            d.id = 'd';
            e.id = 'e';
            f.id = 'f';
            g.id = 'g';
            % connections
            a.connectTo(b);
            b.connectTo(c);
            b.connectTo(d);
            c.connectTo(e);
            d.connectTo(e);
            e.connectTo(f);
            g.connectTo(c);
            % create model
            m = Model();
            m.add(a, b, c, d, e, f, g);
            m.topologicalSort();
            fprintf('Order >> ');
            for i = 1 : numel(m.nodes)
                fprintf('%s ', m.nodes{i}.id);
            end
            fprintf('\n');
        end
        
        function Perceptron()
            sizein  = 64;
            sizeout = 16;
            batchsize = 16;
            % Setting : Sigmoid
            refer = Perceptron(sizein, sizeout, 'actType', 'sigmoid');
            refer.linproc.bias = randn(size(refer.linproc.bias));
            model = Perceptron(sizein, sizeout, 'actType', 'sigmoid');
            model.likelihood = Likelihood('logistic');
            % create validate set
            data = randn([sizein, 1e2]);
            validset = DataPackage(data, 'label', refer.transform(data));
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : UMPrest.parameter.get('iteration')
                data  = randn([sizein, batchsize]);
                label = refer.transform(data);
                dpkg  = DataPackage(data, 'label', label);
                model.learn(dpkg);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    model.likelihood.evaluate(model.forward(validset)));
            end
            % show result
            werr = refer.linproc.weight - model.linproc.weight;
            berr = refer.linproc.bias - model.linproc.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
end
