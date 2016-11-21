function model = Perceptron(sizein, sizeout, varargin)
conf = Config(varargin);
actType = conf.pop('actType', 'ReLU');
lin = LinearTransform(sizein, sizeout);
act = Activation(actType);
lin.connectTo(act);
model = Model();
model.add(lin, act);
