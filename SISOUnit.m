classdef SISOUnit < SimpleUnit
    methods
        function pkgout = forward(obj, pkgin)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get input package from cache
            if not(exist('pkgin', 'var'))
                pkgin = obj.I{1}.pop();
            end
            % unpack input data from package
            datain = obj.I{1}.unpack(pkgin);
            % process data
            dataout = obj.process(obj.pkginfo.class, datain);
            % generate output package
            pkgout = obj.O{1}.packup(dataout);
            % send package when no output argument given
            if nargout == 0
                obj.O{1}.send(pkgout);
            end
        end

        function pkgin = backward(obj, pkgout)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get output package from cache
            if not(exist('pkgout', 'var'))
                pkgout = obj.O{1}.pop();
            end
            % unpack output data from package
            dataout = obj.O{1}.unpack(pkgout);
            % process data
            datain = obj.invproc(obj.pkginfo.class, dataout);
            % generate input package
            pkgin = obj.I{1}.packup(datain);
            % send package when no output argument given
            if nargout == 0
                obj.I{1}.send(pkgin);
            end
        end
    end

    properties (SetAccess = protected)
        I = {} % input access point set
        O = {} % output access point set
    end
    methods
        function set.I(obj, value)
            try
                if isa(value, 'UnitAP')
                    obj.I = {value};
                else
                    assert(iscell(value));
                    if isscalar(value)
                        assert(isa(value{1}, 'UnitAP'));
                    else
                        assert(isempty(value));
                    end
                    obj.I = value;
                end
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end

        function set.O(obj, value)
            try
                if isa(value, 'UnitAP')
                    obj.O = {value};
                else
                    assert(iscell(value));
                    if isscalar(value)
                        assert(isa(value{1}, 'UnitAP'));
                    else
                        assert(isempty(value));
                    end
                    obj.O = value;
                end
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end
