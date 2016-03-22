classdef NewVideoDataset < Dataset & Autoload
% NEWVIDEODATASET is the abstraction of dataset of video materials

% MooGu Z. <hzhu@case.edu>
% Mar 13, 2016

% NOTES:
% 1. initialize database in constructor, ensure 'db' is not empty
% 2. ensure every video get same length
% 3. currently only support one dimension tags
% 4. frame dimension need to be the same

    methods
        function value = volumn(obj)
            value = numel(obj.autoload.flist)
        end

        function [elsmp, smpsz] = dimout(obj)
            if isempty(obj.db)
                elsmp = nan;
                smpsz = nan;
            else
                smpsz = size(obj.db{1});
                elsmp = prod(smpsz);
            end
        end
        
        function data = next(obj, n)
            if exist('n', 'var')
                assert(n > 0 && n == floor(n));
            else
                n = 1;
            end

            data = obj.dataform(obj.fetch(n));
        end
        
        function statistic = patchstat(obj)
            assert(obj.patch.status, 'ConfigError:VideoDataset', ...
                   'patch mode is off, statistic is unavailable.');

            filter = ones(obj.framesize - obj.patch.frmsize + 1);

            stat = struct();
            stat.fcount = obj.statistic.fcount * numel(filter);
            stat.frmsum = conv2(obj.statistic.frmsum, filter, 'valid');
            stat.seqsum = conv2(obj.statistic.seqsum, filter, 'valid');

            stat.covmat = zeros(prod(obj.patch.frmsize));

            idxmat = reshape(1 : prod(obj.framesize), framesize);
            for row = 0 : obj.framesize(1) - 1
                for col = 0 : obj.framesize(2) - 1
                    patchidx = idxmat( ...
                        row + (1 : obj.patch.frmsize(1)), ...
                        col + (1 : obj.patch.frmsize(2)));
                    patchidx = patchidx(:);

                    stat.covmat = stat.covmat + ...
                        obj.statistic.covmat(patchidx, patchidx);
                end
            end
        end

        function data = datainfo(obj, data)
        % to be continue
        % 1. add fild of 'help' in structure to contain help information of
        %    each field of 'data' structure
        end

        function data = dataform(obj, datacell)
            if iscell(datacell)         % batch case
                n = numel(datacell);
                x = zeros([prod(obj.dimout), n]);
                
                if tagged
                    y = zeros([prod(obj.dimtag), n]);
                    for i = 1 : n
                        x(:, i) = MathLib.vec(obj.dataform(datacell{i}.data))
                        y(:, i) = MathLib.vec(datacell{i}.tag);
                    end
                    y = reshape(y, [obj.dimtag, n]);
                else
                    for i = 1 : n
                        x(:, i) = MathLib.vec(obj.dataform(datacell{i}));
                    end
                end
                
                x = reshape(x, [obj.dimout, n]);
                
                data = struct('x', x, 'y', y);
                data = datainfo(data);
            else                        % single case
                if obj.patch.status
                    data = randpatch(data , obj.patch.size);
                end

                switch lower(obj.postproc.method)
                  case {'none'}
                    % do nothing

                  case {'whitening'}
                    data = obj.whiteningEncode(data);

                  case {'dimnorm'}
                    data = obj.dimnormEncode(data);

                  case {'recenter'}
                    data = obj.recenterEncode(data);

                  otherwise
                    error('ConfigError:VideoDataset', ...
                          'Unrecognized post-processing method.');
                end
            end
        end
        
        function data = videorecover(obj, data)
            if isstruct(data)
                data = data.x;
            end

            switch lower(obj.postproc.method)
              case {'none'}
                % do nothing

              case {'whitening'}
                data = obj.whiteningDecode(data);

              case {'dimnorm'}
                data = obj.dimnormDecode(data);

              case {'recenter'}
                data = obj.recenterDecode(data);

              otherwise
                error('ConfigError:VideoDataset', ...
                      'Unrecognized post-processing method.');
            end
        end

        function whiteningSetup(obj)
            assert(obj.statistic.status, ...
                   'ConfigError:VideoDataset', ...
                   'whitening operation need statistic information.');

            if obj.patch.status
                stat = obj.patchstat();
            else
                stat = obj.statistic;
            end

            % bias vector
            obj.wspace.bias = stat.frmsum / stat.fcount;

            % principle component analysis
            [vec, val] = eig(stat.covmat / stat.fcount);
            [val, idx] = sort(diag(val), 'descend');
            vec = vec(:, idx);

            % output dimension according to eigen value
            npixel = stat.fcount * numel(stat.frmsum);
            pixelvar = (sum(stat.seqsum(:)) / npixel) ...
                - (sum(stat.frmsum(:)) / npixel).^2;

            threshold = pixelvar * obj.postproc.whitening.cutoffRatio;
            dim = sum(val > threshold);

            val = val(1 : dim);
            vec = vec(: 1 : dim);

            obj.wspace.encode = diag(1 ./ sqrt(val)) * vec';
            obj.wspace.decode = vec * diag(sqrt(val));

            obj.wspace.zerophase = vec * diag(1 ./ sqrt(val)) * vec';

            rodim = sum(val > pixelvar * obj.postproc.whitening.rolloffFactor);
            obj.wspace.pixelweight = ...
                MathLib.rolloff(dim, rodim) / obj.postproc.whitening.noiseRatio;
        end

        function data = whiteningEncode(obj, data)
            data = bsxfun(@minus, data, obj.wspace.bias);

            nfrm = size(data, 3);
            data = obj.wspace.encode * reshape(data, numel(data) / nfrm, nfrm);
        end

        function data = whiteningDecode(obj, data, zerophase)
            if exist('zerophase', 'var')
                data = obj.wspace.zerophase * data;
            else
                data = obj.wspace.decode * data;
            end

            if obj.patch.status
                data = reshape(data, obj.patch.frmsize, size(data, 2));
            else
                data = reshape(data, obj.framesize, size(data, 2));
            end

            data = bsxfun(@plus, data, obj.wspace.bias);
        end

        function dimnormSetup(obj)
            assert(obj.statistic.status, ...
                   'ConfigError:VideoDataset', ...
                   'Dimension normalization need statistic information.');

            if obj.patch.status
                stat = obj.patchstat();
            else
                stat = obj.statistic;
            end
            
            obj.wspace.bias = stat.seqsum / stat.fcount;
            obj.wspace.std  = sqrt((stat.seqsum - stat.frmsum.^2) / stat.fcount);
        end

        function data = dimnormEncode(obj, data)
            data = bsxfun(@minus, data, obj.wspace.bias);
            data = bsxfun(@rdivide, data, obj.wspace.std);
        end

        function data = dimnormDecode(obj, data)
            data = bsxfun(@times, data, obj.wspace.std);
            data = bsxfun(@plus, data, obj.wspace.bias);
        end

        function recenterSetup(obj)
            assert(obj.statistic.status, ...
                   'ConfigError:VideoDataset', ...
                   'whitening operation need statistic information.');

            if obj.patch.status
                stat = obj.patchstat();
            else
                stat = obj.statistic;
            end
            
            obj.wspace.bias = stat.seqsum / stat.fcount;
        end

        function data = recenterEncode(obj, data)
            data = bsxfun(@minus, data, obj.wspace.bias);
        end

        function data = recenterDecode(obj, data)
            data = bsxfun(@plus, data, obj.wspace.bias);
        end
    end

    methods
        function obj = NewVideoDataset(fpath)
            obj.tagged = false;         % [!restriction]

            obj.dbinit(fpath);
            obj.statcmd('init');

            obj.wspace = struct();

            if obj.patch.status
                obj.patch.count = obj.patch.patchPerFrame;
            end
        end
    end

    properties
        autoload = struct(...
            'froot', '', ...
            'ftype', {'', '.gif'}, ...
            'flist', {}, ...
            'complete', false, ...
            'capacity', 5e4, ...
            'read', struct());

        db
        idb

        wspace

        framesize

        patch = struct( ...
            'status', false, ...
            'frmsize', [], ...
            'nframe', [], ...
            'patchPerFrame', 7, ...
            'count', []);

        postproc = struct( ...
            'method', 'none', ...
            'whitening', struct( ...
                'noiseRatio',    0.01, ...
                'cutoffRatio',   1.25, ...
                'rolloffFactor', 8));

        statistic
    end
end
