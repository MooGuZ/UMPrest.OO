classdef GaborGenerator < MappingUnit
    methods
        function obj = GaborGenerator(imsize)
            if isscalar(imsize)
                obj.imsize = [imsize, imsize];
            else
                obj.imsize = imsize;
            end
            
            [crdx, crdy] = meshgrid(linspace(-1, 1, obj.imsize(2)), ...
                linspace(1, -1, obj.imsize(1)));
            obj.coord = [crdx(:), crdy(:)]';
            
            obj.likelihood = Likelihood('kldiv');
        end
        
        function y = process(obj, x)
            [alpha, mu, invcov, nvec, bias] = obj.decodeInput(x);
            crd = bsxfun(@minus, obj.coord, mu);
            y = alpha * exp(-diag(crd' * invcov * crd) / 2) .* cos(crd' * nvec) + bias;
            ymin = min(y);
            obj.offset = ifte(ymin <= 0, - min(y), 0);
            y = y + obj.offset;
            obj.scale = 1 / (sum(y) + eps);
            y = reshape(y * obj.scale , obj.imsize);
            y = ifte(ymin <= 0, y + eps, y);
        end
        
        function d = errprop(obj, d, ~)
            d = d * obj.scale;
            
            [alpha, mu, invcov, nvec, bias] = obj.decodeInput(obj.I);
            
            crd = bsxfun(@minus, obj.coord, mu);
            wDelta = ((obj.O(:) - bias) .* d(:))'; % weighted delta
                        
            dAlpha  = sum(wDelta) / alpha;
            dMu     = sum(bsxfun(@times, (invcov + invcov') * crd, wDelta), 2) / 2;
            dInvcov = -bsxfun(@times, crd, wDelta) * crd' / 2;
            dNvec   = -crd * (alpha * exp(-diag(crd' * invcov * crd) / 2) .* sin(crd' * nvec) .* d(:));
            dBias   = sum(d(:));
            
            d = obj.encodeInput(dAlpha, dMu, dInvcov, dNvec, dBias);
        end
        
        function update(~)
            % do nothing
        end
        
        function inverseUnit(~)
            error('This function has not been completed yet');
        end
        
        function data = infer(obj, rep, initval)
            sizeIn = [10, 1];
            data = reshape(OptimLib.minimize(@obj.objfunc, initval, ...
                OptimLib.config('debug'), rep, sizeIn), sizeIn);
        end
    end
    
    methods
        function [alpha, mu, invcov, nvec, bias] = decodeInput(~, x)
            alpha  = x(1);
            mu     = x(2 : 3);
            invcov = reshape(x(4 : 7), [2, 2]);
            nvec   = x(8 : 9);
            bias   = x(10);
        end
        
        function x = encodeInput(~, alpha, mu, invcov, nvec, bias)
            x = [alpha; mu(:); invcov(:); nvec(:); bias];
        end
    end
    
    methods (Static)
        function checkGradient(stepsize)
            input = randn(10, 1);
            model = GaborGenerator(8);
            output = model.transform(input);
            initval = randn(10, 1);
            predict = model.transform(initval);
            objval = model.likelihood.evaluate(predict, output);
            deriv = model.errprop(model.likelihood.delta(predict, output));
            for i = 1 : numel(deriv)
                newval = initval;
                newval(i) = newval(i) - stepsize * deriv(i);
                newobj = model.likelihood.evaluate(model.process(newval), output);
                if newobj < objval
                    fprintf('[%02d] VRIFIED (decreased by %.2e [%.2f%%])\n', ...
                        i, objval - newobj, (objval - newobj) / objval * 100);
                else
                    fprintf('[%02d] FAILED  (increased by %.2e [%.2f%%])\n',  ...
                        i, newobj - objval, (newobj - objval) / objval * 100);
                end
            end
            disp('Here is a place to stop');
        end
    end
    
    properties
        imsize, coord
        offset, scale
    end
    
    properties (Dependent, Hidden)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(~)
            value = SizeDescription.format(10);
        end
        
        function descriptionOut = sizeIn2Out(obj, ~)
            descriptionOut = SizeDescription.format(obj.imsize);
        end
    end        
end
