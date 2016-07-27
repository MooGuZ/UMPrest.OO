classdef SequentialModel < Model & MappingUnit
    % ======================= DATA PROCESSING =======================
    methods
        function data = process(obj, data)
            for i = 1 : numel(obj.nodes)
                data = obj.nodes{i}.unit.transform(data);
            end
        end
        
        function d = errprop(obj, d, isEvolving)
            if not(exist('isEvolving', 'var'))
                isEvolving = true;
            end
            
            for i = numel(obj.nodes) : -1 : 1
                d = obj.nodes{i}.unit.errprop(d, isEvolving);
            end
        end
        
        function update(obj, stepsize)
            index = cellfun(@(nd) isa(nd.unit, 'EvolvingUnit'), obj.nodes);
            if exist('stepsize', 'var')
                cellfun(@(nd) nd.unit.update(stepsize), obj.nodes(index));
            else
                cellfun(@(nd) nd.unit.update(), obj.nodes(index));
            end
        end
    end
    
    % ======================= TOPOLOGY LOGIC =======================
    methods
        function appendUnit(obj, unit)
            node = Node(unit);
            if isempty(obj.nodes)
                obj.root(node);
                obj.nodes = {node};
            else
                obj.connect(obj.nodes{end}, node);
                obj.nodes = [obj.nodes, {node}];
            end
            obj.outputSizePattern = SizeDescription.getPattern( ...
                obj.nodes{1}.inputSizeDescription, ...
                obj.nodes{end}.outputSizeDescription);
        end
        
        function node = iterator(obj, index)
            node = obj.nodes{index};
        end
    end
    
    methods
        function unit = inverseUnit(obj)
            unit = SequentialModel();
            for i = numel(obj.nodes) : -1 : 1
                unit.appendUnit(obj.nodes{i}.inverseUnit());
            end
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent)
        inputSizeRequirement
    end
    properties
        outputSizePattern
    end
    methods
        function value = get.inputSizeRequirement(obj)
            if isempty(obj.nodes)
                value = sym.inf();
            else
                value = obj.nodes{1}.inputSizeDescription;
            end
        end
        
        function set.outputSizePattern(obj, value)
            assert(isstruct(value) && all(isfield(value, {'in', 'out'})));
            assert(SizeDescription.islegal(value.in) && ...
                   SizeDescription.isconcrete(value.out));
            obj.outputSizePattern = value;
            obj.outputSizeDescriptionCache = [];
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = SizeDescription.applyPattern( ...
                descriptionIn, obj.outputSizePattern);
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = SequentialModel()
            obj = obj@Model();
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        nodes
        logger
        tasktype
    end
    methods
        function set.tasktype(obj, value)
            assert(isempty(value) || ...
                (ischar(value) && any(strcmpi(value, Task.typelist()))));
            obj.tasktype = value;
        end
    end
    
    % ======================= DEVELOPER TOOL =======================
    methods
        function showNodeDescription(obj)
            for i = 1 : numel(obj.nodes)
                node = obj.nodes{i};
                fprintf('[%s : %s] %s ---> %s\n', class(node.unit), ...
                    char(node.inputSizeRequirement), ...
                    char(node.inputSizeDescription), ...
                    char(node.outputSizeDescription));
            end
        end
    end
end
