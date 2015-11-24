% PROBCALCLIB contains anonymous functions to calculate common distribution
% and their derivatives. Prefix 'NL' means 'negative log(e)', while 'd' is
% short for 'derivative'. Noted that, all functions here ignored the average
% value 'mu'. Because most probability description works on decentralized data.
% BTW, constant terms are ignored too.
% MATHLIB < handle
%   MATHLIB provides functions (or function handle as properties) for subclass
%   to calculate common mathematical target.
%
%   Currently, the library mainly contains functions to calculate distribution
%   and probabilities.
%
% see also, handle, hgsetget
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
classdef MathLib < hgsetget
    properties (Access = protected)
        % Gaussian Distribution (Normal Distribution)
        nlGauss  = @(x, sigma) sum(x(:).^2) / (2 * sigma^2);
        dNLGauss = @(x, sigma) x / sigma^2;
        % Cauchy Distribution
        nlCauchy  = @(x, sigma) sum(log(1 + (x(:) / sigma).^2));
        dNLCauchy = @(x, sigma) (2 * x) ./ (sigma^2 + x.^2);
        % Laplace Distribution
        nlLaplace  = @(x, sigma) sum(abs(x(:) / sigma));
        dNLLaplace = @(x, sigma) sign(x) / abs(sigma);
        % von Mise Distribution (Circular Normal Distribution)
        nlVonMise  = @(x, kai) numel(x) - kai * sum(cos(x(:)));
        dNLVonMise = @(x, kai) kai * sin(x);
    end
end