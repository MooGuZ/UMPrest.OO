classdef GenerativeUnit < Unit
    methods
        function y = transform(obj, x)
            y = obj.infer(x);
            obj.I = x;
            obj.O = y;
        end 
        
        function x = compose(obj, y)
            x = obj.process(y);
            obj.I = x;
            obj.O = y;
        end
        
        function d = deltaproc(obj, d, isEvolving)
            d = obj.mapunit.deltaproc(d, false);
            if isEvolving
                obj.genunit.deltaproc(d, true);
            end
        end
        
        function learn(obj, datapkg)
            obj.genunit.errprop(obj.genunit.likelihood.delta( ...
                obj.backward(obj.forward(datapkg)).data, ...
                datapkg.data));
            obj.genunit.update();
        end
        
        function update(obj)
            obj.genunit.update();
        end
    end
    
    methods
        function rep = infer(obj, data)
            rep = obj.mapunit.process(data);
            rec = obj.genunit.process(repinit);
            if obj.genunit.likelihood.evaluate(rec, data) > obj.acceptLikelihoodValue
                repsz  = [obj.size('out'), numel(data) / prod(obj.size('in'))];
                optrep = reshape(OptimLib.minimize(@obj.objfunc, rep(:), ...
                    OptimLib.config('default'), data, repsz), repsz);
                obj.mapunit.deltaproc(obj.mapunit.likelihood.delta(rep, optrep), true);
                obj.mapunit.update();
            end
        end
        
        function data = process(obj, rep)
            data = obj.genunit.process(rep);
        end
    end
    
    methods
        function [value, grad] = objfunc(obj, dataIn, dataOut, sizeIn)
            if nargout > 1
                [value, grad] = obj.genunit.objfunc(dataIn, dataOut, sizeIn);
                if not(isempty(obj.prior))
                    value = value + obj.prior.evaluate(dataIn);
                    grad  = grad + MathLib.vec(obj.prior.delta(dataIn));
                end
            else
                value = obj.genunit.objfunc(dataIn, dataOut, sizeIn);
                if not(isempty(obj.prior))
                    value = value + obj.prior.evaluate(dataIn);
                end
            end
        end
    end
    
    methods
        function obj = GenerativeUnit(unit, varargin)
            obj.genunit = unit;
            obj.mapunit = obj.genunit.counterunit(); % TBC
            conf = Config.parse(varargin);
            obj.likelihood = Config.popItem(conf, 'likelihood', Likelihood('mse'));
            Config.apply(obj, conf);
        end
    end
    
    properties
        genunit, mapunit
        likelihood, prior
    end
    methods
        function set.genunit(obj, value)
            assert(isa(value, 'EvolvingUnit'));
            obj.genunit = value;
        end
        
        function set.mapunit(obj, value)
            assert(isa(value, 'EvolvingUnit'));
            obj.mapunit = value;
        end
        
        function set.likelihood(obj, value)
            assert(isempty(value) || isa(value, 'Likelihood'));
            obj.likelihood = value;
        end
        
        function set.prior(obj, value)
            assert(isempty(value) || isa(value, 'Prior'));
            obj.prior = value;
        end
    end
    
    properties
        acceptLikelihoodValue = 1e-2;
    end
end
