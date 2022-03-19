classdef Model < BuildingBlock & Evolvable
    methods
        % PRB: package leak to units which is not in the Model
        function varargout = forward(obj, varargin)
            obj.prepare();
            % load each input units with given package
            if not(isempty(varargin))
                for i = 1 : numel(obj.I)
                    obj.I{i}.push(varargin{i});
                end
            end
            % data package backward propagation
            for i = 1 : numel(obj.nodes)
                obj.nodes{i}.forward();
            end
            % collect output package
            varargout = cell(1, numel(obj.O));
            for i = 1 : numel(obj.O)
                varargout{i} = obj.O{i}.packagercd;
            end
        end
        
        function varargout = backward(obj, varargin)
            obj.prepare();
            % load each input units with given package
            if not(isempty(varargin))
                for i = 1 : numel(obj.O)
                    obj.O{i}.push(varargin{i});
                end
            end
            % data package backward propagation
            for i = numel(obj.nodes) : -1 : 1
                obj.nodes{i}.backward();
            end
            % collect output package
            varargout = cell(1, numel(obj.I));
            for i = 1 : numel(obj.I)
                varargout{i} = obj.I{i}.packagercd;
            end
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = cellfun(@hparam, obj.evolvable, 'UniformOutput', false);
            hpcell = cat(2, hpcell{:});
        end
        
        function edgedump = dumpedges(self)
            edgedump = cell(1, numel(self.edges));
            for i = 1 : numel(edgedump)
                edgedump{i} = cell(1, numel(self.edges{i}));
                for j = 1 : numel(edgedump{i})
                    edgedump{i}{j} = dumpconnection(self, i, self.edges{i}(j));
                end
                try
                    edgedump{i} = cat(2, edgedump{i}{:});
                catch
                    error('EDGE DISAPPEARED, MODEL IS BROKEN');
                end
            end
            edgedump = cat(2, edgedump{:});
        end
        
        function cdump = dumpconnection(self, ifrom, ito)
            unitFrom = self.nodes{ifrom};
            % get access-point's id of second unit
            idApTo = cellfun(@(ap) ap.id, self.nodes{ito}.I, 'UniformOutput', false);
            % check each connection from first unit's output access-point
            buffer = cell(1, numel(unitFrom.O));
            for i = 1 : numel(unitFrom.O)
                idLink = cellfun(@(ap) ap.id, unitFrom.O{i}.links, 'UniformOutput', false);
                [~, ~, iApTo] = intersect(idLink, idApTo);
                buffer{i} = arrayfun(@(index) [ifrom, i, ito, index], iApTo, ...
                    'UniformOutput', false);                
            end
            cdump = cat(2, buffer{:});
        end
        
        function modeldump = dump(self)
            self.prepare();
            % dump each units
            unitdump = cellfun(@dump, self.nodes, 'UniformOutput', false);
            % according to specific condition add extra settings as key-value pairs
            % such as specific input (set by setAsInput)
            modeldump = {'Model.loaddump', {'Transparent', unitdump}, ...
                {'Transparent', self.dumpedges()}};
        end
        
        function update(obj)
            for i = 1 : numel(obj.evolvable)
                obj.evolvable{i}.update();
            end
        end
        
        function freeze(obj)
            for i = 1 : numel(obj.evolvable)
                obj.evolvable{i}.freeze();
            end
        end
        
        function unfreeze(obj)
            for i = 1 : numel(obj.evolvable)
                obj.evolvable{i}.unfreeze();
            end
        end

        function refresh(obj)
            for i = 1 : numel(obj.evolvable)
                obj.evolvable{i}.refresh();
            end
        end
    end
    
    methods (Static)
        function self = loaddump(unitdump, edgedump, varargin)
            unitset = cellfun(@BuildingBlock.loaddump, unitdump, 'UniformOutput', false);
            % connect units according to edgedump
            for i = 1 : numel(edgedump)
                unitset{edgedump{i}(1)}.O{edgedump{i}(2)}.connect( ...
                    unitset{edgedump{i}(3)}.I{edgedump{i}(4)});
            end
            self = Model(unitset{:});
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
                        if isa(node, 'Evolvable')
                            obj.evolvable{end + 1} = node;
                        end
                    end
                elseif isempty(node)
                    % skip
                else
                    warning('NOT AVAILABLE');
                end
            end
        end
    end
    
    methods
        function updateConnections(obj, index)
            unit = obj.nodes{index};
            obj.edges{index} = [];
            % update input connection of the unit
            for i = 1 : numel(unit.I)
                noPrevUnit = true;
                for j = 1 : numel(unit.I{i}.links)
                    prevAP = unit.I{i}.links{j};
                    if isa(prevAP.parent, 'Unit')
                        prevID = prevAP.parent.id;
                        if obj.id2ind.isKey(prevID)
                            noPrevUnit = false;
                            prevIndex = obj.id2ind(prevID);
                            obj.edges{prevIndex} = unique([obj.edges{prevIndex}, index]);
                            % remove this AP from OBJ.O
                            obj.O(cellfun(@prevAP.compare, obj.O)) = [];
                        end
                    end
                end
                if noPrevUnit
                    obj.I = [obj.I, unit.I(i)];
                end
            end
            % update output connections of the unit
            for i = 1 : numel(unit.O)
                noPostUnit = true;
                for j = 1 : numel(unit.O{i}.links)
                    postAP = unit.O{i}.links{j};
                    if isa(postAP.parent, 'Unit')
                        postID = postAP.parent.id;
                        if obj.id2ind.isKey(postID)
                            noPostUnit = false;
                            postIndex = obj.id2ind(postID);
                            obj.edges{index} = unique([obj.edges{index}, postIndex]);
                            % remove this AP from OBJ.I
                            obj.I(cellfun(@postAP.compare, obj.I)) = [];
                        end
                    end
                end
                if noPostUnit
                    obj.O = [obj.O, unit.O(i)];
                end
            end
        end
        
        function topologicalSort(obj)
        % TOPOLOGICALSORT reorder nodes by topological sort (implemented by 
        % depth-first search). Tree search are started from units those own 
        % input access-points, while in the inverse order of their position
        % node list. This is necessary fot keeping their relative order after
        % topological sort. Besides, units contains output access-points would
        % be rearranged to match their order in node list before sort. This 
        % rearrangement would not break topological order, because they are not
        % dependence for any other units in the model.
            states = false(1, numel(obj.nodes));
            order  = zeros(1, numel(obj.nodes));
            index  = numel(obj.nodes);
            starts = obj.startNodes(end : -1 : 1);
            endInd = unique(cellfun(@(ap) obj.id2ind(ap.parent.id), obj.O), 'stable');
            for i = 1 : numel(starts)
                [states, order, index] = obj.visit(starts(i), states, order, index);
            end
            % adjust order of nodes who have output access-point
            order(endInd) = sort(order(endInd), 'ascend');
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
                % get inverse list for stable sort
                edgelist = sort(obj.edges{root}, 'descend');
                % visit all children
                for i = 1 : numel(edgelist)
                    child = edgelist(i);
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
        function obj = seal(obj)
            for i = 1 : numel(obj.nodes)
                unit = obj.nodes{i};
                % remove all in-ward links from outside
                for j = 1 : numel(unit.I)
                    apoint = unit.I{j};
                    index = cellfun(@(ap) obj.id2ind.isKey(ap.parent.id), apoint.links);
                    if any(index) && not(all(index))
                        cellfun(@apoint.disconnect, apoint.links(not(index)), ...
                            'UniformOutput', false);
                    end
                end
                % remove all out-ward links to outside
                for j = 1 : numel(unit.O)
                    apoint = unit.O{j};
                    index = cellfun(@(ap) obj.id2ind.isKey(ap.parent.id), apoint.links);
                    if any(index) && not(all(index))
                        cellfun(@apoint.disconnect, apoint.links(not(index)), ...
                            'UniformOutput', false);
                    end
                end
            end
            obj.prepare();
        end
        
        % RECRTMODE extends containers in each units to specific capacity.
        % This methods calls RECRTMODE method of class SIMPLEUNIT to
        % complete this operation.
        % PRM: Is SimpleUnit the only class to be called here?
        function obj = recrtmode(obj, n)
            for i = 1 : numel(obj.nodes)
                unit = obj.nodes{i};
                if isa(unit, 'SimpleUnit')
                    unit.recrtmode(n);
                end
                if isa(unit, 'Reshaper')
                    unit.shapercd.init(n);
                end
            end
        end
    end
    
    methods
        function obj = Model(varargin)
            obj.id2ind   = containers.Map( ...
                'KeyType', 'char', 'ValueType', 'any');
            obj.sorted   = true;
            % initialize model with given components
            obj.add(varargin{:});
            % keep model legal and sorted
            if not(isempty(obj.nodes))
                obj.prepare();
            end
        end
    end
    
    properties (SetAccess = protected)
        I = {} % input access point set
        O = {} % output access point set
        nodes = {}
        edges = {}
        evolvable = {}
        id2ind
        sorted
    end
    properties (Dependent)
        startNodes
    end
    methods
        function value = get.startNodes(obj)
            value = cellfun(@(id) obj.id2ind(id), unique( ...
                cellfun(@(ap) ap.parent.id, obj.I, 'UniformOutput', false), 'stable'));
        end
    end
end
