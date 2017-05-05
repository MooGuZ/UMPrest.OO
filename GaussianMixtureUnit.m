classdef GaussianMixtureUnit < MISOUnit & FeedforwardOperation & Evolvable
    methods
        function p = dataproc(obj, x, l)
            p = zeros(1, numel(l), 'like', x);
            for i = 1 : numel(p)
                p(i) = x(:, i)' * obj.invC{l(i)} * x(:, i) / 2;
            end
            % p = p + log(obj.detC(l));
        end
        
        function [dx, dl] = deltaproc(obj, dp)
            % data and label
            x = obj.apdata.datarcd.pop();
            l = obj.aplabel.datarcd.pop();
            % gaussian basis and parameter
            b = obj.catbasis;
            y = exp(obj.catcord);
            % initialize gradients
            db = zeros(size(b), 'like', dp);
            dy = zeros(size(y), 'like', dp);
            dl = zeros(size(l), 'like', dp);
            dx = zeros(size(x), 'like', dp);
            % calculate gradient category by category
            for i = 1 : obj.ncategory
                index = (l == i);
                % number of input date with label 'i'
                Nl = sum(index(:));
                if Nl ~= 0
                    % section of input data with label 'i'
                    Xl = x(:, index);
                    % basis weighted by category cordinated of category 'i'
                    Bl = bsxfun(@times, b, y(:, i)');
                    % transformed input data of label 'i'
                    Xt = obj.invC{i} * Xl;
                    % gradient weight of each sample
                    Ws = dp(index);
                    % gradient of category cordinates
%                     % [branch A] with DET term
%                     for j = 1 : size(b, 2)
%                         dy(j, i) = b(:, j)' * obj.invC{i} * b(:, j);
%                     end
%                     dy(:, i) = sum(Ws) * dy(:, i) ...
%                         - 0.5 * sum(bsxfun(@times, (b' * Xt).^2, Ws), 2);
                    % [Branch B] without DET term
                    dy(:, i) = -sum(bsxfun(@times, (b' * Xt).^2, Ws), 2) / 2;
                    % gradient of category basis
%                     % [Branch A] with DET term
%                     db = db - Xt * diag(Ws) *  Xt' * Bl + 2 * sum(Ws) * obj.invC{i} * Bl;
                    % [Branch B]
                    db = db - Xt * diag(Ws) * Xt' * Bl;
                    % gradient of input date
                    dx(:, index) = 2 * bsxfun(@times, Xt, Ws);
                end
            end
            % record gradients for hyper-parameters
            obj.A.addgrad(dy .* y); % NOTE: y = exp(a)
            obj.B.addgrad(db);
        end
        
        function update(obj)
            obj.A.update();
            obj.B.update();
            % normalization of Y, which is exp(A)
            y = exp(obj.A.get());
            y = bsxfun(@rdivide, y, sum(y.^2, 1));
            obj.A.set(log(y));
            % normalize basis B
            obj.B.normalize(1);
            % update convariance matrix
            obj.updateCovMatrix();
        end
        
        function updateCovMatrix(obj)
            b = obj.catbasis;
            y = exp(obj.catcord);
            obj.C = cell(1, obj.ncategory);
            obj.invC = cell(1, obj.ncategory);
            obj.detC = zeros(1, obj.ncategory, 'like', b);
            for i = 1 : obj.ncategory
                obj.C{i} = b * diag(y(:, i)) * b';
                obj.invC{i} = inv(obj.C{i});
                obj.detC(i) = det(obj.C{i});
            end
        end
    end
    
    methods
        function psize = sizeIn2Out(~, ~, lsize)
            psize = lsize;
        end
        
        function [xsize, lsize] = sizeOut2In(obj, psize)
            xsize = [obj.datadim, size(psize, 2)];
            lsize = psize;
        end
    end
    
    methods
        function hpcell = hparam(obj)
            hpcell = {obj.A, obj.B};
        end
    end
    
    methods
        function obj = GaussianMixtureUnit(catcord, catbasis)
            obj.ncategory = size(catcord, 2);
            obj.nbasis    = size(catcord, 1);
            obj.datadim   = size(catbasis, 1);
            assert(size(catbasis, 2) == obj.nbasis, 'ILLEGAL ASSIGNMENT');
            % setup hyper-parameters
            obj.A = HyperParam(catcord);
            obj.B = HyperParam(catbasis);
            % setup access points
            obj.apdata  = UnitAP(obj, 1, '-recdata');
            obj.aplabel = UnitAP(obj, 1, '-recdata');
            obj.approb  = UnitAP(obj, 1);
            obj.I = {obj.apdata, obj.aplabel};
            obj.O = {obj.approb};
            % initialization
            obj.updateCovMatrix();
        end
    end
    
    methods (Static)
        function obj = randinit(ncategory, nbasis, datadim)
            obj = GaussianMixtureUnit(randn(nbasis, ncategory), ...
                2 * rand(datadim, nbasis) - 1);
        end
    end
    
    properties (Constant)
        taxis = false
    end
    
    properties (SetAccess = private)
        A, B %, M, W
        apdata, aplabel, approb
        C, invC, detC
        ncategory, nbasis, datadim
    end
    properties (Dependent)
        catcord, catbasis %, mu, weight
    end
    methods
        function value = get.catcord(obj)
            value = obj.A.get();
        end
        function set.catcord(obj, value)
            obj.A.set(value);
        end
        
        function value = get.catbasis(obj)
            value = obj.B.get();
        end
        function set.catbasis(obj, value)
            obj.B.set(value);
        end
        
        % function value = get.weight(obj)
        %     value = obj.W.get();
        % end
        % function set.weight(obj, value)
        %     obj.W.set(value);
        % end
        % 
        % function value = get.mu(obj)
        %     value = obj.M.get();
        % end
        % function set.mu(obj, value)
        %     obj.M.set(value);
        % end
    end
end