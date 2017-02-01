classdef LinearTransform < SISOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(obj, x)
            y = bsxfun(@plus, obj.weight * x, obj.bias);
        end
        
        function d = deltaproc(obj, d, isEvolving)
            if not(exist('isEvolving', 'var')) || isEvolving
                obj.B.addgrad(sum(d, 2));
                obj.W.addgrad(d * obj.I{1}.datarcd.pop()');
            end
            d = obj.weight' * d;
        end
        
        % function update(obj, stepsize)
        %     if exist('stepsize', 'var')
        %         obj.W.update(stepsize);
        %         obj.B.update(stepsize);
        %     else
        %         obj.W.update();
        %         obj.B.update();
        %     end
        % end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.W, obj.B};
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    methods
        function sizeinfo  = sizeIn2Out(obj, sizeinfo)
            sizeinfo(1) = size(obj.W, 1);
        end
        
        function sizeinfo = sizeOut2In(obj,sizeinfo)
            sizeinfo(1) = size(obj.W, 2);
        end
        
        function value = smpsize(obj, io)
            switch lower(io)
                case {'in', 'input'}
                    value = size(obj.W, 2);
                    
                case {'out', 'output'}
                    value = size(obj.W, 1);
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
    end
    
    methods
        function obj = LinearTransform(weight, bias)
            assert(nndims(weight) <= 2 && nndims(bias) <= 1 && ...
                size(weight, 1) == size(bias, 1), 'UMPrest:ArgumentError', ...
                'Provide WEIGHT and BIAS are illeagal.');
            obj.W = HyperParam(weight);
            obj.B = HyperParam(bias);
            obj.I = {UnitAP(obj, 1, '-recdata')};
            obj.O = {UnitAP(obj, 1)};
        end
    end
    
    methods (Static)
        function obj = randinit(sizein, sizeout)
            obj = LinearTransform( ...
                (rand(sizeout, sizein) - 0.5) * (2 / sqrt(sizein)), ...
                zeros(sizeout, 1));
        end
    end
    
    methods (Static)
        function debug()
            sizein = 64; sizeout = 128;
            weight = randn(sizeout, sizein);
            bias   = randn(sizeout, 1);
            refer = LinearTransform(weight, bias);
            model = LinearTransform.randinit(sizein, sizeout);
            likelihood = Likelihood('mse');
            % create validate set
            % data = randn(sizein, 1e2);
            % validset = DataPackage(data, 'label', bsxfun(@plus, ltrans * data, bias));
            validsetIn  = DataPackage(randn(sizein, 1e2), 1, false);
            validsetOut = refer.forward(validsetIn);
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    likelihood.evaluate( ...
                    model.forward(validsetIn).data, ...
                    validsetOut.data));
            for i = 1 : UMPrest.parameter.get('iteration')
                data = randn(sizein, 8);
                ipkg = DataPackage(data, 1, false);
                opkg = refer.forward(ipkg);
                model.backward(likelihood.delta(model.forward(ipkg), opkg));
                model.update();
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    likelihood.evaluate( ...
                    model.forward(validsetIn).data, ...
                    validsetOut.data));
            end
            % show result
            werr = weight - model.weight;
            berr = bias - model.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
    
    properties (Constant, Hidden)
        taxis      = false;
        % expandable = false;
    end
    
    properties (Access = protected)
        W, B
    end
    
    properties (Dependent)
        weight, bias
    end
    methods
        function value = get.weight(obj)
            value = obj.W.get();
        end
        function set.weight(obj, value)
            obj.W.set(value);
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
end
