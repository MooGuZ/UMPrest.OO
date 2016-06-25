% GAN is short for Generative Adversarial Nets, which is the concept
% created in Ian Goodfellow's same name paper in 2014.
classdef GAN < EvolvingUnit
    methods
        function y = trainsproc(obj, x)
            y = obj.gmodel.transform(x);
        end
        
        function d = errprop(obj, d)
            d = obj.gmodel.errprop(d);
        end
        
        function update(obj)
            obj.gmodel.update();
            obj.updateCounter = obj.updateCounter + 1;
        end
        
        function value = evaluate(obj, datapkg)
            value = obj.objective.evaluate(obj.forward(datapkg));
        end
    end
       
    methods
        function trainproc(obj, sdata)
            gdata = obj.gmodel.forward(obj.noisegen.next(sdata.numel()));
            gdata.label = false(1, numel(gdata));
            sdata.label = true(1, numel(sdata));
            datapkg = DataPackage.Combine(gdata, sdata).shuffle();
            for i = 1 : obj.dUpdateFrequence
                obj.dmodel.errprop(obj.objective.delta(obj.dmodel.forward(datapkg)));
                obj.dmodel.update();
            end
            gdata.label = true(1, numel(gdata));
            obj.gmodel.errprop(obj.dmodel.errprop(obj.objective.delta(obj.dmodel.forward(gdata))));
            obj.gmodel.update();
            obj.dmodel.refresh();
        end
        
        function train(obj, dataset, objective, varargin)
            obj.objective = objective;
            Trainer.minibatch(obj, dataset, varargin{:});
        end
    end
    
    methods
        function obj = GAN(gmodel, dmodel, varargin)
            obj.gmodel = gmodel;
            obj.dmodel = dmodel;
            conf = Config.parse(varargin);
            obj.noisegen = DataGenerator( ...
                Config.getValue(conf, 'noiseType', 'gaussian'), ...
                size(gmodel, 'in'));
            obj.objective = Objective(Config.getValue(conf, 'objective', 'logistic'));
        end
    end
    
    properties
        gmodel, dmodel, noisegen, objective
        dUpdateFrequence = 7;
        updateCounter = 0;
        logger
        tasktype
    end
end
