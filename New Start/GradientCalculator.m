classdef GradientCalculator < handle
    methods
        function push(obj, grad)
            obj.data = obj.data + grad;
        end
        
        function grad = pop(obj)
            switch lower(obj.type)
                case {'basic'}
                    grad = obj.data;
                    
                case {'ada'}
                    obj.mem.r = obj.mem.r + obj.data.^2;
                    grad = obj.data ./ (1e-7 + sqrt(obj.mem.r));
                    
                case {'rmsprop'}
                    obj.mem.r = obj.conf.decaySndOrd * obj.mem.r + ...
                        (1 - obj.conf.decaySndOrd) * (obj.data.^2);
                    grad = obj.data ./ sqrt(1e-6 + obj.mem.r);
                    
                case {'adam'}
                    obj.mem.s = obj.conf.decayFstOrd * obj.mem.s + ...
                        (1 - obj.conf.decayFstOrd) * obj.data;
                    obj.mem.r = obj.conf.decaySndOrd * obj.mem.r + ...
                        (1 - obj.conf.decaySndOrd) * (obj.data.^2);
                    unbiasS = obj.mem.s / (1 - obj.conf.decayFstOrd^obj.n);
                    unbiasR = obj.mem.r / (1 - obj.conf.decaySndOrd^obj.n);
                    grad = unbiasS ./ (1e-8 + sqrt(unbiasR));
                    
                otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized gradient calculating method : %s', ...
                        upper(method));
            end
            obj.data = 0;
        end
    end
    
    methods
        function obj = GradientCalculator(type, varargin)
            if not(exist('type', 'var'))
                type = 'basic';
            end
            
            obj.type = type;
            obj.data = 0;
            obj.n    = 0;
            
            param = Config(varargin);
            
            switch lower(type)
                case {'basic'}
                    
                case {'ada'}
                    obj.mem = struct('r', 0);
                    
                case {'rmsprop'}
                    obj.mem  = struct('r', 0);
                    obj.conf = struct('decaySndOrd', ...
                                      param.get('decaySndOrd', 0.999));
                    
                case {'adam'}
                    obj.mem  = struct('s', 0, 'r', 0);
                    obj.conf = struct( ...
                        'decayFstOrd', param.get('decayFstOrd', 0.9), ...
                        'decaySndOrd', param.get('decaySndOrd', 0.999));
                    
                otherwise
                    error('UMPrest:ArgumentError', ...
                        'Unrecognized gradient calculating method : %s', ...
                        upper(type));
            end
        end
    end
    
    properties
        n, data, conf, mem
    end
    
    properties (Access = private)
        type
    end
end
