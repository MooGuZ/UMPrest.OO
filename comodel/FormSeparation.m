classdef FormSeparation < DPModule & UtilityLib
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function form = proc(obj, sample)
            data = sample.data.amplitude;
            mask = data > obj.amplitudeThreshold;
            data(~mask) = log(obj.amplitudeThreshold);
            form = struct('data', data, 'ffindex', sample.ffindex);
        end

        function sample = invp(~, form)
            sample = struct( ...
                'data', struct('amplitude', exp(form.data)), ...
                'ffindex', form.ffindex)
        end

        function sample = setup(~, sample),   end
        function tof = ready(~),  tof = true; end
        function n = dimin(~),    n = nan;    end
        function n = dimout(~),   n = nan;    end
    end

    % ================= DATA STRUCTURE =================
    properties
        amplitudeThreshold = exp(-4);
    end

    % ================= UTILITY =================
    methods
        function obj = FormSeparation(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
