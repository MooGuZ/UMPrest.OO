classdef Recenter < DPModule
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function dataOut = proc(obj, dataIn)
            dataOut = bsxfun(@minus, dataIn, obj.biasVector);
        end

        function dataIn = invp(obj, dataOut)
            dataIn = bsxfun(@plus, dataOut, obj.biasVector);
        end

        function setup(obj, data)
            assert(numel(size(data)) == 2);
            obj.biasVector = mean(data, 2);
        end

        function tof = ready(obj)
            tof = ~isempty(obj.biasVector);
        end

        function n = dimin(obj)
            assert(obj.ready());
            n = numel(obj.biasVector);
        end
        
        function n = dimout(obj)
            n = obj.dimin();
        end
    end
    % ================= DATA STRUCTURE =================
    properties (Hidden)
        biasVector
    end
end
