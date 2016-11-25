classdef ElementwiseOperation < Operation
    methods
        function output = process(obj, type, input)
            switch type
              case {'DataPackage'}
                output = obj.dataproc(input);
                
              case {'SizePackage'}
                output = input;
                
              case {'ErrorPackage'}
                output = input ./ obj.gradient(obj.O.state.data);
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function input = invproc(obj, type, output)
            switch type
              case {'DataPackage'}
                input = obj.datainvp(output);
                
              case {'SizePackage'}
                input = output;
                
              case {'ErrorPackage'}
                input = output .* obj.gradient(obj.O.state.data);
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
    methods
        function obj = ElementwiseOperation()
            assert(isa(obj, 'SISOUnit'), 'Program Error', ...
                'Elementwise Operation only available in SISOUnit');
        end
    end
    
    properties (Abstract, SetAccess = protected, Hidden)
        dataproc, datainvp, gradient
    end
end
