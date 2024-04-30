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

        function opt = getGlobalOptimizer()
            persistent optimizer
            if isempty(optimizer)
                optimizer = HyperParamOptimizer();
            end
            opt = optimizer;
        end
        
        function debug(probScale)
            if not(exist('probScale', 'var'))
                probScale = 16;
            end
            
            fprintf('\n\n[Linear Transformation]\n'); 
            LinearTransform.debug(probScale);
            pause();
                        
            fprintf('\n\n[Complex Linear Transformation]\n');
            CLinearTransform.debug(probScale);
            pause();
                        
            fprintf('\n\n[Polar Complex Linear Transformation]\n');
            PolarCLT.debug(probScale);
            pause();
            
            fprintf('\n\n[Multiple Linear Transformation]\n');
            MultiLT.debug(probScale);
            pause();
            
            fprintf('\n\n[Multiple Layers Perceptron]\n');
            MLP.debug(probScale);
            pause();
            
            fprintf('\n\n[Convolutional Transformation]\n');
            ConvTransform.debug(probScale);
            pause();
            
            fprintf('\n\n[Convolutional Network]\n');
            ConvNet.debug(probScale);
            pause();
            
            fprintf('\n\n[Simple Recurrent Neural Network]\n');
            SimpleRNN.debug(probScale);
            pause();
            
            fprintf('\n\n[Long-Short Term Memory]\n');
            LSTM.debug(probScale);
            pause();
            
            fprintf('\n\n[Peep-Hole Long-Short Term Memory]\n');
            PHLSTM.debug(probScale);
            pause();
            
            fprintf('\n\n[Dual Peep-Hole Long-Short Term Memory]\n');
            DPHLSTM.debug(probScale);
            pause();            
        end
    end
end
