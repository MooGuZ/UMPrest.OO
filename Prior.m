classdef Prior < Objective
    methods
        function value = evaluate(self, data)
            value = self.scale * self.evalproc(data);
            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
        
        function d = delta(self, data)
            d = self.scale * self.deltaproc(data);
        end
    end
    
    methods (Abstract)
        value = evalproc(self, data)
        d = deltaproc(self, data)
    end
    
%     methods
%         function [data, shape] = format(self, data)
%             shape = size(data);
%             if self.host.expandable
%                 dim = self.host.dsample + self.host.parent.pkginfo.dexpand;
%             else
%                 dim = self.host.dsample;
%             end
%             data = vec(data, dim, 'both');
%         end
%     end
    
    methods
        function self = Prior(varargin)
            conf       = Config(varargin);
            self.scale = conf.pop('scale', 1);
        end
    end
    
    properties
        scale
    end
end
