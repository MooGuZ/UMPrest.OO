classdef PolarCCT < MISOUnit & FeedforwardOperation & Evolvable
% Polarized Complex Convolutional Transform
    methods
        function y = dataproc(self, amp, phi)
            realRespond = amp .* cos(phi);
            imagRespond = amp .* sin(phi);
            y = MathLib.nnconv(realRespond, self.rfilter, self.bias, 'same') ...
                + MathLib.nnconv(imagRespond, self.ifilter, zeros(size(self.bias)), 'same');
        end
        
        function [damp, dphi] = deltaproc(self, d)
            amp = self.I{1}.datarcd.pop();
            phi = self.I{2}.datarcd.pop();
            realRespond = amp .* cos(phi);
            imagRespond = amp .* sin(phi);
            if self.pkginfo.updateHParam
                [dRR, dRF, dB] = MathLib.nnconvDifferential( ...
                    d, realRespond, self.rfilter, 'same');
                [dIR, dIF] = MathLib.nnconvDifferential( ...
                    d, imagRespond, self.ifilter, 'same');
                self.B.addgrad(dB);
                self.realF.addgrad(dRF);
                self.imagF.addgrad(dIF);
            else
                dRR = MathLib.nnconvDifferential( ...
                    d, realRespond, self.rfilter, 'same');
                dIR = MathLib.nnconvDifferential( ...
                    d, imagRespond, self.ifilter, 'same');
            end
            damp = dRR .* cos(phi) + dIR .* sin(phi);
            dphi = amp .* (dIR .* cos(phi) - dRR .* sin(phi));
        end
        
        function ysize = sizeIn2Out(self, asize, psize)
            assert(asize(3) == size(self.realF, 3), 'ILLEGAL DATA SHAPE');
            assert(psize(3) == size(self.imagF, 3), 'ILLEGAL DATA SHAPE');
            ysize = asize; ysize(3) = size(self.realF, 4);
        end
        
        function [asize, psize] = sizeOut2In(self, ysize)
            assert(ysize(3) == size(self.realF, 4), 'ILLEGAL DATA SHAPE');
            asize = ysize; asize(3) = size(self.realF, 3);
            psize = asize;
        end
        
        function hpcell = hparam(self)
            hpcell = {self.realF, self.imagF, self.B};
        end
        
        function update(self)
            self.realF.update();
            self.imagF.update();
            self.B.update();
            if self.useCOModelNormalization
                re = vec(self.realF.get(), 2, 'front');
                im = vec(self.imagF.get(), 2, 'front');
                % GS orthogonalization
                im = im - re * diag(sum(re .* im) ./ sum(re.^2));
                % renormalize length of bases
                re = bsxfun(@rdivide, re, sqrt(sum(re.^2)));
                im = bsxfun(@rdivide, im, sqrt(sum(im.^2)));
                % flip real and imaginary part
                self.realF.set(reshape(im, size(self.realF)));
                self.imagF.set(reshape(re, size(self.imagF)));
            end
        end
    end
    
    methods
        function self = PolarCCT(rfilter, ifilter, bias)
            assert(nndims(rfilter) <= 4 && nndims(ifilter) <= 4 ...
                && size(rfilter, 4) == size(ifilter, 4) ...
                && size(rfilter, 4) == numel(bias), ...
                'ILLEGAL PARAMERTER SHAPE');
            % setup hyper-parameter
            self.realF = HyperParam(rfilter);
            self.imagF = HyperParam(ifilter);
            self.B     = HyperParam(reshape(bias, 1, 1, numel(bias)));
            % setup access-point
            self.I = {UnitAP(self, 3, '-recdata'), UnitAP(self, 3, '-recdata')};
            self.O = {UnitAP(self, 3)};
        end
    end
    
    methods (Static)
        function self = randinit(fltsize, nchannel, nfilter)
            if isscalar(fltsize)
                fltsize = fltsize * [1,1];
            end
            self = PolarCCT( ...
                HyperParam.randct(fltsize, nchannel, nfilter), ...
                HyperParam.randct(fltsize, nchannel, nfilter), ...
                zeros(nfilter, 1));
        end
        
        function [amp, phi] = normalize(amp, phi)
            [amp, phi] = PolarCLT.normalize(amp, phi);
        end
        
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            nfilter  = ceil(log2(probScale));
            fltsize  = ceil(sqrt(probScale)) * [1, 1];
            nchannel = nfilter;
            datasize = [probScale, probScale, nchannel];
            % reference model
            refer = PolarCCT.randinit(fltsize, nchannel, nfilter);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = PolarCCT.randinit(fltsize, nchannel, nfilter);
            % data generator
            dataset = DataGenerator('normal', datasize);
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
        realF, imagF, B
    end
    properties (Dependent)
        rfilter, ifilter, bias
    end
    methods
        function set.useCOModelNormalization(self, value)
            assert(islogical(value), 'ILLEGAL ASSIGNMENT');
            self.useCOModelNormalization = value;
        end
        
        function value = get.rfilter(self)
            value = self.realF.get();
        end
        function set.rfilter(self, value)
            self.realF.set(value);
        end
        
        function value = get.ifilter(self)
            value = self.imagF.get();
        end
        function set.ifilter(self, value)
            self.imagF.set(value);
        end
        
        function value = get.bias(self)
            value = self.B.get();
        end
        function set.bias(self, value)
            self.B.set(value);
        end
    end
end
