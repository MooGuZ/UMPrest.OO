%% gaussian distribution parameters
theta = pi / 8;
u = [sin(theta + pi / 2), sin(theta); cos(theta + pi / 2), cos(theta)];
v = diag([2, 1]);
C = u * v * u';

%% data generator
dgen = DataGenerator('gaussian', 2, 'covmat', C);

%% generate data and draw plot
data = dgen.next(1e4);
% draw data points
figure();
plot(data.data(1, :), data.data(2, :), '.k');
hold on; axis equal;
% draw gaussian distribution
plotgauss2d([0;0], C);
plot(0, 0, '.r', 'markerSize', 15);
hold off