classdef Trainer < handle
    methods (Static)
        function conf = defaultConfig(trainMethod)
            switch lower(trainMethod)
                case {'minibatch'}
                    conf = struct( ...
                        'divisionRatio',    [0.6, 0.1, 0.3], ...
                        'epoch',            10, ...
                        'batchsize',        32, ...
                        'validateInterval', 1000);
            end
            
            conf = containers.Map(fields(conf), struct2cell(conf));
        end
    end
    
    methods (Static)
        function varargout = minibatch(model, dataset, varargin)
            conf = Config.merge(Trainer.defaultConfig('minibatch'), ...
                Config.parse(varargin));
            
            % PROBLEM: cannot deal with unlimited data source
            [trainset, validset, testset] = dataset.subsets(conf('divisionRatio'));
            % gather validate and test data
            vdata = validset.next(validset.volumn());
            tdata = testset.next(testset.volumn());
            
            log = Logger(model, Config.getValue(conf, 'displayMode', 'shell'));
            log.initRecord('ValidSet', vdata, 'interval', conf('validateInterval'));
            log.initRecord('TestSet', tdata);
           
            for ep = 1 : conf('epoch')
                for bat = 1 : ceil(trainset.volumn() / conf('batchsize'))
                    model.trainproc(trainset.next(conf('batchsize')));
                    log.record('ValidSet', vdata); 
                    % TBC : modify model parameters according to validation result
                end
                log.record('TestSet', tdata);
            end
            
            if nargout > 0
                varargout{1} = log;
            end
        end
    end
end
