% DPStack < Stack & DPModule & GPUModule
%   DPStack provides a way to concatenate data processing modules.
%   It very suit for modulized extendable preprocess (or postprocess)
%   This class implement all interface of it super-class, while add
%   nothing, including interfaces and properties.
%
% see also, Stack, DPModule, GPUModule
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
classdef DPStack < Stack & DPModule & GPUModule
    % ================= STACK IMPLEMENTATION =================
    methods (Access = protected)
        function tof = isqualified(~, unit)
            tof = isa(unit, 'DPModule') ;
        end
    end
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sample.data = obj.toGPU(sample.data);
            for i = 1 : numel(obj.stack)
                sample = obj.stack{i}.proc(sample);
            end
        end

        function sample = invp(obj, sample)
            sample.data = obj.toGPU(sample.data);
            for i = numel(obj.stack) : -1 : 1
                sample = obj.stack{i}.invp(sample);
            end
        end

        function setup(obj, sample)
            sample.data = obj.toGPU(sample.data);
            % each module in the stack only setup once
            if isempty(obj.stack) || obj.ready()
                return
            end
            % setup level by level
            for i = 1 : numel(obj.stack)
                if ~obj.stack{i}.ready()
                    obj.stack{i}.setup(sample);
                end
                sample = obj.stack{i}.proc(sample);
            end
        end

        function tof = ready(obj)
            tof = true;
            for i = 1 : numel(obj.stack)
                if ~obj.stack{i}.ready()
                    tof = false;
                    return
                end
            end
        end

        function n = dimin(obj)
            if isempty(obj.stack)
                n = nan;
            else
                for i = 1 : numel(obj.stack)
                    if isnan(obj.stack{i}.dimin()) && isnan(obj.stack{i}.dimout())
                        continue
                    end
                    break
                end
                n = obj.stack{i}.dimin();
            end
        end

        function n = dimout(obj)
            if isempty(obj.stack)
                n = nan;
            else
                for i = numel(obj.stack) : -1 : 1
                    if isnan(obj.stack{i}.dimout())
                        assert(isnan(obj.stack{i}.dimin()));
                        continue
                    end
                    break
                end
                n = obj.stack{i}.dimout();
            end
        end
    end
    % ================= GPUMODULE IMPLEMENTATION =================
    methods
        function activateGPU(obj)
            for i = 1 : numel(obj.stack)
                if isa(obj.stack{i}, 'GPUModule')
                    obj.stack{i}.activateGPU();
                end
            end
        end
        function deactivateGPU(obj)
            for i = 1 : numel(obj.stack)
                if isa(obj.stack{i}, 'GPUModule')
                    obj.stack{i}.deactivateGPU();
                end
            end
        end
        function copy = clone(obj)
            copy = feval(class(obj));
            for i = 1 : numel(obj.stack)
                if isa(obj.stack{i}, 'GPUModule')
                    copy.push(obj.stack{i}.clone());
                else
                    copy.push(obj.stack{i});
                end
            end
        end
    end
end
