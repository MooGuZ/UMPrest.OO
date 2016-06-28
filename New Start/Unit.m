classdef Unit < handle
    methods
        function datapkgOut = forward(obj, datapkgIn)
            dataIn = datapkgIn.data;
            if iscell(dataIn)
                dataOut = cell(1, numel(dataIn));
                for i = 1 : numel(dataIn)
                    dataOut{i} = obj.transform(dataIn{i});
                end
                datapkgOut = datapkgIn.derive('data', dataOut);
            else
                datapkgOut = datapkgIn.derive('data', obj.transform(dataIn));
            end
        end
        
        function datapkgIn = backward(obj, datapkgOut)
            dataOut = datapkgOut.data;
            if iscell(dataOut)
                dataIn = cell(1, numel(dataOut));
                for i = 1 : numel(dataOut)
                    dataIn{i} = obj.compose(dataOut{i});
                end
                datapkgIn = datapkgOut.derive('data', dataIn);
            else
                datapkgIn = datapkgOut.derive('data', obj.transform(dataOut));
            end
        end
        
        function delta = errprop(obj, delta)
            assert(not(iscell(delta)), 'UMPrest:ProgramError', ...
                   'No cell array allowed in error propagation.');
            delta = obj.deltaproc(delta, true);
        end
    end
    
    methods (Abstract)
        y = transform(obj, x)
        x = compose(obj, y)
        d = deltaproc(obj, d, isEnvolving)
    end
    
    methods (Abstract)
        function value = size(obj, io)
            switch lower(io)
              case {'in'}
                value = obj.szinfo.in;
                
              case {'out'}
                value = obj.szinfo.out;
                
              otherwise
                error('UMPrest:ArgumentError', 'Unknow option : %s', upper(io));
            end
            index = cellfun(@(v) isa(v, 'sym'), value);
            temp  = nan(size(index));
            temp(~index) = value{~index};
            value = temp;
        end
    end
    
    methods
        function tof = sizeCheck(obj, io, datapkg)
            tof = true;
            if obj.ndims(io) == datapkg.datadim % TBC
                requireSize = obj.size(io);
                for i = 1 : numel(requireSize)
                    if isnan(requireSize(i)) || ...
                            requireSize(i) == datapkg.size('data', i);
                        continue
                    else
                        tof = false;
                    end
                end
            else
                tof = false;
            end
        end
        
        % DATASIZECHECK check consistency of given size information with the
        % requirement of current unit. Return value can be in three forms: TRUE,
        % which mean the given size is acceptable to current unit; FALSE, which mean
        % the given size has confliction to the requirement of current unit;
        % SOLUTION, which is a structure contains solution of symbolic value in
        % given size information that make it acceptable to current unit.
        function value = sizeSolver(obj, givenSize)
            if exist('givenSize', 'var')
                if numel(obj.sizereq) == numel(givenSize)
                    for i = 1 : numel(givenSize)
                        if 
                    end
                else
                    error('UMPrest:SizeMismatch', 'Size requirement cannot be satisfied.');
                end
            else
                value = obj.sizereq;
            end
        end
    end
    
    properties (Hidden)
        I, O, szinfo
    end
end
