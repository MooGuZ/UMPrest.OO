classdef Statistics < handle
% STATISTICS is a sub-unit providing functionality of collecting statistics of
% provided data

% MooGu Z. <hzhu@case.edu>
% 3 22, 2016

    properties (Dependent)
        statistics
    end
    methods
        function value = get.statistics(obj)
            value = obj.stat.status;
        end
        
        function set.statistics(obj, value)
            if value ~= obj.statistics
                if value
                    obj.statcmd('turnon');
                else
                    obj.statcmd('turnoff');
                end
            end
        end
    end
    
    properties
        stat = struct('status', false);
    end
    
    methods
        function statcol(sample)
            assert(obj.statistics, 'ApplicationError:Statistics', ...
                   'Statistics module has not been initialized.');
            
            if obj.stat.lock
                return
            end
            
            sample = MathLib.vec(sample, obj.stat.unitdim, 'back');
            
            obj.stat.sum  = obj.stat.sum + sum(sample, obj.stat.unitdim + 1);
            obj.stat.sum2 = obj.stat.sum2 + sum(sample.^2, obj.stat.unitdim + 1);
            
            sample = MathLib.vec(sample, obj.stat.unitdim, 'front');
            
            obj.stat.covmat = obj.stat.covmat + sample * sample';
            obj.stat.count  = obj.stat.count + size(sample, 2);
        end
        
        function statcmd(cmd)
            assert(ischar(cmd), 'ArgumentError:Statistics', ...
                   'Command is a string, such as SHOW and INIT');
            
            switch strtrim(lower(cmd))
              case {'init', 'turnon'}
                obj.stat = struct( ...
                    'status', true, ...
                    'unitdim', 2, ...
                    'count', 0, ...
                    'sum', 0, ...
                    'sum2', 0, ...
                    'covmat', 0, ...
                    'lock', false);
                
              case {'reset'}
                if obj.stat.status
                    obj.stat.count  = 0;
                    obj.stat.sum    = 0;
                    obj.stat.sum2   = 0;
                    obj.stat.covmat = 0;
                    obj.stat.lock   = false;
                else
                    obj.statcmd('init');
                end
                
              case {'turnoff'}
                obj.stat = struct('status', false);
                
              case {'show'}
                disp(obj.stat)
                
              otherwise
                error('ArgumentError:Statistics', ...
                      'Unrecognized command : %s', upper(cmd));
            end
        end
    end
end
