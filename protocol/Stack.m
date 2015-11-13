classdef Stack < hgsetget
    methods (Abstract)
        % ### [obj] ----> (size) ----> n
        n = size(obj)
        % ### unit ----> (push) --update--> [obj]
        push(unit)
        % ### [obj] ----> (pop) ----> unit
        % ###   <___update__|
        unit = pop(obj)
    end
end
