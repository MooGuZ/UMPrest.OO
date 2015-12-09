classdef MotionSeparation < DPModule & UtilityLib
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function motion = proc(obj, sample)
            % calculate phase change value between frames
            data = wrapToPi(segdiff(sample.data.phase, sample.ffindex, 2));
            % calculate mask of phase difference according to amplitude
            index = false(1, size(sample.data.amplitude, 2));
            index(sample.ffindex) = true;
            mask = sample.data.amplitude > obj.amplitudeThreshold;
            mask = mask(:, 1 : end-1) & mask(:, 2 : end);
            mask = double(mask(:, ~index(2:end)));
            % compose output sample
            motion = struct('data', data, 'mask', mask, ...
                'fframe', sample.data.phase(:, sample.ffindex), ...
                'ffindex', sample.ffindex - (0 : numel(sample.ffindex)-1));
        end

        function sample = invp(~, motion)
            [npixel, nframe] = size(motion.data);
            nsegment = numel(motion.ffindex);
            % initialize components
            phase = zeros(npixel, nframe + nsegment);
            % first frame index
            ffindex = motion.ffindex + (0 : nsegment - 1);
            % original phase information
            for i = 1 : size(phase, 2)
                index = find(ffindex == i);
                if isempty(index) % not the first frame
                    phase(:, i) = wrapToPi(phase(:, i-1) + motion.data(:, i - isegment));
                else % first frame
                    isegment = index;
                    phase(:, i) = motion.fframe(:, isegment);
                end
            end
            % compose sample
            sample = struct( ...
                'data', struct('phase', phase), ...
                'ffindex', ffindex);
        end

        function setup(obj, sample)
            amp = sort(sample.data.amplitude(:), 'descend');
            obj.amplitudeThreshold = amp(ceil(p.ampQualifyFraction * numel(amp)));
        end

        function tof = ready(obj)
            tof = not(isempty(obj.amplitudeThreshold));
        end

        function n = dimin(~),    n = nan;    end
        function n = dimout(~),   n = nan;    end
    end

    % ================= DATA STRUCTURE =================
    properties
        ampQualifyFraction = 0.25;
        amplitudeThreshold
    end

    % ================= UTILITY =================
    methods
        function obj = MotionSeparation(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
