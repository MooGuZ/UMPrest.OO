classdef FrameSlicer < PackageProcessor
    methods
        function pkgout = forward(obj, pkgin)
            % obtain input package from access-point
            if not(exist('pkgin', 'var'))
                pkgin = obj.I{1}.pop();
            end
            % slicing the package on temporal axes
            assert(pkgin.taxis, 'PACKAGE HAVE NO TEMPORAL AXES');
            switch obj.loc
                case {'front'}
                    index = 1 + obj.offset;
                    
                case {'back'}
                    index = pkgin.nframe - obj.offset;
                    
                case {'random'}
                    index = randi(pkgin.nframe - obj.n + 1);
            end
            pkgout = DataPackage( ...
                sltondim(pkgin.data, pkgin.dsample + 1, index + (0 : obj.n-1)), ...
                pkgin.dsample, true);
            % send output package through access-point
            if nargout == 0
                obj.O{1}.send(pkgout);
            end
        end
        
        function backward(~, varargin)
            error('ILLEGAL OPERATION');
        end
    end
    
    methods
        function obj = FrameSlicer(n, location, offset)
            obj.n = n;
            if exist('location', 'var')
                obj.loc = location; % FRONT/BACK/RANDOM
            else
                obj.loc = 'random';
            end
            if exist('offset', 'var')
                obj.offset = offset;
            else
                obj.offset = 0;
            end
            obj.I = {SimpleAP(obj)};
            obj.O = {SimpleAP(obj)};
        end
    end
    
    properties (Constant, Hidden)
        locationSet = {'front', 'back', 'random'};
    end
    
    properties (SetAccess = protected)
        I, O
        n, loc, offset
    end
    methods
        function set.loc(obj, value)
            assert(any(strcmpi(value, obj.locationSet)), 'ILLEGAL LOCATION');
            obj.loc = lower(value);
        end
        
        function set.offset(obj, value)
            assert(MathLib.isinteger(value) && value >= 0, 'ILLEGAL OFFSET');
            obj.offset = value;
        end
    end
end