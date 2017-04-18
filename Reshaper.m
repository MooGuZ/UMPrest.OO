classdef Reshaper < PackageProcessor
    methods
        function opackage = forward(obj, ipackage)
            if not(exist('ipackage', 'var'))
                ipackage = obj.datain.pop();
            end
            opackage = ipackage.copy();
            if isempty(obj.shape) % vectorize
                opackage.vectorize();
            else
                opackage.reshape(obj.shape);
            end
            obj.shapercd.push(ipackage.smpsize);
            if nargout == 0
                obj.dataout.send(opackage);
            end
        end
        
        function ipackage = backward(obj, opackage)
            if not(exist('opackage', 'var'))
                opackage = obj.dataout.pop();
            end
            ipackage = opackage.copy();
            ipackage.reshape(obj.shapercd.pop());
            if nargout == 0
                obj.datain.send(ipackage);
            end
        end
    end
    
    methods
        function obj = Reshaper(shape)
            obj.datain  = SimpleAP(obj);
            obj.dataout = SimpleAP(obj);
            obj.I = {obj.datain};
            obj.O = {obj.dataout};
            obj.shapercd = Container();
            if exist('shape', 'var')
                obj.shape = shape;
            else
                obj.shape = []; % corresponding to vectorize
            end
        end
    end
    
    properties (SetAccess = protected)
        I, O
        datain, dataout
        shape, shapercd
    end
end
