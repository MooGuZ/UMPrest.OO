classdef FrameReorder < PackageProcessor
    methods
        function pkgout = forward(obj, pkgin)
            if not(exist('pkgin', 'var'))
                pkgin = obj.I{1}.pop();
            end
            assert(pkgin.taxis, 'PACKAGE HAVE NO TEMPORAL AXES');
            switch obj.mode
              case {'reverse'}
                pkgout = pkgin.copy();
                pkgout.treverse();
                
              otherwise
                error('UNSUPPORTED');
            end
            if nargout == 0
                obj.O{1}.send(pkgout);
            end
        end
        
        
        function pkgin = backward(obj, pkgout)
            if not(exist('pkgout', 'var'))
                pkgout = obj.O{1}.pop();
            end
            assert(pkgout.taxis, 'PACKAGE HAVE NO TEMPORAL AXES');
            switch obj.mode
              case {'reverse'}
                pkgin = pkgout.copy();
                pkgin.treverse();
                
              otherwise
                error('UNSUPPORTED');
            end
            if nargout == 0
                obj.I{1}.send(pkgin);
            end
        end
    end
    
    properties (SetAccess = protected)
        mode
    end
    properties (Constant, Hidden)
        modeset = {'reverse'}
    end
    methods
        function set.mode(obj, value)
            assert(any(strcmpi(value, obj.modeset)), 'ILLEGAL ASSIGNMENT');
            obj.mode = lower(value);
        end
    end
    
    methods
        function obj = FrameReorder(mode)
            obj.mode = mode;
        end
    end
end
