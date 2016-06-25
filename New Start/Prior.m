classdef Prior < Objective
    methods
        function value = evaluate(obj, data)
            value = obj.evalFunction(data);
        end
        
        function d = delta(obj, data)
            d = obj.deltaFunction(data);
        end
    end
    
    methods
        function obj = Prior(type, varargin)
            % TBC : make parameters of function configurable by VARARGIN
            switch lower(type)
                case {'gaussian'}
                    obj.evalFunction  = @MathLib.negLogGauss;
                    obj.deltaFunction = @MathLib.negLogGaussGradient;
                    
                case {'laplace'}
                    obj.evalFunction  = @MathLib.negLogLaplace;
                    obj.deltaFunction = @MathLib.negLogLaplaceGradient;
                    
                case {'cauchy'}
                    obj.evalFunction  = @MathLib.negLogCauchy;
                    obj.deltaFunction = @MathLib.negLogCauchyGradient;
                    
                case {'vonmise'}
                    obj.evalFunction  = @MathLib.negLogVonMise;
                    obj.deltaFunction = @MathLib.negLogVonMiseGradient;
            end
        end
    end
    
    properties
        mu, sigma
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
    
    properties (Access = private)
        evalFunction, deltaFunction
    end
    methods
        function set.evalFunction(obj, fhandle)
            assert(isa(fhandle, 'function_handle'));
            obj.evalFunction = fhandle;
        end
        
        function set.deltaFunction(obj, fhandle)
            assert(isa(fhandle, 'function_handle'));
            obj.deltaFunction = fhandle;
        end
    end
end