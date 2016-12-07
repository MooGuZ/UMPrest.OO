classdef MaxPool < Unit
    methods
        function y = transform(obj, x)
            [y, c] = MathLib.groupmax(x, obj.shape(2), 2);
            [y, r] = MathLib.groupmax(y, obj.shape(1), 1);
            % calculate column subscription of each element
            ind = r;
            csize = size(c);
            for i = 2 : ndims(c)
                ind = MathLib.offsetOnDim(ind, i, prod(csize(1 : i-1)));
            end
            c = c(ind);
            % record size of input
            obj.map.size = size(x);
            % compose index of each element
            obj.map.index = (c - 1) * size(x, 1) + r;
            for i = 3 : ndims(x)
                obj.map.index = MathLib.offsetOnDim(obj.map.index, i, ...
                    prod(obj.map.size(1 : i - 1)));
            end
        end
        
        % TODO: deal with the condition that 'obj.map' is empty
        function x = compose(obj, y)
            x = obj.errprop(y);
        end
        
        function deltaOut = errprop(obj, deltaIn, ~)
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
            value = SizeDescription.format([nan, nan, inf]);
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = [ceil(descriptionIn(1 : 2) ./ obj.shape), ...
                descriptionIn(3 : end)];
        end
    end
    
    methods
        function obj = MaxPool(shape)
            obj.shape = shape;
        end
    end
    
    properties
        shape
    end
    properties (Access = private)
        map
    end
    methods
        function set.shape(obj, value)
            assert(MathLib.isinteger(value) && all(value > 0));
            switch numel(value)
                case {1}
                    obj.shape = value * [1, 1];
                case {2}
                    obj.shape = value;
                otherwise
                    error('Shape of MaxPool should be at most 2D');
            end
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
                
                erecov = erecov + sum(vec(r(mp.map.index) ~= m(mp.map.index)));
            end
            
            fprintf('Everage transformation time : %.3e (s)\n', ttrans / times);
            fprintf('Everage reconstruction time : %.3e (s)\n', trecov / times);
            if erecov > 0
                fprintf('There are %d errors!\n', erecov);
            end
        end
    end
end
