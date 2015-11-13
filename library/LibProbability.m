% PROBCALCLIB contains anonymous functions to calculate common distribution
% and their derivatives. Prefix 'NL' means 'negative log(e)', while 'd' is
% short for 'derivative'. Noted that, all functions here ignored the average
% value 'mu'. Because most probability description works on decentralized data.
% BTW, constant terms are ignored too.
classdef LibProbability < hgsetget
    properties (Access = protected)
        % Gaussian Distribution (Normal Distribution)
        nlGauss  = @(x, sigma) sum(x(:).^2) / (2 * sigma^2);
        dNLGauss = @(x, sigma) x / sigma^2;
        % Cauchy Distribution
        nlCauchy  = @(x, sigma) sum(log(1 + (x(:) / sigma).^2));
        dNLCauchy = @(x, sigma) (2 * x) ./ (sigma^2 + x.^2);
    end
end
