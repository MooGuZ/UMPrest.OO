function symbol = symgen(n)
    persistent counter;
    % initial counter
    if isempty(counter)
        counter = 0;
    end
    % default settings
    prefix = 'Var';
    if not(exist('n', 'var'))
        n = 1;
    end
    % generate symbolic vars
    symname = arrayfun(@(i) [prefix, num2str(i)], counter + (1 : n), ...
                       'UniformOutput', false);
    symbol = sym(symname, 'clear');
    % update counter
    counter = counter + n;
end
