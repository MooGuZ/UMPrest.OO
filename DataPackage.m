classdef DataPackage < Package
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = DataPackage(data, dsample, taxis)
            if MathLib.ndims(data) > dsample + double(taxis) + 1
                data = MathLib.vec(data, dsample + double(taxis) + 1, 'back');
            end
            obj.X       = Tensor(data);
            obj.dsample = dsample;
            obj.taxis   = taxis;
        end
    end
    
    methods (Static)
        function dpkg = create(data, dsample, taxis)
            if iscell(data)
                [data, flag] = MathLib.concatecell(data, dsample + double(taxis));
                if flag
                    dpkg = DataPackage(data, dsample, taxis);
                else
                    dpkg(numel(data)) = DataPackage(data{end}, dsample, taxis);
                    for i = numel(data) - 1 : -1 : 1
                        dpkg(i) = DataPackage(data{i}, dsample, taxis);
                    end
                end
            else
                dpkg = DataPackage(data, dsample, taxis);
            end
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties (SetAccess = private)
        dsample, taxis
    end
    properties (Access = private)
        X
    end
    properties (Dependent)
        data, szsample
        nsample, nframe, nsequence
    end
    properties
        info % TBC: reserve field for future usage
    end
    methods
        function value = get.data(obj)
            value = obj.X.get();
        end
        
        function value = get.nsample(obj)
            value = size(obj.X, obj.dsample + 1) * size(obj.X, obj.dsample + 2);
        end
        
        function value = get.nframe(obj)
            if obj.taxis
                value = size(obj.X, obj.dsample + 1);
            else
                value = 1;
            end
        end
        
        function value = get.nsequence(obj)
            if obj.taxis
                value = size(obj.X, obj.dsample + 2);
            else
                value = size(obj.X, obj.dsample + 1);
            end
        end
        
        function value = get.szsample(obj)
            szinfo = size(obj.X);
            if numel(szinfo) >= obj.dsample
                value = szinfo(1 : obj.dsample);
            else
                value = [szinfo, ones(1, obj.dsample - numel(szinfo))];
            end
        end
    end
end

