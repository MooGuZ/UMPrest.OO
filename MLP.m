% MLP (MutiLayer Perceptron) is the abstraction of multiple layer neural network
% model. 
%
% MooGu Z. <hzhu@case.edu> 
% Feb 11, 2016
classdef MLP < DPModule
    % ================= LMODEL IMPLEMENTATION =================
    methods
        function y = proc(obj, data)
            y = obj.process(data.x);
        end
        
        
        
        function value = evaluate(~, output, ref)
            value = MathLib.logistic(output, ref);
        end
        
        function signal = impulse(~, output, ref)
            signal = MathLib.logistic_derv(output, ref);
        end
    end
    
    methods
        function y = process(obj, x)
            unit = obj.first;
            
        
        
    end
    % ================= Constructor =================
    methods
        function obj = MLP(numElemArr, activateType)
            nunit = numel(numElemArr) - 1;
            
            % check validity of input arguments
            assert(nunit > 1, 'At lest one Perceptron is needed for MLP.');
            assert((iscellstr(activateType) && numel(activateType) == nunit) ...
                   || ischar(activateType));
            
            % construct perceptrons
            for i = 1 : nunit
                obj.addUnit(Perceptron( ...
                    numElemArr(i), ...
                    numElemArr(i+1), ...
                    ite(ischar(activateType), activateType, activateType{i}));
            end
        end
    end
end
