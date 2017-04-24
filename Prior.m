classdef Prior < Objective
    methods
        function value = evaluate(obj, data)
            if not(exist('data', 'var'))
                data = obj.getdata();
            end
            value = obj.scale * obj.evalproc(data);
            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
        
        function d = delta(obj, data)
            if not(exist('data', 'var'))
                data = obj.getdata();
            end
            d = obj.scale * obj.deltaproc(data);
        end
    end
    
    methods (Abstract)
        value = evalproc(obj, data)
        d = deltaproc(obj, data)
    end
    
    methods
        function data = getdata(obj)
            switch class(obj.host)
              case {'UnitAP'}
                data = obj.host.datarcd.fetch(-1);
              case {'HyperParam'}
                data = obj.host.get();
              otherwise
                error('BUG HERE');
            end
        end
    end
    
    methods
        function [data, shape] = format(obj, data)
            shape = size(data);
            if obj.host.expandable
                dim = obj.host.dsample + obj.host.parent.pkginfo.dexpand;
            else
                dim = obj.host.dsample;
            end
            data = vec(data, dim, 'both');
        end
    end
    
    methods
        function obj = Prior(host, varargin)
            obj.host  = host;
            conf      = Config(varargin);
            obj.scale = conf.pop('scale', 1);
        end
    end
    
    properties
        host, scale
    end
    methods
        function set.host(obj, value)
            switch class(value)
              case {'HyperParam'}
                obj.host = value;
                obj.host.prior = obj;
                
              case {'UnitAP'}
                obj.host = value;
                obj.host.prior = obj;
                obj.host.recdata = true;
                
              otherwise
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end
