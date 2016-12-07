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

classdef MathLib < handle
    methods (Static)
        % Gaussian Distribution
        function p = gauss(x, mu, sigma)
            p = exp(-((x - mu) / sigma).^2 / 2) / (sqrt(2 * pi) * sigma);
        end
        function d = gaussGradient(x, mu, sigma)
            d = (mu - x) * exp(-((x - mu) / sigma).^2 / 2) / (sqrt(2 * pi) * sigma^3);
        end
        function p = negLogGauss(x, mu, sigma)
            p = (x - mu).^2 / (2 * sigma^2);
        end
        function d = negLogGaussGradient(x, mu, sigma)
            d = (x - mu) / sigma^2;
        end
        % Cauchy Distribution
        function p = cauchy(x, mu, sigma)
            p = (1 / (pi * sigma)) ./ (1 + ((x - mu) / sigma).^2);
        end
        function d = cauchyGradient(x, mu, sigma)
            x = (x - mu) /sigma;
            d = - (2 / pi / sigma) * x ./ (1 + (x - mu).^2).^2;
        end
        function p = negLogCauchy(x, mu, sigma)
            p = log(1 + ((x - mu) / sigma).^2);
        end
        function d = negLogCauchyGradient(x, mu, sigma)
            x = (x - mu) / sigma;
            d = (2 / sigma) * x ./ (1 + x.^2);
        end
        function rdv = randcc(varargin)
            rdv = tan(pi * (rand(varargin{:}) - 0.5));
        end
        % Laplace Distribution
        function p = laplace(x, mu, sigma)
            p = exp(-abs(x - mu) / sigma) / (2 * sigma);
        end
        function d = laplaceGradient(x, mu, sigma)
            x = abs(x - mu) / sigma;
            d = - sign(x) * exp(-x) / (2 * sigma^2);
        end
        function p = negLogLaplace(x, mu, sigma)
            p = abs(x - mu) / sigma;
        end
        function d = negLogLaplaceGradient(x, mu, sigma)
            d = sign(x - mu) / sigma;
        end
        function rdv = randll(varargin)
            rdv = rand(varargin{:});
            % case : less than or equal to 0.5
            index = (rdv <= 0.5);
            rdv(index) = log(2 * rdv(index));
            % case : greater than 0.5
            index = ~index;
            rdv(index) = - log(2 * (1 - rdv(index)));
        end
        % von Mise Distribution (Circular Normal Distribution)
        function p = negLogVonMise(x, mu, sigma)
            p = - sigma * cos(x - mu);
        end
        function d = negLogVonMiseGradient(x, mu, sigma)
            d = sigma * sin(x - mu);
        end
        % prior of slowness
        function p = slow(x, ~, ~)
        % PROBLEM: hardcode 2nd dim as time-axis currently
            p = diff(x, 1, 2) .^ 2;
        end
        function d = slowGradient(x, ~, ~)
            D = diff(x, 1, 2);
            d = [-D(:, 1, :), -diff(D, 1, 2), D(:, end, :)];
        end
    end
    
    % ============= ACTIVATION FUNTION =============
    methods (Static)
        function y = sigmoid(x)
            y = 1 ./ (1 + exp(-x));
        end
        function x = sigmoidInverse(y)
            y = MathLib.bound(y, [eps, 1 - eps]);
            x = -log(1 ./ y - 1);
        end
        function d = sigmoidDifferential(y)
            y = MathLib.bound(y, [eps, 1 - eps]);
            d = y .* (1 - y);
        end
        
        function x = tanhInverse(y)
            y = MathLib.bound(y, [eps - 1, 1 - eps]);
            x = log((1 + y) ./ (1 - y)) / 2;
        end
        function d = tanhDifferential(y)
            y = MathLib.bound(y, [eps - 1, 1 - eps]);
            d = (1 - y.^2);
        end
        
        function y = relu(x)
            y = max(x, 0);
        end
        function x = reluInverse(y)
            x = max(y, 0);
        end
        function d = reluDifferential(y)
            d = double(y > 0);
        end
        
        function y = softmax(x)
            y = exp(x) / sum(exp(x(:)));
        end
        % PRB: this function is not element-vise, cause a lot of problems
        function d = softmaxDifferential(y)
            n = numel(y);
            d = eye(y) - repmat(-y(:)', n ,1);
        end
    end
    
    % ============= LIKELIHOOD =============
    methods (Static)
        function v = logistic(x, ref)
            x = MathLib.bound(x, [eps, 1 - eps]);
            v = - (ref .* log(x) + (1 - ref) .* log(1 - x));
            v = sum(v(:)) / numel(x);
        end
        function d = logisticGradient(x, ref)
            x = MathLib.bound(x, [eps, 1 - eps]);
            d = - (ref ./ x - (1 - ref) ./ (1 - x)) / numel(x);
        end
        
        function v = mse(x, ref, weight)
            % v = sum((x(:) - ref(:)).^2) / numel(x);
            if exist('weight', 'var')
                d = bsxfun(@times, x - ref, weight);
            else
                d = x - ref;
            end
            v = sum(d(:).^2) / numel(x);
        end
        function d = mseGradient(x, ref, weight)
            % d = 2 * (x - ref) / numel(x);
            if exist('weight', 'var')
                d = 2 * bsxfun(@times, x - ref, weight);
            else
                d = 2 * (x - ref) / numel(x);
            end
        end
        
        function v = tmse(x, ref)
            d = bsxfun(@times, (x - ref).^2, (0.9).^(size(x, 2) - 1 : -1 : 0));
            v = sum(d(:)) / numel(x);
        end
        function d = tmseGradient(x, ref)
            d = (2 / numel(x)) * bsxfun(@times, x - ref, ...
                (0.9).^(size(x, 2) - 1 : -1 : 0));
        end
        
        function v = kldiv(x, ref)
            % x = MathLib.bound(x, [eps, inf]);
            % ref = MathLib.bound(ref, [eps, inf]);
            v = sum(x .* log(x ./ ref), 1);
            v = mean(v(:));
        end
        function d = kldivGradient(x, ref)
            % x = MathLib.bound(x, [eps, inf]);
            % ref = MathLib.bound(ref, [eps, inf]);
            d = (log(x ./ ref) + 1) / (numel(x) / size(x, 1));
        end
    end
    
    % ======================= Calculation Operator =======================
    methods (Static)
        function y = nnconv(x, filter, bias, shape)
            y = zeros(MathLib.nnconvsize(size(x), size(filter), shape), 'like', x);
            for k = 1 : size(x, 4)
                for i = 1 : size(filter, 4)
                    for j = 1 : size(x, 3)
                        y(:, :, i, k) = y(:, :, i, k) ...
                            + conv2(x(:, :, j, k), filter(:, :, j, i), shape);
                    end
                    y(:, :, i, k) = y(:, :, i, k) + bias(i);
                end
            end
        end
        
        function [dI, dF, dB] = nnconvDifferential(d, input, filter, shape)
            fsize    = [size(filter, 1), size(filter, 2)];
            nchannel = size(filter, 3);
            nfilter  = size(filter, 4);
            nsample  = size(d, 4);
            % flip version of INPUT and FILTER (on dimension 1 and 2)
            flipI = matflip(input);
            flipF = matflip(filter);
            % pre-calculate coordinates
            if strcmpi(shape, 'same')
                [nRow, nCol, ~] = size(input); % number of row and column
                posFC = ceil((fsize + 1) / 2); % position of filter center
            end
            % derivatives of INPUT
            dI = zeros(size(input), 'like', input);
            switch shape
              case {'valid'}
                for k = 1 : nsample
                    for j = 1 : nchannel
                        for i = 1 : nfilter
                            dI(:, :, j, k) = dI(:, :, j, k) + ...
                                conv2(flipF(:, :, j, i), d(:, :, i, k), 'full');
                        end
                    end
                end
                
              case {'same'}
                % derivative of input
                if all(mod(fsize, 2)) % size of filter is odd in both direction
                    for k = 1 : nsample
                        for j = 1 : nchannel
                            for i = 1 : nfilter
                                dI(:, :, j, k) = dI(:, :, j, k) ...
                                    + conv2(d(:, :, i, k), flipF(:, :, j, i), 'same');
                            end
                        end
                    end
                else
                    posTL = posFC - 1;                % top-left coordinate
                    posBR = posTL + [nRow, nCol] - 1; % bottom-right coordinate
                    for k = 1 : nsample
                        for j = 1 : nchannel
                            for i = 1 : nfilter
                                res = conv2(d(:, :, i,  k), flipF(:, :, j, i), 'full');
                                dI(:, :, j, k) = dI(:, :, j, k) ...
                                    + res(posTL(1) : posBR(1), posTL(2) : posBR(2));
                            end
                        end
                    end
                end
            
              case 'full'
                for k = 1 : nsample
                    for j = 1 : nchannel
                        for i = 1 : nfilter
                            dI(:, :, j, k) = dI(:, :, j, k) + ...
                                    conv2(d(:, :, i, k), flipF(:, :, j, i), 'valid');
                        end
                    end
                end
            end
            % derivatives of FILTER
            if nargout > 1
                dF = zeros(size(filter), 'like', filter);
                switch lower(shape)
                  case {'valid'}
                    for i = 1 : nfilter
                        for j = 1 : nchannel
                            for k = 1 : nsample
                                dF(:, :, j, i) = dF(:, :, j, i) + ...
                                    conv2(flipI(:, :, j. k), d(:, :, i, k), 'valid');
                            end
                        end
                    end
                    
                  case {'same'}
                    posTL = [nRow, nCol] - posFC + 1; % top-left coordinate
                    posBR = posTL + fsize - 1;        % bottom-right coordinate
                    for i = 1 : nfilter
                        for j = 1 : nchannel
                            for k = 1 : nsample
                                res = conv2(d(:, :, i, k), flipI(:, :, j, k), 'full');
                                dF(:, :, j, i) = dF(:, :, j, i) + ...
                                    res(posTL(1) : posBR(1), posTL(2) : posBR(2));
                            end
                        end
                    end
                    
                  case {'full'}
                    for i = 1 : nfilter
                        for j = 1 : nchannel
                            for k = 1 : nsample
                                dF(:, :, j, i) = dF(:, :, j, i) + ...
                                    conv2(d(:, :, i, k), flipI(:, :, j, k), 'valid');
                            end
                        end
                    end
                end
            end
            % derivatives of BIAS
            if nargout > 2
                dB = MathLib.margin(d, 3);
            end
        end
        
        function dsize = nnconvsize(dsize, fsize, shape)
            if numel(dsize) < 3
                dsize = [dsize, ones(1, 3 - numel(dsize))];
            end
            
            % type conversion in case of symbolic
            assert(logical(dsize(3) == fsize(3)));
            
            switch lower(shape)
              case {'same'}
                dsize = [dsize(1 : 2), fsize(4), dsize(4 : end)];
                
              case {'valid'}
                dsize = [dsize(1 : 2) - fsize(1 : 2) + 1, fsize(4), dsize(4 : end)];
                
              case {'full'}
                dsize = [dsize(1 : 2) + fsize(1 : 2) - 1, fsize(4), dsize(4 : end)];
            end
        end
    end
    
    methods (Static)
        function tof = isinteger(x)
            tof = not(iscell(x)) && all(x(:) == round(x(:))) && not(any(isinf(x(:))));
        end
        
        function v = rolloff(n, m)
            v = ones(n, 1);
            v(m + 1 : end) = 0.5 * (1 + cos(linspace(0, pi, n - m)));
        end
        
        function x = mask(x, ind)
            x(~ind) = 0;
        end
        
        function C = objarr2cell(A)
            C = arrayfun(@(el) el, A, 'UniformOutput', false);
        end
        
        function c = pack2cell(x, dim)
            orgsz = size(x);
            if not(exist('dim', 'var'))
                dim = numel(orgsz);
            end
            x = vec(x, dim - 1, 'both');
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
        
        function x = splitDim(x, dim, szarr)
            if dim >= 1 && dim <= nndims(x)
                sz = size(x);
                if isscalar(szarr) || prod(szarr) ~= sz(dim)
                    szarr = [szarr, sz(dim) / prod(szarr)];
                end
                sz = [sz(1 : dim-1), szarr, sz(dim+1 : end)];
                x  = reshape(x, sz);
            end
        end
        
        function x = expandDim(x, dim)
            if dim >= 1 && dim < nndims(x)
                sz = size(x);
                sz = [sz(1 : dim-1), sz(dim) * sz(dim+1), sz(dim+2 : end)];
                x  = reshape(x, sz);
            end
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
            index = bsxfun(@plus, index, MathLib.mapToDim((0 : n - 1) * groupSize, dim));
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
        
        function value = margin(data, dim)
            datadim = nndims(data);
            if datadim < dim
                value = sum(data(:));
            elseif datadim == dim
                value = sum(vec(data, dim))';
            else
                data = vec(vec(data, dim - 1, 'front'), 2, 'back');
                value = sum(sum(data, 1), 3)';
            end
        end
        
       function [M, flag] = concatecell(C, unitdim)
            if iscell(C)
                switch numel(C)
                  case {0}
                    M    = [];
                    flag = true;
                
                  case {1}
                    M    = C{1};
                    flag = true;
                
                  otherwise
                    diminfo = cellfun(@ndims, C);
                    if isscalar(unique(diminfo))
                        sizeinfo = cellfun(@size, C(:), 'UniformOutput', false);
                        if all(vec(diff(cell2mat(sizeinfo), 1, 1)) == 0)
                            if not(exist('unitdim', 'var'))
                                unitdim = nndims(C{1});
                            end
                            M    = cell2mat(reshape(C, [ones(1, unitdim), numel(C)]));
                            flag = true;
                            return
                        end
                    end
                    M    = C;
                    flag = false;
                    % elsize = size(C{1});
                    % for i = 2 : numel(C)
                    %     assert(numel(size(C{i})) == numel(elsize), 'MathLib:RuntimeError', ...
                    %            'Size of matrix in the cell mismatch!');
                    %     assert(all(size(C{i}) == elsize), 'MathLib:RuntimeError', ...
                    %            'Size of matrix in the cell mismatch!');
                    % end
                    % elsize = MathLib.trimtail(elsize, 1);
                    % if isempty(elsize)
                    %     elsize = 1;
                    % end
                    % if numel(elsize) == 1
                    %     M = repmat(C{1}, 1, numel(C));
                    % else
                    %     M = repmat(C{1}, [ones(1, numel(elsize)), numel(C)]);
                    %     M = reshape(M, [prod(elsize), numel(C)]);
                    % end
                    % for i = 2 : numel(C)
                    %     M(:, i) = C{i}(:);
                    % end
                    % if numel(elsize) > 1
                    %     M = reshape(M, [MathLib.trimtail(elsize, 1), numel(C)]);
                    % end
                end
            else
                M = C;
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
            C = [vec(A, dim - 1, 'both'), vec(B, dim - 1, 'both')];
            C = reshape(C, [unitsize, size(C, 2)]);
        end
    end
end
