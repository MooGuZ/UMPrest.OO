classdef SizePackage < Package
    methods
        function obj = SizePackage(datasize, dsample, taxis)
            obj.dsample  = dsample;
            obj.taxis    = taxis;
            % add padding 1s if necessary
            npadding = dsample + double(taxis) + 1 - numel(datasize);
            if npadding > 0
                obj.datasize = padarray(datasize, [0, npadding], 1, 'post');
            elseif npadding < 0
                warning('STANDARDIZED DATA SHAPE');
                obj.datasize = [datasize(1 : end + npadding - 1), ...
                    prod(datasize(end + npadding : end))];
            else
                obj.datasize = datasize;
            end
        end
    end
    
    properties (SetAccess = protected)
        datasize  % size of data, corresponding to DATASIZE in DATAPACKAGE
        dsample   % dimension of sample
        taxis     % TRUE/FALSE, indicating contains time-axis
    end
    properties (Dependent)
        batchsize % quantity of samples (sequences) in the batch
    end
    methods
        function value = get.batchsize(self)
            value = self.datasize(self.dsample + double(self.taxis) + 1);
        end
    end
end