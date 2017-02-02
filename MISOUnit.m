classdef MISOUnit < SimpleUnit
    methods
%         function opackage = propagate(obj, apin, apout, proc, varargin)
%             obj.pkginfo = UnitAP.initPackageInfo();
%             % get output access point
%             apout = apout{1};
%             % get input package
%             if isempty(varargin)
%                 ipackage = cellfun(@pop, apin, 'UniformOutput', false);
%             else
%                 ipackage = varargin;
%             end
%             % unpack data from package
%             idata = cellfun(@(ap, pkg) ap.unpack(pkg), apin, ipackage, 'UniformOutput', false);
%             % process the data
%             odata = proc(obj.pkginfo.class, idata{:});
%             % packup data into package
%             opackage = apout.packup(odata);
%             % send package if no output argument
%             if nargout == 0
%                 apout.send(opackage);
%             end
%         end

        function pkgout = forward(obj, varargin)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get input package from cache
            if isempty(varargin)
                varargin = cell(1, numel(obj.I));
                for i = 1 : numel(obj.I)
                    varargin{i} = obj.I{i}.pop();
                end
            end
            % unpack input data from package
            datain = cell(1, numel(obj.I));
            for i = 1 : numel(obj.I)
                datain{i} = obj.I{i}.unpack(varargin{i});
            end
            % process input data
            dataout = obj.process(obj.pkginfo.class, datain{:});
            % packup output data into package
            pkgout = obj.O{1}.packup(dataout);
            % send package when no output argument given
            if nargout == 0
                obj.O{1}.send(pkgout);
            end
        end
        
        function varargout = backward(obj, pkgout)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get output package from cache
            if not(exist('pkgout', 'var'))
                pkgout = obj.O{1}.pop();
            end
            % unpack output data from package
            dataout = obj.O{1}.unpack(pkgout);
            % process output data
            datain = cell(1, numel(obj.I));
            [datain{:}] = obj.invproc(obj.pkginfo.class, dataout);
            % packup input data into package
            varargout = cell(1, numel(obj.I));
            for i = 1 : numel(obj.I)
                varargout{i} = obj.I{i}.packup(datain{i});
            end
            % send package when no output argument given
            if nargout == 0
                for i = 1 : numel(obj.I)
                    obj.I{i}.send(varargout{i});
                end
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
                assert(iscell(value) && not(isscalar(value)));
                for i = 1 : numel(value)
                    assert(isa(value{i}, 'UnitAP'));
                    value{i}.cooperate(i);
                end
                obj.I = value;
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