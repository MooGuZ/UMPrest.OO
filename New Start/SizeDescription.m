classdef SizeDescription < handle
    methods (Static)
        % % FORMAT transform size description into standard form, a vector of
        % % symbols. If the given value cannot be conerted to a legal size
        % % description, an error will be raised.
        % function description = format(value)
        %     if isempty(value)
        %         description = [];
        %     elseif isvector(value)
        %         foreach = ifte(iscell(value), @cellfun, @arrayfun);
        %         assert(all(foreach(@SizeDescriptor.islegal, value)), ...
        %             'UMPrest:RuntimeError', 'Given description contains illegal element');
        %         value = foreach(@sym, value, 'UniformOutput', false);
        %         description = [value{:}];
        %     else
        %         error('UMPrest:RuntimeError', 'Size description has to be a vector');
        %     end
        % end
        
        function description = format(value)
            if not(isempty(value)) && isnumeric(value)
                description = sym(value);
                ind_nan = isnan(value);
                if any(ind_nan)
                    vargen = VarGenerator('sdtemp_');
                    description(ind_nan) = vargen.next(sum(ind_nan));
                end
            else
                description = value;
            end
            assert(SizeDescription.islegal(description), ...
                   'Cannot convert to a valid size description');
        end
        
        function tof = islegal(description)
            tof = false;
            if not(isempty(description) || iscell(description)) && ...
                    isvector(description)
                tof = all(arrayfun(@SizeDescriptor.isconcrete, ...
                                   description(1 : end-1)));
                tof = tof && SizeDescriptor.islegal(description(end));
            end
        end
        
        function tof = isnumeric(description)
            tof = false;
            if not(isempty(description) || iscell(description)) && ...
                    isvector(description)
                tof = all(arrayfun(@SizeDescriptor.isnumeric, description));
            end
        end
        
        function tof = isconcrete(description)
            tof = false;
            if not(isempty(description) || iscell(description)) && ...
                    isvector(description)
                tof = all(arrayfun(@SizeDescriptor.isconcrete, description));
            end
        end
        
        function tof = isexpendable(description)
            tof = false;
            if not(isempty(description) || iscell(description)) && ...
                    isvector(description)
                tof = all(arrayfun(@SizeDescriptor.isconcrete, ...
                                   description(1 : end-1)));
                tof = tof && SizeDescriptor.isexpendable(description(end));
            end
        end
        
        function tof = iscompact(description)
            tof = (numel(SizeDescription.symvar(description)) <= ...
                   sum(arrayfun(@SizeDescriptor.isexpression, description)));
        end
        
        function tof = check(description, value)
            if SizeDescription.isexpendable(description)
                n = numel(description) - 1;
                tof = numel(value) >= n && ...
                      SizeDescription.check(description(1 : n), value(1 : n));
            elseif numel(description) == numel(value)
                if isnumeric(value)
                    value = sym(value);
                end
                [tof, solution] = SizeDescriptor.check(description(1), value(1));
                for i = 2 : numel(value)
                    if tof
                        description(i) = SizeDescription.subs(description(i), solution);
                    else
                        return
                    end
                    [tof, sol] = SizeDescriptor.check(description(i), value(i));
                    solution = SizeDescription.updateSolution(solution, sol);
                end
            else
                tof = false;
            end
        end
        
        function [tof, solution] = match(dscptA, dscptB)
            if numel(dscptA) == numel(dscptB)
                avarlist = SizeDescription.symvar(dscptA);
                [tof, solution] = SizeDescriptor.match(dscptA(1), dscptB(1), avarlist);
                for i = 2 : numel(dscptB)
                    if tof
                        dscptA(i) = SizeDescription.subs(dscptA(i), solution);
                        dscptB(i) = SizeDescription.subs(dscptB(i), solution);
                    else
                        return
                    end
                    [tof, sol] = SizeDescriptor.match(dscptA(i), dscptB(i), avarlist);
                    solution = SizeDescription.updateSolution(solution, sol);
                end
            else
                tof = false;
                solution = [];
            end
        end
        
        function solution = updateSolution(solution, new)
            if not(isempty(new))
                if not(isempty(solution))
                    solution(2, :) = SizeDescription.subs(solution(2, :), new);
                end
                solution = [solution, new];
            end
        end
        
        function solution = simplifySolution(solution)
            if not(isempty(solution))
                solution(2, :) = SizeDescription.subs(solution(2, :), solution);
            end
        end
        
        % ction dscpt = refreshVariableName(dscpt, namegen)
        %  [dscpt(1), solution] = ...
        %      SizeDescriptor.refreshVariableName(dscpt(1), namegen);
        %  for i = 2 : numel(dscpt)
        %      dscpt(i) = SizeDescription.subs(dscpt(i), solution);
        %      [dscpt(i), sol] = ...
        %          SizeDescriptor.refreshVariableName(dscpt(2), namegen);
        %      solution = [solution, sol];
        %  end
        % 
        % 
        % ction [dscptA, dscptB] = solveDimension(dscptA, dscptB)
        %  isvarA = (SizeDescriptor.interp(dscptA(end)) == SizeDescriptor.Variable);
        %  isvarB = (SizeDescriptor.interp(dscptB(end)) == SizeDescriptor.Variable);
        %  if isvarA && isvarB
        %      if numel(dscptA) < numel(dscptB)
        %          dscptA = [dscptA(1 : numel(dscptA - 1)), dscptB(numel(dscptA) : end)];
        %      elseif numel(dscptB) < numel(dscptA)
        %          dscptB = [dscptB(1 : numel(dscptB - 1)), dscptA(numel(dscptB) : end)];
        %      end
        %  elseif isvarA
        %      if numel(dscptA) - 1 <= numel(dscptB)
        %          dscptA = [dscptA(1 : numel(dscptA - 1)), dscptB(numel(dscptA) : end)];
        %      end
        %  elseif isvarB
        %      if numel(dscptB) - 1 <= numel(dscptA)
        %          dscptB = [dscptB(1 : numel(dscptB - 1)), dscptA(numel(dscptB) : end)];
        %      end
        %  end
        % 
        
        function varlist = symvar(dscpt)
            varlist = arrayfun(@symvar, dscpt, 'UniformOutput', false);
            varlist = unique(cat(2, varlist{:}));
        end
        
        function dscpt = subs(dscpt, solution)
            if not(isempty(solution))
                while not(isempty(intersect(SizeDescription.symvar(dscpt), solution(1, :))))
                    dscpt = arrayfun(@(d) subs(d, solution(1, :), solution(2, :)), ...
                        dscpt, 'UniformOutput', false);
                    dscpt = [dscpt{:}];
                end
            end
        end
        
        function pattern = getPattern(descriptionIn, descriptionOut)
            if SizeDescription.isexpendable(descriptionIn)
                assert(SizeDescription.isexpendable(descriptionOut));
                pattern = SizeDescription.getPattern( ...
                    descriptionIn(1 : end-1), descriptionOut(1 : end-1));
                pattern.in = [pattern.in, sym.inf];
            else
                assert(SizeDescription.iscompact(descriptionIn), 'UMPrest:RuntimeError', ...
                       'Input description has redundent variable.');
                invars  = SizeDescription.symvar(descriptionIn);
                outvars = SizeDescription.symvar(descriptionOut);
                assert(all(ismember(outvars, invars)), 'UMPrest:RuntimeError', ...
                       'Output description contains unknown variable.');
                vargen = VarGenerator('p');
                patvars =  vargen.next(numel(descriptionIn));
                [status, solution] = SizeDescription.match(descriptionIn, patvars);
                assert(status, 'UMPrest:ProgramError', 'Should be able to match!');
                pattern = struct( ...
                    'in', patvars, 'out', ...
                    SizeDescription.subs(descriptionOut, solution));
            end
        end
        
        function descriptionOut = applyPattern(descriptionIn, pattern)
            if SizeDescription.isexpendable(pattern.in)
                nfixedpart = numel(pattern.in) - 1;
                assert(numel(descriptionIn) >= nfixedpart);
                pattern.in = pattern.in(1 : end-1);
                descriptionOut = ...
                    [SizeDescription.applyPattern( ...
                        descriptionIn(1 : nfixedpart), pattern), ...
                     descriptionIn(nfixedpart+1 : end)];
            else
                assert(numel(descriptionIn) == numel(pattern.in), 'UMPrest:RuntimeError', ...
                       'Given description and pattern are mismatched!');
                solution = [pattern.in; descriptionIn];
                descriptionOut = SizeDescription.subs(pattern.out, solution);
            end
        end

        function debug()
            % reject empty input
            assert(not(SizeDescription.islegal([])));
            assert(not(SizeDescription.islegal({})));
            % reject cell
            assert(not(SizeDescription.islegal({sym(1), sym(2)})));
            % reject non-symbol
            assert(not(SizeDescription.islegal([1, 2])));
            % reject non-positive
            assert(not(SizeDescription.islegal([sym(0), sym(1)])));
            % reject non-integer
            assert(not(SizeDescription.islegal([sym(1), sym(1.9)])));
            % reject sym.nan
            assert(not(SizeDescription.islegal(sym.nan())));
            % reject not-tail sym.inf
            assert(not(SizeDescription.islegal([sym(1), sym.inf(), sym(2)])));
            
            assert(SizeDescription.islegal([sym(1), sym(2), sym(3)]));
            assert(SizeDescription.islegal([sym(1);  sym(2); sym(3)]));
            assert(not(SizeDescription.islegal([sym(1), sym.inf(), sym(2)])));
            
            % check pattern extraction and application
            x = sym('x', 'clear'); y = sym('y', 'clear');
            p = SizeDescription.getPattern([10-x, x+y], [3*x, 2*y]);
            assert(all(SizeDescription.applyPattern([7, 8], p) == [9, 10]));
            p = SizeDescription.getPattern( ...
                [x, y, 3, sym.inf], [ceil(x / 2), ceil(y / 2), 7, sym.inf]);
            assert(all(SizeDescription.applyPattern([31, 33, 3, 2, 7], p) == ...
                       [16, 17, 7, 2, 7]));
        end
    end
end
