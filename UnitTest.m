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
            a.connect(b);
            b.connect(c);
            b.connect(d);
            c.connect(e);
            d.connect(e);
            e.connect(f);
            g.connect(c);
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
        
        function GenerativeUnitWithPrior()
            % Generative Unit of Linear Transformation
            insize  = 2;
            outsize = 4;
            batchsize = 3;
            refer = LinearTransform(randn(outsize, insize), randn(outsize, 1), true);
            model = GenerativeUnit(LinearTransform(insize, outsize));
%             % Generative Unit of Convolutional Transformation
%             filterSize = [5, 5];
%             nfilter = 3;
%             nchannel = 2;
%             insize = [32, 32, nchannel];
%             batchsize = 16;
%             refer = ConvTransform(filterSize, nfilter, nchannel);
%             refer.bias = randn(size(refer.bias));
%             model = GenerativeUnit(ConvTransform(filterSize, nfilter, nchannel));
            datasrc = DataGenerator('Gaussian', insize);
            % set likelihood of model
            model.likelihood = Likelihood('mse');
            % set prior of representation
            model.prior = Prior('Gaussian');
            % create validate set
            validlabel = datasrc.next(batchsize * 10).data;
            validset = DataPackage(refer.transform(validlabel));
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset).data, validlabel));
            for i = 1 : 1e3
                label = datasrc.next(batchsize).data;
                dpkg = DataPackage(refer.transform(label));
                model.learn(dpkg);
%                 disp([refer.weight, refer.bias, nan(4,1), model.genunit.weight, model.genunit.bias, nan(4, 1), model.mapunit.weight', [model.mapunit.bias; nan(2,1)]]);
                objvalue = model.likelihood.evaluate(model.forward(validset).data, validlabel);
                if isnan(objvalue) || isinf(objvalue)
                    warning('UMPrest:Debug', 'Objective value is invalid');
                end
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, objvalue);
%                 pause();
            end
            % show result
            werr = refer.weight - model.genunit.weight;
            berr = refer.bias - model.genunit.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
        
        function GenerativeUnit()
%             % Generative Unit of Linear Transformation
%             insize  = 2;
%             outsize = 4;
%             batchsize = 3;
%             refer = LinearTransform(randn(outsize, insize), randn(outsize, 1), true);
%             model = GenerativeUnit(LinearTransform(insize, outsize));
            % Generative Unit of Convolutional Transformation
            filterSize = [5, 5];
            nfilter = 3;
            nchannel = 2;
            insize = [32, 32, nchannel];
            batchsize = 16;
            refer = ConvTransform(filterSize, nfilter, nchannel);
            refer.bias = randn(size(refer.bias));
            model = GenerativeUnit(ConvTransform(filterSize, nfilter, nchannel));
            datasrc = DataGenerator('Gaussian', insize);
            % set likelihood of model
            model.likelihood = Likelihood('mse');
            % create validate set
            label = datasrc.next(batchsize * 10).data;
            validset = DataPackage(refer.transform(label), 'label', label);
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : UMPrest.parameter.get('iteration')
                label = datasrc.next(batchsize).data;
                dpkg = DataPackage(refer.transform(label), 'label', label);
                model.learn(dpkg);
                objvalue = model.likelihood.evaluate(model.forward(validset));
                if isnan(objvalue) || isinf(objvalue)
                    warning('UMPrest:Debug', 'Objective value is invalid');
                end
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, objvalue);
            end
            % show result
            werr = refer.weight - model.genunit.weight;
            berr = refer.bias - model.genunit.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
end
