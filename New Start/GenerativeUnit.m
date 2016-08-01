classdef GenerativeUnit < EvolvingUnit
    % ======================= DATA PROCESSING MODULE =======================
    methods
        function y = transform(obj, x)
            y = obj.infer(x);
            obj.I = x;
            obj.O = y;
        end 
        
        function x = compose(obj, y)
            x = obj.genunit.transform(y);
            obj.I = x;
            obj.O = y;
        end
        
        function d = errprop(obj, d, isEvolving)
            d = obj.mapunit.errprop(d, false);
            if not(exist('isEvolving', 'var')) || isEvolving
                obj.genunit.errprop(d, true);
            end
        end
    end
    
    methods
        function rep = infer(obj, data)
            trail = obj.mapunit.transform(data);
            recon = obj.genunit.transform(trail);
            if obj.genunit.likelihood.evaluate(recon, data) > obj.errorTolerance
                rep = reshape(OptimLib.minimize(@obj.objfunc, trail(:), ...
                    obj.optconf, data, size(trail)), size(trail));
                obj.mapunit.errprop(obj.mapunit.likelihood.delta(trail, rep));
                obj.mapunit.update();
%                 nupdate = 0;
%                 while obj.mapunit.likelihood.evaluate(rep, optrep) > obj.errorTolerance
%                     obj.mapunit.errprop(obj.mapunit.likelihood.delta(rep, optrep), true);
%                     obj.mapunit.update();
%                     nupdate = nupdate + 1;
%                     rep = obj.mapunit.transform(data);
%                 end
            else
                rep = trail;
%                 fprintf('  [INFO] MapUnit has been update [%04d] times\n', nupdate);
%                 if nupdate == 0 && obj.gmratio < 10
%                     obj.gmratio  = obj.gmratio + 1;
% %                     fprintf('  [INFO] Gen-Map tolerance ration change to %.2f\n', ...
% %                         obj.gmratio);
%                 end
%                 rep = optrep;
            end
        end

%         function rep = infer(obj, data)
%             repinit = obj.mapunit.transform(data);
%             rep = reshape(OptimLib.minimize(@obj.objfunc, repinit(:), ...
%                 obj.optconf, data, size(repinit)), size(repinit));
%             obj.genunit.transform(rep);
%         end
        
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
    
    % ======================= TOPOLOGY LOGIC =======================
    methods
        function unit = inverseUnit(obj)
            unit = obj.genunit; % TEMPORAL : need make a copy
        end
        
        function [genkernel, mapkernel] = kernelDump(obj)
            genkernel = obj.genunit.kernelDump();
            if nargout > 1
                mapkernel = obj.mapkernel.kernelDump();
            end
        end
    end
    
    % ======================= EVOLVING MODULE =======================
    methods
        function update(obj)
            obj.genunit.update();
        end
        
        function learn(obj, datapkg)
            if isempty(datapkg.label)
                obj.mapunit.errprop(obj.genunit.errprop(obj.genunit.likelihood.delta( ...
                    obj.compose(obj.transform(datapkg.data)), ...
                    datapkg.data)));
                obj.mapunit.update();
            else
                obj.genunit.errprop(obj.likelihood.delta( ...
                    obj.genunit.transform(datapkg.label), ...
                    datapkg.data));
            end
            obj.genunit.update();
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
        function obj = GenerativeUnit(unit, varargin)
            obj.genunit = unit;
            obj.mapunit = obj.genunit.inverseUnit();
            obj.genunit.likelihood = Likelihood('mse');
            obj.mapunit.likelihood = Likelihood('mse');
            obj.optconf = OptimLib.config('default');
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        genunit, mapunit, prior
        optconf, errorTolerance = 1e-2
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
        function debugWithPrior()
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
%             model = GenerativeUnit(refer);
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
        
        function debug()
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
            model = GenerativeUnit(refer);
            datasrc = DataGenerator('Gaussian', insize);
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
