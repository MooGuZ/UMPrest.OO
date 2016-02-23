% HMODEL is an abstraction of learning model in hierarchy structure
%
% MooGu Z <hzhu@case.edu>
% Feb 17, 2016

classdef HModel < Unit
    % ================= API  =================
    methods
        % feedforward data process
        function output = proc(obj, input)
            if isstruct(input)
                input = input.x;
            end
            % traverse units to get output
            unit = obj.first;
            data = input;
            while ~isnan(unit)
                data = unit.feedforward(data);
                unit = unit.next;
            end
            output = data;
            % record input and output
            obj.I = input;
            obj.O = output;
        end
        
        % back-propagation methods to update model
        function delta = bprop(obj, delta)
            assert(~isempty(obj.optimizer), ...
                   '[LMODEL:BPROP] optimizer is not available');
            % traverse units backwards
            unit = obj.last;
            while ~isnan(unit)
                delta = unit.bprop(signal, obj.optimizer);
                unit  = unit.prev;
            end
        end
        
        function trainproc(obj, input)
            output = obj.proc(input);
            obj.bprop(obj.delta(output, input.y));
        end
        
        function dim = dimin(obj)
            dim = obj.first.dimin();
        end
        
        function dim = dimout(obj, dimin)
            if exist('dimin', 'var')
                unit = obj.first;
                dim  = dimin;
                while ~isnan(unit)
                    dim = unit.dimout(dim);
                    unit = unit.next;
                end
            else
                dim = obj.last.dimout();
            end
        end
    end
    
    % ============= INTERFACE =============
    methods (Abstract)
        % objective function 
        value = objective(obj, output, ref)
        % calculate delta of output according to objective function
        d = delta(obj, output, ref)
    end
        
    % ================= ASSISTANT METHOD =================
    methods
        function unit = addUnit(obj, unit)
            assert(isa(unit, 'Unit'));
            unit.connect(obj)
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        U                               % stack of learning units
        I                               % input state of model
        O                               % output state of model
    end
    properties (Abstract)
        optimizer
    end
    
    % ================= FUNCTIONAL PROP =================
    properties (Dependent, Access = protected)
        size                            % number of learning units
        first                           % first unit of model
        last                            % last unit of model
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
