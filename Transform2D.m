classdef Transform2D < Dataset
    methods
        function [anim, info] = next(self, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % initialize cell array for animations
            anim = cell(1, n);
            info = cell(1, n);
            % generate animation one by one
            for i = 1 : n
                self.updateCache();
                anim{i} = self.generate();
                info{i} = Transform2D.encodeConfig(self.cache);
            end
            % packup animation and information
            anim = self.data.packup(anim);
            info = self.label.packup(info);
            % send packages if necessary
            if nargout == 0
                self.data.send(anim);
                self.label.send(info);
            end
        end
    end

    methods
        function anim = generate(self)
            for i = 1 : numel(self.cache)
                conf = self.cache(i);
                % canvas initialization
                [X,Y]  = meshgrid( ...
                    linspace(-1, 1, self.framesize(2)), ...
                    linspace(1, -1, self.framesize(1)));
                xscale = self.canvasScale.x / conf.scale;
                yscale = self.canvasScale.y / conf.scale;
                Z      = complex(xscale * X, yscale * Y);
                % adapt initial object position
                Z = Z - conf.position * [xscale; 1j*yscale];
                % adapt initial object orientation
                Z = Z * exp(-1j * conf.orient);
                % calculate translation vector
                T = conf.translation * [xscale; 1j*yscale] / (self.nframes - 1);
                T = T * exp(-1j * conf.orient);
                % calculate rotation multiplexer
                R = exp(-2j * pi * conf.rotation / (self.nframes - 1));
                % calculate scaling factor
                S = conf.scaling ^ (1 / (self.nframes - 1));
                % initialize animation data
                buffer = zeros([self.framesize, self.nframes]);
                % transforming frame by frame
                for f = 1 : self.nframes
                    % generate current frame accordint to the shape
                    buffer(:, :, f) = self.(conf.shape)(Z, conf);
                    % update Z and T
                    Z = (Z - T) * R / S;
                    T = T * R / S;                    
                end
                % compose animation
                if i == 1
                    anim = buffer;
                else
                    anim = self.combine(buffer, anim);
                end
            end
            % update cache count
            self.count = self.count - 1;
        end
        
        function frame = circle(self, Z, conf)
            frame = self.boundaryFunction(abs(Z) - 1, conf.tzwidth);
        end
        
        function frame = edge(self, Z, conf)
            frame = self.boundaryFunction(abs(real(Z)) - 1, conf.tzwidth);
        end
        
        function frame = triangle(self, Z, conf)
            conf.nedges       = 3;
            conf.edgeOrient   = [0, 2/3, 4/3] * pi;
            conf.edgeDistance = [1, 1, 1];
            frame = self.polygon(Z, conf);
        end
        
        function frame = square(self, Z, conf)
            conf.nedges       = 4;
            conf.edgeOrient   = [0, 0.5, 1, 1.5] * pi;
            conf.edgeDistance = [1, 1, 1, 1];
            frame = self.polygon(Z, conf);
        end
        
        function frame = polygon(self, Z, conf)
            I = zeros([size(Z), conf.nedges]);
            for i = 1 : conf.nedges
                normVec = exp(1j * conf.edgeOrient(i));
                I(:, :, i) = self.boundaryFunction( ...
                    real(Z * conj(normVec)) - conf.edgeDistance(i), conf.tzwidth);
            end
            frame = min(I, [], 3);
        end
        
        function frame = boundaryFunction(~, M, tzwidth)
            frame = zeros(size(M));            
            % make object to be black
            frame(M <= -tzwidth) = 1;
            % setup transition zone
            tzindex = abs(M) < tzwidth;
            frame(tzindex) = 1 - (sin(pi * M(tzindex) / (2 * tzwidth + eps)) + 1) / 2;
        end
        
        function anim = combine(~, layer, anim)
            index = layer > 0;
            anim(index) = layer(index);
            % anim = max(anim, layer);
        end
    end
    
    % function set for randomization
    methods % (Access = private)
        function value = randval(~, range, n)
        % generate random value in specific range and quantity, use normal distribution
            if not(exist('n', 'var'))
                n = 1;
            end
            % generate random value
            if isscalar(range)
                value = range * ones(1, n);
            else
                value = range(1) + (range(2) - range(1)) * rand(1, n);
            end
        end
        
        function value = randival(~, range, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            % generate random value
            if isscalar(range)
                value = round(range) * ones(1, n);
            else
                value = randi(round(range), 1, n);
            end
        end
        
        function value = randort(~, n)
        % generate a sequence of random numbers representing orientation
            value = rand(1, n) + 2;                         % random number between 2 and 3
            value = 2 * pi * cumsum(value / sum(value));    % put them in range 0 to 2*Pi
        end
    
        function updateCache(self)
            if self.count <= 0
                self.cache = [];
                for i = 1 : self.randival(self.nobjects)
                    buffer.shape = self.shape{randi(numel(self.shape))};
                    switch buffer.shape
                      case {'circle'}
                        buffer.nedges       = 1;
                        buffer.edgeOrient   = 0; % PRB: need a more reasonable value
                        buffer.edgeDistance = 1;
                        
                      case {'edge'}
                        buffer.nedges       = 2;
                        buffer.edgeOrient   = [0, pi];
                        buffer.edgeDistance = [1, 1];
                        
                      case {'triangle'}
                        buffer.nedges       = 3;
                        buffer.edgeOrient   = [0, 2/3, 4/3] * pi;
                        buffer.edgeDistance = [1, 1, 1];
                        
                      case {'square'}
                        buffer.nedges       = 4;
                        buffer.edgeOrient   = [0, 0.5, 1, 1.5] * pi;
                        buffer.edgeDistance = [1, 1, 1, 1];
                        
                      otherwise
                        buffer.nedges       = self.randival(self.nedges);
                        buffer.edgeOrient   = self.randort(buffer.nedges);
                        buffer.edgeDistance = self.randval(self.edgeDistance, buffer.nedges);
                    end
                    buffer.scale       = self.randval(self.scale);
                    buffer.position    = self.randval(self.position, 2);
                    buffer.orient      = self.randval(self.orient);
                    buffer.translation = self.randval(self.translation, 2);
                    buffer.scaling     = self.randval(self.scaling);
                    buffer.rotation    = self.randval(self.rotation);
                    buffer.tzwidth     = self.randval(self.tzwidth);
                    % add to cache
                    self.cache = [self.cache, buffer];                    
                end
                self.count = 1;
            end
        end
    end
    
    methods (Static)
        function value = shapeset(index)
            persistent sset
            if isempty(sset)
                sset = {'circle', 'edge', 'triangle', 'square', 'polygon'};
            end
            if exist('index', 'var')
                value = sset{index};
            else
                value = sset;
            end
        end
        
        function code = encodeConfig(conf)
            code = cell(1, numel(conf));
            for i = 1 : numel(conf)
                cfg = conf(i);
                code{i} = [ ...
                    find(strcmpi(cfg.shape, Transform2D.shapeset())), ...
                    cfg.nedges, ...
                    cfg.edgeOrient, ...
                    cfg.edgeDistance, ...
                    cfg.scale, ...
                    cfg.position, ...
                    cfg.orient, ...
                    cfg.translation, ...
                    cfg.scaling, ...
                    cfg.rotation, ...
                    cfg.tzwidth]';
            end
            code = cat(1, numel(conf), code{:});
        end
        
        function conf = decodeConfig(code)
            index = 2;
            conf  = cell(1, code(1));
            for i = 1 : numel(cell);
                cfg.shape        = Transform2D.shapeset(code(index));
                cfg.nedges       = code(index + 1);
                index = index + 1;
                cfg.edgeOrient   = code(index + (1 : cfg.nedges))';
                index = index + cfg.nedges;
                cfg.edgeDistance = code(index + (1 : cfg.nedges))';
                index = index + cfg.nedges;
                cfg.scale        = code(index + 1);
                cfg.position     = code(index + (2 : 3))';
                cfg.orient       = code(index + 4);
                cfg.translation  = code(index + (5 : 6))';
                cfg.scaling      = code(index + 7);
                cfg.rotation     = code(index + 8);
                cfg.tzwidth      = code(index + 9);
                index = index + 10;
                conf{i} = cfg;
            end
            conf = cell2mat(conf);
        end
    end
    
    % configuration interfaces
    methods
        function self = default(self)
            self.nobjects     = 1;
            self.tzwidth      = 0.2;
            self.shape        = Transform2D.shapeset();
            self.nedges       = [3, 5];
            self.edgeDistance = [0.5, 1.5];
            self.scale        = [0.5, 2];
            self.position     = [-0.8, 0.8];
            self.orient       = [-pi, pi];
            self.translation  = [-1.3, 1.3];
            self.scaling      = [0.3, 3];
            self.rotation     = [-3, 3];
            self.count        = 0;
        end
        
        function self = config(self, varargin)
            Config(varargin).apply(self);
            self.count = 0;
        end
        
        function conf = getLastConfig(self)
            conf = self.cache;
        end
        
        function self = useConfig(self, conf, lifetime)
            if not(exist('lifetime', 'var'))
                lifetime = false;
            end
            % setup cache
            self.cache = conf;
            % setup cache's lifetime
            if islogical(lifetime)
                if lifetime
                    self.count = inf;
                else
                    self.count = 1;
                end
            elseif isnumeric(lifetime)
                self.count = lifetime;
            else
                error('ILLEGAL ARGUMENT');
            end
        end
    end

    methods
        function self = Transform2D(varargin)
            self.data  = DatasetAP(self, self.dsample, self.taxis);
            self.label = DatasetAP(self, 1, self.taxis);
            % load default configuration
            self.default();
            % apply configuration in argument
            self.config(varargin{:});
        end
    end

    properties (Constant)
        taxis       = true
        dsample     = 2
        canvasScale = struct('x', 3, 'y', 3)
    end
    properties (Access = protected)
        cache = [], count = 0         % cache and its lifetime
    end
    % properties (SetAccess = protected)
    %     data, label              % Access-Points
    % end
    properties (Dependent)
        islabelled
        volume
    end
    properties
        framesize = [32, 32]     % size of each frame
        nframes   = 30           % frame quantity in a sequence
        nobjects                 % number of objects in the sequence
        tzwidth                  % width of transition zone
        shape, nedges, edgeDistance
        scale, position, orient, translation, scaling, rotation
    end
    methods
        function value = get.islabelled(~)
            value = true;
        end
        
        function value = get.volume(~)
            value = inf;
        end
        
        function set.framesize(self, value)
            assert(numel(value) == 2 && MathLib.isinteger(value) && all(value >= 8), ...
                'ILLEGAL ASSIGNMENT');
            self.framesize = value;
        end
        
        function set.nframes(self, value)
            assert(isscalar(value) && MathLib.isinteger(value) && value >= 3, ...
                'ILLEGAL ASSIGNMENT');
            self.nframes = value;
        end
        
        function set.nobjects(self, value)
            assert(MathLib.isinteger(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.nobjects = MathLib.bound(value, [1, 5]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.nobjects = MathLib.bound(value, [1, 5]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.tzwidth(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.tzwidth = MathLib.bound(value, [0, 0.5]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.tzwidth = MathLib.bound(value, [0, 0.5]);
            else
                error('ILLEGAL ASSIGNMENT');
            end            
        end
        
        function set.shape(self, value)
            assert(numel(value) == numel(intersect(value, Transform2D.shapeset())), ...
                'ILLEGAL ASSIGNMENT');
            if iscell(value)
                self.shape = value;
            else
                self.shape = {value};
            end
        end
        
        function set.nedges(self, value)
            assert(MathLib.isinteger(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.nedges = MathLib.bound(value, [3, 8]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.nedges = MathLib.bound(value, [3, 8]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.edgeDistance(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.edgeDistance = MathLib.bound(value, [eps, 3]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.edgeDistance = MathLib.bound(value, [eps, 3]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.scale(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.scale = MathLib.bound(value, [eps, 3]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.scale = MathLib.bound(value, [eps, 3]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.position(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.position = MathLib.bound(value, [-1, 1]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.position = MathLib.bound(value, [-1, 1]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.orient(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.orient = MathLib.bound(value, [-pi, pi]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.orient = MathLib.bound(value, [-pi, pi]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.translation(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.translation = MathLib.bound(value, [-2, 2]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.translation = MathLib.bound(value, [-2, 2]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.scaling(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.scaling = MathLib.bound(value, [0, 3]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.scaling = MathLib.bound(value, [0, 3]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.rotation(self, value)
            assert(isnumeric(value), 'ILLEGAL ASSIGNMENT');
            if isscalar(value)
                self.rotation = MathLib.bound(value, [-5, 5]);
            elseif numel(value) == 2
                assert(value(2) >= value(1), 'ILLEGAL ASSIGNMENT');
                self.rotation = MathLib.bound(value, [-5, 5]);
            else
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end