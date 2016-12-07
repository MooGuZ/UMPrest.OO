classdef Interface < handle
    methods
        function connect(obj, anotherUnit)
            assert(numel(obj.O) == numel(anotherUnit.I), 'ILLEGAL OPERATION');
            arrayfun(@(i) obj.O(i).connect(anotherUnit.I(i)), 1 : numel(obj.O));
        end
        
        function oneway(obj, anotherUnit)
            assert(numel(obj.O) == numel(anotherUnit.I), 'ILLEGAL OPERATION');
            arrayfun(@(i) obj.O(i).addlink(anotherUnit.I(i)), 1 : numel(obj.O));
        end
    end
    
    methods (Abstract)
        varargout = forward(obj, varargin)
        varargout = backward(obj, varargin)
    end
    
    properties (SetAccess = protected)
        I, O % container of Input/Output AccessPoints
    end
    methods
        function set.I(obj, value)
            assert(all(arrayfun(@(e) isa(e, 'AccessPoint'), value)), 'ILLEGAL OPERATION');
            obj.I = value;
        end
        
        function set.O(obj, value)
            assert(all(arrayfun(@(e) isa(e, 'AccessPoint'), value)), 'ILLEGAL OPERATION');
            obj.O = value;
        end
    end
end
