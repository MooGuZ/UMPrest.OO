classdef Normalize < handle
% NORMALIZE is an abstraction of normalization in neural network training.

% MooGu Z. <hzhu@case.edu>
% Feb 24, 2016

% TO-DO
% [ ] implement Batch Normalization

    properties (Access = protected)
        norm = struct('type',  'off', ...
                      'proc',  @nullfunc, ...
                      'bprop', @nullfunc);
    end
    
    properties (Abstract)
        wspace
    end
    
    properties (Dependent)
        normType
    end
    methods
        function value = get.normType(obj)
            value = obj.norm.type;
        end
        function set.normType(obj, ntype)
            switch lower(ntype)
              case 'batch'
                obj.norm.type  = 'batch';
                obj.norm.proc  = @obj.batchnorm;
                obj.norm.bprop = @obj.batchnorm_bprop;
                
              case 'off'
                obj.norm.type  = 'off';
                obj.norm.proc  = @nullfunc;
                obj.norm.bprop = @nullfunc;
            end
        end
    end

    methods
        function out = batchnorm(obj, in)
            switch class(obj)
              case {'Perceptron'}
                if size(in, 2) > 1
                    if not(isfield(obj.wspace.norm, 'gamma') ...
                           && isfield(obj.wspace.norm, 'beta'))
                        obj.wspace.norm.gamma = ones(size(in, 1), 1);
                        obj.wspace.norm.beta  = zeros(size(in, 1), 1);
                        obj.wspace.gamme = struct();
                        obj.wspace.beta  = struct();
                    end
                    
                    gamma = obj.wspace.norm.gamma;
                    beta  = obj.wspace.norm.beta;
                    
                    m = mean(in, 2);
                    s = std(in, 1, 2);
                    out = bsxfun(@rdivide, bsxfun(@minus, in, m), s + eps);
                    obj.wspace.norm.xhat = out;
                    out = bsxfun(@plus, bsxfun(@times, out, gamma), beta);
                    
                    obj.wspace.norm.mean = m;
                    obj.wspace.norm.std  = s;
                    
                end
                
              case {'ConvPerceptron'}
                if size(in, 4) > 1
                    if not(isfield(obj.wspace.norm, 'gamma') ...
                           && isfield(obj.wspace.norm, 'beta'))
                        obj.wspace.norm.gamma = ones(1, 1, size(in, 3));
                        obj.wspace.norm.beta  = zeros(1, 1, size(in, 3));
                        obj.wspace.gamme = struct();
                        obj.wspace.beta  = struct();
                    end
                    
                    gamma = obj.wspace.norm.gamma;
                    beta  = obj.wspace.norm.beta;
                    
                    n = prod(size(in)) / size(in, 3);
                    m = sum(sum(sum(in, 1), 2), 4) / n;
                    s = sqrt(sum(sum(sum((in - m).^2, 1), 2), 4) / n);
                    out = bsxfun(@rdivide, bsxfun(@minus, in, m), s + eps);
                    obj.wspace.norm.xhat = out;
                    out = bsxfun(@plus, bsxfun(@times, out, gamma), beta);
                    
                    obj.wspace.norm.mean = m;
                    obj.wspace.norm.std  = s;
                end
            end
        end
        function delta = batchnorm_bprop(obj, delta, optimizer)
            switch class(obj)
              case {'Perceptron'}
                if size(delta, 2) > 1
                    m = obj.wspace.norm.mean;
                    s = obj.wspace.norm.std;
                    
                    gamma = obj.wspace.norm.gamma;
                    beta  = obj.wspace.norm.beta;
                    
                    xhat  = obj.wspace.norm.xhat;
                    
                    dgamma = sum(delta .* xhat, 2);
                    dbeta  = sum(delta, 2);
                    
                    dxhat = bsxfun(@times, delta, gamma);
                    dvar  = - sum(bsxfun(@rdivide, dxhat .* xhat, s.^2), 2) / 2;
                    debia = bsxfun(@times, xhat, s + eps)
                    dmean = - sum(bsxfun(@rdivide, dxhat, s + eps), 2) ...
                            - (2 / size(delta, 2)) * dvar .* sum(debia, 2);
                    delta = bsxfun(@rdivide, dxhat, s + eps) ...
                            + (bsxfun(@plus, 2 * (bsxfun(@times, dvar, debia)), dmean) / size(delta, 2));
                    
                    obj.wspace.norm.gamma = gamma - optimizer.proc(dgamma, obj.wspace.gamma);
                    obj.wspace.norm.beta  = beta  - optimizer.proc(dbeta, obj.wspace.beta);
                end
                
              case {'ConvPerceptron'}
                if size(delta, 2) > 1
                    m = obj.wspace.norm.mean;
                    s = obj.wspace.norm.std;
                    
                    gamma = obj.wspace.norm.gamma;
                    beta  = obj.wspace.norm.beta;
                    
                    xhat  = obj.wspace.norm.xhat;
                    
                    dgamma = sum(sum(sum(delta .* xhat, 1), 2), 4);
                    dbeta  = sum(sum(sum(delta, 1), 2), 4);
                    
                    dxhat = bsxfun(@times, delta, gamma);
                    dvar  = - sum(sum(sum(bsxfun(@rdivide, dxhat .* xhat, s.^2), 1), 2), 4) / 2;
                    debia = bsxfun(@times, xhat, s + eps)
                    dmean = - sum(sum(sum(bsxfun(@rdivide, dxhat, s + eps), 1), 2), 4) ...
                            - (2 / size(delta, 2)) * dvar .* sum(sum(sum(debia, 1), 2), 4);
                    delta = bsxfun(@rdivide, dxhat, s + eps) ...
                            + (bsxfun(@plus, 2 * (bsxfun(@times, dvar, debia)), dmean) / size(delta, 2));
                    
                    obj.wspace.norm.gamma = gamma - optimizer.proc(dgamma, obj.wspace.gamma);
                    obj.wspace.norm.beta  = beta  - optimizer.proc(dbeta, obj.wspace.beta);
                end
            end
            
            methods
                function obj = Normalize()
                    obj.wspace.norm = struct();
                end
            end
        end
    end
end
