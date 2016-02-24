%% Model
m = MLP([400, 200, 100, 10], 'logistic');
load ex4data1.mat
X = X';
t = zeros(10, numel(y));
for i = 1 : numel(y)
    t(y(i), i) = 1;
end
m.optimizer = SGD(1);
%% Learn
for epoch = 1 : 3
    seq = randperm(numel(y));
    for i = 1 : numel(seq)
        in = struct('x', X(:, seq(i)), ...
            'y', t(:, seq(i)));
        
        out = m.proc(in);
        [~, recA] = max(out.x);
        objA = m.objective(out.x, in.y);
        
        m.trainproc(in);
        
        out = m.proc(in);
        [~, recB] = max(out.x);
        objB = m.objective(out.x, in.y);
        
        fprintf('TRUE : %d \t CLAS : %d(%.4f) -> %d(%.4f)\n', ...
            y(seq(i)), recA, objA, recB, objB);
    end
end
%% Test
count = 0;
error = false(numel(y), 1);
for i = 1 : numel(y)
    out = m.proc(struct('x', X(:,i)));
    if find(out.x == max(out.x)) == y(i)
        count = count + 1;
    else
        error(i) = true;
    end
end
disp(['Correctness >> ', num2str(count / numel(y))]);
multimg(reshape(X(:, error), 20, 20, sum(error)));
%% Train focus on errors
nError = sum(error);
iError = find(error);
index  = [iError', randperm(size(X, 2), 3 * nError)];
E  = X(:, index);
tt = t(:, index);
yy = y(index);
for epoch = 1 : 10
    seq = randperm(size(E, 2));
    for i = 1 : numel(seq)
        in = struct('x', E(:, seq(i)), ...
            'y', tt(:, seq(i)));
        
        out = m.proc(in);
        [~, recA] = max(out.x);
        objA = m.objective(out.x, in.y);
        
        m.trainproc(in);
        
        out = m.proc(in);
        [~, recB] = max(out.x);
        objB = m.objective(out.x, in.y);
        
        fprintf('TRUE : %d \t CLAS : %d(%.4f) -> %d(%.4f)\n', ...
            yy(seq(i)), recA, objA, recB, objB);
    end
end
