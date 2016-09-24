classdef ErrorPackage < DataPackage
% TODO: add field for derivative from prior
    methods
        function obj = ErrorPackage(varargin)
            obj = obj@DataPackage(varargin{:});
        end
    end
end
