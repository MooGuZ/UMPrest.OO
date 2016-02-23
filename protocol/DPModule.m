% DPModule is an abstraction of data processing module
% 
% [Interfaces]
%   data = obj.proc(data)
%   dim  = obj.dimin()
%   dim  = obj.dimout([dimin])

% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015

classdef DPModule < handle
    methods (Abstract)
        % PROC (process data) 
        data = proc(obj, data)
        
        % DIMIN (input dimension)
        % returns a vector, describing the requirement of input data
        % size. '0' in the vector means no requirement in this dimension.
        dim = dimin(obj)
        
        % DIMOUT (output dimension)
        % The second argument is optional. When DIMIN exist, DIMOUT return
        % the output dimension is calculated by set input dimension to
        % DIMIN. This functionality is especially useful to the module with
        % plexible input size.
        dim = dimout(obj, dimin)
    end
end
