classdef LinearTransform < EvolvingUnit
    methods
        function y = transproc(obj, x)
            if size(x, 2) > 1
                y = bsxfun(@plus, obj.weight * x, obj.bias);
            else
                y = obj.weight * x + obj.bias;
            end
        end
        
        function d = deltaproc(obj, d, isEvolving)
            d = obj.weight' * d;
            if isEvolving
                obj.B.addgrad(sum(d, 2));
                obj.W.addgrad(d * obj.I');
            end
        end
        
        function update(obj)
            obj.W.update();
            obj.B.update();
        end
    end
    
    methods
        function sz = size(obj)
            sz = fliplr(size(obj.W));
        end
    end
    
    methods
        function obj = LinearTransform(inputSize, outputSize)
            % Initialize weight to uniform distribution in the suggestion
            % range inverse proportional to square root of input element
            % quantity. While, bias are initialized as zeros.
            obj.W = HyperParam((rand(outputSize, inputSize) - 0.5) * (2 / sqrt(inputSize)));
            obj.B = HyperParam(zeros(outputSize, 1));
        end
    end
    
    methods (Static)
        function inferDebug()
            sizeIn  = 32;
            sizeOut = 16;
            groudTruth = LinearTransform(sizeIn, sizeOut);
            simulation = GenerativeModel(LinearTransform(sizeIn, sizeOut));
            datasource = DataGenerator('gauss', sizeIn);
            ds = VirtualDataset(datasource, groudTruth);
            simulation.train(ds, Likelihood('mse'));
        end
    end
    
    properties (Access = private)
        W, B
    end
    
    properties (Dependent)
        weight
        bias
    end
    methods
        function value = get.weight(obj)
            value = obj.W.get();
        end
        function set.weight(obj, value)
            obj.W.set(value);
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
end
