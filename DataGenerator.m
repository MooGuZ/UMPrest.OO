classdef DataGenerator < handle
    methods
        function datapkg = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % generate data
            if obj.tmode.status
                datasize = [obj.unitsize, obj.tmode.nframe, n];
            else
                datasize = [obj.unitsize, n];
            end
            data = obj.datagen(datasize);
            % transform to fit covariance matrix
            if obj.covmat.status
                data = obj.covmat.T * vec(data, obj.unitdim, 'both');
                data = reshape(data, datasize);
            end
            % create data package
            datapkg = DataPackage(data, obj.unitdim, obj.tmode.status);
        end
    end
    
    properties (SetAccess = protected)
        tmode, covmat
    end
    methods
        function obj = enableTmode(obj, n)
            obj.tmode = struct('status', true, 'nframe', n);
        end
        function obj = disableTmode(obj)
            obj.tmode = struct('status', false);
        end
        
        function obj = enableCovmat(obj, C)
            assert(all(size(C) == prod(obj.unitsize) * [1, 1]), ...
                'COVARIANCE MATRIX MISMATCH');
            assert(all(vec(C == C')), 'ILLEGAL COVARIANCE MATRIX');
            [u, v] = eig(C);
            assert(all(diag(v) > 0), 'ILLEGAL COVARIANCE MATRIX');
            obj.covmat = struct( ...
                'status', true, ...
                'C', C, ...
                'T', u * sqrt(v));
        end
        function obj = disableCovmat(obj)
            obj.covmat = struct('status', false);
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
                obj.enableTmode(conf.pop('tmode'));
            else
                obj.disableTmode();
            end
            if conf.exist('covmat')
                obj.enableCovmat(conf.pop('covmat'));
            else
                obj.disableCovmat();
            end
        end
    end
    
    properties (Access = private)
        datagen
    end
    properties (SetAccess = protected)
        unitsize
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
