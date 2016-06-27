classdef Unit < handle
    methods
        function datapkgOut = forward(obj, datapkgIn)
            dataIn = datapkgIn.data;
            if iscell(dataIn)
                dataOut = cell(1, numel(dataIn));
                for i = 1 : numel(dataIn)
                    dataOut{i} = obj.transform(dataIn{i});
                end
                datapkgOut = datapkgIn.derive('data', dataOut);
            else
                datapkgOut = datapkgIn.derive('data', obj.transform(dataIn));
            end
        end
        
        function datapkgIn = backward(obj, datapkgOut)
            dataOut = datapkgOut.data;
            if iscell(dataOut)
                dataIn = cell(1, numel(dataOut));
                for i = 1 : numel(dataOut)
                    dataIn{i} = obj.compose(dataOut{i});
                end
                datapkgIn = datapkgOut.derive('data', dataIn);
            else
                datapkgIn = datapkgOut.derive('data', obj.transform(dataOut));
            end
        end
        
        function delta = errprop(obj, delta)
            assert(not(iscell(delta)), 'UMPrest:ProgramError', ...
                   'No cell array allowed in error propagation.');
            delta = obj.deltaproc(delta, true);
        end
    end
    
    methods (Abstract)
        y = transform(obj, x)
        x = compose(obj, y)
        d = deltaproc(obj, d, isEnvolving)
    end
    
    methods (Abstract)
        s = size(obj, io)
    end
    
    properties (Hidden)
        I, O
    end
end
