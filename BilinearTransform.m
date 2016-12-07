classdef BilinearTransform < MIMOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(obj, a, b)
            y = bsxfun(@plus, obj.weightA * a + obj.weightB * b, obj.bias);
        end
        
        function [da, db] = deltaproc(obj, d)
            obj.B.addgrad(sum(d, 2));
            obj.WA.addgrad(d * obj.IA.state.data');
            obj.WB.addgrad(d * obj.IB.state.data');
            da = obj.weightA' * d;
            db = obj.weightB' * d;
        end
        
        function update(obj)
%             fprintf('[WA]   ');
            obj.WA.update();
%             fprintf('[WB]   ');
            obj.WB.update();
%             fprintf('[BIAS] ');
            obj.B.update();
        end
        
        % PRB: not completely rule out all bad conditions
        function sizeout = sizeIn2Out(obj, sizeinA, sizeinB)
            assert(sizeinA(2) == sizeinB(2), 'ILLEGAL ARGUMENT');
            sizeout = [size(obj.WA, 1), sizeinA(2)];
        end
        
        function [sizeinA, sizeinB] = sizeOut2In(obj, sizeout)
            sizeinA = [size(obj.WA, 2), sizeout(2)];
            sizeinB = [size(obj.WB, 2), sizeout(2)];
        end
    end
    
    methods
        function obj = BilinearTransform(weightA, weightB, bias)
            obj.WA = HyperParam(weightA);
            obj.WB = HyperParam(weightB);
            obj.B  = HyperParam(bias);
            % craete access points
            obj.IA = UnitAP(obj, 1);
            obj.IB = UnitAP(obj, 1);
            obj.I  = [obj.IA, obj.IB];
            obj.O  = UnitAP(obj, 1);
        end
    end
    
    methods (Static)
        function obj = randinit(sizeA, sizeB, sizeO)
            wa = (rand(sizeO, sizeA) - 0.5) * (2 / sqrt(sizeA));
            wb = (rand(sizeO, sizeB) - 0.5) * (2 / sqrt(sizeB));
            b  = zeros(sizeO, 1);
            obj = BilinearTransform(wa, wb, b);
        end
    end
    
    properties (Constant)
        taxis      = false;
        expandable = false;
    end
    
    properties (SetAccess = protected)
        IA, IB
    end
    
    properties (Access = protected)
        WA, WB, B
    end
    properties (Dependent)
        weightA, weightB, bias
    end
    methods
        function value = get.weightA(obj)
            value = obj.WA.get();
        end
        function set.weightA(obj, value)
            obj.WA.set(value);
        end
        
        function value = get.weightB(obj)
            value = obj.WB.get();
        end
        function set.weightB(obj, value)
            obj.WB.set(value);
        end
        
        function value = get.bias(obj)
            value = obj.B.get();
        end
        function set.bias(obj, value)
            obj.B.set(value);
        end
    end
    
    methods (Static)
        function debug()
            sizeinA = 64; 
            sizeinB = 32;
            sizeout = 48;
            model   = BilinearTransform.randinit(sizeinA, sizeinB, sizeout);
            wa    = randn(sizeout, sizeinA); 
            wb    = randn(sizeout, sizeinB);
            bias  = randn(sizeout, 1);
            refer = BilinearTransform(wa, wb, bias);
            likelihood = Likelihood('mse');
            % create validate set
            nValid = 1e2;
            validsetInA = DataPackage(randn(sizeinA, nValid), 1, false);
            validsetInB = DataPackage(randn(sizeinB, nValid), 1, false);
            validsetOut = refer.forward(validsetInA, validsetInB);
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                likelihood.evaluate( ...
                model.forward(validsetInA, validsetInB).data, ...
                validsetOut.data));
            batchsize = 8;
            for i = 1 : UMPrest.parameter.get('iteration')
                apkg = DataPackage(randn(sizeinA, batchsize), 1, false);
                bpkg = DataPackage(randn(sizeinB, batchsize), 1, false);
                opkg = refer.forward(apkg, bpkg);
                model.backward(likelihood.delta(model.forward(apkg, bpkg), opkg));
                model.update();
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    likelihood.evaluate( ...
                    model.forward(validsetInA, validsetInB).data, ...
                    validsetOut.data));
            end
            % show result
            distinfo(abs(wa - model.weightA), 'WeightA Error');
            distinfo(abs(wb - model.weightB), 'WeightB Error');
            distinfo(abs(bias - model.bias),  'Bias Error');
        end
    end
end
