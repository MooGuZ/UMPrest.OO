% MLP (MutiLayer Perceptron) is the abstraction of multiple layer neural network
% model. 
%
% MooGu Z. <hzhu@case.edu> 
% Feb 11, 2016
classdef MLP < HModel
% ================= HMODEL IMPLEMENTATION =================
    methods
        function value = objective(~, y, ref)
            value = MathLib.logistic(y, ref);
        end
        
        function d = delta(~, y, ref)
            d = MathLib.logistic_derv(y, ref);
        end
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



