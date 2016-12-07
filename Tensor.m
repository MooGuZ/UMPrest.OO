classdef Tensor < handle
    methods
        function data = get(obj)
            data = obj.data;
        end
        
        function set(obj, data)
            obj.data = data;
        end
        
        function data = getcpu(obj) % get data in form of locating in cpu memory
            if isa(obj.data, 'gpuArray')
                data = double(gather(obj.data));
            else
                data = obj.data;
            end
        end
        
        function data = getgpu(obj) % get data in form of locating in gpu memory
            if isa(obj.data, 'gpuArray')
                data = obj.data;
            else
                data = gpuArray(single(obj.data));
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
            obj.data = data;
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
        dataToSave
    end
    methods
        function value = get.dataToSave(obj)
            value = obj.getcpu();
        end
        function set.dataToSave(obj, value)
            obj.set(value);
        end
    end
    
    properties (Transient)
        data % collection of data samples in matrix form (may located in CPU/GPU memory)
    end
    methods
        function set.data(obj, value)
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
    end
    
    properties (Constant)
        enableGPU = logical(gpuDeviceCount);
    end
end
