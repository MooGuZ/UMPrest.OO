classdef FormSeparation < DPModule & LibUtility
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function form = proc(obj, sample)
            data = log(obj.amplitudeThreshold) * ones(size(sample.data.amplitude));
            mask = sample.data.amplitude > obj.amplitudeThreshold;
            data(mask) = log(sample.data.amplitude(mask));
            form = struct('data', data, 'ffindex', sample.ffindex);
        end
        
        function sample = invp(~, form)
            sample.data.amplitude = exp(form.data);
            sample.ffindex = form.ffindex;
        end
        
        function setup(varargin),             end
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
