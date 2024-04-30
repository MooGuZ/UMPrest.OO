classdef Evolvable < handle
    methods (Abstract)
        % HPARAM returns cell array of all hyper-parameters in the unit. For SimpleUnit, 
        % the implementation should be a list of all defined hyper-parameters, while, 
        % CompoundUnit and Model would defined as cycle over its sub-units.
        hpcell = hparam(obj)
    end
    % !!!NEED TO BE TESTED!!!
    % automatically list all parameter members
    methods
        function hpcell = paramlist(obj)
            if isempty(obj.hpmem)
                proplist = properties(obj);
                index = cellfun(@(pname) isa(obj.(pname), 'HyperParam'), proplist);
                obj.hpmem = cellfun(@(pname) obj.(pname), proplist(index));
            end
            hpcell = obj.hpmem;
        end
    end
    properties (Hidden, Access=private)
        hpmem
    end
    
    % NOTE: implementation of following methods is for SimpleUnit. Rewriting is needed to
    %       them work properly in CompoundUnit and Model.
    methods
        function unitdump = dump(obj)
            hpcell = obj.hparam();
            unitdump = cell(1, numel(hpcell));
            for i = 1 : numel(hpcell)
                unitdump{i+1} = hpcell{i}.getcpu();
            end
            unitdump{1} = class(obj);
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
        
        function obj = freeze(obj)
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
        
        function tf = isfrozen(obj)
            hpcell = obj.hparam();
            tf = hpcell{1}.frozen;
        end
        
        function addnoise(obj, stdvar)
            hpcell = obj.hparam();
            for i = 1 : numel(hpcell)
                hpcell{i}.addnoise(stdvar);
            end
        end
    end
end