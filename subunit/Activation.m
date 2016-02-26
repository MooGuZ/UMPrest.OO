classdef Activation < handle
% ACTIVATION provide functionality of activation function in Neural Network models.

% MooGu Z. <hzhu@case.edu>
% Feb 23, 2016

    properties (Access = protected)
        act = struct('type',  'off', ...
                     'proc',  @nullfunc, ...
                     'bprop', @nullfunc);
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
                obj.act.type  = value;
                obj.act.proc  = @obj.sigmoid;
                obj.act.bprop = @obj.sigmoid_bprop;
              
              case {'tanh'}
                obj.act.type  = value;
                obj.act.proc  = @obj.hypertgt;
                obj.act.bprop = @obj.hypertgt_bprop;
                
              case {'relu'}
                obj.act.type  = value;
                obj.act.proc  = @obj.ReLU;
                obj.act.bprop = @obj.ReLU_bprop;
                
              case {'off'}
                obj.act.type  = 'off';
                obj.act.proc  = @nullfunc;
                obj.act.bprop = @nullfunc;
                
              otherwise
                warning('[ACTIVATION] Unrecognized type');
            end
        end
    end
    
    methods % (Access = protected)
        function y = sigmoid(obj, x)
            obj.wspace.act.y = 1 ./ (1 + exp(-x));
            y = obj.wspace.act.y;
        end
        function delta = sigmoid_bprop(obj, delta)
            delta = delta .* (obj.wspace.act.y .* (1 - obj.wspace.act.y));
        end
        
        function y = hypertgt(obj, x)
            obj.wspace.act.y = tanh(x);
            y = obj.wspace.act.y;
        end
        function delta = hypertgt_bprop(obj, delta)
            delta = delta .* (1 - obj.wspace.act.y .^ 2);
        end
        
        function y = ReLU(obj, x)
            obj.wspace.act.y = max(x, 0);
            y = obj.wspace.act.y;
        end
        function delta = ReLU_bprop(obj, delta)
            delta(obj.wspace.act.y <= 0) = 0;
        end
    end
    
    methods
        function obj = Activation()
            obj.wspace.act = struct();
            obj.actType    = 'ReLU';
        end
    end
end

