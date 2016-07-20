% PROBLEM: whether or not 'Model' should inherit from 'Unit'
classdef Model < handle
    methods
        function refreshSizeDescription(obj)
            obj.vargen.refresh();
            
            description = obj.termin.inputSizeRequirement;
            if SizeDescription.isexpendable(description)
                datadim = obj.vargen.next() + numel(description) - 1;
            else
                datadim = sym(numel(description));
            end
            
            solution = [];
            for i = 1 : numel(obj.nodes)
                node = obj.iterator(i);
                [tof, sol] = node.resolveDimension(datadim, obj.vargen);
                if tof
                    datadim  = node.outputDimDescription;
                    solution = SizeDescription.updateSolution(solution, sol);
                else
                    error('UMPrest:RuntimeError', ...
                          'Size description cannot be initialized!');
                end
            end
            
            for i = 1 : numel(obj.nodes)
                node = obj.iterator(i);
                if SizeDescriptor.isexpression(node.dimExpend)
                    node.dimExpend = subs(node.dimExpend, solution);
                end
                node.initSizeDescription(obj.vargen);
            end
            
            solution = [];
            description = obj.termin.inputSizeDescription;
            for i = 1 : numel(obj.nodes)
                node = obj.iterator(i);
                [tof, sol] = node.updateSizeDescription(description);
                if tof
                    solution = SizeDescription.updateSolution(solution, sol);
                    description = node.outputSizeDescription;
                else
                    error('UMPrest:RuntimeError', 'Mismatch is found!');
                end
            end
            
            for i = 1 : numel(obj.nodes)
                node = obj.iterator(i);
                node.inputSizeDescription = SizeDescription.subs( ...
                    node.inputSizeDescription, solution);
            end
        end
    end
    
    methods (Abstract)
        node = iterator(obj, index)
    end
    
    properties (Abstract)
        nodes
    end
    
    properties
        vargen % generator of local variables
    end
    
    methods
        function obj = Model(varargin)
            obj.vargen = VarGenerator('d');
        end
    end
    
    methods
        function n = numel(obj)
            n = numel(obj.nodes);
        end
        
        function unit = units(obj, index)
            unit = obj.nodes{index}.unit;
        end
        
        function root(obj, node)
            if SizeDescription.isexpendable(node.inputSizeRequirement)
                node.dimExpend = obj.vargen.next();
            else
                node.dimExpend = [];
            end
        end
        
        function connect(obj, nodeA, nodeB)
            [status, solution] = nodeB.resolveDimension( ...
                nodeA.outputDimDescription, obj.vargen);
            if status
                if not(isempty(solution))
                    for i = 1 : numel(obj.nodes)
                        node = obj.iterator(i);
                        node.dimExpend = subs(node.dimExpend, solution);
                    end
                end
            else
                error('UMPrest:RuntimeError', ...
                      'Connection failed : data dimension mismatch');
            end
            
            nodeB.initSizeDescription(obj.vargen);
            
            [status, solution] = ...
                nodeB.updateSizeDescription(nodeA.outputSizeDescription);
            if status
                if not(isempty(solution))
                    for i = 1 : numel(obj.nodes)
                        node = obj.iterator(i);
                        node.inputSizeDescription = SizeDescription.subs( ...
                            node.inputSizeDescription, solution);
                    end
                end
            else
                error('UMPrest:RuntimeError', ...
                      'Connection failed : data size mismatch');
            end
        end
    end
end
