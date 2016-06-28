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

classdef MathLib < handle
    methods
        % Gaussian Distribution
        function p = gauss(~, x, mu, sigma)
            p = exp(-((x - mu) / sigma).^2 / 2) / (sqrt(2 * pi) * sigma);
        end
        function d = gaussGradient(~, x, mu, sigma)
            d = (mu - x) * exp(-((x - mu) / sigma).^2 / 2) / (sqrt(2 * pi) * sigma^3);
        end
        function p = negLogGauss(~, x, mu, sigma)
            p = (x - mu).^2 / (2 * sigma^2);
        end
        function d = negLogGaussGradient(~, x, mu, sigma)
            d = (x - mu) / sigma^2;
        end
        % Cauchy Distribution
        function p = cauchy(~, x, mu, sigma)
            p = (1 / (pi * sigma)) ./ (1 + ((x - mu) / sigma).^2);
        end
        function d = cauchyGradient(~, x, mu, sigma)
            x = (x - mu) /sigma;
            d = - (2 / pi / sigma) * x ./ (1 + (x - mu).^2).^2;
        end
        function p = negLogCauchy(~, x, mu, sigma)
            p = log(1 + ((x - mu) / sigma).^2);
        end
        function d = negLogCauchyGradient(~, x, mu, sigma)
            x = (x - mu) / sigma;
            d = (2 / sigma) * x ./ (1 + x.^2);
        end
        function rdv = randcc(~, sz, mu, sigma)
            if ~exist('mu', 'var'), mu = 0; end
            if ~exist('sigma', 'var'), sigma = 1; end
            rdv = sigma * tan(pi * (rand(sz) - 0.5)) + mu;
        end
        % Laplace Distribution
        function p = laplace(~, x, mu, sigma)
            p = exp(-abs(x - mu) / sigma) / (2 * sigma);
        end
        function d = laplaceGradient(~, x, mu, sigma)
            x = abs(x - mu) / sigma;
            d = - sign(x) * exp(-x) / (2 * sigma^2);
        end
        function p = negLogLaplace(~, x, mu, sigma)
            p = abs(x - mu) / sigma;
        end
        function d = negLogLaplaceGradient(~, x, mu, sigma)
            d = sign(x - mu) / sigma;
        end
        function rdv = randll(~, sz, mu, sigma)
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
        function p = negLogVonMise(~, x, mu, sigma)
            p = - sigma * cos(x - mu);
        end
        function d = negLogVonMiseGradient(~, x, mu, sigma)
            d = sigma * sin(x - mu);
        end
    end
    
    % ============= ACTIVATION FUNTION =============
    methods (Static)
        function y = sigmoid(x)
            y = 1 ./ (1 + exp(-x));
        end
        function x = sigmoidInverse(y)
            y = MathLib.bound(y, [eps, 1 - eps]);
            x = -log(1 ./ y - 1)
        end
        function d = sigmoidDifferential(d, y)
            y = MathLib.bound(y, [eps, 1 - eps]);
            d = d .* (y .* (1 - y));
        end
        
        function x = tanhInverse(y)
            y = MathLib.bound(y, [eps - 1, 1 - eps]);
            x = log((1 + y) ./ (1 - y)) / 2;
        end
        function d = tanhDifferential(d, y)
            y = MathLib.bound(y, [eps - 1, 1 - eps]);
            d = d .* (1 - y.^2);
        end
        
        function y = relu(x)
            y = max(x, 0);
        end
        function x = reluInverse(y)
            x = max(y, 0);
        end
        function d = reluDifferential(d, y)
            d = MathLib.mask(d, y > 0);
        end
    end
    
    % ============= EVALUATION FUNTION =============
    methods (Static)
        function v = logistic(x, ref)
            x = MathLib.bound(x, [eps, 1 - eps]);
            v = - (ref .* log(x) + (1 - ref) .* log(1 - x));
            v = sum(v(:));
        end
        function d = logisticGradient(x, ref)
            x = MathLib.bound(x, [eps, 1 - eps]);
            d = - (ref ./ x - (1 - ref) ./ (1 - x));
        end
        
        function v = mse(x, ref)
            v = sum((x(:) - ref(:)).^2) / numel(x);
        end
        function d = mseGradient(x, ref)
            d = 2 * (x - ref) / numel(x);
        end
    end
    
    methods (Static)
        function tof = isinteger(x)
            tof = (x == round(x));
        end
        
        function v = rolloff(n, m)
            v = ones(n, 1);
            v(m + 1 : end) = 0.5 * (1 + cos(linspace(0, pi, n - m)));
        end
        
        function x = vec(x, dim, mode)
            if exist('dim', 'var')
                if ~exist('mode', 'var')
                    mode = 'front';
                end
                
                sz = size(x);
                
                switch lower(mode)
                  case {'front'}
                    if dim <= 1
                        return
                    elseif numel(sz) > dim
                        x = reshape(x, [prod(sz(1 : dim)), sz(dim + 1 : end)]);
                    else
                        x = x(:);
                    end
                    
                  case {'back'}
                    if dim <= 0
                        x = x(:)';
                    elseif numel(sz) > dim
                        x = reshape(x, [sz(1 : dim), prod(sz(dim + 1 : end))]);
                    end
                    
                  case {'both'}
                    if dim <= 0
                        x = x(:)';
                    elseif numel(sz) > dim
                        x = reshape(x, ...
                                    [prod(sz(1 : dim)), prod(sz(dim + 1 : end))]);
                    else
                        x = x(:);
                    end
                    
                  otherwise
                    error('ArguemntError:MathLib', ...
                          'Unrecognized vectorization mode : %s', upper(mode));
                end
            else
                x = x(:);
            end
        end
        
        function x = mask(x, ind)
            x(~ind) = 0;
        end
        
        function c = pack2cell(x, dim)
            orgsz = size(x);
            if not(exist('dim', 'var'))
                dim = numel(orgsz);
            end
            x = MathLib.vec(x, dim - 1, 'both');
            c = cell(1, size(x, 2));
            if dim > 2
                unitsize = orgsz(1 : dim - 1);
                for i = 1 : numel(c)
                    c{i} = reshape(x(:, i), unitsize);
                end
            else
                for i = 1 : numel(c)
                    c{i} = x(:, i);
                end
            end
        end
        
        function tf = ind2tf(x, minValue, maxValue)
            assert(MathLib.isinteger(minValue) && MathLib.isinteger(maxValue));
            x  = MathLib.bound(x(:)', [minValue, maxValue]) - (minValue - 1);
            tf = false(maxValue - minValue + 1, numel(x));
            i  = x + size(tf, 1) * (0 : numel(x) - 1);
            tf(i) = true;
        end
        
        function x = bound(x, range)
            assert(numel(range) == 2, 'MathLib:WrongParameter', ...
                'RANGE should be in form of [MIN, MAX]');
            
            lowerBound = range(1);
            upperBound = range(2);
            
            if lowerBound ~= -inf
                x(x < lowerBound) = lowerBound;
            end
            
            if upperBound ~= inf
                x(x > upperBound) = upperBound;
            end
        end
        
        function x = smpvec(n, v, pos, u)
            x = ones(1, n) * v;
            x(pos) = u;
        end
        
        function x = mapToDim(x, dim)
            x = reshape(x, MathLib.smpvec(max(dim, 2), 1, dim, numel(x)));
        end
        
        function [out, index] = groupmax(in, groupSize, dim)
            shape = size(in);
            
            assert(numel(shape) >= dim, ...
                'UMPrest:ArgumentError', ...
                'Operation on dimension %d is not practical', dim);
            
            r = mod(shape(dim), groupSize);
            if r ~= 0
                padsize = zeros(1, numel(size(in)));
                padsize(dim) = groupSize - r;
                in = padarray(in, padsize, -inf, 'post');
                shape = size(in);
            end
            
            % reshape input matrix
            n = shape(dim) / groupSize;
            if dim < numel(shape)
                shape(dim+1) = shape(dim+1) * n;                
            else
                shape = [shape, n];
            end
            shape(dim) = groupSize;
            in = reshape(in, shape);

            % get maximum value and index
            [out, index] = max(in, [], dim);
            
            % reshape return values to match original input shape
            shape(dim)   = n;
            shape(dim+1) = shape(dim+1) / n;
            out   = reshape(out, shape);
            index = reshape(index, shape);
            
            % update indexs
            index = bsxfun(@plus, index, MathLib.mapToDim((0 : n - 1) * size(in, dim), dim));
        end
        
        function x = offsetOnDim(x, dim, step)
            x = bsxfun(@plus, x, MathLib.mapToDim((0 : size(x, dim) - 1) * step, dim));
        end
        
        function a = modarr(a, b, allowExtend, validfunc)
            if not(exist('allowExtend', 'var'))
                allowExtend = false;
            end
            
            if allowExtend
                if numel(a) < numel(b)
                    a = modarr(b, a);
                    return
                end
            else
                assert(numel(a) >= numel(b), ...
                    'Do not allow modification that changes size of original array');
                if exist('validfunc', 'var')
                    assert(all(arrayfun(validfunc, b, a(1 : numel(b)))));
                end
                a(1 : numel(b)) = b(:);
            end
        end
        
        function arr = trimtail(arr, v)
            ind = numel(arr);
            while ind > 0 && arr(ind) == v
                ind = ind - 1;
            end
            arr = arr(1 : ind);
        end
        
        function n = ndims(mat)
            n = numel(MathLib.trimtail(size(mat), 1));
        end
        
        function M = concatecell(C)
            if isempty(C)
                M = [];
            elseif numel(C) == 1
                M = C{1};
            else
                elsize = size(C{1});
                for i = 2 : numel(C)
                    assert(numel(size(C{i})) == numel(elsize), 'MathLib:RuntimeError', ...
                        'Size of matrix in the cell mismatch!');
                    assert(all(size(C{i}) == elsize), 'MathLib:RuntimeError', ...
                        'Size of matrix in the cell mismatch!');
                end
                elsize = MathLib.trimtail(elsize, 1);
                if isempty(elsize)
                    elsize = 1;
                end
                if numel(elsize) == 1
                    M = repmat(C{1}, 1, numel(C));
                else
                    M = repmat(C{1}, [ones(1, numel(elsize)), numel(C)]);
                    M = reshape(M, [prod(elsize), numel(C)]);
                end
                for i = 2 : numel(C)
                    M(:, i) = C{i}(:);
                end
                if numel(elsize) > 1
                    M = reshape(M, [MathLib.trimtail(elsize, 1), numel(C)]);
                end
            end
        end
        
        function D = dupcell(C, n)
            assert(iscell(C) && isnumeric(n));
            assert(numel(C) == numel(n) || isscalar(n));
            if isscalar(n)
                D = C(kron(1 : numel(C), ones(1, n)));
            else
                n = cumsum(n(:)');
                n = [n(1 : end - 1) + 1; n(2 : end)];
                ind = ones(1, n(end));
                for i = 1 : size(n, 2)
                    ind(n(1, i) : n(2, i)) = i + 1;
                end
                D = C(ind);
            end
        end
        
        function C = matconcate(A, B)
            dim = min(ndims(A), ndims(B));
            unitsize = size(A);
            unitsize = unitsize(1 : dim - 1);
            C = [MathLib.vec(A, dim - 1, 'both'), MathLib.vec(B, dim - 1, 'both')];
            C = reshape(C, [unitsize, size(C, 2)]);
        end
    end
end
