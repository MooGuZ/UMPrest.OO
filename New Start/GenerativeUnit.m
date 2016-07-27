classdef GenerativeUnit < EvolvingUnit
    % ======================= DATA PROCESSING MODULE =======================
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
        
        function d = errprop(obj, d, isEvolving)
            d = obj.mapunit.errprop(d, false);
            if exist('isEvolving', 'var')
                obj.genunit.errprop(d, isEvolving);
            else
                obj.genunit.errprop(d, true);
            end
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
                obj.mapunit.errprop(obj.mapunit.likelihood.delta(rep, optrep), true);
                obj.mapunit.update();
            end
        end
        
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
        
        function data = process(obj, rep)
            data = obj.genunit.process(rep);
        end
    end
    
    properties
        acceptLikelihoodValue = 1e-2;
    end
    
    % ======================= EVOLVING MODULE =======================
    methods
        function learn(obj, datapkg)
            obj.genunit.errprop(obj.genunit.likelihood.delta( ...
                obj.backward(obj.forward(datapkg)).data, ...
                datapkg.data));
            obj.genunit.update();
        end
    end

    % ======================= SIZE DESCRIPTION MODULE =======================
    properties (Dependent)
        inputSizeRequirement, outputSizeDescription
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = obj.mapunit.inputSizeDescription;
        end
        
        % PROBLEM: need more complex solution to deal with units that contains
        %          sub-units
        function value = get.outputSizeDescription(obj)
            value = obj.mapunit.outputSizeDescription;
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = GenerativeUnit(unit, varargin)
            obj.genunit = unit;
            obj.mapunit = obj.genunit.symmetryUnit(); % TBC
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
end
