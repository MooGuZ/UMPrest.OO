function model = Perceptron(sizein, sizeout, varargin)
conf = Config(varargin);
actType = conf.pop('actType', 'ReLU');
lin = LinearTransform(sizein, sizeout);
act = Activation(actType);
lin.connect(act);
model = Model(lin, act);

