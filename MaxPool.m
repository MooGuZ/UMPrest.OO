classdef MaxPool < SISOUnit & FeedforwardOperation
    methods
        function y = dataproc(obj, x)
            [y, c] = MathLib.groupmax(x, obj.shape(2), 2);
            [y, r] = MathLib.groupmax(y, obj.shape(1), 1);
            % calculate column subscription of each element
            ind = r;
            csize = size(c);
            for i = 2 : ndims(c)
                ind = MathLib.offsetOnDim(ind, i, prod(csize(1 : i-1)));
            end
            c = c(ind);
            % creat map for this operation
            map = struct();
            % record size of input
            map.size = size(x);
            % compose index of each element
            map.index = (c - 1) * size(x, 1) + r;
            for i = 3 : ndims(x)
                map.index = MathLib.offsetOnDim(map.index, i, ...
                    prod(map.size(1 : i - 1)));
            end
            % record map
            obj.maprcd.push(map);
        end
        
        function deltaOut = deltaproc(obj, deltaIn)
            map = obj.maprcd.pop();
            deltaOut = zeros(map.size, 'like', deltaIn);
            deltaOut(map.index) = deltaIn(:);
        end
    end
    
    methods
        function szinfo = sizeIn2Out(obj, szinfo)
            szinfo(1 : 2) = ceil(szinfo(1 : 2) ./ obj.shape);
        end
        
        function szinfo = sizeOut2In(obj, szinfo)
            warning('Size calculation of MaxPool Unit is not accurate!');
            szinfo(1 : 2) = szinfo(1 : 2) .* obj.shape;
        end
    end
    
    methods
        % OVERIDE SIMPLEUNIT.RECRTMODE
        function obj = recrtmode(obj, n)
            if n == 1
                obj.maprcd.simple();
            else
                obj.maprcd.init(n);
            end
        end
    end
    
    methods
        function obj = MaxPool(shape)
            obj.shape = shape;
            obj.maprcd = Container();
            obj.I = {UnitAP(obj, 0, '-expandable')};
            obj.O = {UnitAP(obj, 0, '-expandable')};
        end
    end
    
    properties (Constant)
        taxis = false;
    end
    
    properties
        maprcd, shape
    end
    methods
        function set.shape(obj, value)
            assert(numel(value) == 2 && MathLib.isinteger(value) && all(value > 0), ...
                'ILLEGAL ASSIGNMENT');
            obj.shape = value;
        end
    end
end