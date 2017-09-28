classdef CommonPrior < Prior
    methods
        function value = evalproc(obj, data)
            value = sum(vec(obj.evalfcn(data, obj.mu, obj.sigma)));
        end
        
        function d = deltaproc(obj, data)
            d = obj.deltafcn(data, obj.mu, obj.sigma);
        end
    end
    
    methods
        function obj = CommonPrior(type, varargin)
            obj@Prior(varargin{:});
            % get extra configuration
            conf = Config(varargin);
            % setup operating methods
            switch lower(type)
              case {'gaussian'}
                obj.evalfcn  = @MathLib.negLogGauss;
                obj.deltafcn = @MathLib.negLogGaussGradient;
                
              case {'laplace'}
                obj.evalfcn  = @MathLib.negLogLaplace;
                obj.deltafcn = @MathLib.negLogLaplaceGradient;
                
              case {'cauchy'}
                obj.evalfcn  = @MathLib.negLogCauchy;
                obj.deltafcn = @MathLib.negLogCauchyGradient;
                
              case {'vonmise'}
                obj.evalfcn  = @MathLib.negLogVonMise;
                obj.deltafcn = @MathLib.negLogVonMiseGradient;
                
              case {'slow'}
                obj.evalfcn  = @MathLib.slow;
                obj.deltafcn = @MathLib.slowGradient;
                
              otherwise
                error('UMPrest:ArgumentError', 'Unrecognized prior : %s', upper(type));
            end
            obj.mu    = conf.pop('mean', 0);
            obj.sigma = conf.pop('stdvar', 1);
        end
    end
    
    properties
        mu, sigma
    end
    properties (Access = private)
        evalfcn, deltafcn
    end
    methods
        function set.mu(obj, value)
            assert(isreal(value));
            obj.mu = value;
        end
        
        function set.sigma(obj, value)
            assert(isreal(value) && value > 0);
            obj.sigma = value;
        end
    end
end
