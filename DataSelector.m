classdef DataSelector < Model
    methods
        function obj = DataSelector()
            act = Activation('Sigmoid');
            mix = TimesUnit().appendto([], act);
            obj@Model(mix, act);
            % assign access point
            obj.control = act.I{1};
            obj.datain  = mix.I{1};
            obj.dataout = mix.O{1};
            % record units
            obj.act = act;
            obj.mix = mix;
        end
    end
    
    properties (SetAccess = protected)
        control, datain, dataout
        act, mix
    end
end