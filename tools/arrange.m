function [r, c] = arrange(n)
% ARRANGE returns quantity of rows and columns to make N elements in a good
% arrangement of matrix form.
%
% [R, C] = ARRANGE(N) returns number of rows (R) and columns (C) that can
% contain N element (R x C >= N), while, R and C are as close as possible.
% In this implementation C >= R.
%
% This program follows these steps to get the result.
%
%  1. Check square root of N. If it is an integer just return R = C =
%  sqrt(N). If not, check R = floor(sqrt(N)) and C = ceil(sqrt(N)). If R x
%  C > N, start from these values. Otherwise, start with R = C = ceil(N).
%
%  2. check R = R - 1, and C = C + 1. If R x C > N. Repeat this step.
%
%  3. When condition of step 2 can't be satisfied. If R x C = N, return
%  current value. If not return R = R + 1, and C = C - 1.
%
%  Because, each interation in step 2 would decrease value of R x C by C -
%  R + 1. This create an arithmetic progression. The implementation uses a
%  formula to get number of steps needed before stop the procedure in a 
%  parametric fashion.

% MooGu Z. <hzhu@case.edu>
% Feb 22, 2016

r = floor(sqrt(n));
c = ceil(sqrt(n));

if r * c == n
    return
elseif r * c < n
    r = c;
    a = 0;
else
    a = 1;
end

s = floor((sqrt(a^2 + 4 * (r * c - n)) - a) / 2);

r = r - s;
c = c + s;

