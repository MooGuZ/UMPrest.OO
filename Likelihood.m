% TBC : add properties containing the type of likelihood
classdef Likelihood < Objective
    methods
        function value = evaluate(obj, x, ref)
            if isa(x, 'DataPackage')
                if isempty(obj.weight)
                    value = obj.evalFunction(x.data, ref.data);
                else
                    value = obj.evalFunction(x.data, ref.data, obj.weight);
                end
                    
            else
                if isempty(obj.weight)
                    value = obj.evalFunction(x, ref);
                else
                    value = obj.evalFunction(x, ref, obj.weight);
                end
            end
        end
        
        function d = delta(obj, x, ref)
            if isa(x, 'DataPackage')
                if isempty(obj.weight)
                    d = obj.deltaFunction(x.data, ref.data);
                else
                    d = obj.deltaFunction(x.data, ref.data, obj.weight);
                end
                d = ErrorPackage(d, x.dsample, x.taxis);
            else
                if isempty(obj.weight)
                    d = obj.deltaFunction(x, ref);
                else
                    d = obj.deltaFunction(x, ref, obj.weight);
                end
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
        function obj = Likelihood(type, weight)
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
            
            if exist('weight', 'var')
                obj.weight = weight;
            end
        end
    end
    
    properties
        weight
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
