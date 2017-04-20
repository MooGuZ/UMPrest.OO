classdef Entropy < Objective
    methods
        function value = evaluate(obj, data)
            if not(exist('data', 'var'))
                data = obj.getdata();
            end
            if obj.host.expandable
                dim = obj.host.dsample + obj.host.parent.pkginfo.dexpand;
            else
                dim = obj.host.dsample;
            end
            data = vec(data, dim);
            value = obj.scale * log(det(data * data'));
            if isa(value, 'gpuArray')
                value = double(gather(value));
            end
        end
        
        function d = delta(obj, data)
            if not(exist('data', 'var'))
                data = obj.getdata();
            end
            % vectorize sample of data
            datasize = size(data);
            if obj.host.expandable
                dim = obj.host.dsample + obj.host.parent.pkginfo.dexpand;
            else
                dim = obj.host.dsample;
            end
            data = vec(data, dim);
            C = data * data';
            if rcond(C) > 1e-10
                d = 2 * obj.scale * ((data * data') \ data);
                d = reshape(d, datasize);
            else
                d = 0;
            end
        end
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
        function obj = Entropy(host)
            obj.host = host;
        end
    end
    
    properties
        host, scale = -1
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
