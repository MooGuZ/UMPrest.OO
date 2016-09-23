classdef GenerativeUnit < EvolvingUnit
    % ======================= DATA PROCESSING MODULE =======================
    methods
        function varargout = transform(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.genunit.compose(varargin{:});
        end 
        
        function varargout = compose(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.genunit.transform(varargin{:});
        end
        
        function d = errprop(obj, d, isEvolving)
            error('UMPrest:ProgramError', 'This function is not supported!');
        end
        
        function d = delta(obj, d)
        end
        
        function x = process(obj, x)
        end
        
        function x = invproc(obj, x)
        end
    end
    
    % ======================= EVOLVING MODULE =======================
    methods
        function update(obj)
            obj.genunit.update();
        end
        
        function learn(obj, varargin)
            ipackage = varargin;
            opackage = cell(1, numel(obj.O));
            [opackage{:}] = obj.transform(ipackage{:});
            rpackage = cell(1, numel(obj.I));
            [rpackage{:}] = obj.compose(opackage{:});
            obj.genunit.errprop(obj.likelihood.delta(rpackage{:}, ipackage{:}));
            obj.genunit.update();
            obj.age = obj.age + 1;
        end
    end

    % ======================= SIZE DESCRIPTION MODULE =======================
    methods
        function varargout = sizeIn2Out(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.genunit.sizeOut2In(varargin{:});
        end
        
        function varargout = sizeOut2In(obj, varargin)
            varargout = cell(1, nargout);
            [varargout{:}] = obj.genunit.sizeIn2Out(varargin{:});
        end
    end
    
    methods
        function sobj = save(obj, filename)
            sobj = obj.genunit.save(filename);
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = GenerativeUnit(unit, varargin)
            conf = Config(varargin);
            obj.genunit = unit;
            obj.likelihood = conf.get('Likelihood', Likelihood('mse'));
            obj.optconf = conf.get('OptimizeConfig', OptimLib.config('default'));
            obj.I = obj.genunit.O;
            obj.O = obj.genunit.I;
            obj.taxis = obj.genunit.taxis;
            obj.expandable = obj.genunit.expandable;
            obj.genunit.likelihood = obj.likelihood;
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        genunit, optconf
    end
    
    properties (SetAccess = private)
        taxis, expandable
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
