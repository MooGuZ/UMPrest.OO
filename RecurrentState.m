classdef RecurrentState < Unit
    methods
        function forward(obj)
            obj.O{1}.send(obj.I{1}.pull());
        end
        
        function backward(obj)
            obj.I{1}.send(obj.O{1}.pull());
        end
        
        function clear(obj)
            obj.I{1}.reset();
            obj.O{1}.reset();
            obj.SI.reset();
            obj.SO.reset();
        end
    end
    
    properties (SetAccess = protected)
        SI, SO
    end
    methods
        function initForwardState(obj)
            if obj.SI.isempty()
                state = obj.defaultPackage( ...
                    obj.parent.pkginfo.class, ...
                    obj.parent.pkginfo.batchsize);
            else
                state = obj.SI.pull();
            end
            obj.I{1}.push(state);
        end
        
        function initBackwardState(obj)
            if obj.SO.isempty()
                state = obj.defaultPackage( ...
                    obj.parent.pkginfo.class, ...
                    obj.parent.pkginfo.batchsize);
            else
                state = obj.SO.pull();
            end
            obj.O{1}.push(state);
        end
        
        function stateForward(obj)
            if not(obj.I{1}.isempty())
                obj.SO.send(obj.I{1}.pull());
            end
        end
        
        function stateBackward(obj)
            if not(obj.O{1}.isempty())
                obj.SI.send(obj.O{1}.pull());
            end
        end
    end
    
    methods
        function package = defaultPackage(obj, type, batchsize)
            switch type
              case {'DataPackage'}
                package = DataPackage(repmat(obj.S.get(), ...
                    [ones(1, obj.dstate), batchsize]), ...
                    obj.dstate, false);
                
              case {'ErrorPackage'}
                % warning('SHOULD NOT HAPPEND');
                package = ErrorPackage( ...
                    Tensor(zeros([obj.statesize, batchsize])).get(), ...
                    obj.dstate, false);
                
              case {'SizePackage'}
                package = SizePackage([obj.statesize, batchsize], ...
                    obj.dstate, false);
            end
        end
    end
    
    methods
        function obj = RecurrentState(parent, apin, apout, statesize)
            obj.parent    = parent;
            obj.statesize = arraytrim(statesize, 1);
            obj.dstate    = numel(obj.statesize);
            obj.I = {SimpleAP(obj).connect(apin)};
            obj.O = {SimpleAP(obj).connect(apout)};
            obj.S = HyperParam(zeros([statesize, 1]));
            obj.SI = SimpleAP(parent);
            obj.SO = SimpleAP(parent);
        end
    end
    
    properties (SetAccess = protected)
        I % collection of input access-points
        O % collection of output access-points
        parent
    end
    properties
        S % hyper-parameter containing initial state for one frame
        dstate
        statesize
    end
end
