% TODO: use element wise functions here, don't sum up the each element for
%       convenience of dealing with weight problem.
classdef Likelihood < Objective
    methods
        % TODO: apply weight functions in EVALUATION and DELTA
        function value = evaluate(obj, x, ref)
            if not(exist('x', 'var'))
                x   = obj.x.pop();
                ref = obj.ref.pop();
            end
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
            if not(exist('x', 'var'))
                x   = obj.x.pop();
                ref = obj.ref.pop();
            end
            if isa(x, 'DataPackage')
                if isempty(obj.weight)
                    d = obj.deltaFunction(x.data, ref.data);
                else
                    d = obj.deltaFunction(x.data, ref.data, obj.weight);
                end
                d = ErrorPackage(d, x.dsample, x.taxis);
                if nargout == 0
                    obj.x.push(d);
                end
            else
                if isempty(obj.weight)
                    d = obj.deltaFunction(x, ref);
                else
                    d = obj.deltaFunction(x, ref, obj.weight);
                end
            end
        end
    end
    
    methods
        function enableWeight(obj, varargin)
            conf = Config(varargin);
            obj.weight = struct( ...
                'status', true, ...
                'taxis',  conf.pop('taxisWeight', []), ...
                'daxis',  conf.pop('daxisWeight', []));
        end
        
        function disableWeight(obj)
            obj.weight = struct('status', false);
        end
    end
    
    methods
        function obj = Likelihood(type, weight)
            % TODO: make parameters of function configurable by VARARGIN
            % TODO: replace current functions with element based ones
            switch lower(type)
                case {'mse', 'gaussian'}
                    obj.type          = 'MSE';
                    obj.evalFunction  = @MathLib.mse;
                    obj.deltaFunction = @MathLib.mseGradient;
                    
                case {'tmse'}
                    obj.type          = 'TMSE';
                    obj.evalFunction  = @(x, ref) MathLib.tmse(x, ref, weight);
                    obj.deltaFunction = @(x, ref) MathLib.tmseGradient(x, ref, weight);
                    
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
            % TODO: more comprehensive setup of Weight Mechanism
            % if exist('weight', 'var')
            %     obj.weight = weight;
            % end
            % initialize access-points
            obj.x   = SimpleAP(obj);
            obj.ref = SimpleAP(obj);
        end
    end
    
    properties
        x, ref, weight
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
