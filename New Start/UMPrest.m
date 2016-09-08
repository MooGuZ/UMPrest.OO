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
    end
end
