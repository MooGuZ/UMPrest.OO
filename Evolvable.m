classdef Evolvable < handle
    methods (Abstract)
        % HPARAM returns cell array of all hyper-parameters in the unit. For SimpleUnit, 
        % the implementation should be a list of all defined hyper-parameters, while, 
        % CompoundUnit and Model would defined as cycle over its sub-units.
        hpcell = hparam(obj)
    end
    
    % NOTE: implementation of following methods is for SimpleUnit. Rewriting is needed to
    %       them work properly in CompoundUnit and Model.
    methods
        function datamat = dump(obj)
            hpcell  = obj.hparam();
            datamat = cell(1, numel(hpcell));
            for i = 1 : numel(hpcell)
                datamat{i+1} = hpcell{i}.getcpu();
            end
            datamat{1} = class(obj);
        end
        
        function rawdata = dumpraw(obj)
            hpcell = obj.hparam();
            for i = 1 : numel(hpcell)
                hpcell{i} = vec(hpcell{i}.get());
            end
            rawdata = cat(1, hpcell{:});
        end
        
        function update(obj)
            hpcell = obj.hparam();
            for i = 1 : numel(hpcell)
                hpcell{i}.update();
            end
        end
        
        function freeze(obj)
            hpcell = obj.hparam();
            for i = 1 : numel(hpcell)
                hpcell{i}.cleanup();
                hpcell{i}.frozen = true;
            end
        end
        
        function unfreeze(obj)
            hpcell = obj.hparam();
            for i = 1 : numel(hpcell)
                hpcell{i}.frozen = false;
            end
        end
    end
    
    methods (Static)
        function unit = loaddump(unitdump)
            for i = 2 : numel(unitdump)
                element = unitdump{i};
                if iscell(element)
                    unitdump{i} = Evolvable.loaddump(element);
                end
            end
            unit = feval(unitdump{:});
        end
    end
end