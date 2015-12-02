% GPUMODULE < handle
%   It provides support for GPU acceleration by API to transmit data to or from GPU
%   memory and override 'saveobj' and 'loadobj' to gather GPU data automatically before
%   save and activate GPU acceleration after load. At mean time, GPUMODULE also provide
%   interface for subclass to define which member of them should be accelerated by GPU.
%
% [API]
%   value = toGPU(obj, value)
%   value = toCPU(obj, value)
%
% [INTERFACE]
%   copy = clone(obj)
%   activateGPU(obj)
%   deactivateGPU(obj)
%
% [NOTE]
%   CLONE here is supposed only create new objects for GPModule. This is different
%   from the common definition.
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
classdef GPUModule < handle
    % ================= APPLICATION INTERFACE =================
    methods (Access = protected)
        % TOGPU (or TOCPU) transfer variable to (or from) GPU memory. If the variable is
        % a strucuture, the operation would run on its member recursively. Due to concern
        % of performance, TOGPU would convert data to SINGLE before transmission, and
        % TOCPU would convert data to DOUBLE after transmission.
        function value = toGPU(obj, value)
            if obj.enableGPU && not(isempty(value))
                if isstruct(value)
                    member = fields(value);
                    for i = 1 : numel(member)
                        value.(member{i}) = obj.toGPU(value.(member{i}));
                    end
                elseif not(isa(value, 'gpuArray'))
                    value = gpuArray(single(value));
                end
            end
        end
        function value = toCPU(obj, value)
            if isstruct(value)
                member = fields(value);
                for i = 1 : numel(member)
                    value.(member{i}) = obj.toCPU(value.(member{i}));
                end
            elseif isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
    end
    % ================= SAVE&LOAD SUPPORT =================
    methods
        function sobj = saveobj(obj)
            sobj = obj.clone();
            sobj.deactivateGPU();
        end
    end
    methods (Static)
        function obj = loadobj(obj)
            obj.enableGPU = logical(gpuDeviceCount);
            obj.activateGPU();
        end
    end
    % ================= INTERFACE FOR SUBCLASS =================
    methods (Abstract)
        copy = clone(obj)
        obj  = activateGPU(obj)
        obj  = deactivateGPU(obj)
    end
    % ================= DATA STRUCTURE =================
    properties
        enableGPU = logical(gpuDeviceCount);
    end
end
