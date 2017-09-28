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
    end
    
    methods (Static)
        function obj = randinit(sizein, sizeout)
            obj = LinearTransform(HyperParam.randlt(sizeout, sizein), zeros(sizeout, 1));
        end
    end
    
    methods (Static)
        function debug()
            sizein  = 16;
            sizeout = 16;
            refer = LinearTransform(randn(sizeout, sizein), randn(sizeout, 1));
            aprox = LinearTransform.randinit(sizein, sizeout);
            dataset = DataGenerator('normal', sizein);
            objective = Likelihood('mse');
            opt = HyperParam.getOptimizer();
            % opt.gradmode('basic');
            % opt.stepmode('adapt', 'estimatedChange', 1e-1);
            % opt.enableRcdmode(3);
            % opt.gradmode('rmsprop', 'decay2ndOrder', 0.999);
            opt.gradmode('adam', 'decay1stOrder', 0, 'decay2ndOrder', 0.999);
            opt.stepmode('static', 'step', 1e-2);
            task = SimulationTest(aprox, refer, dataset, objective);
            task.run(3e2, 16, 64);
        end
        
        function gdebug()
            sizein  = 16;
            sizeout = 16;
            refer = LinearTransform(randn(sizeout, sizein), randn(sizeout, 1));
            aprox = LinearTransform.randinit(sizein, sizeout);
            dataset = DataGenerator('normal', sizein);
            objective = Likelihood('mse');
            % opt = HyperParam.getOptimizer();
            % opt.gradmode('basic');
            % opt.stepmode('adapt', 'estimatedChange', 1e-1);
            % opt.enableRcdmode(3);
            % opt.gradmode('rmsprop', 'decay2ndOrder', 0.999);
            % opt.gradmode('adam', 'decay1stOrder', 0.9, 'decay2ndOrder', 0.999);
            % opt.gradmode('basic');
            % opt.stepmode('static', 'step', 1e-3);
            task = GenerativeTest(aprox, refer, dataset, objective);
            task.run(3e2, 16, 64);
        end
    end
    
    properties (Constant, Hidden)
        taxis = false;
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
