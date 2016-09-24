classdef NullUnit < Unit
    methods
        function x = transform(~, x), end
        function y = compose(~, y),   end
        function d = errprop(~, d),   end
    end
    
    methods
        function unit = inverseUnit(obj)
            unit = obj;
        end
    end
    
    properties (Dependent, Hidden)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(~)
            value = SizeDescription.format(inf);
        end
        
        function description = sizeIn2Out(~, description), end
    end
end
