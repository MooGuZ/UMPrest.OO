classdef Task < handle
    methods (Abstract)
        varargout = run(varargin)
    end
    
    properties (SetAccess = protected)
        model, dataset, objective
    end
    methods
        function set.model(obj, value)
            assert(isa(value, 'Interface'), 'ILLEGAL ASSIGNMENT');
            obj.model = value;
        end
        
%         function set.dataset(obj, value)
%             assert(iscell(value) || isa(value, 'Dataset') || isa(value, 'DataGenerator'), ...
%                 'ILLEGAL ASSIGNMENT');
%             obj.dataset = value;
%         end
        
        function set.objective(obj, value)
            assert(iscell(value) || isa(value, 'Objective'), 'ILLEGAL ASSIGNMENT');
            obj.objective = value;
        end
    end
end