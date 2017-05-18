classdef RecurrentState < Unit
    methods
        function forward(obj)
            if obj.I{1}.isempty
                package = obj.defaultPackage( ...
                    obj.parent.pkginfo.class, ...
                    obj.parent.pkginfo.batchsize);
            else
                package = obj.I{1}.pull();
            end
            obj.O{1}.send(package);
        end
        
        function backward(obj)
            if obj.O{1}.isempty
                package = obj.defaultPackage( ...
                    obj.parent.pkginfo.class, ...
                    obj.parent.pkginfo.batchsize);
            else
                package = obj.O{1}.pull();
            end
            obj.I{1}.send(package);
        end
        
        % function update(obj)
        %     if not(obj.O{1}.isempty)
        %         package = obj.O{1}.fetch(1);
        %         if isa(package, 'ErrorPackage')
        %             obj.S.addgrad(sum(package.data, obj.dstate + 1));
        %             obj.S.update();
        %             obj.O{1}.pull();
        %         end
        %     elseif not(obj.I{1}.isempty)
        %         package = obj.I{1}.fetch(1);
        %         if isa(package, 'ErrorPackage')
        %             obj.S.addgrad(sum(package.data, obj.dstate + 1));
        %             obj.S.update();
        %             obj.I{1}.pull();
        %         end
        %     end
        % end
        
        function clear(obj)
            obj.I{1}.reset();
            obj.O{1}.reset();
        end
    end
    
    properties (Hidden)
        SI, SO
    end
    methods
        function stateAheadof(obj, runit)
            obj.SO = runit;
            runit.SI = obj;
        end
        
        function stateAppendto(obj, runit)
            obj.SI = runit;
            runit.SO = obj;
        end
        
        function stateForward(obj)
            if not(obj.I{1}.isempty() || isempty(obj.SO))
                obj.SO.I{1}.push(obj.I{1}.pull());
            end
        end
        
        function stateBackward(obj)
            if not(obj.O{1}.isempty() || isempty(obj.SI))
                obj.SI.O{1}.push(obj.O{1}.pull());
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
