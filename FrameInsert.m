classdef FrameInsert < PackageProcessor
    methods
        function pkgout = forward(obj, pkgin)
            if not(exist('pkgin', 'var'))
                pkgin = obj.I{1}.pop();
            end
            assert(pkgin.taxis, 'PACKAGE HAVE NO TEMPORAL AXES');
            data = zeros([pkgin.smpsize, obj.n, pkgin.batchsize]);
            switch obj.loc
              case {'front'}
                index = obj.offset;
                
              case {'back'}
                index = pkgin.nframe - obj.offset;
            end
            if index <= 0
                pkgout = DataPackage(cat(pkgin.dsample + 1, data, pkgin.data), ...
                    pkgin.dsample, true);
            elseif index >= pkgin.nframe
                pkgout = DataPackage(cat(pkgin.dsample + 1, pkgin.data, data), ...
                    pkgin.dsample, true);
            else
                [front, back] = sltondim(pkgin.data, pkgin.dsample + 1, 1 : index);
                pkgout = DataPackage(cat(pkgin.dsample + 1, front, data, back), ...
                    pkgin.dsample, true);
            end
            if nargout == 0
                obj.O{1}.send(pkgout);
            end
        end
        
        function backward(~, varargin)
            error('ILLEGAL OPERATION');            
        end
    end
    
    methods
        function obj = FrameInsert(n, location, offset)
            obj.n = n;
            if exist('location', 'var')
                obj.loc = location; % FRONT/BACK
            else
                obj.loc = 'front';
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
        locationSet = {'front', 'back'};
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
