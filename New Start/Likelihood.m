% TBC : add properties containing the type of likelihood
classdef Likelihood < Objective
    methods
        function value = evaluate(obj, argA, argB)
            if isa(argA, 'DataPackage')
                value = obj.evalFunction(argA.data, argA.label);
            else
                value = obj.evalFunction(argA, argB);
            end
        end
        
        function d = delta(obj, argA, argB)
            if isa(argA, 'DataPackage')
                assert(argA.isunified);
                d = obj.deltaFunction(argA.data, argA.label);
            else
                d = obj.deltaFunction(argA, argB);
            end
        end
        
%         function value = evaluate(obj, varargin)
%             switch nargin
%                 case 2
%                     datapkg = varargin{1};
%                     value = obj.evalFunction(datapkg.data, datapkg.label);
%                 case 3
%                     data  = varargin{1};
%                     label = varargin{2};
%                     value = obj.evalFunction(data, label);
%                 otherwise
%                     error('UMPrest:RuntimeError', 'Should not happen');
%             end
%         end
        
%         function d = delta(obj, varargin)
%             switch nargin
%                 case 2
%                     datapkg = varargin{1};
%                     d = obj.deltaFunction(datapkg.data, datapkg.label);
%                 case 3
%                     data  = varargin{1};
%                     label = varargin{2};
%                     d = obj.deltaFunction(data, label);
%                 otherwise
%                     error('UMPrest:RuntimeError', 'Should not happen');
%             end
%         end
    end
    
    methods
        function obj = Likelihood(type, varargin)
        % TBC : make parameters of function configurable by VARARGIN
            switch lower(type)
              case {'mse', 'gaussian'}
                obj.type          = 'MSE';
                obj.evalFunction  = @MathLib.mse;
                obj.deltaFunction = @MathLib.mseGradient;
                
              case {'logistic'}
                obj.type          = 'Logistic';
                obj.evalFunction  = @MathLib.logistic;
                obj.deltaFunction = @MathLib.logisticGradient;
                
              case {'kld', 'kldiv', 'kldivergence'}
                obj.type          = 'KL-Divergence';
                obj.evalFunction  = @MathLib.kldiv;
                obj.deltaFunction = @MathLib.kldivGradient;
                
              otherwise
                error('UMPrest:ArgumentError', 'Unrecognized likelihood : %s', ...
                      upper(type));
            end
        end
    end
    
    properties (SetAccess = private)
        type
    end
    properties (Access = private)
        evalFunction
        deltaFunction
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
