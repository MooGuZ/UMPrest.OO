% NORMDIM rescale data to let variance of each dimension to be 1
classdef NormDim < DPModule & LibUtility
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sample.data = bsxfun(@rdivide, sample.data, obj.stdVector);
        end
        
        function sample = invp(obj, sample)
            sample.data = bsxfun(@times, sample.data, obj.stdVector);
        end
        
        function setup(obj, sample)
            assert(numel(size(sample.data)) == 2);
            obj.stdVector = std(sample.data, 0, 2);
        end
        
        function tof = ready(obj)
            tof = not(isempty(obj.stdVector)); 
        end
        
        function n = dimin(obj)
            assert(obj.ready());
            n = numel(obj.stdVector);
        end
        
        function n = dimout(obj)
            n = obj.dimin();
        end
    end
    
    % ================= DATA STRUCTURE =================
    properties
        stdVector
    end
    
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function obj = NormDim(varargin)
            obj.setupByArg(varargin{:});
        end        
    end
end
