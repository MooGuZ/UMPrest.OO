classdef Objective < handle
    methods
        varargout = evaluate(obj, varargin)
        varargout = delta(obj, varargin)
    end
end
