% GAN is short for Generative Adversarial Nets, which is the concept
% created in Ian Goodfellow's same name paper in 2014.
classdef GAN < EvolvingUnit
    methods
        function y = process(obj, x)
            y = obj.gmodel.transform(x);
        end
        
        function d = errprop(obj, d, isEvolving)
            if exist('isEvolving', 'var')
                d = obj.gmodel.errprop(d, isEvolving);
            else
                d = obj.gmodel.errprop(d, true);
            end
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
        function unit = inverseUnit(obj)
            unit = obj.gmodel.inverseUnit();
        end
        
        function kernel = kernelDump(obj)
            kernel = obj.gmodel.kernelDump();
        end
    end
       
    methods
        function learn(obj, sdata)
            gdata = obj.gmodel.forward(obj.noisegen.next(sdata.numel()));
            gdata.label = false(1, numel(gdata));
            sdata.label = true(1, numel(sdata));
            datapkg = DataPackage.Combine(gdata, sdata).shuffle();
            for i = 1 : obj.dUpdateFrequence
                obj.dmodel.errprop(obj.objective.delta(obj.dmodel.forward(datapkg)));
                obj.dmodel.update();
            end
            gdata.label = true(1, numel(gdata));
            obj.gmodel.errprop(obj.dmodel.errprop( ...
                obj.objective.delta(obj.dmodel.forward(gdata)), ...
                false));
            obj.gmodel.update();
            obj.dmodel.refresh(); % TBC
        end
        
        % TODO: remove method 'train' and implement it as a out call to Trainer class
        function train(obj, dataset, objective, varargin)
            obj.objective = objective;
            Trainer.minibatch(obj, dataset, varargin{:});
        end
    end
    
    methods
        function obj = GAN(gmodel, dmodel, varargin)
            obj.gmodel = gmodel;
            obj.dmodel = dmodel;
            conf = Config(varargin);
            obj.noisegen = DataGenerator( ...
                conf.get('noiseType', 'gaussian'), ...
                size(gmodel, 'in'));
            obj.likelihood = Objective(conf.get('likelihood', 'logistic'));
        end
    end
    
    properties
        gmodel, dmodel, noisegen
        dUpdateFrequence = 7;
    end
end
