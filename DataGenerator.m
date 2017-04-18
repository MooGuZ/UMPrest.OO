classdef DataGenerator < handle
    methods
        function datapkg = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % generate data package
            if obj.tmode.status
                datasize = [obj.unitsize, obj.tmode.nframe, n];
                datapkg = DataPackage(obj.datagen(datasize), obj.unitdim, true);
            else
                datasize = [obj.unitsize, n];
                datapkg  = DataPackage(obj.datagen(datasize), obj.unitdim, false);
            end
        end
        
        function obj = enableTAxis(obj, n)
            obj.tmode = struct('status', true, 'nframe', n);
        end
        
        function obj = disableTAxis(obj)
            obj.tmode = struct('status', false);
        end
    end
    
    methods
        function obj = DataGenerator(type, unitsize, varargin)
            conf = Config(varargin);
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
            if conf.exist('tmode')
                obj.enableTAxis(conf.pop('tmode'));
            else
                obj.disableTAxis();
            end
        end
    end
    
    properties (Access = private)
        datagen
    end
    properties (SetAccess = protected)
        unitsize, tmode
    end
    properties (Dependent)
        unitdim
    end
    methods
        function set.unitsize(obj, value)
            assert(all(MathLib.isinteger(value)));
            obj.unitsize = value(:)';
        end
        
        function value = get.unitdim(obj)
            value = numel(obj.unitsize);
        end
    end
end
