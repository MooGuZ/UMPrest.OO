% DPModule is a protocol that all data processing module should follow
% [Interfaces]
%   sampleOut = proc(obj, sampleIn)
%   sampleIn = invp(obj, sampleOut)
%   setup(obj, sample)
%   tof = ready(obj)
%   n = dimin(obj)
%   n = dimout(obj)
%
% see also, DPModule, GPUModule, Stack, GenerativeModel
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015

% [Change Log]
% Nov 20, 2015 - initial commit
% Dec 08, 2015 - modify definition of function 'setup' to accept sample or dataset
classdef DPModule < handle
    methods (Abstract)
        % ### sample ----> (proc) ----> sample
        % PROC take sample (a structure with field 'data') in and produce
        % a sample after applied data processing procedure of the class
        sampleOut = proc(obj, sampleIn)
        % ### sample ----> (invp) ----> sample
        % INVP is short for inverse-process and act as the counter-part of
        % PROC. It produces a sample has the same structure as the input
        % sample of PROC
        sampleIn = invp(obj, sampleOut)
        % ### sod ----> (setup) --update--> [obj]
        % SETUP initialize data processing module according to given sample
        % or dataset. Generally speaking, data processing module with Learning
        % capability receive dataset, while pure data processing module needs
        % sample as input.
        setup(obj, sod)
        % ### stat ----> (statistics) ----> stat
        % STATISTICS take statistic information in and revise it according
        % its own properties and characteristic. If the statistics informaiton
        % is uncertain, return NaN.
        % stat = statistics(obj, stat)
        % READY returns the status of data processing module
        % that whether or not it is ready for operating
        tof = ready(obj)
        % DIMIN and DIMOUT return the dimensionality of input and
        % output sample data. If there are multiple fields of data
        % the dimensionality is the sum of the each one. NaN means
        % here means the module adaptes to all size
        n = dimin(obj)
        n = dimout(obj)
    end
end
