classdef MultiLT < MISOUnit & FeedforwardOperation & Evolvable
    methods
        function y = dataproc(obj, varargin)
            y = 0;
            for i = 1 : numel(varargin)
                y = y + obj.W{i}.get() * varargin{i};
            end
            y = bsxfun(@plus, y, obj.B.get());
        end
        
        function varargout = deltaproc(obj, d)
            obj.B.addgrad(sum(d, 2));
            for i = 1 : numel(obj.W)
                obj.W{i}.addgrad(d * obj.I{i}.datarcd.pop()');
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
        function sizeout = sizeIn2Out(obj, varargin) % DANGEROUS
            sizein  = varargin{1};
            sizeout = [size(obj.B, 1), sizein(2)];
        end
        
        function varargout = sizeOut2In(obj, sizeout) % DANGEROUS
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
        taxis      = false;
        expandable = false;
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
            obj.I = arrayfun(@(n) UnitAP(obj, n, '-recdata'), ones(1, nargin - 1), ...
                'UniformOutput', false);
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
        
        function debug(n)
            if not(exist('n', 'var')), n = 3; end
            sizeout = 32;
            sizein  = num2cell(randi(32, [1, n]));
            weights = cellfun(@(szin) randn(sizeout, szin), sizein, 'UniformOutput', false);
            refer = MultiLT(weights{:}, randn(sizeout, 1));
            model = MultiLT.randinit(sizeout, sizein{:});
            dataset = cellfun(@(sz) DataGenerator('normal', sz), sizein, 'UniformOutput', false);
            objective = Likelihood('mse');
            task = SimulationTest(model, refer, dataset, objective);
            task.run(1000, 16, 64);
        end
    end
end
