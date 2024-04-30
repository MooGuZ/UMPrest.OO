classdef Tensor < handle
    methods
        function value = get(obj)
            value = obj.data;
        end
        
        function set(obj, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT'); % RMPERF
            if obj.enableGPU
                if isa(value, 'gpuArray')
                    obj.data = value;
                else
                    obj.data = gpuArray(single(value));
                end
            else
                if isa(value, 'gpuArray')
                    obj.data = double(gather(value));
                else
                    obj.data = value;
                end
            end
        end
        
        function value = getcpu(obj) % get data in form of locating in cpu memory
            if isa(obj.data, 'gpuArray')
                value = double(gather(obj.data));
            else
                value = obj.data;
            end
        end
        
        function value = getgpu(obj) % get data in form of locating in gpu memory
            if isa(obj.data, 'gpuArray')
                value = obj.data;
            else
                value = gpuArray(single(obj.data));
            end
        end
    end
    
    methods
        % PRB: program would be confused in checking the size of a Tensor array,
        %      which only have one unit.
        function sz = size(obj, varargin)
            sz = size(obj.data, varargin{:});
        end
        
        function reshape(obj, varargin)
            obj.data = reshape(obj.data, varargin{:});
        end
    end
    
    methods
        function obj = Tensor(data)
            obj.set(data);
        end
    end
    
%     % SAVE and LOAD
%     methods
%         function sobj = saveobj(obj)
%             sobj.data = obj.getcpu();
%         end
%     end
%     methods (Static)
%         function obj = loadobj(sobj)
%             if isstruct(sobj)
%                 obj = Tensor(sobj.data);
%             else
%                 obj = sobj;
%             end
%         end
%     end

    properties (Access = private)
        dump
    end
    methods
        function value = get.dump(obj)
            value = obj.getcpu();
        end
        function set.dump(obj, value)
            obj.set(value);
        end
    end
    
    properties (SetAccess = protected, Transient)
        data % collection of data samples in matrix form (may located in CPU/GPU memory)
    end
    
    properties (Constant)
        enableGPU = logical(gpuDeviceCount);
        % enableGPU = false;
    end
end
