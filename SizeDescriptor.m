classdef SizeDescriptor
    enumeration
        Expendable, Expression, Numeric, Illegal
    end
    methods (Static)
        function descriptor = interp(value)
            descriptor = SizeDescriptor.Illegal;
            if isa(value, 'sym') && isscalar(value)
                if isinf(value)
                    descriptor = SizeDescriptor.Expendable;   % sym.inf
                elseif not(isempty(symvar(value)))
                    descriptor = SizeDescriptor.Expression;    % variable or expression
                else
                    value = double(value);
                    if MathLib.isinteger(value) && value > 0
                        descriptor = SizeDescriptor.Numeric; % symbolic positive integer
                    end
                end
            end
        end
        
        function tof = islegal(value)
            tof = (SizeDescriptor.interp(value) ~= SizeDescriptor.Illegal);
        end
        
        function tof = isexpendable(value)
            tof = (SizeDescriptor.interp(value) == SizeDescriptor.Expendable);
        end
        
        function tof = isexpression(value)
            tof = (SizeDescriptor.interp(value) == SizeDescriptor.Expression);
        end
        
        function tof = isnumeric(value)
            tof = (SizeDescriptor.interp(value) == SizeDescriptor.Numeric);
        end
        
        function tof = isconcrete(value)
            descriptor = SizeDescriptor.interp(value);
            tof = (descriptor == SizeDescriptor.Expression ...
                   || descriptor == SizeDescriptor.Numeric);
        end
        
        % function [dscpt, solution] = refreshVariableName(dscpt, namegen)
        %     assert(SizeDescriptor.islegal(dscpt));
        %     assert(isa(namegen, 'function_handle'));
        %     solution = {};
        %     switch SizeDescriptor.interp(dscpt)
        %       case SizeDescriptor.Unlimited
        %         dscpt = sym(namegen()); % assign a variable to unlimited descriptor
        %         
        %       case SizeDescriptor.Dependent
        %         varlist = symvar(dscpt);
        %         for i = 1 : numel(varlist)
        %             solution = [solution, {varlist(i); sym(namegen())}];
        %         end
        %         dscpt = SizeDescription.subs(dscpt, solution);
        %     end
        % end
        
        function tof = issolvable(descriptor)
        % this function aims at checking whether or not there is a integer solution
        % of variables in the descriptor that makes the descriptor an integer.
        % However the implementation here use a naive method to check it. Hope it
        % to be a effective one.
            type = SizeDescriptor.interp(descriptor);
            switch type
              case SizeDescriptor.Expression
                varlist = symvar(descriptor);
                value = double(subs(descriptor, ...
                                    varlist, sym(zeros(1, numel(varlist)))));
                tof = isinf(value) || MathLib.isinteger(value);
                
              case SizeDescriptor.Numeric
                tof = true;
                
              otherwise
                tof = false;
            end
        end
        
        function solution = solve(left, right, preferVars)
        % PROBLEM: this implementation only take the first legal solution
        %          for this equation, and drop other solutions those maybe
        %          the true solution for the whole unit network.
        % NOTE: this implementation requires all the variable used in size
        %       descriptions have to be a positive integer. However, there is
        %       possibility that user use a formula on some dimension while using
        %       non-integer variables. Fortunately, this would not be common
        %       situation.
            if not(exist('right', 'var'))
                right = 0;
            end
            
            equation = left - right;
            varlist  = symvar(equation);
            if isempty(varlist)
                solution = [];
            elseif isscalar(varlist)
                assume(varlist, 'integer');
                assumeAlso(varlist > 0);
                solution = solve(equation, varlist);
                if not(isempty(solution))
                    solution = [varlist; solution(1)];
                end
            else
                if exist('preferVars', 'var')
                    preferVars = intersect(preferVars, varlist);
                else
                    preferVars = symvar(left);
                end
                if isempty(preferVars)
                    var = varlist(1);
                else
                    var = preferVars(1);
                end
                solution = solve(equation, var);
                if SizeDescriptor.issolvable(solution)
                    solution = [var; solution];
                end
            end
        end
        
        function [tof, solution] = check(descriptor, value)
            assert(SizeDescriptor.isnumeric(value), ...
                   'UMPrest:RuntimeError', ...
                   'Second argument has to be a valid size value.');
            
            solution = [];
            switch SizeDescriptor.interp(descriptor)
              case SizeDescriptor.Expendable
                tof = true;
                
              case SizeDescriptor.Expression
                solution = SizeDescriptor.solve(descriptor, value);
                tof = not(isempty(solution));
                
              case SizeDescriptor.Numeric
                tof = (double(descriptor) == double(value));
                
              otherwise
                error('UMPrest:RuntimeError', ...
                      'First Argument is not a legal size description.');
            end
        end
        
        % NOTE: this implementation would match sym.inf only to sym.inf
        function [tof, solution] = match(master, follower, preferVars)
            assert(SizeDescriptor.islegal(follower), 'UMPrest:RuntimeError', ...
                   'Second argument has to be a valid size descriptor.');
            
            solution = [];
            if SizeDescriptor.isexpendable(master)
                tof = SizeDescriptor.isexpendable(follower);
                return
            elseif SizeDescriptor.isexpendable(follower)
                tof = false;
                return
            end
            
            switch SizeDescriptor.interp(master)
              case SizeDescriptor.Expression
                if exist('preferVars', 'var')
                    solution = SizeDescriptor.solve(master, follower, preferVars);
                else
                    solution = SizeDescriptor.solve(master, follower);
                end
                tof = not(isempty(solution));
                
              case SizeDescriptor.Numeric
                switch SizeDescriptor.interp(follower)
                  case SizeDescriptor.Expression
                    solution = SizeDescriptor.solve(follower, master);
                    tof = not(isempty(solution));
                    
                  case SizeDescriptor.Numeric
                    tof = (master == follower);
                end
            end
        end
    end
end
