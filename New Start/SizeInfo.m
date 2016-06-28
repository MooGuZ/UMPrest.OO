classdef SizeInfo < handle
    methods
        % PROBLEM: cannot deal with the situation there are multiple input point in
        %          the network.
        function [sz, solution] = match(obj, sz)
            if numel(sz) == numel(obj)
                solution = {};
                for i = 1 : numel(sz)
                    if isa(sz.status{i}, 'sym')
                        if not(isempty(solution))
                            sz.status{i} = sz.status{i}.subs(solution{:});
                            if isempty(symvar(sz.status{i}))
                                sz.status{i} = double(sz.status{i});
                            end                                
                        end
                    end
                    
                    if isa(obj.status{i}, 'sym')
                        obj.status{i} = sz.status{i};
                    elseif isa(sz.status{i}, 'sym')
                        expr = sz.status{i} - obj.status{i};
                        vars = symvar(expr);
                        s = solve(expr, vars(end));
                        solution = {solution{:}, vars(end), s};
                    else
                        if obj.status{i} ~= sz.status{i}
                            error('UMPrest:SizeMismatch', ...
                                  'Size requirement cannot be satisfied.');
                        end
                    end    
                end
            else
                error('UMPrest:SizeMismatch', ...
                      'Size requirement cannot be satisfied.');
            end
        end
        
        function value = size(obj, varargin)
            value = size(obj.status, varargin{:});
        end
        
        function n = numel(obj)
            n = numel(obj.status);
        end
    end
    
    properties
        status
    end
    methods
        function set.status(obj, value)
            assert(not(iscell(value)) && isrow(value) ...
                   && all(arrayfun(@(v) isa(v, 'sym'))));
            obj.status = value;
        end
    end
    
    properties (Dependent)
        varlist
    end
    methods
        function value = get.varlist(obj)
            value = symvar(sum(obj.status));
        end
    end 
end
