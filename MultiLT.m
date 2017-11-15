classdef MultiLT < MISOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(obj, varargin)
            y = 0;
            for i = 1 : numel(varargin)
                if not(isempty(varargin{i}))
                    y = y + obj.W{i}.get() * varargin{i};
                end
            end
            y = bsxfun(@plus, y, obj.B.get());
        end
        
        function varargout = deltaproc(obj, d)
            if obj.pkginfo.updateHParam
                obj.B.addgrad(sum(d, 2));
                for i = 1 : numel(obj.W)
                    if not(obj.I{i}.datarcd.isempty)
                        obj.W{i}.addgrad(d * obj.I{i}.datarcd.pop()');
                    end
                end
            end
            varargout = cellfun(@(w) w.get()' * d, obj.W, 'UniformOutput', false);
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = [obj.W, {obj.B}];
        end
    end
    
    methods
        function sizeout = sizeIn2Out(obj, varargin)
            batchsize = unique(cellfun(@(el) el(2), varargin));
            assert(issingle(batchsize), 'INCONSISTANT DATA SHAPE');
            for i = 1 : numel(varargin)
                assert(varargin{i}(1) == size(obj.W{i}, 2), 'ILLEGAL DATA SHAPE');
            end
            sizeout = [size(obj.B, 1), batchsize];
        end
        
        function varargout = sizeOut2In(obj, sizeout)
            assert(sizeout(1) == size(obj.B, 1), 'ILLEGAL DATA SHAPE');
            varargout = cellfun(@(w) [size(w, 2), sizeout(2)], obj.W, ...
                'UniformOutput', false);
        end
        
        function value = smpsize(obj, io)
            switch lower(io)
                case {'in', 'input'}
                    value = cellfun(@(w) size(w, 2), obj.W, 'UniformOutput', false);
                    
                case {'out', 'output'}
                    value = size(obj.B, 1);
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
    end
    
    properties (Constant)
        taxis = false;
    end
    properties
        W, B
    end
    
    methods
        function obj = MultiLT(varargin)
            assert(nargin >= 2, 'AT LEAST TWO INPUT ARGUMENTS');
            % create hyper-parameters
            obj.W = cellfun(@HyperParam, varargin(1 : end-1), 'UniformOutput', false);
            obj.B = HyperParam(varargin{end});
            % initialize access-points
            obj.I = arrayfun(@(n) UnitAP(obj, n, '-recdata', '-absent'), ...
                ones(1, nargin - 1), 'UniformOutput', false);
            obj.O = {UnitAP(obj, 1)};            
        end
    end
    
    methods (Static)
        function obj = randinit(sizeout, varargin)
            assert(nargin >= 2, 'AT LEAST TWO INPUT ARGUMENTS');
            % create weight matrix
            weight = cellfun(@(sizein) HyperParam.randlt(sizeout, sizein), varargin, ...
                'UniformOutput', false);
            bias   = zeros(sizeout, 1);
            % initialize multi-linear transform unit
            obj = MultiLT(weight{:}, bias);
        end
        
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            ninput  = ceil(log2(probScale));
            sizeout = probScale;
            sizein  = num2cell(randi(3 * probScale, [1, ninput]));
            % reference model
            refer = MultiLT.randinit(sizeout, sizein{:});
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = MultiLT.randinit(sizeout, sizein{:});
            % data generator
            dataset = cellfun(@(sz) DataGenerator('normal', sz), sizein, 'UniformOutput', false);
            % objective function
            objective = Likelihood('mse');
            % create task and run experiment
            task = SimulationTest(model, refer, dataset, objective);
            task.run(niter, batchsize, validsize);
        end
    end
end
