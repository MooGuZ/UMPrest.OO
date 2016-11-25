function unit = Activation(type)
% create Activation unit according to given type
switch lower(type)
    case {'softmax'}
        unit = SoftmaxActivation();
        
    otherwise
        unit = SimpleActivation(type);
end
