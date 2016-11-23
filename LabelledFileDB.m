classdef LabelledFileDB < FileDataBlock
    methods
        function unit = getdata(obj, index)
            fname = obj.ftree.get(index);
            unit.data  = obj.readFileFcn(fname);
            unit.label = obj.readLabelFcn(obj.fetchLabelFcn(fname));
            if obj.stat.status && not(obj.stat.tag(index))
                obj.stat.collector.commit(unit.data);
                obj.stat.tag(index) = true;
            end
        end
    end
    
    methods
        function obj = LabelledFileDB( ...
                flist, readFileFcn, readLabelFcn, fetchLabelFcn, fileExt, labelExt, stat)
        end
    end
end