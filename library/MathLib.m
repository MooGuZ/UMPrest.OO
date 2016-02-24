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

% TO-DO
% 1. [x] add more activate function
% 2. [x] add more pooling function
% 3. [x] add more normalize function
% 4. [ ] reform the structure and names
% 5. [x] make functions static
% 6. [ ] evaluation function : mse, logistic ...

classdef MathLib
    methods (Static)
        % Gaussian Distribution
        function p = Gauss(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            p = exp(-((x - mu) / sigma).^2 / 2) / (sqrt(2 * pi) * sigma);
        end
        function d = dGauss(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            d = (mu - x) * exp(-((x - mu) / sigma).^2 / 2) / (sqrt(2 * pi) * sigma^3);
        end
        function p = nlGauss(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            p = (x - mu).^2 / (2 * sigma^2);
        end
        function d = dNLGauss(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            d = (x - mu) / sigma^2;
        end
        % Cauchy Distribution
        function p = Cauchy(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            p = (1 / (pi * sigma)) ./ (1 + ((x - mu) / sigma).^2);
        end
        function d = dCauchy(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            x = (x - mu) /sigma;
            d = - (2 / pi / sigma) * x ./ (1 + (x - mu).^2).^2;
        end
        function p = nlCauchy(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            p = log(1 + ((x - mu) / sigma).^2);
        end
        function d = dNLCauchy(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            x = (x - mu) / sigma;
            d = (2 / sigma) * x ./ (1 + x.^2);
        end
        function rdv = randcc(~, sz, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            rdv = sigma * tan(pi * (rand(sz) - 0.5)) + mu;
        end
        % Laplace Distribution
        function p = Laplace(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            p = exp(-abs(x - mu) / sigma) / (2 * sigma);
        end
        function d = dLaplace(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            x = abs(x - mu) / sigma;
            d = - sign(x) * exp(-x) / (2 * sigma^2);
        end
        function p = nlLaplace(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            p = abs(x - mu) / sigma;
        end
        function d = dNLLaplace(~, x, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            d = sign(x - mu) / sigma;
        end
        function rdv = randll(~, sz, sigma, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            rdv = rand(sz);
            % case : less than or equal to 0.5
            index = rdv <= 0.5;
            rdv(index) = sigma * log(2 * rdv(index)) + mu;
            % case : greater than 0.5
            index = ~index;
            rdv(index) = - sigma * log(2 * (1 - rdv(index))) + mu;
        end
        % von Mise Distribution (Circular Normal Distribution)
        function p = nlVonMise(~, x, kai, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('kai', 'var'), kai = 1; end
            p = - kai * cos(x - mu);
        end
        function d = dNLVonMise(~, x, kai, mu)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('kai', 'var'), kai = 1; end
            d = kai * sin(x - mu);
        end
        % ============= EVALUATION FUNTION =============
        function v = logistic(x, ref)
            v = - (ref .* log(x) + (1 - ref) .* log(1 - x)) / numel(x);
            if any(isinf(v(:))) || any(isnan(v(:)))
                x(x == 0) = eps;
                x(x == 1) = 1 - eps;
                v = - (ref .* log(x) + (1 - ref) .* log(1 - x)) / numel(x);
            end
            v = sum(v(:));
        end
        function d = logistic_derv(x, ref)
            d = - (ref ./ x - (1 - ref) ./ (1 - x)) / numel(x);
            if any(isinf(d(:))) || any(isnan(d(:)))
                x(x == 0) = eps;
                x(x == 1) = 1 - eps;
                d = - (ref ./ x - (1 - ref) ./ (1 - x)) / numel(x);
            end
        end     
    end
end
