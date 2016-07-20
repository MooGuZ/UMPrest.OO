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
                    p = fullfile(proot, target);
            end
            if exist('fname', 'var')
                p = fullfile(p, fname);
            end
        end
    end
end
