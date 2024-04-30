% UPDATE LOG:
%  2017SEP06: add assertion for SIZEIN2OUT and SIZEOUT2IN

classdef LinearTransform < SISOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(obj, x)
            y = bsxfun(@plus, obj.weight * x, obj.bias);
        end
        
        function d = deltaproc(obj, d)
            if obj.pkginfo.updateHParam
                obj.B.addgrad(sum(d, 2));            
                obj.W.addgrad(d * obj.I{1}.datarcd.pop()');
            end
            d = obj.weight' * d;
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.W, obj.B};
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    methods
        function sizeinfo  = sizeIn2Out(obj, sizeinfo)
            assert(sizeinfo(1) == size(obj.W, 2), 'ILLEGAL DATA SHAPE');
            sizeinfo(1) = size(obj.W, 1);
        end
        
        function sizeinfo = sizeOut2In(obj,sizeinfo)
            assert(sizeinfo(1) == size(obj.W, 1), 'ILLEGAL DATA SHAPE');
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

        function refresh(obj)
            obj.W.set(HyperParam.randlt(size(obj.W,1),size(obj.W,2)));
            obj.B.set(zeros(size(obj.B)));
        end
    end
    
    methods (Static)
        function obj = randinit(sizein, sizeout)
            obj = LinearTransform(HyperParam.randlt(sizeout, sizein), zeros(sizeout, 1));
        end
    end
    
    methods (Static)
        function exprcd = debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            sizein  = probScale;
            sizeout = probScale;
            % reference model
            refer = LinearTransform.randinit(sizein, sizeout);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = LinearTransform.randinit(sizein, sizeout);
            % data generator
            dataset = DataGenerator('normal', sizein);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, dataset, objective);
            exprcd = task.run(niter, batchsize, validsize);
        end
        
        function gdebug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            sizein  = probScale;
            sizeout = probScale;
            % reference model
            refer = LinearTransform.randinit(sizein, sizeout);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = LinearTransform.randinit(sizein, sizeout);
            % data generator
            dataset = DataGenerator('normal', sizein);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = GenerativeTest(model, refer, dataset, objective);
            task.run(niter, batchsize, validsize);
        end
    end
    
    properties (Constant, Hidden)
        taxis = false;        
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
