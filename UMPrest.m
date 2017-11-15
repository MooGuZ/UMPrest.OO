% PRP: 1. implement static SAVE and LOAD function (ConstructOnLoad)
%      2. create class for ID register
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
        
        function debug(probScale)
            if not(exist('probScale', 'var'))
                probScale = 16;
            end
            
            % record current setup
            opt = HyperParam.getOptimizer();
            opt.push();
            
            disp('\n\n[Linear Transformation]'); 
            opt.fetch(-1); LinearTransform.debug(probScale); pause();
                        
            disp('\n\n[Complex Linear Transformation]');
            opt.fetch(-1); CLinearTransform.debug(probScale); pause();
                        
            disp('\n\n[Polar Complex Linear Transformation]');
            opt.fetch(-1); PolarCLT.debug(probScale); pause();
            
            disp('\n\n[Multiple Linear Transformation]');
            opt.fetch(-1); MultiLT.debug(probScale); pause();
            
            disp('\n\n[Multiple Layers Perceptron]');
            opt.fetch(-1); MLP.debug(probScale); pause();
            
            disp('\n\n[Convolutional Transformation]');
            opt.fetch(-1); ConvTransform.debug(probScale); pause();
            
            disp('\n\n[Convolutional Network]');
            opt.fetch(-1); ConvNet.debug(probScale); pause();
            
            disp('\n\n[Simple Recurrent Neural Network]');
            opt.fetch(-1); SimpleRNN.debug(probScale); pause();
            
            disp('\n\n[Long-Short Term Memory]');
            opt.fetch(-1); LSTM.debug(probScale); pause();
            
            disp('\n\n[Peep-Hole Long-Short Term Memory]');
            opt.fetch(-1); PHLSTM.debug(probScale); pause();
            
            disp('\n\n[Dual Peep-Hole Long-Short Term Memory]');
            opt.fetch(-1); DPHLSTM.debug(probScale); pause();
            
            % restore optimizer setup
            opt.pop();
        end
    end
end
