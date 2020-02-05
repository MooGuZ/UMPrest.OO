classdef FrameSlicer < PackageProcessor
    methods
        function pkgout = forward(obj, pkgin)
            % obtain input package from access-point
            if not(exist('pkgin', 'var'))
                pkgin = obj.I{1}.pop();
            end
            % slicing the package on temporal axes
            assert(pkgin.taxis, 'PACKAGE HAVE NO TEMPORAL AXES');
            if obj.n == 0
                pkgout = pkgin;
            else
                switch obj.loc
                    case {'front'}
                        index = obj.offset;
                        
                    case {'back'}
                        index = pkgin.nframe - obj.offset - obj.n;
                        
                    case {'random'}
                        if obj.nframe > obj.n
                            index = randi(pkgin.nframe - obj.n);
                        else
                            index = 0;
                        end
                end
                % Compose output package
                pkgout = DataPackage( ...
                    sltondim(pkgin.data, pkgin.dsample + 1, index + (1 : obj.n)), ...
                    pkgin.dsample, true);
            end
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
            % Default values
            if not(exist('n',        'var')), n        = 0;        end
            if not(exist('location', 'var')), location = 'random'; end
            if not(exist('offset',   'var')), offset   = 0;        end
            % Setup frame-slicer
            obj.setup(n, location, offset);
            % Initialize interfaces
            obj.I = {SimpleAP(obj)};
            obj.O = {SimpleAP(obj)};
        end
        
        function obj = setup(obj, n, location, offset)
            obj.n      = n;
            obj.loc    = location;
            obj.offset = offset;
        end
    end
    
    properties (Constant, Hidden)
        locationSet = {'front', 'back', 'random'};
    end
    
    properties (SetAccess = protected)
        I, O
    end
    
    properties (SetAccess = private, Hidden)
        n, loc, offset
    end
    methods
        function set.n(obj, value)
            assert(MathLib.isinteger(value) && value >= 0, 'ILLEGAL QUANTITY');
            obj.n = value;
        end
            
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