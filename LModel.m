% LMODEL is an abstraction of learning model
%
% MooGu Z <hzhu@case.edu>
% Feb 17, 2016

classdef LModel < handle
    % ================= API =================
    methods
        % decompose data into functional parts
        [input, ref] = decompose(dat)
        % feedforward data process
        function output = produce(obj, input)
            unit = obj.first;
            data = input;
            while ~isnan(unit)
                data = unit.feedforward(data);
                unit = unit.next;
            end
            output = data;
        end
        % evaluate given state
        value = evaluate(obj, output, ref)
        % generate impulse single under current state for evolution
        signal = impulse(obj, output, ref)
        % let model envolve according to impulse signal
        function signal = evolve(obj, signal, opt)
            unit = obj.last;
            while ~isnan(unit)
                signal = unit.backpropagate(signal, opt);
                unit = unit.prev;
            end
        end
    end
    
    % ================= ASSISTANT METHOD =================
    methods
        function unit = addUnit(obj, unit)
            assert(isa(unit, 'LUnit'));
            unit.connect(obj)
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        U = cell(0);                    % stack of learning units
    end
    
    % ================= FUNCTIONAL PROP =================
    properties (Dependent)
        I                               % input state of model
        O                               % output state of model
    end
    properties (Dependent, Access = protected)
        size                            % number of learning units
        first                           % first unit of model
        last                            % last unit of model
    end
    properties (Dependent, Abstract)
        dimin                           % dimension of input
        dimout                          % dimension of output
    end
    methods
        function value = get.size(obj)
            value = numel(obj.U);
        end
        
        function unit = get.first(obj)
            unit = nan;
            if obj.size > 0
                unit = obj.U{1};
            end
        end
        
        function unit = get.last(obj)
            unit = nan;
            if obj.size > 0
                unit = obj.U{end};
            end
        end
        
        function state = get.I(obj)
            state = [];
            if obj.size > 0
                state = obj.U{1}.I;
            end
        end
        
        function state = get.O(obj)
            state = [];
            if obj.size > 0
                state = obj.U{end}.O;
            end
        end
    end        
end
