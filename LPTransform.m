classdef LPTransform < SISOUnit & BidirectionOperation
    methods
        function dataout = dataproc(obj, datain)
            [nrow, ncol, nlayer] = size(datain);
            % calculate center of frames
            center.x = (ncol + 1) / 2;
            center.y = (nrow + 1) / 2;
            % get transform
            T = obj.getTransform(nrow, ncol);
            % initialize dataout
            dataout = zeros(size(datain));
            % apply transform to each layer of data
            for i = 1 : nlayer
                dataout(:, :, i) = imtransform( ...
                    datain(:, :, i), T, ...
                    'UData', [1, ncol] - center.x, ...
                    'VData', [1, nrow] - center.y, ...
                    'XData', [0, ncol], ...
                    'YData', [-pi, pi], ...
                    'Size', [nrow, ncol]);
            end
        end
        
        function datain = datainvp(obj, dataout)
            [nrow, ncol, nlayer] = size(dataout);
            % calculate center of frames
            center.x = (ncol + 1) / 2;
            center.y = (nrow + 1) / 2;
            % get transform
            T = fliptform(obj.getTransform(nrow, ncol));
            % initialize dataout
            datain = zeros(size(dataout));
            % apply transform to each layer of data
            for i = 1 : nlayer
                datain(:, :, i) = imtransform( ...
                    dataout(:, :, i), T, ...
                    'XData', [1, ncol] - center.x, ...
                    'YData', [1, nrow] - center.y, ...
                    'UData', [0, ncol], ...
                    'VData', [-pi, pi], ...
                    'Size', [nrow, ncol]);
            end
        end
        
        function deltaproc(~, ~)
            error('UNSUPPORTED');
        end
        
        function deltainvp(~, ~)
            error('UNSUPPORTED');
        end
        
        function sizeout = sizeIn2Out(~, sizein)
            sizeout = sizein;
        end
        
        function sizein = sizeOut2In(~, sizeout)
            sizein = sizeout;
        end
    end
    
    methods
        function T = getTransform(obj, nrow, ncol)
            % calculate center of the image
            center.x = (ncol + 1) / 2;
            center.y = (nrow + 1) / 2;
            % calculate the radius of the images
            radius = sqrt((ncol - center.x)^2 + (nrow - center.y)^2);
            
            if obj.useLogScale
                tdata.useLogScale = true;
                % calculate scale of radius in log-polar system
                tdata.rScale = ncol / log(radius);
            else
                tdata.useLogScale = false;
                % calculate scale of radius in log-polar system
                tdata.rScale = ncol / radius;
            end
            % compose geometric transformation
            T = maketform('custom', 2, 2, @LPTransform.cart2lp, @LPTransform.lp2cart, tdata);
        end
    end
    
    methods (Static)
        function lp = cart2lp(cart, t)
            x = cart(:, 1);
            y = cart(:, 2);
            % transform to polar coordinates
            [theta, r] = cart2pol(x, y);
            if t.tdata.useLogScale
                % special case : r = 0
                r = max(r, 1);
                % compose log-polar coordinates
                lp = [t.tdata.rScale * log(r), theta];
            else
                lp = [t.tdata.rScale * r, theta];
            end
        end
        
        function cart = lp2cart(lp, t)
            if t.tdata.useLogScale
                r = exp(lp(:, 1) / t.tdata.rScale);
            else
                r = lp(:, 1) / t.tdata.rScale;
            end
            theta = lp(:, 2);
            % transform 2 Cartesian coordinates
            [x, y] = pol2cart(theta, r);
            % compose coordinates
            cart = [x, y];
        end
    end
    
    methods
        function obj = LPTransform(useLogScale)
            if exist('useLogScale', 'var')
                obj.useLogScale = useLogScale;
            end
            obj.I = {UnitAP(obj, 2)};
            obj.O = {UnitAP(obj, 2)};
        end
        
        function unitdump = dump(~)
            unitdump = {'LPTransform'};
        end
    end
    
    properties (Constant)
        taxis = false;
    end
    properties
        useLogScale = true
    end
end