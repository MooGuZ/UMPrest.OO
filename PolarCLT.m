classdef PolarCLT < MISOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(self, amp, phi)
            y = bsxfun(@plus, ...
                self.rweight * (amp .* cos(phi)) + self.iweight * (amp .* sin(phi)), self.bias);
        end
        
        function [damp, dphi] = deltaproc(self, d)
            amp = self.I{1}.datarcd.pop();
            phi = self.I{2}.datarcd.pop();
            if self.pkginfo.updateHParam
                self.B.addgrad(sum(d, 2));
                self.realW.addgrad(d * (amp .* cos(phi))');
                self.imagW.addgrad(d * (amp .* sin(phi))');
            end
            dr   = self.rweight' * d;
            di   = self.iweight' * d;            
            damp = dr .* cos(phi) + di .* sin(phi);
            dphi = amp .* (di .* cos(phi) - dr .* sin(phi));
        end
        
        function hpcell = hparam(self)
            hpcell = {self.realW, self.imagW, self.B};
        end
       
        function ysize = sizeIn2Out(self, asize, psize)
            assert(asize(1) == size(self.realW, 2), 'ILLEGAL DATA SHAPE');
            assert(psize(1) == size(self.imagW, 2), 'ILLEGAL DATA SHAPE');
            ysize = asize; ysize(1) = size(self.B, 1);
        end
        
        function [asize, psize] = sizeOut2In(self, ysize)
            assert(ysize(1) == size(self.B, 1), 'ILLEGAL DATA SHAPE');
            asize = ysize; asize(1) = size(self.realW, 2);
            psize = ysize; psize(1) = size(self.imagW, 2);
        end
        
        function update(self)
            self.realW.update();
            self.imagW.update();
            self.B.update();
            if self.useCOModelNormalization
                re = self.realW.get();
                im = self.imagW.get();
                % GS orthogonalization
                im = im - re * diag(sum(re .* im) ./ sum(re.^2));
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
        function self = PolarCLT(rweight, iweight, bias)
            assert(nndims(rweight) <= 2 && nndims(iweight) <= 2 ...
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
            self = PolarCLT( ...
                HyperParam.randlt(sizeout, sizein), ...
                HyperParam.randlt(sizeout, sizein), ...
                zeros(sizeout, 1));
        end
        
        function [amp, phi] = normalize(amp, phi)
            index = (amp < 0);
            phi(index) = phi(index) + pi;
            amp = abs(amp);
            phi = wrapToPi(phi);
        end
        
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            sizein  = probScale;
            sizeout = probScale;
            % reference model
            refer = PolarCLT.randinit(sizein, sizeout);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = PolarCLT.randinit(sizein, sizeout);
            % data generator
            dataset = DataGenerator('normal', sizein);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, {dataset, dataset}, objective);
            task.run(niter, batchsize, validsize);
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
