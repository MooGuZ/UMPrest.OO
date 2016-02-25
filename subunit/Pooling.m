classdef Pooling < handle
% POOLING is the abstraction of pooling methods in convolutional neural network.

% MooGu Z. <hzhu@case.edu>
% Feb 24, 2016

    properties (Access = protected)
        pool = struct('type',  'off', ...
                      'proc',  @nullfunc, ...
                      'bprop', @nullfunc, ...
                      'size',  3);
    end
    
    properties (Abstract)
        wspace
    end
    
    properties (Dependent)
        poolType, poolSize
    end
    methods
        function value = get.poolType(obj)
            value = obj.pool.type;
        end
        function set.poolType(obj, value)
            switch lower(value)
                case 'max'
                    obj.pool.type  = 'max';
                    obj.pool.proc  = @obj.maxpool;
                    obj.pool.bprop = @obj.maxpool_bprop;
                    
                case 'off'
                    obj.pool.type  = 'off';
                    obj.pool.proc  = @nullfunc;
                    obj.pool.bprop = @nullfunc;
            end
        end
        
        function value = get.poolSize(obj)
            value = obj.pool.size;
        end
        function set.poolSize(obj, sz)
            assert(isscalar(sz) && sz > 0 ...
                && round(sz) == sz);
            obj.pool.size = sz;
        end
    end
    
    methods (Access = protected)
        function dimout = poolin2out(obj, dimin)
            switch obj.pool.type
                case 'off'
                    dimout = dimin;
                    
                case 'max'
                    dimout = [floor(dimin(1:2) / obj.pool.size), dimin(3)];
                    
                otherwise
                    error('[Pooling] Unrecognized type');
            end
        end
    end

    methods
        function out = maxpool(obj, in)
            psize = obj.pool.size;
            
            % create temporal map from index to coordinate to accelerate speed
            [r, c] = ind2sub(psize, (1 : psize^2)'); 
            ind2rc = [r, c];
            
            dimin  = size(in);
            dimout = [floor(dimin(1:2) / psize), dimin(3)];
            
            out = zeros(dimout);
            idx = zeros(size(in));
            
            for i = 1 : dimout(1)
                for j = 1 : dimout(2)
                    for k = 1 : dimout(3)
                        window = in( ...
                            psize*(i-1) + 1 : psize*i, ...
                            psize*(j-1) + 1 : psize*j, ...
                            k);
                        
                        out(i, j, k) = max(window(:));
                        
                        rc = ind2rc(window(:) == out(i, j, k), :);
                        idx(psize*(i-1) + rc(1), psize*(j-1) + rc(2), k) = 1;
                    end
                end
            end
            
            obj.wspace.pool.idx    = idx;
            obj.wspace.pool.dimin  = dimin;
            obj.wspace.pool.dimout = dimout;
        end
        
        function delta = maxpool_bprop(obj, delta)
            dimout = obj.wspace.pool.dimout;
            dimin  = obj.wspace.pool.dimin;
            psize  = obj.pool.size;
            
            delta  = reshape(delta, dimout);
            
            v  = zeros(dimin);
            if any(mod(dimin(1:2), psize))
                for i = 1 : dimin(3)
                    v(1 : dimout(1) * psize, 1 : dimout(2) * psize, i) ...
                        = kron(delta(:, :, i), ones(psize));
                end
            else
                for i = 1 : dimin(3)
                    v(:, :, i) = kron(delta(:, :, i), ones(psize));
                end
            end
            delta = v .* obj.wspace.pool.idx;
        end

        % = Another Implementation based on BLOCKPROC, however, it is slow =
        % function vi = findmax(~, B)
        %     [v, r] = max(B.data, [], 1);
        %     [v, c] = max(v);
        %     rc = [r(c), c] + B.location - 1;
        %     vi = [v, rc];
        % end
        %     
        % function out = maxPool(obj, in)
        %     % create map from index to coordinates to accelerate process
        %     [r, c] = ind2sub(obj.pool.size, (1 : obj.pool.size^2)');
        %     obj.wspace.pool.i2rc = [r, c] - 1; % set first element to [0,0]
        %     max pool by BLOCKPROC
        %     mat = blockproc(in(:, :, 1), obj.pool.size * [1, 1], @obj.findmax, 'UseParallel', true);
        %     if size(in, 3) == 1
        %         out = mat(:, 1 : 3 : end);
        %         obj.wspace.pool.crdr = mat(:, 2 : 3 : end);
        %         obj.wspace.pool.crdc = mat(:, 3 : 3 : end);
        %     else
        %         out = zeros(size(mat) ./ [1, 3]);
        %         crdr = out;
        %         crdc = out;
        %         
        %         out(:, :, 1)  = mat(:, 1 : 3 : end);
        %         crdr(:, :, 1) = mat(:, 2 : 3 : end);
        %         crdc(:, :, 1) = mat(:, 3 : 3 : end);
        %         
        %         for i = 2 : size(in, 3)
        %             mat = blockproc(in(:, :, i), obj.pool.size * [1, 1], @obj.findmax, 'UseParallel', true);
        %             out(:, :, i)  = mat(:, 1 : 3 : end);
        %             crdr(:, :, i) = mat(:, 2 : 3 : end);
        %             crdc(:, :, i) = mat(:, 3 : 3 : end);
        %         end
        %         
        %         obj.wspace.pool.crdr = crdr;
        %         obj.wspace.pool.crdc = crdc;
        %     end
        %     obj.wspace.pool.size = size(in);
        % end
        % 
        % function out = maxPool_bprop(obj, in)
        %     out = zeros(obj.wspace.pool.size);
        %     for f = 1 : size(out, 3)
        %         v = in(:, :, f);
        %         i = obj.wspace.pool.crdr(:, :, f);
        %         j = obj.wspace.pool.crdc(:, :, f);
        %         out(:, :, f) = sparse(i(:), j(:), v(:), size(out,1), size(out, 2));
        %     end
        % end
    end
    
    methods
        function obj = Pooling()
            obj.wspace.pool = struct();
        end
    end
end
