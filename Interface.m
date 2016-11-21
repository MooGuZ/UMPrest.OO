classdef Interface < handle
% INTERFACE defines common methods and properties between Unit and Model
    methods (Abstract)
        varargout = forward(obj, varargin)
        varargout = backward(obj, varargin)
    end
    
    properties
        I, O
    end
    
    methods
        function connectTo(obj, unit)
            assert(numel(obj.O) == numel(unit.I), 'UMPrest:Runtime', 'RUNTIME');
            arrayfun(@AccessPoint.connect, obj.O, unit.I);
        end
        
        function connectOneWayTo(obj, unit)
            assert(numel(obj.O) == numel(unit.I), 'UMPrest:Runtime', 'RUNTIME');
            arrayfun(@AccessPoint.connectOneWay, obj.O, unit.I);
        end
    end
end
