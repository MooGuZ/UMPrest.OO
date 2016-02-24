% HMODEL is an abstraction of learning model in hierarchy structure
%
% MooGu Z <hzhu@case.edu>
% Feb 17, 2016

classdef HModel < Model
    % ================= API  =================
    methods
        % feedforward data process
        function output = proc(obj, input)
            data = input.x;
            
            unit = obj.first;
            while ~isempty(unit)
                data = unit.proc(data);
                unit = unit.next;
            end
            
            output.x = data;
            
            obj.I = input;
            obj.O = output;
        end
        
        % back-propagation methods to update model
        function delta = bprop(obj, delta)
            assert(~isempty(obj.optimizer), ...
                   '[LMODEL:BPROP] optimizer is not available');
            % traverse units backwards
            unit = obj.last;
            while ~isempty(unit)
                delta = unit.bprop(delta, obj.optimizer);
                unit  = unit.prev;
            end
        end
        
        function trainproc(obj, input)
            if isempty(obj.optimizer)
                warning('[%s] optimizer is not available.\n Training Aborded.', ...
                        class(obj));
                return
            end
            output = obj.proc(input);
            obj.bprop(obj.delta(output.x, input.y));
        end
        
        function dim = dimin(obj, dimout)
            if exist('dimout', 'var')
                unit = obj.last;
                dim  = dimout;
                while ~isnan(unit)
                    dim = unit.dimin(dim);
                    unit = unit.prev;
                end
            else                
                dim = obj.first.dimin();
            end
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
        
    % ================= ASSISTANT METHOD =================
    methods
        function unit = addUnit(obj, unit)
            assert(isa(unit, 'Connectable'));
            if obj.size == 0
                obj.U = {unit};
            elseif unit.connect(obj.last)
                obj.U = [obj.U, {unit}];
            else
                warning('[%s] Connection failed, new unit can not add to the model.');
            end
        end
    end
    
    % ================= DATA & PARAM =================
    properties (Access = protected)
        U                               % stack of learning units
    end
    
    % ================= FUNCTIONAL PROP =================
    properties (Dependent)
        size                            % number of learning units
        first                           % first unit of model
        last                            % last unit of model
    end
    methods
        function value = get.size(obj)
            value = numel(obj.U);
        end
        
        function unit = get.first(obj)
            unit = [];
            if obj.size > 0
                unit = obj.U{1};
            end
        end
        
        function unit = get.last(obj)
            unit = [];
            if obj.size > 0
                unit = obj.U{end};
            end
        end
    end        
end
