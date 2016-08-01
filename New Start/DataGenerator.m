classdef DataGenerator < handle
    methods
        function datapkg = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            datapkg = DataPackage(obj.datagen([obj.unitsize, n]));
        end
    end
    
    methods
        function obj = DataGenerator(type, unitsize, varargin)
            switch lower(type)
              case {'uniform'}
                obj.datagen = @rand;
                    
              case {'gauss', 'gaussian', 'normal'}
                obj.datagen = @randn;
                    
              case {'cauchy'}
                obj.datagen = @MathLib.randcc;
                
              case {'laplace'}
                obj.datagen = @MathLib.randll;
                
              otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized distribution : %s', upper(type));
            end
            obj.unitsize = unitsize;
        end
    end
    
    properties
        unitsize
    end
    properties (Access = private)
        datagen
    end
    methods
        function set.unitsize(obj, value)
            assert(all(MathLib.isinteger(value)));
            obj.unitsize = value(:)';
        end
    end
end
