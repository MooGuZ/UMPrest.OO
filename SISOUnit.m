classdef SISOUnit < SimpleUnit
    methods
        function opackage = propagate(obj, apin, apout, proc, ipackage)
            % clear shared field of access points
            obj.apshare = struct();
            % get input package
            if not(exist('ipackage', 'var'))
                ipackage = apin.pop();
            end
            % unpack input data from package
            idata = apin.unpack(ipackage);
            % process the data
            odata = proc(obj.apshare.class, idata);
            % get output package
            opackage = apout.packup(odata);
            % send package when no output argument given
            if nargout == 0
                apout.send(opackage);
            end
        end
    end
end
