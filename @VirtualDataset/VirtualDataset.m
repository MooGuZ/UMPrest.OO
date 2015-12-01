classdef VirtualDataset < Dataset
    % ================= DATASET IMPLEMENTATION =================
    methods
        % VOLUMN returns the quantity of distinct samples the objects can
        % generated. If output in patches, this function returns a
        % estimated value.
        function n = volumn(obj)
            n = obj.dataSrc.volumn;
        end

        % NEXT returns new data sample(s) with associate information
        function sample = next(obj, n)
            sample = obj.proc(obj.dataSrc.next(n));
        end

        % TRAVERSE returns a set of data samples and information that could
        % represent the whole dataset
        function sample = traverse(obj)
            sample = obj.proc(obj.dataSrc.traverse());
        end

        % STATSAMPLE returns sample set which is sufficient for statistic analysis
        function sample = statsample(obj)
            sample = obj.proc(obj.dataSrc.statsample());
        end

        % ISTRAVERSED returns true/false to the question whether or not the
        % data units have been traversed since last time this status been checked
        function tof = istraversed(obj)
            tof = obj.dataSrc.istraversed();
        end

        % DIMOUT return the dimensionality of DATA field of output sample
        function n = dimout(obj)
            for i = numel(obj.dataProc) : -1 : 1
                n = obj.dataProc{i}.dimout();
                if not(isnan(n))
                    return
                end
            end
            n = obj.dataSrc.dimout();
        end
    end

    % ================= COMPONENT FUNCTION =================
    methods (Access = private)
        function sample = proc(obj, sample)
            for i = 1 : numel(obj.dataProc)
                sample = obj.dataProc{i}.proc(sample);
            end
        end
    end

    % ================= DATA STRUCTURE =================
    properties
        dataSrc
        dataProc
    end

    % ================= UTILITY =================
    methods
        function obj = VirtualDataset(dataset, dpunits)
            obj.dataSrc  = dataset;
            obj.dataProc = dpunits;
            obj.consistencyCheck();
        end

        function consistencyCheck(obj)
            assert(isa(obj.dataSrc, 'Dataset'));
            for i = 1 : numel(obj.dataProc)
                assert(isa(obj.dataProc{i}, 'DPModule'));
            end
        end
    end
end
