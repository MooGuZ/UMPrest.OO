classdef SimpleRNN < RecurrentUnit
    methods
        function obj = SimpleRNN(blin, act)
            act.appendto(blin);
            obj@RecurrentUnit(Model(blin, act), {act.O{1}, blin.IB, blin.smpsize('out')});
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