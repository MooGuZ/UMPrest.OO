% LMODLE is an abstraction of learning model
%
% MooGu Z <hzhu@case.edu>
% Feb 17, 2016

classdef LModel < handle
    % ================= API =================
    methods
        % feedforward data process
        [output, target] = produce(obj, data)
        % evaluate given state
        value = evaluate(obj, output, target)
        % generate impulse single under current state for evolution
        signal = impulse(obj, output, target)
        % let model envolve according to impulse signal
        evolve(obj, signal, opt)
    end
    
    % ================= DATA & PARAM =================
    properties
        U = cell(0) % stack of learning units
    end
    
    % ================= FUNCTIONAL PROP =================
    properties (Dependent)
        size
    end
    methods
        function value = get.size(obj)
            value = Stack.size(obj.U);
        end
    end        
end
