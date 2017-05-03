% NOTE: currently this unit only deal with DataPackage
classdef Mixer < PackageProcessor
    methods
        function opackage = forward(obj, packageA, packageB)
            if not(exist('packageA', 'var'))
                packageA = obj.I{1}.pop();
                packageB = obj.I{2}.pop();
            end
            dim = packageA.dsample + double(packageA.taxis);
            assert(dim == packageB.dsample + double(packageB.taxis), ...
                'DIMENSION MISMATCH');
            dataA = vec(packageA.data, dim, 'front');
            dataB = vec(packageB.data, dim, 'front');
            a = packageA.batchsize;
            b = packageB.batchsize;
            dsize = packageA.datasize + [zeros(1, dim), b];
            switch obj.mode
              case {'append'}
                odata = [dataA, dataB];
                obj.records.push(a);
                
              case {'interleave'}
                indexA = 2 * (1 : a) - 1;
                indexB = 2 * (1 : b);
                [~, index] = sort([indexA, indexB], 'ascend');
                odata = [dataA, dataB];
                odata = odata(:, index);
                [~, order] = sort(index, 'ascend');
                obj.records.push({order(1 : a), order(a + (1 : b))});
                
              case {'random'}
                odata = [dataA, dataB];
                index = randperm(a + b);
                odata = odata(:, index);
                [~, order] = sort(index, 'ascend');
                obj.records.push({order(1 : a), order(a + (1 : b))});
            end
            opackage = DataPackage(reshape(odata, dsize), packageA.dsample, packageA.taxis);
            if nargout == 0
                obj.O{1}.send(opackage);
            end
        end
        
        function [packageA, packageB] = backward(obj, opackage)
            if not(exist('opackage', 'var'))
                opackage = obj.O{1}.pop();
            end
            dsample = opackage.dsample;
            taxis = opackage.taxis;
            odata = vec(opackage.data, dsample + double(taxis), 'front');
            if taxis
                unitsize = [opackage.smpsize, opackage.nframe];
            else
                unitsize = opackage.smpsize;
            end
            switch obj.mode
              case {'append'}
                n = obj.records.pop();
                dataA = odata(:, 1 : n);
                dataB = odata(:, (n + 1) : end);
                
              case {'interleave', 'random'}
                order = obj.records.pop();
                dataA = odata(:, order{1});
                dataB = odata(:, order{2});
            end
            dataA = reshape(dataA, [unitsize, size(dataA, 2)]);
            dataB = reshape(dataB, [unitsize, size(dataB, 2)]);
            packageA = DataPackage(dataA, dsample, taxis);
            packageB = DataPackage(dataB, dsample, taxis);
            if nargout == 0
                obj.I{1}.send(packageA);
                obj.I{2}.send(packageB);
            end
        end
    end
    
    methods
        function obj = Mixer(mode)
            obj.I = {SimpleAP(obj), SimpleAP(obj)};
            obj.O = {SimpleAP(obj)};
            obj.records = Container();
            if exist('mode', 'var')
                obj.mode = lower(mode);
            else
                obj.mode = 'append';
            end
        end
    end
    
    properties (SetAccess = protected)
        I, O, 
        mode, records
    end
    properties (Access = private, Constant)
        modeset = {'append', 'interleave', 'random'}
    end
    methods
        function set.mode(obj, value)
            assert(any(strcmpi(value, obj.modeset)), 'UNRECOGNIZED MODE');
            obj.mode = lower(value);
        end
    end
end
