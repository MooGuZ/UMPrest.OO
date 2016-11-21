classdef UMPrest < handle
    methods (Static)
        function envsetup()
            warning('off', 'symbolic:solve:warnmsg3'); % turn off warning : no
                                                       % integer solution
        end
        
        function p = path(target, fname)
            proot = fileparts(mfilename('fullpath'));
            switch lower(target)
                case {'root', 'rt'}
                    p = proot;
                    
                case {'data'}
                    p = fullfile(proot, 'data');
                    
                case {'conf', 'config', 'configuration'}
                    p = fullfile(proot, 'conf');
            end
            if exist('fname', 'var')
                p = fullfile(p, fname);
            end
        end
        
        function p = parameter()
            persistent param;
            if isempty(param)
                param = Config.loadfile(UMPrest.path('conf', 'default'));
            end
            p = param;
        end
        
        function idOrUnit = unit(unitOrId)
            persistent id2unit;
            if not(exist('unitOrId', 'var'))
                id2unit = containers.Map();
                return
            end
            if isempty(id2unit)
                id2unit = containers.Map();
            end
            if isa(unitOrId, 'Unit')
                % generate a unique id
                idOrUnit = num2str(rand);
                while id2unit.isKey(idOrUnit)
                    idOrUnit = num2str(rand);
                end
                id2unit(idOrUnit) = unitOrId;
            else
                if id2unit.isKey(unitOrId)
                    idOrUnit = id2unit(unitOrId);
                else
                    idOrUnit = [];
                end
            end
        end
    end
end
