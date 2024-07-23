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
                [xdata, refdata] = ignoreMissing(x.data, ref.data);
            else
                [xdata, refdata] = ignoreMissing(x, ref);
            end

            if isempty(obj.weight)
                value = obj.evalFunction(xdata, refdata);
            else
                value = obj.evalFunction(xdata, refdata, obj.weight);
            end

            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
        
        function d = delta(obj, x, ref)
            if not(exist('x', 'var'))
                x   = obj.x.pop();
                ref = obj.ref.pop();
            end

            if isa(x, 'DataPackage')
                [xdata, refdata] = ignoreMissing(x.data, ref.data);
            else
                [xdata, refdata] = ignoreMissing(x, ref);
            end

            if isempty(obj.weight)
                d = obj.deltaFunction(xdata, refdata);
            else
                d = obj.deltaFunction(xdata, refdata, obj.weight);
            end

            if isa(x, 'DataPackage')
                d = ErrorPackage(d, x.dsample, x.taxis, true);
                if nargout == 0
                    obj.x.send(d);
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
                    
                case {'cross-entropy', 'cross'}
                    obj.type          = 'Cross-Entropy';
                    obj.evalFunction  = @MathLib.crossEntropy;
                    obj.deltaFunction = @MathLib.crossEntropyGradient;
                    
                otherwise
                    error('UMPrest:ArgumentError', 'Unrecognized likelihood : %s', ...
                        upper(type));
            end
            % TODO: more comprehensive setup of Weight Mechanism
            if exist('weight', 'var')
                obj.weight = weight;
            end
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

% Remove NaN and Inf from data
function [A,B] = ignoreMissing(A,B)
iNaN = isnan(A) | isnan(B);
iInf = isinf(A) | isinf(B);
index = iNaN | iInf;
A(index) = 0;
B(index) = 0;

if any(iNaN, 'all')
    warning('NaN should not appear!');
end
end
