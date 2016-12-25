classdef ElementwiseOperation < Operation
    methods
        function output = process(obj, type, input)
            switch type
              case {'DataPackage'}
                output = obj.dataproc(input);
                
              case {'SizePackage'}
                output = input;
                
              case {'ErrorPackage'}
                output = input ./ obj.gradient(obj.O{1}.datarcd.pop());
                
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
                input = output .* obj.gradient(obj.O{1}.datarcd.pop());
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
%     methods
%         function value = smpsize(obj, io)
%             switch lower(io)
%                 case {'in', 'input', 'out', 'output'}
%                     try
%                         prevAP = obj.I{1}.links{1};
%                     catch
%                         error('UNDETERMINED');
%                     end
%                     value = prevAP.parent.smpsize('out');
%                     if iscell(value)
%                         value = value{prevAP.no};
%                     end
%                                         
%                 otherwise
%                     error('UNSUPPORTED')
%             end
%         end
%     end
    
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
