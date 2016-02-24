classdef Connectable < handle
% CONNECTABLE is an abstraction that describing the connection between
% different objects. This class also provide several tools to users to
% connect CONEECTABLE objects with some promise.

% MooGu Z. <hzhu@case.edu>
% 2 23, 2016

    methods (Abstract)
        dim = dimin(obj, dimout)
        % DIM = obj.DIMIN() returns dimension of inherient input requirement in form of
        % a vector. '0' in the vector means that dimension is not restrictd.
        %
        % DIM = obj.DIMIN(DIMOUT) returns input dimension in the condition of
        % given output dimension.
        
        dim = dimout(obj, dimin)
        % DIM = obj.DIMOUT() returns dimension of inherient output requirement in form
        % of a vector. '0' in the vector means that dimension is not restricted.
        %
        % DIM = obj.DIMOUT(DIMIN) returns output dimension in the condition of
        % given input dimension.
        
        tof = connect(self, other)
        % CONNECT create connection to another object. During this process,
        % callers should check whether or not its requirements have been all
        % satisfied by the other object. A typical problems is data mismatch
        % between different objects.
    end
    
    % methods
    %     % ENFORCEDIMIN / ENFORCEDIMOUT is prepared for objects whoes
    %     % dimensionality of input/output is flexible. Then other object can
    %     % require them to fix to some dimension. By default, these two method
    %     % would return FALSE everytime. This is the expected responds of
    %     % fixed dimension objects.
    %     
    %     function tof = enforceDimin(obj, dimin)
    %         tof = false;
    %     end
    %     
    %     function tof = enforceDimout(obj, dimout)
    %         tof = false;
    %     end
    % end
    
    properties
        prev                          % link to previous object
        next                          % link to next object
    end
end

