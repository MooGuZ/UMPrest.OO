% CLASS : MotionLearner
%
% Basic class of UMPress.OO package that implement fundamental workflow control 
% of motion representation learning process. Concrete models should be defined
% as subclasses to implement required interfaces.
%
% MooGu Z. <hzhu@case.edu>
%
% Sept 30, 2015 - initial commit

classdef MotionLearner
    properties
        data
    end
    
    methods
        % constructor from MotionMaterial instance
        function self = MotionLearner(motionData)
            self.data = motionData;
        end
        
        % interfaces
        learn(self, motionData);
        infer(self, motionData);
        adapt(self, motionData, modelRespond);
    end
end
