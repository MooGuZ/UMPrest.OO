classdef SoftmaxActivation < SISOUnit & FeedforwardOperation
    methods
        function odata = dataproc(~, idata)
            idata = exp(idata);
            odata = bsxfun(@rdivide, idata, sum(idata));
        end
        
        function idelta = deltaproc(obj, odelta)
            [n, m] = size(odelta);
            Imat  = eye(n);
            odata = obj.O{1}.datarcd.pop();
            idelta = cell2mat(arrayfun( ...
                @(i) (Imat - repmat(odata(:, i), 1, n))' * odelta(:, i), 1 : m, ...
                'UniformOutput', false));
        end
        
        function sizeout = sizeIn2Out(~, sizein)
            sizeout = sizein;
        end
        
        function sizein = sizeOut2In(~, sizeout)
            sizein = sizeout;
        end
    end
    
    methods
        function obj = SoftmaxActivation()
            obj.I = {UnitAP(obj, 0, '-expandable')};
            obj.O = {UnitAP(obj, 0, '-expandable', '-recdata')};
        end
    end
    
    properties (Constant, Hidden)
        taxis      = false;
        expandable = false; % RFP: this property is in AccessPoint now
    end
    
    properties (Constant)
        type = 'Softmax';
    end
end
