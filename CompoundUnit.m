classdef CompoundUnit < Unit
    methods
        function obj = CompoundUnit(model)
            if exist('model', 'var')
                obj.init(model);
            end
        end
        
        function init(obj, model)
            obj.model = model;
            % setup FORWARD/BACKWARD methods
            obj.forward  = @obj.model.forward;
            obj.backward = @obj.model.backward;
            % setup I/O access points
            obj.I = cell2array(arrayfun( ...
                @(ap) GhostAP(obj, ap), obj.model.I, 'UniformOutput', false));
            obj.O = cell2array(arrayfun( ...
                @(ap) GhostAP(obj, ap), obj.model.O, 'UniformOutput', false));
            % prevent modification of the model
            model.freeze();
        end
    end
    
    properties (SetAccess = protected, Hidden)
        model, I, O
    end
    methods
        function set.model(obj, value)
            assert(isa(value, 'Model'), 'ILLEGAL OPERATION');
            obj.model = value;
        end
        
        function set.I(obj, value)
            assert(all(arrayfun(@(ap) isa(ap, 'GhostAP'), value)), ...
                'ILLEGAL OPERATION');
            obj.I = value;
        end
        
        function set.O(obj, value)
            assert(all(arrayfun(@(ap) isa(ap, 'GhostAP'), value)), ...
                'ILLEGAL OPERATION');
            obj.O = value;
        end
    end
end
