classdef Model < Interface
    methods
        % PRB: package leak to units which is not in the Model
        function varargout = forward(obj, varargin)
            obj.check();
            if not(isempty(varargin))
                for i = 1 : numel(obj.I)
                    obj.I(i).push(varargin{i});
                end
            end
            for i = 1 : numel(obj.nodes)
                obj.nodes{i}.forward();
            end
            varargout = arrayfun(@(ap) ap.state.package, obj.O, 'UniformOutput', false);
        end
        
        function varargout = backward(obj, varargin)
            obj.check();
            if not(isempty(varargin))
                for i = 1 : numel(obj.I)
                    obj.O(i).push(varargin{i});
                end
            end
            for i = numel(obj.nodes) : -1 : 1
                obj.nodes{i}.backward();
            end
            varargout = AccessPoint.state.package(obj.I);
        end
        
        function check(obj)
            % ensure there is at lest one input
            if isempty(obj.I)
                error('Please use ''setAsInput'' method to setup a input access point');
            end
            % ensure there is at lest one output
            if isempty(obj.O)
                error('Please use ''setAsOutput'' method to setup a input access point');
            end
            % ensure model is topological sorted
            if not(obj.sorted)
                obj.topologicalSort();
            end
        end
    end
    
    properties
        nodes, edges
        id2ind
        sorted
    end
    properties (Dependent)
        startNodes
    end
    methods
        function value = get.startNodes(obj)
            id = unique(arrayfun(@(ap) ap.parent.id, obj.I, 'UniformOutput', false));
            value = cellfun(@(id) obj.id2ind(id), id);
        end
    end
    
    methods
        function obj = add(obj, varargin)
            for i = 1 : numel(varargin)
                node = varargin{i};
                if isa(node, 'Model')
                    for j = 1 : numel(node.nodes)
                        obj.add(node.nodes{j});
                    end
                elseif isa(node, 'Unit')
                    if not(obj.id2ind.isKey(node.id))
                        index = numel(obj.nodes) + 1;
                        obj.nodes{index} = node;
                        obj.id2ind(node.id) = index;
                        obj.updateConnections(index);
                        obj.sorted = false;
                    end
                else
                    warning('NOT AVAILABLE');
                end
            end
        end
    end
    
    methods
        % PRB: input and output are not symmetric
        function updateConnections(obj, index)
            unit = obj.nodes{index};
            obj.edges{index} = [];
            % update input connection of the unit
            for i = 1 : numel(unit.I)
                noPrevUnit = true;
                for j = 1 : numel(unit.I(i).links)
                    prevID = unit.I(i).links(j).parent.id;
                    if obj.id2ind.isKey(prevID)
                        noPrevUnit = false;
                        prevIndex = obj.id2ind(prevID);
                        obj.edges{prevIndex} = unique( ...
                            [obj.edges{prevIndex}, index]);
                        % remove this AP from OBJ.O
                        obj.O(obj.O == unit.I(i).links(j)) = [];
                    end
                end
                if noPrevUnit
                    obj.I = [obj.I, unit.I(i)];
                end
            end
            % update output connections of the unit
            for i = 1 : numel(unit.O)
                noPostUnit = true;
                for j = 1 : numel(unit.O(i).links)
                    postID = unit.O(i).links(j).parent.id;
                    if obj.id2ind.isKey(postID)
                        noPostUnit = false;
                        postIndex = obj.id2ind(postID);
                        obj.edges{index} = unique( ...
                            [obj.edges{index}, postIndex]);
                        % remove this AP from OBJ.I
                        obj.I(obj.I == unit.O(i).links(j)) = [];
                    end
                end
                if noPostUnit
                    obj.O = [obj.O, unit.O(i)];
                end
            end
        end
        
        function topologicalSort(obj)
            states = zeros(1, numel(obj.nodes));
            order  = zeros(1, numel(obj.nodes));
            index  = numel(obj.nodes);
            starts = obj.startNodes;
            for i = 1 : numel(starts)
                [states, order, index] = obj.visit(starts(i), states, order, index);
            end
            % reordering
            obj.nodes(order) = obj.nodes(:);
            for i = 1 : numel(obj.nodes)
                obj.id2ind(obj.nodes{i}.id) = i;
            end
            obj.edges(order) = obj.edges(:);
            for i = 1 : numel(obj.edges)
                obj.edges{i} = order(obj.edges{i});
            end
            % mark as sorted
            obj.sorted = true;
        end
        
        function [states, order, index] = visit(obj, root, states, order, index)
            % mark root as temporal
            states(root) = 1;
            % visit all children
            for i = 1 : numel(obj.edges{root})
                child = obj.edges{root}(i);
                if not(states(child))
                   [states, order, index] = obj.visit(child, states, order, index);
                end
            end
            % assign order
            order(root) = index;
            index = index - 1;
        end
    end
    
    methods
        function obj = Model()
            obj.nodes  = {};
            obj.edges  = {};
            obj.I      = [];
            obj.O      = [];
            obj.id2ind = containers.Map();
            obj.sorted = true;
        end
    end
end
