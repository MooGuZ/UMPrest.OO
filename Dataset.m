classdef Dataset < handle
    methods (Abstract)
        varargout = next(obj, n)
    end
    
    properties (Abstract, Dependent)
        volume % number of unique samples in the dataset
        islabelled % T/F indicating whether or not there is label with data
    end
    properties (SetAccess = protected, Hidden)
        data  % AccessPoint for data
        label % AccessPoint for label
    end
    methods % RMPERF
        function set.data(obj, value)
            assert(isa(value, 'DatasetAP'), 'ILLEGAL ASSIGNMENT');
            obj.data = value;
        end
        
        function set.label(obj, value)
            assert(isempty(value )|| isa(value, 'DatasetAP'), ...
                'ILLEGAL ASSIGNMENT');
            obj.label = value;
        end
    end
end