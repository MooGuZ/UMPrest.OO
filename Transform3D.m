classdef Transform3D < Dataset
    methods
        function self = Transform3D(varargin)
            self.data = DatasetAP(self, self.dsample, self.taxis);
            self.label = DatasetAP(self, 1, self.taxis);
            self.textureCoef = dct2(im2double(nimgen('cow',256)));
            Config(varargin).apply(self);
        end

        function [anim, info] = next(self, n)
            if not(exist('n', 'var'))
                n = 1;
            end

            anim = cell(1, n);
            info = cell(1, n);

            for i = 1 : n
                [anim{i}, info{i}] = self.generate();
            end

            anim = self.data.packup(anim);
            info = self.label.packup(info);

            if nargout == 0
                self.data.send(anim);
                self.label.send(info);
            end
        end
    end

    methods
        % function [anim, info] = generate(self)
        %     if self.useRandomConfig || isempty(self.config)
        %         self.config = self.randomConfig();
        %     end
        % 
        %     [X,Y] = self.getgrid();
        %     pfinit = [X(:), Y(:)]';
        %     anim = zeros(self.nframes, size(pfinit,2));
        % 
        %     u = [cos(self.config.tilting.direction); sin(self.config.tilting.direction)];
        %     % v = [0 -1; 1 0] * u;
        %     % M = [u, v];
        %     for i = 1 : self.nframes
        %         A      = eye(2);
        %         pfield = pfinit;
        % 
        %         if not(self.noScaling)
        %             scl = self.config.translation.z * (i-1);
        %             As  = (scl + self.d) / self.d;
        %             A   = A * As;
        %         end
        % 
        %         if not(self.noRotation)
        %             rot = self.config.rotation * (i-1);
        %             Ar  = cos(-rot) * eye(2) + sin(-rot) * [0,-1;1,0];
        %             A   = A * Ar;
        %         end
        % 
        %         if not(self.noTranslation)
        %             trs = self.config.translation.xy * (i-1);
        %             pfield = pfield - trs;
        %         end
        % 
        %         if self.noTilting
        %             pfield = A * pfield;
        %         else
        %             til = self.config.tilting.velocity *(i-1);
        %             len = sum(pfield.^2);
        %             dir = bsxfun(@rdivide, pfield, sqrt(len));
        %             tmp = tan(til) * (u' * pfield);
        %             if self.noScaling
        %                 g = - tmp / self.d;
        %             else
        %                 g = - tmp / (self.d + scl);
        %             end
        %             pfield = A * bsxfun(@rdivide, ...
        %                 bsxfun(@times, sqrt(len + tmp.^2), dir), ...
        %                 max(1 + g, 0));
        %         end
        % 
        %         temp = self.masking(pfield);
        %         index = (temp > 0);
        %         anim(i, index) = self.textureRender(pfield(:,index)) .* temp(index);
        %     end
        % 
        %     anim = reshape(anim', [size(X), self.nframes]);
        %     info = Transform3D.encodeConfig(self.config);
        % end
        
        function [anim, info] = generate(self)
            if self.useRandomConfig || isempty(self.config)
                self.config = self.randomConfig();
            end

            [X,Y] = self.getgrid();
            pfinit = [X(:), Y(:)]';
            anim = zeros(self.nframes, size(pfinit,2));

            u = [cos(self.config.tilting.direction); sin(self.config.tilting.direction)];
            v = [0 -1; 1 0] * u;
            M = [u, v];
            for i = 1 : self.nframes
                A      = eye(2);
                pfield = pfinit;

                if self.transformSet.translation
                    trs = self.config.translation.xy * (i-1);
                    scl = self.config.translation.z * (i-1);
                    As  = (scl + self.d) / self.d;

                    pfield = bsxfun(@minus, As * pfield, trs);
                else
                    scl = 0;
                end
                
                if self.transformSet.rotation
                    rot = self.config.rotation * (i-1);
                    Ar  = cos(rot) * eye(2) - sin(rot) * [0,-1;1,0];
                    A   = A * Ar;
                end
                
                if self.transformSet.tilting
                    til = self.config.tilting.velocity *(i-1);
                    At  = M * [1/cos(til) 0; 0 1] * M';
                    A   = A * At;
                    g = -tan(til) * u / (self.d + scl);
                    pfield = bsxfun(@rdivide, A * pfield, max(1 + g' * pfield, 0));
                else
                    pfield = A * pfield;
                end

                temp = self.masking(pfield);
                index = (temp > 0);
                anim(i, index) = self.textureRender(pfield(:,index)) .* temp(index);
            end
            
            anim = reshape(anim', [size(X), self.nframes]);
            info = Transform3D.encodeConfig(self.config);
        end

        function [X,Y] = getgrid(self)
            [X,Y] = meshgrid( ...
                linspace(-1, 1, self.framesize(2)), ...
                linspace(1, -1, self.framesize(1)));
            X = X * self.canvasScale.x;
            Y = Y * self.canvasScale.y;
        end

        function value = textureRender(self, pfield)
            [M,N] = size(self.textureCoef);
            value = idct2func( ...
                pfield(2,:) * (M-1)/2 + (M-1)/2, ...
                pfield(1,:) * (N-1)/2 + (N-1)/2, ...
                self.textureCoef);
        end

        function value = masking(self, pfield)
            if self.config.mask.nedges < 0 % no boundary
                value = ones(1,size(pfield,2));
            elseif self.config.mask.nedges == 1
                value = double(sqrt(sum(pfield.^2)) - self.config.mask.edgeDistance <= 0);
            else
                value = self.polygon(pfield, self.config);
            end
        end

        function frame = polygon(self, pfield, conf)
            I = zeros(conf.mask.nedges, size(pfield,2));
            for i = 1 : conf.mask.nedges
                normVec = [cos(conf.mask.edgeOrient(i)), sin(conf.mask.edgeOrient(i))];
                I(i, :) = self.boundaryFunction( ...
                    normVec * pfield - conf.mask.edgeDistance(i), 0.2);
            end
            frame = min(I);
        end
        
        function frame = boundaryFunction(~, M, tzwidth)
            frame = zeros(size(M));            
            % make object to be black
            frame(M <= -tzwidth) = 1;
            % setup transition zone
            tzindex = abs(M) < tzwidth;
            frame(tzindex) = 1 - (sin(pi * M(tzindex) / (2 * tzwidth + eps)) + 1) / 2;
        end

        function [anim, conf] = getLastAnim(self)
            if self.useRandomConfig
                self.useRandomConfig = false;
                [anim, conf] = self.next();
                self.useRandomConfig = true;
            else
                [anim, conf] = self.next();
            end
        end

        function [texture, shape, motion] = draw(self, resolution, canvasRange)
            if not(exist('resolution', 'var')),  resolution  = [256,256];  end
            if not(exist('canvasRange', 'var')), canvasRange = [-1.5,1.5]; end
            % generate grids
            [X,Y] = meshgrid( ...
                linspace(canvasRange(1), canvasRange(2), resolution(2)), ...
                linspace(canvasRange(2), canvasRange(1), resolution(1)));
            % get shape illustration
            shape = reshape(self.masking([X(:), Y(:)]'), size(X));
            % get texture image
            texture = self.getTexture(resolution, canvasRange);
            % get motion pattern
            Phi = PhaseField3D( ...
                [self.config.translation.xy; self.config.translation.z], ...
                self.config.rotation, ...
                self.config.tilting.velocity, ...
                self.config.tilting.direction);
            Phi.nframes = self.nframes;
            motion = pfprocdisp(Phi, resolution);
        end

        function texture = getTexture(self, resolution, canvasRange)
            if not(exist('resolution', 'var')),  resolution  = size(self.textureCoef); end
            if not(exist('canvasRange', 'var')), canvasRange = [-1,1];                 end
            % generate grids
            [X,Y] = meshgrid( ...
                linspace(canvasRange(1), canvasRange(2), resolution(2)), ...
                linspace(canvasRange(2), canvasRange(1), resolution(1)));
            % get texture image
            [M, N] = size(self.textureCoef);
            texture = idct2func(Y * (M-1)/2 + (M-1)/2, X * (N-1)/2 + (N-1)/2, self.textureCoef);
        end

        function setTexture(self, textureImage)
            if size(textureImage,3) == 3
                textureImage = rgb2gray(textureImage);
            end
            self.textureCoef = dct2(im2double(textureImage));
        end
    end

    methods
        function cfg = randomConfig(self)
            cfg.mask.nedges = randi([1,8]);
            if cfg.mask.nedges == 2
                cfg.mask.edgeOrient = randval([-pi,pi],1) + [0, pi];
            else
                cfg.mask.edgeOrient = randort(cfg.mask.nedges);
            end
            cfg.mask.edgeDistance = randval([0.2,1.2], 1, cfg.mask.nedges);
            cfg.rotation = randval([-1,1]) * pi / self.samplerate;
            cfg.tilting.velocity = randval([-1,1]) * pi / self.samplerate;
            cfg.tilting.direction = randval([-pi, pi]);
            cfg.translation.xy = randval([-1,1], 2, 1) / self.samplerate;
            cfg.translation.z = randval([-0.2,0.2]) * self.d / self.samplerate;
        end
    end
    methods (Static)
        function code = encodeConfig(cfg)
            code = [ ...
                cfg.mask.nedges, ...
                cfg.mask.edgeOrient, ...
                cfg.mask.edgeDistance, ...
                cfg.translation.xy', ...
                cfg.translation.z, ...
                cfg.rotation, ...
                cfg.tilting.velocity, ...
                cfg.tilting.direction]';
        end

        function cfg = decodeConfig(code)
            index = 1;
            cfg.mask.nedges = code(index);
            cfg.mask.edgeOrient = code(index + (1 : cfg.mask.nedges))';
            index = index + cfg.mask.nedges;
            cfg.mask.edgeDistance = code(index + (1 : cfg.mask.nedges))';
            index = index + cfg.mask.nedges;
            cfg.translation.xy = code(index + (1:2));
            cfg.translation.z = code(index + 3);
            cfg.rotation = code(index + 4);
            cfg.tilting.velocity = code(index + 5);
            cfg.tilting.direction = code(index + 6);
        end
    end
    
    properties
        transformSet = struct( ...
            'translation', true, ...
            'rotation', true, ...
            'tilting', true)
    end
    methods
        function setTransform(self, varargin)
            fields = fieldnames(self.transformSet);
            % If the type of transformation named in arguments, set it to
            % TRUE; otherwise FALSE. "NONE" and "ALL" are special.
            if any(strcmpi('all', varargin))
                value = true(numel(fields), 1);
            elseif any(strcmpi('none', varargin))
                value = false(numel(fields), 1);
            else
                value = cellfun(@(f) any(strcmpi(f, varargin)), fields);
            end
            % Assign Value for each Transformation
            for i = 1 : numel(fields)
                self.transformSet.(fields{i}) = value(i);
            end
        end
    end

    properties (Hidden)
        nfrms      = 25
        timelen    = 1.0
        framerate  = 25
        samplerate = 25
    end
    properties (Dependent)
        nframes, duration, fps
    end
    methods
        function value = get.nframes(self)
            value = self.nfrms;
        end
        function set.nframes(self, value)
            self.nfrms   = round(value);
            self.timelen = self.nfrms / self.framerate;
        end

        function value = get.duration(self)
            value = self.timelen;
        end
        function set.duration(self, value)
        % the duration may slightly different from setting value, because
        % number of frames need to be integer. The total duration equals to
        % number of frames divide frame per second.
            self.nfrms = round(value * self.framerate);
            value = self.nfrms / self.framerate;
            self.resample(value / self.timelen);
            self.timelen = value;
        end
            
        function value = get.fps(self)
            value = self.framerate;
        end
        function set.fps(self, value)
            self.nfrms = round(value * self.timelen);
            self.resample(value / self.framerate);
            self.framerate = value;
            self.timelen = self.nfrms / value;
        end

        function resample(self, ratio)         
            self.samplerate = self.samplerate * ratio;
            if not(isempty(self.config))
                self.config.translation.xy   = self.config.translation.xy ./ ratio;
                self.config.translation.z    = self.config.translation.z ./ ratio;
                self.config.rotation         = self.config.rotation ./ ratio;
                self.config.tilting.velocity = self.config.tilting.velocity ./ ratio;
            end
        end
    end

    properties
        d = 10
        useRandomConfig = true
        framesize = [128,128]
        canvasScale = struct('x', 1.5, 'y', 1.5)
        config
        textureCoef
    end

    properties (Constant)
        taxis = true
        dsample = 2
    end

    properties
        islabelled = true
        volume = inf
    end
end