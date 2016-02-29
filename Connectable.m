classdef Connectable < handle
% CONNECTABLE is an abstraction that describing the connection between
% different objects. This class also provide several tools to users to
% connect CONEECTABLE objects with some promise.

% MooGu Z. <hzhu@case.edu>
% 2 23, 2016

    methods (Abstract)
        dim = dimin(obj)
        % DIM = obj.DIMIN() returns dimension of inherient input requirement in form of
        % a vector. 
        
        dim = dimout(obj)
        % DIM = obj.DIMOUT() returns dimension of inherient output requirement in form
        % of a vector.
        
%         tof = connect(self, other)
%         % CONNECT create connection to another object. During this process,
%         % callers should check whether or not its requirements have been all
%         % satisfied by the other object. A typical problems is data mismatch
%         % between different objects.
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
    
    methods (Static)
        function tof = dimatch(objA, objB)
            dimA = size(objA);
            dimB = size(objB);
            
            assert(all([dimA, dimB]), ...
                '[CONNECTABLE] Flexible dimension is not allowed in current edition.');
            
            % remove padding '1' in dimension
            dimA = dimA(1 : find(dimA > 1, 1, 'last'));
            dimB = dimB(1 : find(dimB > 1, 1, 'last'));
            
            % [case] exactly the same
            if (numel(a) == numel(b)) && all(a == b)
                tof = true;
            % [case] get same number of element    
            elseif prod(dimA) == prod(dimB)
                % one of object require 1D data, then it is 
                % save to reshape data in process.
                if numel(dimA) == 1 || numel(dimB) == 1
                    tof = true;
                % both objects require structure data, should
                % warn user that this is unsave
                else
                    warning('[CONNECTABLE] it is dangerous to reshape data between objects.');
                    tof = true;
                end
            else
                tof = false;
            end
        end
        
        function tof = connect(objA, objB)
            if Connectable.dimatch(objA, objB)
                objA.next = objB;
                objB.prev = objA;
            end
            
            tof = false;
        end                
    end
end

