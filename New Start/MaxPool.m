classdef MaxPool < Unit
    methods
        function y = transproc(obj, x)
            [y, c] = MathLib.groupmax(x, obj.size(2), 2);
            [y, r] = MathLib.groupmax(y, obj.size(1), 1);
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
        
        function deltaOut = errprop(obj, deltaIn)
            deltaOut = zeros(obj.map.size, 'like', deltaIn);
            deltaOut(obj.map.index) = deltaIn(:);
        end
    end
    
    methods
        function sz = size(obj, mode, opt)
            if exist('mode', 'var')
                if isnumeric(mode)
                    opt  = mode;
                    mode = 'self';
                end
            else
                mode = 'self';
            end
            
            switch lower(mode)
                case {'in'}
                    sz = nan;
                    
                case {'out'}
                    assert(logical(exist('opt', 'var')), 'Input size is required!');
                    sz = [ceil(opt(1:2) ./ obj.shape), opt(3:end)];
                    
                case {'self'}
                    if exist('opt', 'var')
                        sz = obj.shape(opt);
                    else
                        sz = obj.shape;
                    end
                    
                otherwise
                    error('UMPrest:ArgumentError', 'Unrecognized option : %s', upper(mode));
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