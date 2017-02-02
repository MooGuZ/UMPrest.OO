classdef SIMOUnit < SimpleUnit
    methods
%         function varargout = propagate(obj, apin, apout, proc, ipackage)
%             obj.pkginfo = UnitAP.initPackageInfo();
%             % get input access point
%             apin = apin{1};
%             % get input package
%             if not(exist('ipackage', 'var'))
%                 ipackage = apin.pop();
%             end
%             % unpack data from package
%             idata = apin.unpack(ipackage);
%             % process the data
%             odata = cell(1, numel(apout));
%             [odata{:}] = proc(obj.pkginfo.class, idata);
%             % packup data into package
%             varargout = cellfun(@(ap, d) ap.packup(d), apout, odata, 'UniformOutput', false);
%             % send package if no output argument
%             if nargout == 0
%                 for i = 1 : numel(apout)
%                     apout{i}.send(varargout{i});
%                 end
%             end
%         end

        function varargout = forward(obj, pkgin)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get input package from cache
            if not(exist('pkgin', 'var'))
                pkgin = obj.I{1}.pop();
            end
            % unpack input data from package
            datain = obj.I{1}.unpack(pkgin);
            % process input data
            dataout = cell(1, numel(obj.O));
            [dataout{:}] = obj.process(obj.pkginfo.class, datain);
            % packup output data into package
            varargout = cell(1, numel(obj.O));
            for i = 1 : numel(obj.O)
                varargout{i} = obj.O{i}.packup(dataout{i});
            end
            % send package when no output argument given
            if nargout == 0
                for i = 1 : numel(obj.O)
                    obj.O{i}.send(varargout{i});
                end
            end
        end
        
        function pkgin = backward(obj, varargin)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get output package from cache
            if isempty(varargin)
                varargin = cell(1, numel(obj.O));
                for i = 1 : numel(obj.O)
                    varargin{i} = obj.O{i}.pop();
                end
            end
            % unpack output data from package
            dataout = cell(1, numel(obj.O));
            for i = 1 : numel(obj.O)
                dataout{i} = obj.O{i}.unpack(varargin{i});
            end
            % process output data
            datain = obj.invproc(obj.pkginfo.class, dataout{:});
            % packup input data into package
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
                assert(iscell(value) && not(isscalar(value)));
                for i = 1 : numel(value)
                    assert(isa(value{i}, 'UnitAP'));
                    value{i}.cooperate(i);
                end
                obj.O = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end