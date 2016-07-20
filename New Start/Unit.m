classdef Unit < handle
% UNIT class is the abstraction of fundamental element of AI program. It provides
% interfaces to process data package or pure data. Besides, UNIT also maintain size
% description of itself to inform others the input and output size requirements.
    
    % ======================= DATA PROCESSING  =======================
    methods
        function package = forward(obj, package)
            % TODO: support command package
%             assert(SizeDescription.check(obj.inputSizeRequirement, package.dataSize()), ...
%                 'UMPrest:RuntimeError', ...
%                 'Size of data package mismatch the requirement of unit');
            
            dataIn = package.data;
            if iscell(dataIn)
                dataOut = cell(1, numel(dataIn));
                for i = 1 : numel(dataIn)
                    dataOut{i} = obj.transform(dataIn{i});
                end
                package = package.derive('data', dataOut);
            else
                package = package.derive('data', obj.transform(dataIn));
            end
        end
        
        function package = backward(obj, package)
%             assert(SizeDescription.check(obj.outputSizeRequirement, package.dataSize()), ...
%                 'UMPrest:RuntimeError', ...
%                 'Size of data package mismatch the requirement of unit');
            
            dataOut = package.data;
            if iscell(dataOut)
                dataIn = cell(1, numel(dataOut));
                for i = 1 : numel(dataOut)
                    dataIn{i} = obj.compose(dataOut{i});
                end
                package = package.derive('data', dataIn);
            else
                package = package.derive('data', obj.compose(dataOut));
            end
        end
    end
    
    methods (Abstract)
        y = transform(obj, x)
        x = compose(obj, y)
        d = errprop(obj, d, isEnvolving)
    end
    
    properties (Hidden)
        I, O
    end                  
    
    methods (Abstract)
        unit = inverseUnit(obj)
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent, Abstract)
        inputSizeRequirement
    end
    properties (Dependent)
        inputSizeDescription, outputSizeDescription
    end
    properties (Access = protected)
        inputSizeDescriptionCache, outputSizeDescriptionCache
    end
    methods (Abstract)
        description = sizeIn2Out(obj, description)
    end
    methods
        function value = get.inputSizeDescription(obj)
            if isempty(obj.inputSizeDescriptionCache)
                obj.inputSizeDescription = obj.inputSizeRequirement;
            end
            value = obj.inputSizeDescriptionCache;
        end
        function set.inputSizeDescription(obj, value)
            if isnumeric(value)
                obj.inputSizeDescriptionCache = SizeDescription.format(value);
            elseif isempty(value) || SizeDescription.islegal(value);
                obj.inputSizeDescriptionCache = value;
            else
                error('Unable to set size description with given value');
            end
            obj.outputSizeDescriptionCache = [];
        end
        
        function value = get.outputSizeDescription(obj)
            if isempty(obj.outputSizeDescriptionCache)
                obj.outputSizeDescriptionCache = obj.sizeIn2Out(obj.inputSizeDescription);
            end
            value = obj.outputSizeDescriptionCache;
        end
        function set.outputSizeDescription(obj, value)
            if isnumeric(value)
                obj.outputSizeDescriptionCache = SizeDescription.format(value);
            elseif isempty(value) || SizeDescription.islegal(value);
                obj.outputSizeDescriptionCache = value;
            else
                error('Unable to set size description with given value');
            end
        end
    end
    
    % ======================= DEVELOPMENT TOOL =======================
    methods (Static)
        function validate(instance)
            assert(isa(instance, 'Unit'), ...
                   'This function only check validity of instance of class UNIT.');
            assert(SizeDescription.iscompact(instance.inputSizeRequirement), ...
                   'Input size requirement has redundent variable.');
            invars  = SizeDescription.symvar(instance.inputSizeDescription);
            outvars = SizeDescription.symvar(instance.outputSizeDescription);
            assert(all(ismember(outvars, invars)), ...
                   'Output description contains unknown variable.');
            assert(SizeDescription.match(obj.inputSizeRequirement, ...
                                         obj.inputSizeDescription), ...
                   'Input size description cannot fullfile the requirement');
        end
    end
end
