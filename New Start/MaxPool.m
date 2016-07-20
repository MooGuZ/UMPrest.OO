classdef MaxPool < Unit
    methods
        function y = transform(obj, x)
            [y, c] = MathLib.groupmax(x, obj.shape(2), 2);
            [y, r] = MathLib.groupmax(y, obj.shape(1), 1);
            % calculate column subscription of each element
            ind = MathLib.offsetOnDim(r, 2, size(c, 1));
            ind = MathLib.offsetOnDim(ind, 3, size(c, 1) * size(c, 2));
            c   = c(ind);
            % compose index of each element
            obj.map.index = (c - 1) * size(x, 1) + r;
            obj.map.index = MathLib.offsetOnDim(obj.map.index, 3, size(x, 1) * size(x, 2));
            % record size of input
            obj.map.size  = size(x);
        end
        
        % TODO: deal with the condition that 'obj.map' is empty
        function x = compose(obj, y)
            x = obj.errprop(y);
        end
        
        function deltaOut = errprop(obj, deltaIn)
            deltaOut = zeros(obj.map.size, 'like', deltaIn);
            deltaOut(obj.map.index) = deltaIn(:);
        end
        
        function unit = inverseUnit(obj)
            unit = obj; % TEMPORAL
        end
    end
    
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(~)
            value = [sym('x', 'clear'), sym('y', 'clear'), sym.inf];
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = [ceil(descriptionIn(1 : 2) ./ obj.shape), ...
                descriptionIn(3 : end)];
        end
    end
    
    methods (Static)
        function benchmark(matsize, poolsize, times)
            mp = MaxPool(poolsize);
            
            ttrans = 0;
            trecov = 0;
            erecov = 0;
            for i = 1 : times
                m = rand(matsize);
                
                tstart = tic;
                p = mp.transform(m);
                ttrans = ttrans + toc(tstart);
                
                tstart = tic;
                r = mp.errprop(p);
                trecov = trecov + toc(tstart);
                
                erecov = erecov + sum(MathLib.vec(r(mp.map.index) ~= m(mp.map.index)));
            end
            
            fprintf('Everage transformation time : %.3e (s)\n', ttrans / times);
            fprintf('Everage reconstruction time : %.3e (s)\n', trecov / times);
            if erecov > 0
                fprintf('There are %d errors!\n', erecov);
            end
        end
    end
    
    methods
        function obj = MaxPool(shape)
            if numel(shape) == 1
                obj.shape = shape * [1, 1];
            else
                obj.shape = shape;
            end
        end
    end
    
    properties
        shape
        map
    end
end
