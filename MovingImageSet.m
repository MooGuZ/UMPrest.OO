classdef MovingImageSet < handle
    methods
        function package = next(obj, n)
            if not(exist('n', 'var')), n = 1; end
            samples = cell(1, n);
            for i = 1 : n
                samples{i} = obj.generate( ...
                    obj.db(:, :, randi(obj.volumn, 1, obj.objectPerSample)));
            end
            package = obj.data.packup(samples);
            if nargout == 0
                obj.data.send(package);
            end
        end
        
        function sample = generate(obj, imgs)
            samples = cell(1, size(imgs, 3));
            for i = 1 : numel(samples)
                samples{i} = obj.moving(imgs(:, :, i));
            end
            sample = obj.mixing(samples{:});
        end
        
        function seq = moving(obj, img)
            imsize = size(img);
            % pick a random moving speed
            spd = 2 * arrayfun(@randi, obj.maxSpeed) .* (randi(2, 1, 2) - 1.5);
            % calculate leagal area of img center
            dist = ceil(imsize / 2);
            bottom = dist(1) + 1;
            top    = obj.canvasSize(1) - dist(1);
            left   = dist(2) + 1;
            right = obj.canvasSize(2) - dist(2);
            % pick a random position
            traj = cell(1, obj.nframes);
            traj{1} = [bottom + randi(top - bottom + 1) - 1, ...
                left + randi(right - left + 1) - 1];
            for i = 2 : obj.nframes
                pos = traj{i-1} + spd;
                while (pos(1) < bottom) || (pos(1) > top) || (pos(2) < left) || (pos(2) > right)
                    if (pos(1) < bottom) || (pos(1) > top)
                        spd(1) = -spd(1);
                    end
                    if (pos(2) < left) || (pos(2) > right)
                        spd(2) = -spd(2);
                    end
                    pos = traj{i-1} + spd;
                end
                traj{i} = pos;
            end
            % create sequence
            seq = zeros([obj.canvasSize, obj.nframes]);
            for i = 1 : obj.nframes
                seq(traj{i}(1) - dist(1) + (1 : imsize(1)), ...
                    traj{i}(2) - dist(2) + (1 : imsize(2)), ...
                    i) = img;
            end
        end
        
        function sample = mixing(~, varargin)
            sample = cat(4, varargin{:});
            sample = max(sample, [], 4);
        end
    end
    
    methods
        function obj = MovingImageSet(db)
            obj.db   = db;
            obj.data = DatasetAP(obj, 2, true);
        end
    end
    
    properties
        db, data
        objectPerSample = 2
        maxSpeed = [3, 3]
        canvasSize = [64, 64]
        nframes = 20
    end
    properties (Constant)
        islabelled = false
    end
    properties (Dependent)
        volumn % number of unique samples in the dataset
    end
    methods
        function value = get.volumn(obj)
            value = size(obj.db, 3);
        end
    end
end