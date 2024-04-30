classdef BilinearTransform < MISOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(obj, x1, x2)
            y = hugediag( x1', obj.coefficient, x2)';
        end
        
        function [dx1, dx2] = deltaproc(obj, d)
            x1 = obj.I{1}.datarcd.pop();
            x2 = obj.I{2}.datarcd.pop();
            
            if obj.pkginfo.updateHParam
                obj.C.addgrad(bsxfun(@times, d, x1) * x2');
            end
            
            dx1 = 0;
            dx2 = 0;
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.C};
        end
    end
    
    methods
        function sizeinfo = sizeIn2Out(~, sizeinfo, ~)
            sizeinfo(1) = 1;
        end
        
        function [sizeinfo1, sizeinfo2] = sizeOut2In(obj, sizeinfo)
            sizeinfo1 = [obj.yres, sizeinfo(2)];
            sizeinfo2 = [obj.xres, sizeinfo(2)];
        end
    end
    
    methods
        function obj = BilinearTransform(coef)
            obj.C = HyperParam(coef);
            obj.I = {UnitAP(obj, 1, '-recdata'), UnitAP(obj, 1, '-recdata')};
            obj.O = {UnitAP(obj, 1)};
        end
    end
    
    methods (Static)
        function obj = randinit(yres, xres)
            obj = BilinearTransform(HyperParam.randlt(yres, xres));
        end
        
        function [refer, model] = debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            yres = probScale;
            xres = probScale;
            % reference model
            refer = BilinearTransform.randinit(yres, xres);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            % model = iDCT2Function(refer.coefficient + 0.05*randn(refer.yres, refer.xres));
            model = BilinearTransform.randinit(yres, xres);
            % data generator
            dataset1 = DataGenerator('normal', yres);
            dataset2 = DataGenerator('normal', xres);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, {dataset1, dataset2}, objective);
            task.run(niter, batchsize, validsize);
        end
    end
    
    properties (Constant, Hidden)
        taxis = false;
    end
    
    properties (Access = protected)
        C
    end
    
    properties (Dependent)
        coefficient, yres, xres
    end
    methods
        function value = get.coefficient(obj)
            value = obj.C.get();
        end
        function set.coefficient(obj, value)
            obj.C.set(value);
        end
        
        function value = get.yres(obj)
            value = size(obj.C, 1);
        end
        
        function value = get.xres(obj)
            value = size(obj.C, 2);
        end
    end
end

function d = hugediag(A, B, C)
n = size(A, 1);
if n > 1e4
    step = 2048;
    head = 1;
    tail = head + step + 1;
    d = zeros(n, 1);
    while head <= n
        d(head:tail) = diag(A(head:tail,:) * B * C(:, head:tail));
        head = head + step;
        tail = min(head + step - 1, n);
    end
else
    d = diag(A * B * C);
end
end