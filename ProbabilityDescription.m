classdef ProbabilityDescription < handle
    methods
        function addPrior(self, varargin)
            self.priorSet = [self.priorSet, {CommonPrior(varargin{:})}];
        end
        
        function clearPrior(self)
            self.priorSet = {};
        end
        
        function priorDisplay(self)
            fprintf('[Prior List]\n\n');
            for i = 1 : numel(self.priorSet)
                disp(self.priorSet{i});
                fprintf('\n\n');
            end
        end
        
        function value = priorEval(self, data)
            value = 0;
            if not(exist('data', 'var'))
                data = self.data;
            end
            for i = 1 : numel(self.priorSet)
                value = value + self.priorSet{i}.evaluate(data);
            end
        end
        
        function d = priorDelta(self, data)
            if isempty(self.priorSet)
                d = 0;
            else
                if not(exist('data', 'var'))
                    data = self.data;
                end                
                d = self.priorSet{1}.delta(data);
                for i = 2 : numel(self.priorSet)
                    d = d + self.priorSet{i}.delta(data);
                end
            end
        end
    end
    
    properties (SetAccess = protected)
        priorSet = {}
    end
    properties (Abstract, SetAccess = protected)
        data
    end
end