classdef ConvNet < SequentialModel
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = ConvNet(dataSize, labelSize, nfilter, varargin)
            % nunit = numel(nfilters);
            config = Config.parse(varargin);
            
            filterSize = Config.popItem(config, 'filterSize', [5, 5]);
            poolSize   = Config.popItem(config, 'poolSize', [3, 3]);
            hactType   = Config.popItem(config, 'HiddenLayerActType', 'ReLU');
            oactType   = Config.popItem(config, 'OutputLayerActType', 'Sigmoid');
            
            nunit = numel(nfilter);
            
            if iscell(filterSize)
                assert(numel(filterSize) == nunit);
            else
                filterSize = repmat({filterSize}, 1, nunit);
            end
            
            if iscell(poolSize)
                assert(numel(poolSize) == nunit);
            else
                poolSize = repmat({poolSize}, 1, nunit);
            end
            
            nfilter = [dataSize(3), nfilter];
            % stack convulutional perceptrons
            for i = 1 : nunit
                unit = ConvPerceptron( ...
                    filterSize{i}, nfilter(i + 1), nfilter(i), ...
                    'poolSize', poolSize{i}, 'actType', hactType);
                if i == 1
                    unit.inputSizeDescription = dataSize;
                end
                obj.appendUnit(unit);
            end
            % append perceptron in the end
            if not(isempty(labelSize))
                obj.appendUnit(Vectorizer(3)); % TBC
                obj.appendUnit( ...
                    Perceptron(double(obj.outputSizeDescription), ...
                               labelSize, 'actType', oactType));
            end
            
            Config.apply(obj, config);
            % % set default value
            % if ~exist('actType', 'var'),  actType  = 'sigmoid'; end
            % if ~exist('poolType', 'var'), poolType = 'max';     end
            % if ~exist('poolSize', 'var'), poolSize = 3;         end
            % if ~exist('normType', 'var'), normType = 'batch';   end
            % 
            % % check validity of input arguments
            % assert(numel(dimin) <= 3);
            % assert(numel(dimout) == 1);
            % assert(numel(szfilters) == nunit);
            % assert((iscellstr(actType) && numel(actType) == nunit+1) ...
            %        || ischar(actType));
            % assert((iscellstr(poolType) && numel(poolType) == nunit) ...
            %        || ischar(poolType));
            % assert(isscalar(poolSize) || numel(poolSize) == nunit);
            % assert((iscellstr(normType) && numel(normType) == nunit) ...
            %        || ischar(normType));
            % 
            % % construct convolutional layers
            % datadim = dimin;
            % for i = 1 : nunit
            %     if ischar(actType)
            %         atype = actType;
            %     else
            %         atype = actType{i};
            %     end
            %     
            %     if ischar(poolType)
            %         ptype = poolType;
            %     else
            %         ptype = poolType{i};
            %     end
            %     
            %     if isscalar(poolSize)
            %         psize = poolSize;
            %     else
            %         psize = poolSize(i);
            %     end
            %     
            %     if ischar(normType)
            %         ntype = normType;
            %     else
            %         ntype = normType{i};
            %     end
            %     
            %     unit = obj.addUnit(ConvPerceptron( ...
            %         nfilters(i), ...
            %         szfilters(i), ...
            %         datadim(3), ...
            %         'actType', atype, ...
            %         'poolType', ptype, ...
            %         'poolSize', psize, ...
            %         'normType', ntype));
            %     datadim = unit.dimout(datadim);
            % end
            % 
            % % construct full-connected layer
            % if ischar(actType)
            %     atype = actType;
            % else
            %     atype = actType{end};
            % end
            % obj.addUnit(Perceptron( ...
            %     prod(datadim), ...
            %     dimout, ...
            %     'actType', atype));
        end
    end
    
    % ======================= DEVELOPER TOOL =======================
    methods (Static)
        function debug()
            sampleSize = [20, 20, 1];
            labelSize  = 10;
            nfilter    = [3, 7, 5];
            filterSize = 5;
            poolSize   = 2;
            hactType   = 'ReLU';
            oactType   = 'Sigmoid';
            
            % main work flow
            model = ConvNet(sampleSize, labelSize, nfilter, ...
                            'filterSize', filterSize, ...
                            'poolSize',   poolSize, ...
                            'HiddenLayerActType', hactType, ...
                            'OutputLayerActType', oactType);
            datasource = load(UMPrest.path('data', 'tinytest'));
            nsample = size(datasource.X, 1);
            ds = VideoDataset(MemoryDataBlock( ...
                reshape(datasource.X', [20, 20, 1, nsample]), ...
                StatisticCollector(), 'label', ...
                MathLib.ind2tf(datasource.y, 1, 10)));
            model.likelihood = Likelihood('logistic');
            model.task = Task('classify');
            Trainer.minibatch(model, ds);
        end
    end
end
