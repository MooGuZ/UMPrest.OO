classdef LSTM < RecurrentUnit
    methods
        function obj = LSTM(fw, fb, iw, ib, gw, gb, ow, ob)
            ccat = ConcateUnit(1);
            f    = LinearTransform(fw, fb);
            fact = Activation('sigmoid');
            i    = LinearTransform(iw, ib);
            iact = Activation('sigmoid');
            g    = LinearTransform(gw, gb);
            gact = Activation('tanh');
            fc   = TimesUnit();
            ic   = TimesUnit();
            c    = PlusUnit();
            o    = LinearTransform(ow, ob);
            oact = Activation('sigmoid');
            cact = Activation('tanh');
            hid  = TimesUnit();
            % build connections
            ccat.O.connect(f.I);
            ccat.O.connect(i.I);
            ccat.O.connect(g.I);
            ccat.O.connect(o.I);
            f.O.connect(fact.I);
            i.O.connect(iact.I);
            g.O.connect(gact.I);
            o.O.connect(oact.I);
            fact.O.connect(fc.IA);
            iact.O.connect(ic.IA);
            gact.O.connect(ic.IB);
            fc.O.connect(c.IA);
            ic.O.connect(c.IB);
            c.O.connect(cact.I);
            oact.O.connect(hid.IA);
            cact.O.connect(hid.IB);
            % build recurrent unit
            obj@RecurrentUnit( ...
                Model(ccat, f, fact, i, iact, g, gact, ...
                fc, ic, c, o, oact, cact, hid), ...
                {hid.O, ccat.IB}, {c.O, fc.IB});
            % assign properties
            obj.f = f;
            obj.i = i;
            obj.g = g;
            obj.o = o;
        end
        
        function param = dump(obj)
            param = {obj.f.weight, obj.f.bias, obj.i.weight, obj.i.bias, ...
                obj.g.weight, obj.g.bias, obj.o.weight, obj.o.bias};
        end
    end
    
    methods (Static)
        function unit = randinit(datasize, cellsize)
            f = LinearTransform.randinit(datasize + cellsize, cellsize);
            i = LinearTransform.randinit(datasize + cellsize, cellsize);
            g = LinearTransform.randinit(datasize + cellsize, cellsize);
            o = LinearTransform.randinit(datasize + cellsize, cellsize);
            unit = LSTM(f.weight, f.bias, i.weight, i.bias, ...
                g.weight, g.bias, o.weight, o.bias);
        end
    end
    
    properties
        f, i, g, o
    end
end
