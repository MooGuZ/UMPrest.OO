% DATASET is a protocol that all kinds of dataset should follow
classdef Dataset < hgsetget
    methods (Abstract)
        % VOLUMN returns the quantity of distinct samples the objects can
        % generated. If output in patches, this function returns a
        % estimated value.
        n = volumn(obj)
        
        % NEXT returns new data sample(s) with associate information
        sample = next(obj, n)
        
        % TRAVERSE returns a set of data samples and information that could
        % represent the whole dataset
        sample = traverse(obj)
        
        % ISTRAVERSED returns true/false to the question whether or not the
        % data units have been traversed since last time this status been checked
        tof = istraversed(obj)
        
        % DIMOUT return the dimensionality of DATA field of output sample
        n = dimout(obj)
    end
end
