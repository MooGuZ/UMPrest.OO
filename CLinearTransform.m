classdef CLinearTransform < MISOUnit & FeedforwardOperation & Evolvable
% Complex Linear Transform, take real and imag as input get output as real part of multiplication. 
% NOTE : use conjugate multiplication here: y = R[A * (Z*)]
    methods
        function y = dataproc(self, re, im)
            y = bsxfun(@plus, self.rweight * re + self.iweight * im, self.bias);
        end
        
        function [dreal, dimag] = deltaproc(self, d)
            if self.pkginfo.updateHParam
                self.B.addgrad(sum(d, 2));
                self.realW.addgrad(d * self.I{1}.datarcd.pop()');
                self.imagW.addgrad(d * self.I{2}.datarcd.pop()');                
            end
            dreal = self.rweight' * d;
            dimag = self.iweight' * d;
        end
        
        function hpcell = hparam(self)
            hpcell = {self.realW, self.imagW, self.B};
        end
        
        function ysize = sizeIn2Out(self, rsize, isize)
            assert(rsize(1) == size(self.realW, 2), 'ILLEGAL DATA SHAPE');
            assert(isize(1) == size(self.imagW, 2), 'ILLEGAL DATA SHAPE');
            ysize = rsize; ysize(1) = size(self.B, 1);
        end
        
        function [rsize, isize] = sizeOut2In(self, ysize)
            assert(ysize(1) == size(self.B, 1), 'ILLEGAL DATA SHAPE');
            rsize = ysize; rsize(1) = size(self.realW, 2);
            isize = ysize; isize(1) = size(self.imagW, 2);
        end
        
        function update(self)
            self.realW.update();
            self.imagW.update();
            self.B.update();
            if self.useCOModelNormalization
                re = self.realW.get();
                im = self.imagW.get();
                % GS orthogonalization
                im = im - re * diag(sum(re .* im ./ sum(re.^2)));
                % renormalize length of bases
                re = bsxfun(@rdivide, re, sqrt(sum(re.^2)));
                im = bsxfun(@rdivide, im, sqrt(sum(im.^2)));
                % flip real and imaginary part
                self.realW.set(im);
                self.imagW.set(re);
            end
        end
    end
    
    methods
        function self = CLinearTransform(rweight, iweight, bias)
            assert(nndims(rweight) <=2 && nndims(iweight) <= 2 ...
                && size(rweight, 1) == size(iweight, 1) ...
                && size(rweight, 1) == size(bias, 1), ...
                'ILLEGAL PARAMERTER SHAPE');
            % setup hyper-parameter
            self.realW = HyperParam(rweight);
            self.imagW = HyperParam(iweight);
            self.B     = HyperParam(bias);
            % setup access-point
            self.I = {UnitAP(self, 1, '-recdata'), UnitAP(self, 1, '-recdata')};
            self.O = {UnitAP(self, 1)};
        end
    end
    
    methods (Static)
        function self = randinit(sizein, sizeout)
            self = CLinearTransform( ...
                HyperParam.randlt(sizeout, sizein), ...
                HyperParam.randlt(sizeout, sizein), ...
                zeros(sizeout, 1));
        end
    
        function debug()
            sizein  = 16;
            sizeout = 16;
            refer = CLinearTransform(randn(sizeout, sizein), ...
                randn(sizeout, sizein), randn(sizeout, 1));
            aprox = CLinearTransform.randinit(sizein, sizeout);
            dataset = DataGenerator('normal', sizein);
            objective = Likelihood('mse');
            opt = HyperParam.getOptimizer();
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-1);
            opt.enableRcdmode(3);
            % opt.gradmode('rmsprop', 'decay2ndOrder', 0.999);
            % opt.gradmode('adam', 'decay1stOrder', 0.9, 'decay2ndOrder', 0.999);
            % opt.stepmode('static', 'step', 1e-2);
            task = SimulationTest(aprox, refer, {dataset, dataset}, objective);
            task.run(3e2, 16, 64);
        end
    end
    
    properties
        useCOModelNormalization = false
    end
    properties (Constant, Hidden)
        taxis = false
    end
    properties (Access = protected)
        realW, imagW, B
    end
    properties (Dependent)
        rweight, iweight, bias        
    end
    methods
        function set.useCOModelNormalization(self, value)
            assert(islogical(value), 'ILLEGAL ASSIGNMENT');
            self.useCOModelNormalization = value;
        end
        
        function value = get.rweight(self)
            value = self.realW.get();
        end
        function set.rweight(self, value)
            self.realW.set(value);
        end
        
        function value = get.iweight(self)
            value = self.imagW.get();
        end
        function set.iweight(self, value)
            self.imagW.set(value);
        end
        
        function value = get.bias(self)
            value = self.B.get();
        end
        function set.bias(self, value)
            self.B.set(value);
        end
    end
end
