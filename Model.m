classdef Model < Interface & Evolvable
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
    
    % methods
    %     function varargout = sizeIn2Out(obj, varargin)
    %         assert(numel(varargin) == numel(obj.I), 'ILLEGAL ARGUMENT');
    %         % load SIZEPACKAGE to each input ACCESSPOINT
    %         arrayfun(@(i) obj.I(i).push(SizePackage(varargin{i})), varargin, ...
    %                  'UniformOutput', false);
    %         % pass SIZEPACKAGE through the model
    %         obj.forward();
    %         % collect output SIZE information
    %         varargout = arrayfun(@(ap) ap.datarcd.pop(), obj.O, ...
    %                              'UniformOutput', false);
    %     end
    %     
    %     function varargout = sizeOut2In(obj, varargin)
    %         assert(numel(varargin) == numel(obj.O), 'ILLEGAL ARGUMENT');
    %         % load SIZEPACKAGE to each input ACCESSPOINT
    %         arrayfun(@(i) obj.O(i).push(SizePackage(varargin{i})), varargin, ...
    %                  'UniformOutput', false);
    %         % pass SIZEPACKAGE through the model
    %         obj.backward();
    %         % collect output SIZE information
    %         varargout = arrayfun(@(ap) ap.datarcd.pop(), obj.I, ...
    %                              'UniformOutput', false);
    %     end
    % end
    
    methods
        function hpcell = hparam(obj)
            % hpcell = cell(1, numel(obj.evolvable));
            % for i = 1 : numel(hpcell)
            %     hpcell{i} = obj.evolvable{i}.hparam();
            % end
            hpcell = cellfun(@hparam, obj.evolvable, 'UniformOutput', false);
            hpcell = cat(2, hpcell{:});
        end
        
        function modeldump = dump(obj)
            % IMPLEMENT A:
            % modeldump = cell(1, numel(obj.evolvable));
            % for i = 1 : numel(modeldump)
            %     modeldump{i} = obj.evolvable{i}.dump();
            % end
            % IMPLEMENT B:
            % modeldump = [{'Model'}, cellfun(@dump, obj.evolvable, 'UniformOutput', false)];
            modeldump = {'Model', obj}; 
        end
        
        function rawdata = dumpraw(obj)
            rawdata = cellfun(@dumpraw, obj.evolvable, 'UniformOutput', false);
            rawdata = cat(1, rawdata{:});
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
                    prevID = prevAP.parent.id;
                    if obj.id2ind.isKey(prevID)
                        noPrevUnit = false;
                        prevIndex = obj.id2ind(prevID);
                        obj.edges{prevIndex} = unique([obj.edges{prevIndex}, index]);
                        % remove this AP from OBJ.O
                        obj.O(cellfun(@prevAP.compare, obj.O)) = [];
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
                    postID = postAP.parent.id;
                    if obj.id2ind.isKey(postID)
                        noPostUnit = false;
                        postIndex = obj.id2ind(postID);
                        obj.edges{index} = unique([obj.edges{index}, postIndex]);
                        % remove this AP from OBJ.I
                        obj.I(cellfun(@postAP.compare, obj.I)) = [];
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
        function obj = recrtmode(obj, n)
            for i = 1 : numel(obj.nodes)
                unit = obj.nodes{i};
                if isa(unit, 'SimpleUnit')
                    unit.recrtmode(n);
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
                cellfun(@(ap) ap.parent.id, obj.I, 'UniformOutput', false)));
        end
    end
end
