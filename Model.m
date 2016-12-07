classdef Model < Interface & Evolvable
    methods
        % PRB: package leak to units which is not in the Model
        function varargout = forward(obj, varargin)
            obj.prepare();
            % load each input units with given package
            if not(isempty(varargin))
                arrayfun(@(i) obj.I(i).push(varargin{i}), 1 : numel(obj.I));
            end
            % data package backward propagation
            cellfun(@forward, obj.nodes);
            % collect output package
            varargout = arrayfun(@(ap) ap.state.package, obj.O, ...
                'UniformOutput', false);
        end
        
        function varargout = backward(obj, varargin)
            obj.prepare();
            % load each input units with given package
            if not(isempty(varargin))
                arrayfun(@(i) obj.O(i).push(varargin{i}), 1 : numel(obj.O));
            end
            % data package backward propagation
            cellfun(@backward, obj.nodes(end : -1 : 1));
            % collect output package
            varargout = arrayfun(@(ap) ap.state.package, obj.I, ...
                'UniformOutput', false);
        end
    end
    
    methods
        function varargout = sizeIn2Out(obj, varargin)
            assert(numel(varargin) == numel(obj.I), 'ILLEGAL ARGUMENT');
            % load SIZEPACKAGE to each input ACCESSPOINT
            arrayfun(@(i) obj.I(i).push(SizePackage(varargin{i})), varargin, ...
                     'UniformOutput', false);
            % pass SIZEPACKAGE through the model
            obj.forward();
            % collect output SIZE information
            varargout = arrayfun(@(ap) ap.state.data, obj.O, ...
                                 'UniformOutput', false);
        end
        
        function varargout = sizeOut2In(obj, varargin)
            assert(numel(varargin) == numel(obj.O), 'ILLEGAL ARGUMENT');
            % load SIZEPACKAGE to each input ACCESSPOINT
            arrayfun(@(i) obj.O(i).push(SizePackage(varargin{i})), varargin, ...
                     'UniformOutput', false);
            % pass SIZEPACKAGE through the model
            obj.backward();
            % collect output SIZE information
            varargout = arrayfun(@(ap) ap.state.data, obj.I, ...
                                 'UniformOutput', false);
        end
    end
    
    methods
        function update(obj)
            index = cellfun(@(node) isa(node, 'Evolvable'), obj.nodes);
            cellfun(@update, obj.nodes(index));
        end
    end

    methods
        function prepare(obj)
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
        
        function clear(obj)
            cellfun(@clear, obj.nodes);
        end
    end
    
    methods
        function add(obj, varargin)
            for i = 1 : numel(varargin)
                node = varargin{i};
                if iscell(node)
                    cellfun(@(unit) obj.add(unit), node);
                elseif isa(node, 'Model')
                    cellfun(@(unit) obj.add(unit), node.nodes);
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
                    prevID = unit.I(i).links{j}.parent.id;
                    if obj.id2ind.isKey(prevID)
                        noPrevUnit = false;
                        prevIndex = obj.id2ind(prevID);
                        obj.edges{prevIndex} = unique( ...
                            [obj.edges{prevIndex}, index]);
                        % remove this AP from OBJ.O
                        obj.O(obj.O == unit.I(i).links{j}) = [];
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
                    postID = unit.O(i).links{j}.parent.id;
                    if obj.id2ind.isKey(postID)
                        noPostUnit = false;
                        postIndex = obj.id2ind(postID);
                        obj.edges{index} = unique( ...
                            [obj.edges{index}, postIndex]);
                        % remove this AP from OBJ.I
                        obj.I(obj.I == unit.O(i).links{j}) = [];
                    end
                end
                if noPostUnit
                    obj.O = [obj.O, unit.O(i)];
                end
            end
        end
        
        function topologicalSort(obj)
            states = false(1, numel(obj.nodes));
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
            if not(states(root))
                states(root) = true;
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
    end
    
    methods
        function obj = Model(varargin)
            obj.nodes    = {};
            obj.edges    = {};
            obj.I        = [];
            obj.O        = [];
            obj.id2ind   = containers.Map( ...
                'KeyType', 'char', 'ValueType', 'any');
            obj.sorted   = true;
            % initialize model with given components
            obj.add(varargin{:});
        end
    end
    
    % ======================= CONVERTER FUNCTION =======================
    methods
        function cunit = CompoundUnit(obj)
            cunit = CompoundUnit();
            cunit.init(obj);
        end
    end
    
    properties (SetAccess = protected)
        nodes, edges, id2ind, sorted
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
end
