%% Dropout Class
% The idea explored here is make 'dropout' a module that provides methods for 
% general units to enable dropout in training process. So, 'dropout' should be 
% able to interact with status of the unit that whether or not it is in training 
% session. However, 'GenerativeUnit' already has a property 'training', which 
% indicate whether or not should it do adaptation in forward pass. *Maybe I should 
% consider adding 'training' as a general property for all units, and enforce 
% class 'Task' switching it in the begining and at the end of the procedure. However, 
% in this way, it add more burdens to users.* 
% 
% After some thinking. Solution metioned above would mess things up. I decided 
% to implement it as a unit as in MATLAB's official implementation.

classdef Dropout < PackageProcessor
    methods
        function package = forward(this, package)
            if not(isa(package, 'SizePackage'))
                this.mask = double(rand([pkgin.smpsize, 1]) > this.ratio);
                package.dot(this.mask);
            end
        end
        
        function package = backward(this, package)
            if not(isa(package, 'SizePackage'))
                package.dot(this.mask);
            end
        end
        
        function activate(this)
            this.status = true;
        end
        
        function deactivate(this)
            this.status = false;
        end
    end
    
    methods
        function this = Dropout(ratio)
            this.ratio = ratio;
            this.activate();
            this.I = SimpleAP(this);
            this.O = SimpleAP(this);
        end
    end
    
    properties
        status
        mask
        ratio
    end
    properties (SetAccess = protected)
        I, O
    end
end