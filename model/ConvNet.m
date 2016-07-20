% CONVNET is an abstraction of Convolutional Neural Network.
%
% MooGu Z. <hzhu@case.edu>
% Feb 18, 2016

classdef ConvNet < HModel
    % ============= HMODEL IMPLEMENTATION =============
    methods
        function value = objective(~, y, ref)
            value = MathLib.logistic(y, ref);
        end
        
        function d = delta(~, y, ref)
            d = MathLib.logistic_derv(y, ref);
        end
    end
    
    % ============= CONSTRUCTOR =============
    methods
        function obj = ConvNet(dimin, dimout, nfilters, szfilters, ...
                           actType, poolType, poolSize, normType)
            nunit = numel(nfilters);
            
            % set default value
            if ~exist('actType', 'var'),  actType  = 'sigmoid'; end
            if ~exist('poolType', 'var'), poolType = 'max';     end
            if ~exist('poolSize', 'var'), poolSize = 3;         end
            if ~exist('normType', 'var'), normType = 'batch';   end
            
            % check validity of input arguments
            assert(numel(dimin) <= 3);
            assert(numel(dimout) == 1);
            assert(numel(szfilters) == nunit);
            assert((iscellstr(actType) && numel(actType) == nunit+1) ...
                   || ischar(actType));
            assert((iscellstr(poolType) && numel(poolType) == nunit) ...
                   || ischar(poolType));
            assert(isscalar(poolSize) || numel(poolSize) == nunit);
            assert((iscellstr(normType) && numel(normType) == nunit) ...
                   || ischar(normType));
            
            % construct convolutional layers
            datadim = dimin;
            for i = 1 : nunit
                if ischar(actType)
                    atype = actType;
                else
                    atype = actType{i};
                end
                
                if ischar(poolType)
                    ptype = poolType;
                else
                    ptype = poolType{i};
                end
                
                if isscalar(poolSize)
                    psize = poolSize;
                else
                    psize = poolSize(i);
                end
                
                if ischar(normType)
                    ntype = normType;
                else
                    ntype = normType{i};
                end
                
                unit = obj.addUnit(ConvPerceptron( ...
                    nfilters(i), ...
                    szfilters(i), ...
                    datadim(3), ...
                    'actType', atype, ...
                    'poolType', ptype, ...
                    'poolSize', psize, ...
                    'normType', ntype));
                datadim = unit.dimout(datadim);
            end
            
            % construct full-connected layer
            if ischar(actType)
                atype = actType;
            else
                atype = actType{end};
            end
            obj.addUnit(Perceptron( ...
                prod(datadim), ...
                dimout, ...
                'actType', atype));
        end
    end
end
