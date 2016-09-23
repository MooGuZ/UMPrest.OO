classdef Vectorizer < Unit
    methods
        function opackage = transform(obj, ipackage)
            if not(exist('ipackage', 'var'))
                ipackage = obj.I.pop();
            end
            
            if ipackage.taxis
                opackage = DataPackage( ...
                    reshape(ipackage.data, prod(ipackage.szsample), ipackage.nframe, ...
                            ipackage.nsequence), ...
                    1, true);
            else
                opackage = DataPackage( ...
                    reshape(ipackage.data, prod(ipackage.szsample), ipackage.nsample), ...
                    1, false);
            end
            
            obj.I.szsample = ipackage.szsample;
            
            if nargout == 0
                obj.O.send(opackage);
            end
        end
        
        function ipackage = compose(obj, opackage)
            if not(exist('opackage', 'var'))
                opackage = obj.O.pop();
            end
            
            assert(not(isempty(obj.I.szsample)));
            if opackage.taxis
                ipackage = DataPackage(reshape(opackage.data, [obj.I.szsample, ...
                                               opackage.nframe, opackage.nsequence]), ...
                                       numel(obj.I.szsample), true);
            else
                ipackage = DataPackage(reshape(opackage.data, [obj.I.szsample, ...
                                               opackage.nsample]), ...
                                       numel(obj.I.szsample), false);
            end
            
            if nargout == 0
                obj.I.send(ipackage);
            end
        end
        
        function ipackage = errprop(obj, opackage)
            ipackage = obj.compose(opackage);
        end
        
        function x = process(obj, x)
        end
        
        function x = invproc(obj, x)
        end
        
        function d = delta(obj, d)
        end
    end
    
    methods
        function outsize = sizeIn2Out(obj, insize)
            outsize = prod(insize);
        end
        
        function insize = sizeOut2In(obj, outsize)
            assert(not(isempty(obj.I.szsample)));
            insize = obj.I.szsample;
            assert(prod(insize) == outsize);
        end
    end
    
    methods
        function obj = Vectorizer()
            obj.I = AccessPoint(obj, []);
            obj.O = AccessPoint(obj, nan);
        end
    end
    
    properties (SetAccess = private)
        taxis = []
        expandable = false;
    end
end
