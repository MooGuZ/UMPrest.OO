classdef Interface < handle
    properties (Abstract, SetAccess = protected)
        I, O              % container of AccessPoints
    end
    properties (Abstract, SetAccess = protected, Hidden)
        forward, backward % abstract functions
    end
end
