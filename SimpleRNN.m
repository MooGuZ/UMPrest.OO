classdef SimpleRNN < RecurrentUnit
    methods
        function obj = SimpleRNN(blin, act)
            blin.O.connect(act.I);
            obj@RecurrentUnit(Model(blin, act), {act.O, blin.IB});
            obj.blin = blin;
            obj.act  = act;
        end
    end
    
    methods (Static)
        function obj = randinit(datasize, statesize, acttype)
            obj = SimpleRNN( ....
                BilinearTransform.randinit(datasize, statesize, statesize), ...
                Activation(acttype));
        end
    end
    
    properties
        blin, act
    end
end