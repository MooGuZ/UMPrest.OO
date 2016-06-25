classdef ConvPerceptron < EvolvingUnit
    methods
        function y = transproc(obj, x)
            y = obj.act.transform(obj.pool.transform(obj.conv.transform(x)));
        end
        
        function d = errprop(obj, d)
            d = obj.conv.errprop(obj.pool.errprop(obj.act.errprop(d)));
        end
        
        function update(obj)
            obj.trans.update();
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
                    sz = [obj.inputSize, obj.conv.nchannel];
                    
                case {'out'}
                    sz = obj.pool.size('out', obj.conv.size('out', obj.inputSize));
                    
                case {'self'}
                    if exist('opt', 'var')
                        sz = obj.conv.size(opt);
                    else
                        sz = obj.conv.size();
                    end
                    
                otherwise
                    error('UMPrest:ArgumentError', 'Unrecognized option : %s', upper(mode));
            end
        end
    end
    
    methods
        function obj = ConvPerceptron(filterSize, nfilter, nchannel, varargin)
            propmap = Config.parse(varargin{:});
            
            obj.conv = ConvTransform(nfilter, filterSize, nchannel);
            obj.pool = MaxPool(Config.getValue(propmap, 'poolSize', 3));
            obj.act  = Activation(Config.getValue(propmap, 'activationType', 'ReLU'));
            
            Config.apply(obj, propmap);
        end
    end
    
    properties
        conv, pool, act
    end
    
    properties (Access = private)
        insize
    end
    
    properties (Dependent)
        inputSize
    end
    methods
        function value = get.inputSize(obj)
            value = obj.insize;
        end
        function set.inputSize(obj, value)
            assert(numel(value) == 2, 'Input size should be a 2 elements vector');
            obj.insize = value;
        end
    end
end