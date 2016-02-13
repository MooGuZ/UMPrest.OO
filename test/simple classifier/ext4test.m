%% Model
m = MLP([400, 200, 100, 10], 'logistic');
load ex4data1.mat
X = X';
t = zeros(10, numel(y));
for i = 1 : numel(y)
    t(y(i), i) = 1;
end
%% Learn
for epoch = 1 : 10
    seq = randperm(numel(y));
    for i = 1 : numel(seq)
        in = X(:, seq(i));
        tt = t(:, seq(i));
%         out = m.feedforward(in);
%         recA = mod(find(out == max(out)), 10);
%         objA = m.objective(out, tt);
        m.learn(in, tt, 1 / (epoch + 20));
%         out = m.feedforward(in);
%         recB = mod(find(out == max(out)), 10);
%         objB = m.objective(out, tt);
%         fprintf('TRUE : %d \t CLAS : %d(%.4f) -> %d(%.4f)\n', ...
%             y(seq(i)), recA, objA, recB, objB);
    end
end
%% Test
count = 0;
for i = 1 : numel(y)
    out = m.feedforward(X(:,i));
    if find(out == max(out)) == y(i)
        count = count + 1;
    end
end
disp(['Correctness >> ', num2str(count / numel(y))]);
