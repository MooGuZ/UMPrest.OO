classdef SimpleAnimationGenerator < handle
    methods
        function varargout = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % initialize cell array for animations
            anim = cell(1, n);
            if obj.predmode.status
                animTrans = cell(1, n);
            end
            for i = 1 : n
                object = obj.randObject();
                motion = obj.randMotion();
                anim{i} = obj.generate(object, motion);
                if obj.predmode.status
                    animTrans{i} = obj.transfilter(object, motion);
                end
            end
            % split frames in prediction mode
            if obj.predmode.status
                animPred = cell(1, numel(anim));
                for i = 1 : numel(anim)
                    tdim = obj.dsample + 1;
                    animPred{i} = sltondim(anim{i}, tdim, ...
                        obj.nframes + (1 : obj.predmode.nframes));
                    anim{i} = sltondim(anim{i}, tdim, 1 : obj.nframes);
                end
            end
            % packup animation into data package
            if obj.predmode.status
                varargout = { ...
                    obj.data.packup(anim), ...
                    obj.label.packup(animPred), ...
                    obj.transform.packup(animTrans), ...
                    object, motion};
            else
                varargout = {obj.data.packup(anim), ...
                    object, motion};
            end
            % send data packages if necessary
            if nargout == 0
                obj.data.send(varargout{1});
                if obj.predmode.status
                    obj.label.send(varargout{2});
                    obj.transform.send(varargout{3});
                end
            end
        end
    end
    
    methods
        function value = randval(~, minValue, maxValue)
            value = rand() * (maxValue - minValue) + minValue;
        end
        
        function object = randObject(obj)
            % TODO: currently don't generate RECTANGLE and POLYGON
            % object.shape = obj.shapeSet{randi(numel(obj.shapeSet))};
            object.shape = obj.shapeSet{randi(4)};
            object.size  = ceil(min(obj.frameSize) / obj.randval(3, 7));
            object.position = [obj.randval(-0.3, 0.3), obj.randval(-0.3, 0.3)];
            object.orient = obj.randval(0, 2 * pi);
        end
        
        function motion = randMotion(obj)
            motion = struct();
            if rand() < obj.onoff.translation
                motion.translation = struct( ...
                    'status', true, ...
                    'direction', obj.randval(0, 2 * pi), ...
                    'speed', obj.randval(0.01, 0.07));
            else
                motion.translation = struct('status', false);
            end
            if rand() < obj.onoff.scaling
                motion.scaling = struct( ...
                    'status', true, ...
                    'speed', obj.randval(0.8, 1.2));
            else
                motion.scaling = struct('status', false);
            end
            if rand() < obj.onoff.rotation
                motion.rotation = struct( ...
                    'status', true, ...
                    'speed', obj.randval(pi / 32, pi / 4));
            else
                motion.rotation = struct('status', false);
            end  
        end
    end
    
    methods
        function anim = generate(obj, object, motion)
            % initialize coordinates
            [X,Y]  = meshgrid( ...
                linspace(-0.5, 0.5, obj.frameSize(2)), ...
                linspace(0.5, -0.5, obj.frameSize(1)));
            xscale = (obj.frameSize(2) - 1) / object.size;
            yscale = (obj.frameSize(1) - 1) / object.size;
            Z      = complex(xscale * X, yscale * Y);
            % set start position for the object
            if ~isnan(object.position)
                Z = Z - object.position * [xscale; 1j*yscale];
            end
            % adjust coordinates to start status according to transformation type
            if motion.translation.status
                % move vector (in complex number form)
                mV = exp(1j*motion.translation.direction);
                % % shift to farthest start point, if have not specified object point
                % Z  = Z - min(real(Z(:) * conj(mV))) * mV;
                % rotate move vector to compansate the effects of rotation coordinate
                mV = mV * exp(-1j*object.orient);
            end
            % rotate coordinates to fit object orientation
            Z  = Z * exp(-1j*object.orient);
            
            % calculation number of frames
            nfrms = obj.nframes;
            if obj.predmode.status
                nfrms = nfrms + obj.predmode.nframes;
            end
            % initialize animation data
            anim = zeros([obj.frameSize, nfrms]);
            % calculate step size for each transformation
            if motion.translation.status
                % mvstep = max(real(Z(:) * conj(mV))) / (obj.nframes - 1);
                mvstep = motion.translation.speed;
            end
            % TODO: redefine the scale of scaling and rotation
            % rtstep = 2 * pi / obj.nframes;
            if motion.rotation.status
                rtstep = motion.rotation.speed;
            end
            % scstep = (max(abs(Z(:))))^(1/(obj.nframes-1));
            if motion.scaling.status
                scstep = motion.scaling.speed;
            end
            % initialize transition-zone width
            tzwidth = obj.tzone;
            % transforming frame by frame
            for f = 1 : nfrms
                % generate current frame accordint to the shape
                switch object.shape
                    case {'circle'}
                        anim(:, :, f) = obj.circle(Z, tzwidth);
                        
                    case {'edge'}
                        anim(:, :, f) = obj.edge(Z, tzwidth);
                        
                    case {'triangle'}
                        anim(:, :, f) = obj.polygon(Z, 3, tzwidth);
                        
                    case {'square'}
                        anim(:, :, f) = obj.polygon(Z, 4, tzwidth);
                        
                    case {'rectangle'}
                        distance = [object.edgeDistance, object.edgeDistance];
                        anim(:, :, f) = obj.polygon(Z, 4, tzwidth, [], distance);
                        
                    case {'polygon'}
                        anim(:, :, f) = obj.polygon( ...
                            Z, object.nedges, tzwidth, obj.edgeOrient, obj.edgeDistance);
                        
                    otherwise
                        error('Shape does not defined!');
                end
                % transforming to next status
                if motion.translation.status
                    Z = Z - mvstep * mV;
                end
                if motion.rotation.status
                    Z  = Z * exp(-1j*rtstep);
                    if motion.translation.status
                        mV = mV * exp(-1j*rtstep);
                    end
                end
                if motion.scaling.status
                    Z = Z / scstep;
                    tzwidth = tzwidth / scstep;
                    if motion.translation.status
                        mvstep = mvstep / scstep;
                    end
                end
            end
        end
        
        function tflt = transfilter(obj, object, motion)
            % PRE-ASSUMPTION : motion pattern is translation only
            if mod(obj.predmode.fltsize(2), 2) == 0
                zpoint = obj.predmode.fltsize(2) / 2 + 1;
                xrange = (1 - zpoint : zpoint - 2) / object.size;
            else
                zpoint = (obj.predmode.fltsize(2) + 1) / 2;
                xrange = (1 - zpoint : zpoint - 1) / object.size;
            end
            if mod(obj.predmode.fltsize(1), 2) == 0
                zpoint = obj.predmode.fltsize(1) / 2 + 1;
                yrange = (zpoint - 1 : -1 : 2 - zpoint) / object.size;
            else
                zpoint = (obj.predmode.fltsize(2) + 1) / 2;
                yrange = (zpoint - 1 : -1 : 1 - zpoint) / object.size;
            end
            [X, Y] = meshgrid(xrange, yrange);
            Z = complex(X, Y);
            % motion vector
            if motion.translation.status
                theta = motion.translation.direction;
                alpha = motion.translation.speed;
                mV = alpha * exp(1j*theta);
            else
                mV = complex(0, 0);
            end
            % constant sigma
            sigma = 0.05;
            % transform filter
            fsize = [obj.predmode.fltsize, obj.nframes, obj.predmode.nframes];
            tflt = zeros(fsize);
            for i = 1 : obj.predmode.nframes
                for j = 1 : obj.nframes
                    tflt(:, :, j, i) = ...
                        exp(-abs(Z - (obj.nframes + i - j) * mV).^2 / (2 * sigma^2));
                    alpha = sum(sum(tflt(:, :, j, i)));
                    tflt(:, :, j, i) = tflt(:, :, j, i) / (alpha * obj.nframes);
                end
            end
            % normalization
            % tflt = reshape(tflt, prod(fsize(1:3)), fsize(4));
            % tflt = bsxfun(@rdivide, tflt, sum(tflt));
            % tflt = reshape(tflt, fsize);
        end
    end
    
    methods
        function obj = enablePredmode(obj, npredfrm, fltsize)
            obj.predmode = struct( ...
                'status', true, ...
                'nframes', npredfrm, ...
                'fltsize', fltsize);
        end
        
        function obj = disablePredmode(obj)
            obj.predmode = struct('status', false);
        end
    end
    
    methods
        function frame = circle(obj, Z, tzwidth)
            frame = obj.boundaryFunction(abs(Z) - 1, tzwidth);
        end
        
        function frame = edge(obj, Z, tzwidth)
            frame = obj.boundaryFunction(abs(real(Z)) - 1, tzwidth);
        end
        
        function frame = polygon(obj, Z, n, tzwidth, orient, distance)
            % set orient and distance to center of polygen's each edge
            % by default, this method would generate equilateral polygon
            % with edge lenghth 1.
            if not(exist('orient', 'var')) || isempty(orient)
                orient = (0 : n - 1) * (2 * pi / n);
            end
            if not(exist('distance', 'var')) || isempty(distance)
                distance = cos(pi / n) * ones(1, n);
            end
            % generate frame edge by edge
            I = zeros([size(Z), n]);
            for i = 1 : n
                normVec = complex(cos(orient(i)), sin(orient(i)));
                I(:, :, i) = obj.boundaryFunction(real(Z * conj(normVec)) - distance(i), tzwidth);
            end
            frame = min(I, [], 3);
        end
        
        function frame = boundaryFunction(obj, M, tzwidth)
            frame = zeros(size(M));
            % make background to be black
            % frame(M >= tzwidth) = 1;
            % make object to be black
            frame(M <= -tzwidth) = 1;
            % setup transition zone
            tzindex = abs(M) < tzwidth;
            if obj.tzone > 0
                frame(tzindex) = 1 - (sin((pi * M(tzindex)) / (2 * tzwidth)) + 1) / 2;
            end
        end
    end

    methods
        function obj = SimpleAnimationGenerator()
            obj.data = DatasetAP(obj, obj.dsample);
            obj.label = DatasetAP(obj, obj.dsample);
            obj.transform = DatasetAP(obj, obj.dsample + 1);
            obj.frameSize = [32, 32];
            obj.nframes   = 3;
            obj.disablePredmode();
        end
    end

    properties (Constant)
        taxis = true;
        dsample = 2;
        shapeSet = {'circle', 'edge', 'triangle', 'square', 'rectangle', 'polygon'};
        onoff = struct('translation', 1, 'scaling', 0, 'rotation', 0);
    end
    
    properties
        data, label, transform
        tzone = 0.2;
        frameSize, nframes
        predmode
    end
end