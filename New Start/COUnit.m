classdef COUnit < MappingUnit
    methods
        function frm = process(obj, a, ph)
            frm = obj.rweight * (a .* cos(ph)) + obj.iweight * (a .* sin(ph));
            obj.amp.state   = a;
            obj.phase.state = ph;
            obj.frame.state = frm;
        end
        
        function [dA, dPh] = delta(obj, d, isEvolving)
            a  = obj.amp.state;
            ph = obj.phase.state;
            % gradients of kernel
            if exist('isEvolving', 'var') && isEvolving
                obj.realW.addgrad(d * (a .* cos(ph))');
                obj.imagW.addgrad(d * (a .* sin(ph))');
            end
            % gradients of sample
            rwd = obj.rweight' * d;
            iwd = obj.iweight' * d;
            dA  = rwd .* cos(ph) + iwd .* sin(ph);
            dPh = a .* (iwd .* cos(ph) - rwd .* sin(ph));
        end
        
        function update(obj)
            obj.realW.update();
            obj.imagW.update();
        end
    end
    
    methods
        function frmSize = sizeIn2Out(obj, ampSize, ~)
            frmSize    = ampSize;
            frmSize(1) = size(obj.realW, 1);
        end
        
        function [ampSize, phaseSize] = sizeOut2In(obj, frmSize)
            ampSize    = frmSize;
            ampSize(1) = size(obj.realW, 2);
            phaseSize  = ampSize;
        end
    end
    
    methods
        function sobj = save(obj, filename)
            sobj.realWeight = obj.realW.getcpu();
            sobj.imagWeight = obj.imagW.getcpu();
            save(filename, 'sobj');
        end
    end
    
    methods
        function obj = COUnit(varargin)
            if nargin == 1
                obj.realW = HyperParam(real(varargin{1}));
                obj.imagW = HyperParam(imag(varargin{1}));
            elseif nargin == 2
                obj.realW = HyperParam(varargin{1});
                obj.imagW = HyperParam(varargin{2});
            else
                error('UMPrest:ArgumentError', 'Input arugment quantity : 1 - 2');
            end
            % setup access points
            obj.I = [AccessPoint(obj, size(obj.realW, 2)), ...
                AccessPoint(obj, size(obj.imagW, 2))];
            obj.O = AccessPoint(obj, size(obj.realW, 1));
        end
    end
    
    methods (Static)
        function obj = randinit(insize, outsize)
            amp   = rand(outsize, insize) / sqrt(insize);
            phase = (rand(outsize, insize) - 0.5) * (2 * pi);
            obj   = COUnit(amp .* cos(phase), amp .* sin(phase));
        end
    end
    
    properties (SetAccess = private)
        taxis      = false;
        expandable = false;
    end
    
    properties (Dependent)
        frame, amp, phase
    end
    methods
        function value = get.frame(obj)
            value = obj.O;
        end
        
        function value = get.amp(obj)
            value = obj.I(1);
        end
        
        function value = get.phase(obj)
            value = obj.I(2);
        end
    end
    
    properties (Access = private)
        realW, imagW
    end
    properties (Dependent)
        weight, rweight, iweight
    end
    methods
        function value = get.weight(obj)
            value = complex(obj.realW.get(), obj.imagW.get());
        end
        function set.weight(obj, value)
            obj.realW.set(real(value));
            obj.imagW.set(imag(value));
        end
        
        function value = get.rweight(obj)
            value = obj.realW.get();
        end
        function set.rweight(obj, value)
            obj.realW.set(value);
        end
        
        function value = get.iweight(obj)
            value = obj.imagW.get();
        end
        function set.iweight(obj, value)
            obj.imagW.set(value);
        end
    end
    
    methods (Static)
        function debug(datapath, savepath)
            ds = VideoDataset(datapath, 'coder', 'whiten');
            kernel = ds.coder.getKernel(ds.stat.unitsize);
            m = COUnit.randinit(1024, kernel.sizeout);
            g = GenerativeUnit(m, 'Likelihood', Likelihood('mse', kernel.pixelweight));
            Trainer.trainGUnit(g, ds, 8, 5, 2, savepath);
        end
    end
end

