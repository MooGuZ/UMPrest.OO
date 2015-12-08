% DATASET is a protocol that all kinds of dataset should follow
%
% CHANGE LOG
% Dec 08, 2015 - remove interface of traverse and istraversed
classdef Dataset < handle
    methods (Abstract)
        % VOLUMN returns the quantity of distinct samples the objects can
        % generated. If output in patches, this function returns a
        % estimated value.
        n = volumn(obj)

        % NEXT returns new data sample(s) with associate information
        varargout = next(obj, n)

        % % TRAVERSE returns a set of data samples and information that could
        % % represent the whole dataset
        % sample = traverse(obj)

        % STATSAMPLE returns sample set which is sufficient for statistic analysis
        sample = statsample(obj)

        % % ISTRAVERSED returns true/false to the question whether or not the
        % % data units have been traversed since last time this status been checked
        % tof = istraversed(obj)

        % DIMOUT return the dimensionality of DATA field of output sample
        n = dimout(obj)
    end
end
