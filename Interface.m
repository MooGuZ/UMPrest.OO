classdef Interface < handle
    % methods
    %     function connect(obj, anotherUnit)
    %         assert(numel(obj.O) == numel(anotherUnit.I), 'ILLEGAL OPERATION');
    %         arrayfun(@(i) obj.O(i).connect(anotherUnit.I(i)), 1 : numel(obj.O));
    %     end
    %     
    %     function oneway(obj, anotherUnit)
    %         assert(numel(obj.O) == numel(anotherUnit.I), 'ILLEGAL OPERATION');
    %         arrayfun(@(i) obj.O(i).addlink(anotherUnit.I(i)), 1 : numel(obj.O));
    %     end
    % end
    
    methods
        function obj = aheadof(obj, varargin)
            for i = 1 : numel(varargin)
                apto = varargin{i};
                % skip if when empty array
                if isempty(apto)
                    continue
                end
                % special cases
                if iscell(apto) && isscalar(apto)
                    apto = apto{1};
                elseif isa(apto, 'Interface') && isscalar(apto.I)
                    apto = apto.I{1};
                end
                assert(isa(apto, 'AccessPoint'), 'ILLEGAL OPERATION');
                apto.connect(obj.O{i});
            end
        end
        
        function obj = appendto(obj, varargin)
            for i = 1 : numel(varargin)
                apfrom = varargin{i};
                % skip if when empty array
                if isempty(apfrom)
                    continue
                end
                % special cases
                if iscell(apfrom) && isscalar(apfrom)
                    apfrom = apfrom{1};
                elseif isa(apfrom, 'Interface') && isscalar(apfrom.O)
                    apfrom = apfrom.O{1};
                end
                assert(isa(apfrom, 'AccessPoint'), 'ILLEGAL OPERATION');
                apfrom.connect(obj.I{i});
            end
        end
    end
    
    methods (Abstract)
        varargout = forward(obj, varargin)
        varargout = backward(obj, varargin)
    end
    
    methods (Abstract)
        d = dump(obj)
    end
    
    methods (Static)
        function unit = loaddump(unitdump)
            switch unitdump{1}
              case {'Transparent'}
                unit = unitdump{2};
                if numel(unitdump) > 2
                    warning('SOME INFORMATION IGNORED IN LOAD PROCESS');
                end
                
              otherwise
                for i = 2 : numel(unitdump)
                    element = unitdump{i};
                    if iscell(element)
                        unitdump{i} = Interface.loaddump(element);
                    end
                end
                unit = feval(unitdump{:});
            end
        end
    end
    
    properties (Abstract, SetAccess = protected)
        I, O % container of Input/Output AccessPoints
    end
end
