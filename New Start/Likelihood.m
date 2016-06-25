classdef Likelihood < Objective
    methods
        function value = evaluate(obj, datapkg)
            value = obj.evalFunction(datapkg.data, datapkg.label);
        end
        
        function d = delta(obj, datapkg)
            d = obj.deltaFunction(datapkg.data, datapkg.label);
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
                case {'mse'}
                    obj.evalFunction  = @MathLib.mse;
                    obj.deltaFunction = @MathLib.mseGradient;
                    
                case {'logistic'}
                    obj.evalFunction  = @MathLib.logistic;
                    obj.deltaFunction = @MathLib.logisticGradient;
            end
        end
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
