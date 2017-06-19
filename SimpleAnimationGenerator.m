classdef SimpleAnimationGenerator < handle
    methods
        function varargout = next(self, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % initialize cell array for animations
            anim = cell(1, n);
            % if self.predmode.status
            %     animTrans = cell(1, n);
            % end
            for i = 1 : n
                object  = self.getObject();
                motion  = self.getMotion();
                anim{i} = self.generate(object, motion);
                % if self.predmode.status
                %     animTrans{i} = self.transfilter(object, motion);
                % end
                for j = 2 : self.objPerSample
                    object  = self.getObject();
                    motion  = self.getMotion();
                    anim{1} = self.combine(anim{1}, self.generate(object, motion));
                end
            end
            % % split frames in prediction mode
            % if self.predmode.status
            %     animPred = cell(1, numel(anim));
            %     for i = 1 : numel(anim)
            %         tdim = self.dsample + 1;
            %         animPred{i} = sltondim(anim{i}, tdim, ...
            %             self.nframes + (1 : self.predmode.nframes));
            %         anim{i} = sltondim(anim{i}, tdim, 1 : self.nframes);
            %     end
            % end
            % % packup animation into data package
            % if self.predmode.status
            %     varargout = { ...
            %         self.data.packup(anim), ...
            %         self.label.packup(animPred), ...
            %         self.transform.packup(animTrans), ...
            %         object, motion};
            % else
            varargout = {self.data.packup(anim), object, motion};
            % end
            % send data packages if necessary
            if nargout == 0
                self.data.send(varargout{1});
                % if self.predmode.status
                %     self.label.send(varargout{2});
                %     self.transform.send(varargout{3});
                % end
            end
        end
    end
    
    methods (Access = private)
        function value = randval(~, minValue, maxValue)
            value = rand() * (maxValue - minValue) + minValue;
        end
        
        function anim = combine(~, anim, other)
            anim = max(anim, other);
        end
    end
    
    methods
        function self = objectMode(self, type, varargin)
            switch lower(type)
              case {'static', 'constant'}
                self.objmode.type  = 'static';
                self.objmode.cache = varargin{1};
                
              case {'random', 'rand'}
                self.objmode.type  = 'random';
                self.objmode.cache = [];
                
              otherwise
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function self = motionMode(self, type, varargin)
            switch lower(type)
              case {'static', 'constant'}
                self.mtmode.type  = 'static';
                self.mtmode.cache = varargin{1};
                
              case {'rand', 'random'}
                self.mtmode.type  = 'random';
                self.mtmode.cache = [];
                
              otherwise
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
        
    methods
        function object = getObject(self)
            switch self.objmode.type
              case {'random'}
                object = self.randObject();
                
              case {'static'}
                object = self.objmode.cache;
            end
        end
        
        function motion = getMotion(self)
            switch self.mtmode.type
              case {'random'}
                motion = self.randMotion();
            
              case {'static'}
                motion = self.mtmode.cache;
            end
        end   
        
        function object = randObject(self)
            % TODO: currently don't generate RECTANGLE and POLYGON
            object.shape = self.shapeSet{randi(numel(self.shapeSet))};
            object.size  = ceil(min(self.frameSize) / self.randval(3, 7));
            object.position = [self.randval(-0.3, 0.3), self.randval(-0.3, 0.3)];
            object.orient = self.randval(0, 2 * pi);
            if strcmpi(object.shape, 'polygon')
                object.nedges = randi([3, 8]);
                value = rand(1, object.nedges) + 2;
                object.edgeOrient   = 2 * pi * cumsum(value / sum(value));
                object.edgeDistance = (rand(1, object.nedges) + 3) / 3.5;
            end
        end
        
        function motion = randMotion(self)
            motion = struct();
            if rand() < self.onoff.translation
                motion.translation = struct( ...
                    'status', true, ...
                    'direction', self.randval(0, 2 * pi), ...
                    'speed', self.randval(0.01, 0.07));
            else
                motion.translation = struct('status', false);
            end
            if rand() < self.onoff.scaling
                motion.scaling = struct( ...
                    'status', true, ...
                    'speed', self.randval(0.1, 0.9));
            else
                motion.scaling = struct('status', false);
            end
            if rand() < self.onoff.rotation
                motion.rotation = struct( ...
                    'status', true, ...
                    'speed', self.randval(pi / 32, pi / 4));
            else
                motion.rotation = struct('status', false);
            end  
        end
    end
    
    methods
        function anim = generate(self, object, motion)
            % initialize coordinates
            [X,Y]  = meshgrid( ...
                linspace(-0.5, 0.5, self.frameSize(2)), ...
                linspace(0.5, -0.5, self.frameSize(1)));
            xscale = (self.frameSize(2) - 1) / object.size;
            yscale = (self.frameSize(1) - 1) / object.size;
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
            nfrms = self.nframes;
            % if self.predmode.status
            %     nfrms = nfrms + self.predmode.nframes;
            % end
            % initialize animation data
            anim = zeros([self.frameSize, nfrms]);
            % calculate step size for each transformation
            if motion.translation.status
                % mvstep = max(real(Z(:) * conj(mV))) / (self.nframes - 1);
                mvstep = motion.translation.speed;
            end
            % TODO: redefine the scale of scaling and rotation
            % rtstep = 2 * pi / self.nframes;
            if motion.rotation.status
                rtstep = motion.rotation.speed;
            end
            % scstep = (max(abs(Z(:))))^(1/(self.nframes-1));
            if motion.scaling.status
                % speed in setting represent the end status of object
                sizeEnd = min(self.frameSize) * motion.scaling.speed / 2;
                scstep  = (sizeEnd / object.size) ^ (1 / (self.nframes - 1));
            end
            % initialize transition-zone width
            tzwidth = self.tzone;
            % transforming frame by frame
            for f = 1 : nfrms
                % generate current frame accordint to the shape
                switch object.shape
                    case {'circle'}
                        anim(:, :, f) = self.circle(Z, tzwidth);
                        
                    case {'edge'}
                        anim(:, :, f) = self.edge(Z, tzwidth);
                        
                    case {'triangle'}
                        anim(:, :, f) = self.polygon(Z, 3, tzwidth);
                        
                    case {'square'}
                        anim(:, :, f) = self.polygon(Z, 4, tzwidth);
                        
                    case {'polygon'}
                        anim(:, :, f) = self.polygon( ...
                            Z, object.nedges, tzwidth, object.edgeOrient, object.edgeDistance);
                        
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
    end
    
    % methods
    %     function self = enablePredmode(self, npredfrm, fltsize)
    %         self.predmode = struct( ...
    %             'status', true, ...
    %             'nframes', npredfrm, ...
    %             'fltsize', fltsize);
    %     end
    %     
    %     function self = disablePredmode(self)
    %         self.predmode = struct('status', false);
    %     end
    % end
    
    methods
        function frame = circle(self, Z, tzwidth)
            frame = self.boundaryFunction(abs(Z) - 1, tzwidth);
        end
        
        function frame = edge(self, Z, tzwidth)
            frame = self.boundaryFunction(abs(real(Z)) - 1, tzwidth);
        end
        
        function frame = polygon(self, Z, n, tzwidth, orient, distance)
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
                I(:, :, i) = self.boundaryFunction(real(Z * conj(normVec)) - distance(i), tzwidth);
            end
            frame = min(I, [], 3);
        end
        
        function frame = boundaryFunction(self, M, tzwidth)
            frame = zeros(size(M));
            % make background to be black
            % frame(M >= tzwidth) = 1;
            % make object to be black
            frame(M <= -tzwidth) = 1;
            % setup transition zone
            tzindex = abs(M) < tzwidth;
            if self.tzone > 0
                frame(tzindex) = 1 - (sin((pi * M(tzindex)) / (2 * tzwidth)) + 1) / 2;
            end
        end
    end

    methods
        function self = SimpleAnimationGenerator()
            self.data  = DatasetAP(self, self.dsample, self.taxis);
            self.label = DatasetAP(self, self.dsample, self.taxis);
            % self.transform = DatasetAP(self, self.dsample + 1, false);
            self.frameSize = [32, 32];
            self.nframes   = 30;
            self.tzone     = 0.2;
            self.objPerSample = 1;
            % self.disablePredmode();
            self.objectMode('rand');
            self.motionMode('rand');
            self.onoff = struct('translation', 0.7, 'scaling', 0.7, 'rotation', 0.7);
        end
    end

    properties (Constant)
        taxis = true;
        dsample = 2;
        shapeSet = {'circle', 'edge', 'triangle', 'square', 'polygon'};
    end
    
    properties
        onoff
        data, label, % transform
        tzone
        frameSize, nframes
        % predmode
        objPerSample
        objmode, mtmode
    end
end