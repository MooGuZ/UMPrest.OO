classdef AutoEncoder < EvolvingUnit
    % ======================= DATA PROCESSING =======================
    methods
        function y = transform(obj, x)
            y = obj.mapunit.transform(x);
            obj.genunit.errprop( ...
                obj.genunit.likelihood.delta(obj.genunit.transform(y),x));
            obj.genunit.update();
            obj.I = x;
            obj.O = y;
        end
        
        function x = compose(obj, y)
            x = obj.genunit.transform(y);
            obj.I = x;
            obj.O = y;
        end
        
        function d = errprop(obj, d, isEvolving)
            if not(exist('isEvolving', 'var'))
                isEvolving = true;
            end
            if nargout > 0
                d = obj.mapunit.errprop(d, isEvolving);
            else
                obj.mapunit.errprop(d, isEvolving);
            end
        end
    end
    
    % ======================= TOPOLOGY LOGIC =======================
    methods
        function unit = inverseUnit(obj)
            unit = obj.genunit; % TEMPORAL : need make a copy
        end
    end
    
    % ======================= EVOLVING =======================
    methods
        function update(obj)
            obj.mapunit.update();
        end
        
        function learn(obj, datapkg)
            if isempty(datapkg.label)
                rep = obj.mapunit.transform(datapkg.data);
                delta = obj.genunit.errprop(obj.genunit.likelihood.delta( ...
                    obj.genunit.transform(rep), datapkg.data));
                if isempty(obj.prior)
                    obj.mapunit.errprop(delta);
                else
                    obj.mapunit.errprop(delta + obj.prior.delta(rep));
                end
            else
                obj.errprop(obj.likelihood.delta(obj.forward(datapkg)));
            end
            obj.mapunit.update();
        end
    end
    
    % ======================= SIZE DESCRIPTION MODULE =======================
    properties (Dependent, Hidden)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = obj.mapunit.inputSizeDescription;
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = obj.mapunit.sizeIn2Out(descriptionIn);
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = AutoEncoder(unit, varargin)
            obj.mapunit = unit;
            obj.genunit = unit.inverseUnit();
            obj.genunit.likelihood = Likelihood('mse');
            obj.mapunit.likelihood = Likelihood('mse');
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        genunit, mapunit, prior
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
        
        function set.prior(obj, value)
            assert(isempty(value) || isa(value, 'Prior'));
            obj.prior = value;
        end
    end
    
    % ======================= DEVELOPER TOOL =======================
    methods (Static)
        function debug()
%             % AutoEncoder  of Linear Transformation
%             insize  = 4;
%             outsize = 2;
%             batchsize = 3;
%             refer = LinearTransform(randn(insize, outsize), randn(insize, 1), true);
%             model = AutoEncoder(LinearTransform(insize, outsize));
            % AutoEncoder of Convolutional Transformation
            filterSize = [5, 5];
            nfilter = 3;
            nchannel = 2;
            insize = [32, 32, nchannel];
            outsize = [insize(1 : 2), nfilter];
            batchsize = 16;
            refer = ConvTransform(filterSize, nchannel, nfilter);
            refer.bias = randn(size(refer.bias));
            model = AutoEncoder(ConvTransform(filterSize, nfilter, nchannel));
            datasrc = DataGenerator('Gaussian', outsize);
            % set likelihood of model
            model.likelihood = Likelihood('mse');
            % create validate set
            label = datasrc.next(batchsize * 10).data;
            validset = DataPackage(refer.transform(label), 'label', label);
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : 3e2
                label = datasrc.next(batchsize).data;
                dpkg = DataPackage(refer.transform(label), 'label', label);
                % disp([refer.weight, refer.bias, nan(insize,1), model.genunit.weight, ...
                %       model.genunit.bias]);
                % disp([model.mapunit.weight, model.mapunit.bias]);
                model.learn(dpkg);
                objvalue = model.likelihood.evaluate(model.forward(validset));
                if isnan(objvalue) || isinf(objvalue)
                    warning('UMPrest:Debug', 'Objective value is invalid');
                end
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, objvalue);
                % pause();
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
