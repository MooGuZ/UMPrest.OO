classdef PackageDistributor < PackageProcessor
    methods
        function varargout = forward(obj, ipackage)
            % obtain input package from access-point
            if not(exist('ipackage', 'var'))
                ipackage = obj.I{1}.pop();
            end
            % replicate and distribute packages
            varargout = cell(1, numel(obj.O));
            for i = 1 : numel(varargout)
                varargout{i} = ipackage.copy();
            end
            % send output packages through access-point
            if nargout == 0
                for i = 1 : numel(obj.O)
                    obj.O{i}.send(varargout{i});
                end
            end
        end
        
        function ipackage = backward(obj, varargin)
            % obtain input package from access-point
            if isempty(varargin)
                varargin = cell(1, numel(obj.O));
                for i = 1 : numel(obj.O)
                    varargin{i} = obj.O{i}.pop();
                end
            end
            % combine error package if capable
            switch class(varargin{1})
                case {'ErrorPackage'}
                    ipackage = varargin{1}.copy();
                    for i = 2 : numel(varargin)
                        ipackage.merge(varargin{i});
                    end
                    
                otherwise
                    error('ILLEGAL OPERATION');
            end
            % send output packages through access-point
            if nargout == 0
                obj.I{1}.send(ipackage);
            end
        end
    end
    
    methods
        function obj = PackageDistributor(n)
            assert(MathLib.isinteger(n) && n > 0, 'ILLEGAL ARGUMENT');
            obj.O = cell(1, n);
            for i = 1 : n
                obj.O{i} = SimpleAP(obj);
            end
            obj.I = {SimpleAP(obj)};
        end
    end
    
    properties (SetAccess = protected)
        I, O
    end
end