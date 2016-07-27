classdef Node < handle
    % ======================= INTERFACE =======================
    methods
        status = propogate(obj)
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        unit
        prev, next, cache
    end
    methods
        function set.unit(obj, value)
            assert(isa(value, 'Unit'));
            obj.unit = value;
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Node(unit)
            obj.unit = unit;
        end
    end
    
    % ======================= TOPOLOGY LOGIC =======================
    methods
        % RESOLVEDIMENSION only handle uninitialized units
        function [tof, solution] = resolveDimension(obj, datadim, vargen)
            if SizeDescription.isexpendable(obj.inputSizeRequirement)
                var = symvar(datadim);
                if not(isempty(var))
                    n = double(subs(datadim, var, sym(zeros(1, numel(var)))));
                else
                    n = double(datadim);
                end
                m = numel(obj.inputSizeRequirement) - 1;
                if n < m
                    if isempty(var)
                        tof = false;
                        solution = [];
                    else
                        obj.dimExpend = vargen.next();
                        solution = [var; obj.dimExpend + m - n];
                        tof = true;
                    end
                else
                    if isempty(var)
                        obj.dimExpend = sym(n - m);
                    else
                        obj.dimExpend = var + n - m;
                    end
                    solution = [];
                    tof = true;
                end
            else
                obj.dimExpend = [];
                [tof, solution] = SizeDescriptor.match( ...
                    datadim, sym(numel(obj.inputSizeRequirement)));
            end
        end
        
        function initSizeDescription(obj, vargen)
            if isempty(obj.dimExpend) % not expendable
                concretepart = obj.inputSizeRequirement;
                expendpart   = [];
            else % expendable
                dimvar = symvar(obj.dimExpend);
                if isempty(dimvar)
                    expendpart = vargen.next(double(obj.dimExpend));
                else
                    n = double(subs(obj.dimExpend, dimvar, sym(0)));
                    expendpart = [vargen.next(n), sym.inf];
                end
                concretepart = obj.inputSizeRequirement(1 : end - 1);
            end
            
            varlist = SizeDescription.symvar(concretepart);
            if not(isempty(varlist))
                concretepart = SizeDescription.subs( ...
                    concretepart, [varlist; vargen.next(numel(varlist))]);
            end
            
            obj.inputSizeDescription = [concretepart, expendpart];
        end
        
        function [tof, solution] = updateSizeDescription(obj, dataSize)
            [tof, solution] = SizeDescription.match( ...
                obj.inputSizeDescription, dataSize);
            if tof
                obj.inputSizeDescription = SizeDescription.subs(dataSize, solution);
            end
        end
    end
    
    properties
        dimExpend
    end
    properties (Dependent)
        inputSizeRequirement
        inputSizeDescription, outputSizeDescription
        inputDimDescription, outputDimDescription
    end
    methods
        function set.dimExpend(obj, value)
            assert(isempty(value) || SizeDescriptor.isconcrete(value));
            obj.dimExpend = value;
        end
        
        function value = get.inputSizeRequirement(obj)
            value = obj.unit.inputSizeRequirement;
        end
        function set.inputSizeRequirement(obj, value)
            obj.unit.inputSizeRequirement = value;
        end
        
        function value = get.inputSizeDescription(obj)
            value = obj.unit.inputSizeDescription;
        end
        function set.inputSizeDescription(obj, value)
            obj.unit.inputSizeDescription = value;
        end
        
        function value = get.outputSizeDescription(obj)
            value = obj.unit.outputSizeDescription;
        end
        function set.outputSizeDescription(obj, value)
            obj.unit.outputSizeDescription = value;
        end
        
        function value = get.inputDimDescription(obj)
            dscpt = obj.inputSizeDescription;
            if SizeDescription.isexpendable(dscpt)
                assert(not(isempty(obj.dimExpend)), 'UMPrest:ProgramError', ...
                       'Should not access OUTPUTDIMDESCRIPTION when DIMEXPEND is unset.');
                value = numel(dscpt) - 1 + obj.dimExpend;
            else
                value = sym(numel(dscpt));
            end
        end
        
        function value = get.outputDimDescription(obj)
            dscpt = obj.outputSizeDescription;
            if SizeDescription.isexpendable(dscpt)
                assert(not(isempty(obj.dimExpend)), 'UMPrest:ProgramError', ...
                       'Should not access OUTPUTDIMDESCRIPTION when DIMEXPEND is unset.');
                value = numel(dscpt) - 1 + obj.dimExpend;
            else
                value = sym(numel(dscpt));
            end
        end
    end
end
