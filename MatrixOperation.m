% This class containes several self-define matrix operations which are
% required by my other program.
classdef MatrixOperation
    methods (Static)
        % C = MATSPLIT(M, DIM) split multi-dimension matrix M into a cell
        % array containing matrices with DIM dimensions.
        function C = matsplit(M, dim)
            assert(MathLib.isinteger(dim) && dim > 0, ...
                'DIM_KEEP must to be a positive integer!');
            
            szinfo = size(M);
            % split matrix if it has more dimension than the requirement
            if dim < numel(szinfo)
                M = vec(M, dim, 'both');
                C = cell(size(M, 2), 1);
                for i = 1 : numel(C)
                    C{i} = reshape(M(:, i), [szinfo(1 : dim), 1]);
                end
                C = reshape(C, [szinfo(dim+1 : end), 1]);
            else % otherwise put matrix into a cell
                C = {M};
            end
        end
        
        % M = CELLCOMBINE(C, DIM) convert a cell array into a matrix by
        % concatenate cells along the DIM-th dimension. However, DIM would
        % be ignored if cell element has more than DIM-1 dimensions.
        %
        % This is basically reverse operation of MATSPLIT, cannot use in
        % general purpose.
        function M = cellcombine(C, dim)
            if exist('dim', 'var')
                dim = max(nndims(C{1}) + 1, dim);
            else
                dim = nndims(C{1}) + 1;
            end
            
            szinfo = size(C);
            M = cat(dim, C{:});
            M = MathLib.splitDim(M, dim, szinfo);
        end
        
        % [XSET, padsize] = GETSTRIDESET(X, STRIDE, REFPOINT, DIRECTION)
        function [xset, padsize] = getStrideSet(x, stride, refpoint, direction)
            M = size(x, 1);
            N = size(x, 2);
            L = numel(x) / (M * N);
            m = stride(1);
            n = stride(2);
            
            % STEP 0 : setup default values
            if not(exist('refpoint', 'var')),  refpoint  = [1,1];    end
            if not(exist('direction', 'var')), direction = 'normal'; end
            
            % STEP 1 : padding matrix with zeros
            if all(refpoint == [1,1]) % post padding
                padpre  = [0, 0];
                padpost = mod(-[M, N], [m, n]);
                P = padarray(x, padpost, 0, 'post');
            else % both-side padding
                switch direction
                    case {'normal'}
                        gridStart = refpoint;
                        gridEnd   = refpoint + [m, n] - 1;
                        
                    case {'reverse'}
                        gridEnd   = refpoint;
                        gridStart = refpoint - [m, n] + 1;
                end
                % calculate padding size on each side
                nrowGrid = max(ceil((gridStart(1)-1) / m), ceil((M-gridEnd(1)) / m));
                ncolGrid = max(ceil((gridStart(2)-1) / n), ceil((N-gridEnd(2)) / n));
                padpre  = [nrowGrid * m, ncolGrid * n] - (gridStart - 1);
                padpost = [nrowGrid * m, ncolGrid * n] - ([M, N] - gridEnd);
                % padding array
                P = padarray(padarray(x, padpre, 0, 'pre'), padpost, 0, 'post');
            end
            % compose padding size
            padsize = [padpre, padpost];
            
            % STEP 2 : get each sub-matrix
            nrow = size(P, 1) / m;
            ncol = size(P, 2) / n;
            % reshape to separate grids
            P = reshape(P, [m, nrow, n, ncol, L]);
            % permute to make slice in first two dimensions
            P = permute(P, [2, 4, 5, 1, 3]);
            % calculate size of each sub-matrix
            szinfo = size(x);
            szinfo = [nrow, ncol, szinfo(3:end)];
            % put sub-matrix into cell array
            xset = cell(m, n);
            switch direction
                case {'normal'}
                    for i = 1 : m
                        for j = 1 : n
                            xset{i, j} = reshape(P(:, :, :, i, j), szinfo);
                        end
                    end
                    
                case {'reverse'}
                    for i = 1 : m
                        for j = 1 : n
                            xset{m - i + 1, n - j + 1} = reshape(P(:, :, :, i, j), szinfo);
                        end
                    end
            end
        end
        
        % X = COMBINESTRIDESET(XSET, PADSIZE, DIRECTION)
        function x = combineStrideSet(xset, padsize, direction)
            if exist('direction', 'var') && strcmpi(direction, 'reverse')
                xset = flip(flip(xset, 1), 2);
            end
            
            % reshape each sub-matrix into a 3D matrix
            [m, n] = size(xset);
            szinfo = size(xset{1});
            M      = szinfo(1);
            N      = szinfo(2);
            L      = prod(szinfo(3:end));
            for i = 1 : m
                for j = 1 : n
                    xset{i, j} = reshape(xset{i, j}, [M, N, L]);
                end
            end
            % combine sub-matrix along 4th dimension
            x = cat(4, xset{:});
            % reshape and permute x to recover original matrix
            x = reshape(x, [M, N, L, m, n]);
            x = permute(x, [4, 1, 5, 2, 3]);
            x = reshape(x, [m * M, n * N, L]);
            % remove paddings if exist
            if exist('padsize', 'var') && any(padsize(:))
                x = x(1 + padsize(1) : end - padsize(3), 1 + padsize(2) : end - padsize(4), :);
            end
            % recover shape of higher dimensions
            x = reshape(x, [size(x, 1), size(x, 2), szinfo(3:end)]);
        end
        
        % POS = GETREFPOINT(SZINFO) return position of reference point in
        % convolution operation.
        function pos = getRefPoint(szinfo)
            pos = ceil((szinfo(1:2) + 1) / 2);
        end
        
        function x = diminsert(x, dim)
            if dim > nndims(x)
                return
            else
                xsize = size(x);
                x = reshape(x, [xsize(1:dim-1), 1, xsize(dim:end)]);
            end                
        end
        
        function x = dimcomb(x, dfrom, dto)
            if dfrom >= nndims(x)
                return
            elseif not(exist('dto', 'var'))
                dto = dfrom + 1;
            end
            xsize = size(x);
            x = reshape(x, [xsize(1:dfrom-1), prod(xsize(dfrom:dto)), xsize(dto+1:end)]);
        end
        
        % convolutional operation specified for neural network
        function y = nnconv(x, f, shape)
            if strcmpi(shape, 'same')
                padsize = ([size(f, 1), size(f, 2)] - 1) / 2;
                if MathLib.isinteger(padsize)
                    x = padarray(x, padsize, 0, 'both');
                else
                    x = padarray(x, floor(padsize), 0, 'pre');
                    x = padarray(x, ceil(padsize), 0, 'post');
                end
            elseif not(strcmpi(shape, 'valid'))
                error('ONLY SUPPORT SAME OR VALID!');
            end
            % flip filter's 3rd dimension to get right results
            f = flip(f, 3);
            % separate filers
            if size(f, 4) > 1
                f = MatrixOperation.matsplit(f, 3);
                y = cell(numel(f));
                for i = 1 : numel(f)
                    y{i} = convn(x, f{i}, 'valid');
                end
                y = cat(3, y{:});
            else
                y = convn(x, f, 'valid');
            end
        end
    end
end