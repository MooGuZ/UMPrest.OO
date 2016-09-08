classdef ComplexLinearTransform < MappingUnit
    methods
        function y = process(obj, x)
            if iscomplex(x)
                rx = real(x);
                ix = imag(x);
            else
                rx = x;
                ix = 0;
            end
            
            ry = bsxfun(@plus, obj.rweight * rx + obj.iweight * ix, obj.rbias);
            iy = bsxfun(@plus, obj.iweight * rx - obj.rweight * ix, obj.ibias);
            
            y = complex(ry, iy);
        end
        
        function d = errprop(obj, d, isEvolving)
            if not(exist('isEvolving', 'var')) || isEvolving
                obj.realB.addgrad(sum(real(d), 2));
                obj.imagB.addgrad(sum(imag(d), 2));
                obj.realW.addgrad(real(d) * real(obj.I') - imag(d) * imag(obj.I'));
                obj.imagW.addgrad(real(d) * imag(obj.I') + imag(d) * real(obj.I'));
            end
            d = obj.weight' * d;
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.realW.update(stepsize);
                obj.imagW.update(stepsize);
                obj.realB.update(stepsize);
                obj.imagB.update(stepsize);
            else
                obj.realW.update();
                obj.imagW.update();
                obj.realB.update();
                obj.imagB.update();
            end
        end
    end
    
    methods
        function unit = inverseUnit(obj)
            unit = ComplexLinearTransform( ...
                obj.weight', zeros(size(obj.realW, 2), 1), true)
        end
        
        function kernel = kernelDump(obj)
            w = complex(obj.realW.getcpu(), obj.imagW.getcpu());
            b = complex(obj.realB.getcpu(), obj.imagB.getcpu());
            kernel = [w(:); b(:)];
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = SizeDescription.format(size(obj.realW, 2));
        end
        
        function descriptionOut = sizeIn2Out(obj, ~)
            descriptionOut = SizeDescription.format(size(obj.realW, 1));
        end
    end
    
    methods
        function obj = ComplexLinearTransform(argA, argB, opt)
            if exist('opt', 'var') && opt
                weight = argA; bias = argB;
                assert(MathLib.ndims(weight) <= 2 && MathLib.ndims(bias) <= 1 && ...
                       size(weight, 1) == size(bias, 1), 'UMPrest:ArgumentError', ...
                       'Provide WEIGHT and BIAS are illeagal.');
                obj.realW = HyperParam(real(weight));
                obj.imagW = HyperParam(imag(weight));
                obj.realB = HyperParam(real(bias));
                obj.imagB = HyperParam(imag(bias));
            else
                inputSize = argA; outputSize = argB;
                ampWeight = ...
                    (rand(outputSize, inputSize) - 0.5) * (2 / sqrt(inputSize));
                angWeight = (rand(outputSize, inputSize) - 0.5) * (2 * pi);
                obj.realW = HyperParam(ampWeight .* cos(angWeight));
                obj.imagW = HyperParam(ampWeight .* sin(angWeight));
                obj.realB = HyperParam(zeros(outputSize, 1));
                obj.imagB = HyperParam(zeros(outputSize, 1));
            end
        end
    end
    
    properties (Access = private)
        realW, imagW, realB, imagB
    end
    
    properties (Dependent)
        weight, rweight, iweight
        bias, rbias, ibias
    end
    methods
        function value = get.weight(obj)
            value = complex(obj.realW.get(), obj.imagW.get());
        end
        function value = get.rweight(obj)
            value = obj.realW.get();
        end
        function value = get.iweight(obj)
            value = obj.imagW.get();
        end
        
        function value = get.bias(obj)
            value = complex(obj.realB.get(), obj.imagB.get());
        end
        function value = get.rbias(obj)
            value = obj.realB.get();
        end
        function value = get.ibias(obj)
            value = obj.imagB.get();
        end
    end
    
    % properties
    %     complexMode = 'ampang'; % 'complex', 'ampang' or 'realimag' TBC
    % end
end
