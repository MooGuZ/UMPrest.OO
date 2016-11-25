classdef Operation < handle
    methods (Abstract)
        varargout = process(obj, type, varargin)
        varargout = invproc(obj, type, varargin)
    end
end
