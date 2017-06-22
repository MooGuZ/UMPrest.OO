classdef TranslationFilter < SISOUnit & FeedforwardOperation
% TRANSLATIONFILTER is not complete until I really need it to deal concrete problem.
    methods
        function tflt = transfilter(obj, object, motion)
            % PRE-ASSUMPTION : motion pattern is translation only
            if mod(obj.predmode.fltsize(2), 2) == 0
                zpoint = obj.predmode.fltsize(2) / 2 + 1;
                xrange = (1 - zpoint : zpoint - 2) / object.size;
            else
                zpoint = (obj.predmode.fltsize(2) + 1) / 2;
                xrange = (1 - zpoint : zpoint - 1) / object.size;
            end
            if mod(obj.predmode.fltsize(1), 2) == 0
                zpoint = obj.predmode.fltsize(1) / 2 + 1;
                yrange = (zpoint - 1 : -1 : 2 - zpoint) / object.size;
            else
                zpoint = (obj.predmode.fltsize(2) + 1) / 2;
                yrange = (zpoint - 1 : -1 : 1 - zpoint) / object.size;
            end
            [X, Y] = meshgrid(xrange, yrange);
            Z = complex(X, Y);
            % motion vector
            if motion.translation.status
                theta = motion.translation.direction;
                alpha = motion.translation.speed;
                mV = alpha * exp(1j*theta);
            else
                mV = complex(0, 0);
            end
            % constant sigma
            sigma = 0.05;
            % transform filter
            fsize = [obj.predmode.fltsize, obj.nframes, obj.predmode.nframes];
            tflt = zeros(fsize);
            for i = 1 : obj.predmode.nframes
                for j = 1 : obj.nframes
                    tflt(:, :, j, i) = ...
                        exp(-abs(Z - (obj.nframes + i - j) * mV).^2 / (2 * sigma^2));
                    alpha = sum(sum(tflt(:, :, j, i)));
                    tflt(:, :, j, i) = tflt(:, :, j, i) / (alpha * obj.nframes);
                end
            end
            % normalization
            % tflt = reshape(tflt, prod(fsize(1:3)), fsize(4));
            % tflt = bsxfun(@rdivide, tflt, sum(tflt));
            % tflt = reshape(tflt, fsize);
        end
    end
end
