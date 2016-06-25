classdef Unit < handle
    methods
        function datapkgOut = forward(obj, datapkgIn)
            dataIn = datapkgIn.data;
            if iscell(dataIn)
                dataOut = cell(1, numel(dataIn));
                for i = 1 : numel(dataIn)
                    dataOut{i} = obj.transform(dataIn{i});
                end
                datapkgOut = datapkgIn.derive('data', dataOut);
            else
                datapkgOut = datapkgIn.derive('data', obj.transform(dataIn));
            end
        end
        
        function datapkgIn = backward(obj, datapkgOut)
            dataOut = datapkgOut.data;
            if iscell(dataOut)
                dataIn = cell(1, numel(dataOut));
                for i = 1 : numel(dataOut)
                    dataIn{i} = obj.transform(dataOut{i});
                end
                datapkgIn = datapkgOut.derive('data', dataIn);
            else
                datapkgIn = datapkgOut.derive('data', obj.transform(dataOut));
            end
        end
        
        function delta = errprop(obj, delta)
            if iscell(delta)
                buffer = cell(1, numel(delta));
                for i = 1 : numel(buffer)
                    buffer{i} = obj.deltaproc(delta{i}, true);
                end
                delta = buffer; % PROPOSAL: try to reunify it to matrix again
            else
                delta = obj.deltaproc(delta, true);
            end
        end
    end
    
    methods
        function y = transform(obj, x)
            y = obj.transproc(x);
            
            obj.I = x; 
            obj.O = y;
        end
        
        function x = inference(obj, y)
            x = obj.inferproc(y);
            
            obj.I = x;
            obj.O = y;
        end
    end
    
    methods
        function dataIn = inferproc(obj, dataOut)
            warning('UMPrest:OperationUnavailable', 'This method has not been implemented');
            sizeIn = [obj.size('in'), numel(dataOut) / prod(obj.size('out'))];
            dataIn = OptimLib.minimize( ...
                @obj.objfuncOfInference, ...
                randn(prod(sizeIn)), ...
                OptimLib.config('default'), ...
                dataOut, sizeIn);
            dataIn = reshape(dataIn, sizeIn);
        end
        
        function [value, grad] = objfuncOfInference(obj, dataIn, dataOut, sizeIn)
            dataIn  = reshape(dataIn, sizeIn);
            dataGet = obj.transproc(dataIn);
            value = MathLib.mse(dataGet, dataOut);
            if not(empty(obj.prior))
                value = value + obj.prior(dataGet);
            end
            if nargout > 1
                grad = obj.deltaproc(MathLib.mseGradient(dataGet, dataOut));
                if not(empty(obj.prior))
                    grad = grad + obj.prior.delta(dataIn);
                end
                grad = grad(:);
            end
        end
    end
    methods (Abstract)
        y = transproc(obj, x)
        d = deltaproc(obj, d, isEvolving)
        s = size(obj, io)
    end
    
    properties (Hidden)
        I, O
    end
end
