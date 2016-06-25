classdef DataGenerator < handle
    methods
        function init(obj)
            switch lower(obj.type)
                case {'gauss', 'gaussian', 'normal'}
                    obj.datagen = @randn;
            end
        end
        
        function datapkg = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            datapkg = DataPackage(obj.datagen([obj.unitsize, n]));
        end
    end
    
    methods
        function obj = DataGenerator(type, unitsize, varargin)
            obj.type = type;
            obj.unitsize = unitsize;
            obj.init();
        end
    end
    
    properties (Constant, Hidden)
        typeset = {'gauss', 'gaussian', 'normal'};
    end
    
    properties
        type, unitsize
        datagen
    end
    methods
        function set.type(obj, value)
            assert(ischar(value) && any(strcmpi(value, obj.typeset)));
            obj.type = value;
        end
        function set.unitsize(obj, value)
            assert(all(MathLib.isinteger(value)));
            obj.unitsize = value(:)';
        end
    end
end
