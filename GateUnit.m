function obj = GateUnit()
% GATEUNIT return a model acts as a gate-unit. Its input access-points are
% arranged in order of DATA and MASK.
act = Activation('Sigmoid');
mix = TimesUnit().appendto([], act);
obj = Model(mix, act);
