classdef DataGenerator < handle
    methods
        function datapkg = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % generate data
            if obj.tmode.status
                datasize = [obj.smpsize, obj.tmode.nframe, n];
            else
                datasize = [obj.smpsize, n];
            end
            D = obj.datagen(datasize);
            % transform to fit covariance matrix
            if obj.covmat.status
                D = obj.covmat.T * vec(D, obj.dsample, 'both');
                D = reshape(D, datasize);
            end
            % create data package
            if obj.errmode
                datapkg = ErrorPackage(D, obj.dsample, obj.tmode.status);
            else
                datapkg = DataPackage(D, obj.dsample, obj.tmode.status);
            end
            % send package through access point
            if nargout == 0
                obj.data.send(datapkg);
            end
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
            assert(all(size(C) == prod(obj.smpsize) * [1, 1]), ...
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
        function obj = DataGenerator(type, smpsize, varargin)
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
                
              case {'zero'}
                obj.datagen = @zeros;
                
              otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized distribution : %s', upper(type));
            end
            obj.smpsize = smpsize;
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
            obj.errmode = conf.pop('errmode', false);
            obj.data = SimpleAP(obj);
        end
    end
    
    properties
        errmode
    end
    properties (Access = private)
        datagen
    end
    properties (SetAccess = protected)
        data, smpsize
    end
    properties (Constant)
        islabelled = false
    end
    properties (Dependent)
        dsample
    end
    methods
        function set.smpsize(obj, value)
            assert(all(MathLib.isinteger(value)));
            obj.smpsize = value(:)';
        end
        
        function value = get.dsample(obj)
            value = numel(obj.smpsize);
        end
    end
end
