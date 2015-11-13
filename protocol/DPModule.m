% DPModule is a protocol that all data processing module should follow
classdef DPModule < hgsetget
    methods (Abstract)
        % PROC process data according to specified purpose
        % ### dataIn ----> (proc) ----> dataOut
        dataOut = proc(obj, dataIn)
        % INVP apply inverse process to reconstruct data
        % ### dataOut ----> (invp) ----> dataIn
        dataIn = invp(obj, dataOut)
        % SETUP initialize data processing module according
        % to given data. This operation is useful to those
        % operations who need statistic information
        setup(obj, data)
        % READY returns the status of data processing module
        % that whether or not it is ready for operating
        tof = ready(obj)
        % DIMIN returns the dimensionality of input data (frame)
        % NaN means it adapted to all size
        n = dimin(obj)
        % DIMOUT returns the dimensionality of output data (frame)
        % NaN means it is varying according to the input size
        n = dimout(obj)
    end
end
