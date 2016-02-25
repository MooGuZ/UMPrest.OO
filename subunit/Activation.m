classdef Activation < handle
% ACTIVATION provide functionality of activation function in Neural Network models.

% MooGu Z. <hzhu@case.edu>
% Feb 23, 2016

    properties (Access = protected)
        act = struct('type', 'relu', ...
                     'proc', @Activation.ReLU, ...
                     'derv', @Activation.ReLU_derv);
    end
    
    properties (Abstract)
        wspace
    end
    
    properties (Dependent)
        actType
    end
    methods
        function value = get.actType(obj)
            value = obj.act.type;
        end
        function set.actType(obj, value)
            switch lower(value)
              case {'sigmoid', 'logistic'}
                obj.act.type = value;
                obj.act.proc = @Activation.sigmoid;
                obj.act.derv = @Activation.sigmoid_derv;
              
              case {'tanh'}
                obj.act.type = value;
                obj.act.proc = @Activation.tanh;
                obj.act.derv = @Activation.tanh_derv;
                
              case {'relu'}
                obj.act.type = value;
                obj.act.proc = @Activation.ReLU;
                obj.act.derv = @Activation.ReLU_derv;
                
              case {'off'}
                obj.act.type = 'off';
                obj.act.proc = @nullfunc;
                obj.act.derv = @nullfunc;
                
              otherwise
                warning('[ACTIVATION] Unrecognized type');
            end
        end
    end
    
    methods % (Access = protected)
        function y = sigmoid(obj, x)
            y = 1 ./ (1 + exp(-x));
            obj.wspace.act.y = y;
        end
        function d = sigmoid_derv(obj)
            y = obj.wspace.act.y;
            d = y .* (1 - y);
        end
        
        function y = hypertgt(obj, x)
            y = tanh(x);
            obj.wspace.act.y = y;
        end
        function d = hypertgt_derv(obj)
            d = 1 - obj.wspace.act.y .^ 2;
        end
        
        function y = ReLU(obj, x)
            y = max(x, 0);
            obj.wspace.act.y = y;
        end
        function d = ReLU_derv(obj)
            y = obj.wspace.act.y;
            d = ones(size(y));
            d(y <= 0) = 0;
        end
    end
    
    methods
        function obj = Activation()
            obj.wspace.act = struct();
        end
    end
end

