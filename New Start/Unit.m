classdef Unit < handle
    % ======================= DATA PROCESSING  =======================
    methods
        function varargout = transform(obj, varargin)
            varargout      = cell(1, nargout);
            [varargout{:}] = obj.propagate('forward',  @obj.process, 'DataPackage', varargin{:});
        end
        
        function varargout = compose(obj, varargin)
            varargout      = cell(1, nargout);
            [varargout{:}] = obj.propagate('backward', @obj.invproc, 'DataPackage', varargin{:});
        end
        
        function varargout = errprop(obj, varargin)
            varargout      = cell(1, nargout);
            [varargout{:}] = obj.propagate('backward', @obj.delta, 'ErrorPackage', varargin{:});
        end
        
        function varargout = checkSampleSizeSuitability(obj, varargin)
            varargout      = cell(1, nargout);
            [varargout{:}] = obj.propagate('forward', @obj.sizeIn2Out, 'SizePackage', varargin{:});
        end
        
        % function [tf, varargout] = checkSampleSizeSuitability(obj, varargin)
        % % PROPOSAL: implement a version based on PROPAGATE and multiple PACKAGE type
        %     if numel(varargin)
        %         insize = varargin;
        %         % ASSERT: insize is cell with same number of elements as obj.I 
        %         try
        %             for i = 1 : numel(obj.I)
        %                 obj.I(i).szsample = varargin{i};
        %             end
        %         catch mexcption
        %             warning(mexception.identifier, mexception.message);
        %             tf = false;
        %             return
        %         end
        %     else
        %         insize = {obj.I(:).szsample};
        %     end
        %     % calculate output size info
        %     outsize      = cell(1, numel(obj.O));
        %     [outsize{:}] = obj.sizeIn2Out(insize{:});
        %     % assign output size info to corresponding access points
        %     for i = 1 : numel(obj.O)
        %         obj.O(i).szsample = sizeout{i};
        %     end
        %     % send or return sizeinfo
        %     if argout > 1
        %         varargout = outsize;
        %     else
        %         try
        %             for i = 1 : numel(obj.O)
        %                 obj.O.link.szsample = outsize{i};
        %             end
        %         catch mexcption
        %             warning(mexception.identifier, mexception.message);
        %             tf = false;
        %             return
        %         end
        %     end
        %     tf = true;
        % end
    end
    
    methods
        function varargout = propagate(obj, direction, proc, pkgtype, varargin)
            switch lower(direction)
              case {'forward'}
                apin  = obj.I;
                apout = obj.O;
                
              case {'backward'}
                apin  = obj.O;
                apout = obj.I;
                
              otherwise
                error('UMPrest:ArguementError', 'Unrecognized direction : %s', ...
                      upper(direction));
            end
            % clear CDINFO of parent unit
            if exist('pkgtype', 'var')
                obj.cdinfo = struct('pkgtype', pkgtype);
            else
                obj.cdinfo = struct();
            end
            % Single-In-Single-Out version
            if isscalar(apin) && isscalar(apout)
                % NOTE: arguments in the VARARGIN is ignored from 2nd term
                % get input package
                if isempty(varargin)
                    ipackage = obj.I.pop();
                else
                    ipackage = varargin{1};
                end
                % unpack input data from package
                idata = apin.unpack(ipackage);
                % process the data
                odata = proc(idata);
                % get output package
                opackage = apout.packup(odata);
                % send or return output package
                if nargout
                    varargout{1} = opackage;
                else
                    apout.send(opackage);
                end
            % General MIMO version
            else
                % get input package
                if isempty(varargin)
                    ipackage = arrayfun(@pop, apin, 'UniformOutput', false);
                else
                    ipackage = varargin;
                end
                % unpack data from package
                idata = cell(1, numel(apin));
                for i = 1 : numel(apin)
                    idata{i} = apin(i).unpack(ipackage{i});
                end
                % process the data
                odata = cell(1, numel(apout));
                [odata{:}] = proc(idata{:});
                % send or return output package
                if nargout
                    for i = 1 : min(nargout, numel(apout))
                        varargout{i} = apout(i).packup(odata{i});
                    end
                else
                    for i = 1 : numel(apout)
                        apout(i).send(apout(i).packup(odata{i}));
                    end
                end
            end
        end
    end
    
    methods
        function forward(obj)
            obj.propagate('forward', @obj.procByType);
        end
        
        function backward(obj)
            obj.propagate('backward', @obj.invpByType);
        end
        
        function varargout = procByType(obj, varargin)
            varargout = cell(1, nargout);
            switch obj.cdinfo.pkgtype
              case {'DataPackage'}
                [varargout{:}] = obj.process(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeIn2Out(varargin{:});
                
              case {'ErrorPackage'}
                error('UMPrest:RuntimeError', 'This operation is not supported!');
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
        
        function varargout = invpByType(obj, varargin)
            varargout = cell(1, nargout);
            switch obj.cdinfo.pkgtype
              case {'DataPackage'}
                [varargout{:}] = obj.invproc(varargin{:});
                
              case {'SizePackage'}
                [varargout{:}] = obj.sizeOut2In(varargin{:});
                
              case {'ErrorPackage'}
                [varargout{:}] = obj.delta(varargin{:});
                
              otherwise
                error('Other Package types are not supported at current time.');
            end
        end
    end
    
    methods (Abstract)
        data = process(obj, data)
        data = invproc(obj, data)
        d    = delta(obj, d)
        outsize = sizeIn2Out(obj, insize)
        insize  = sizeOut2In(obj, outsize)
    end
    
    properties (Hidden)
        I      % list of, access points for input interface
        O      % list of access points for output interface
        cdinfo % share field of current data information
    end
    
    properties (Abstract, SetAccess = private)
        taxis, expandable
    end
    
    % % ======================= TOPOLOGY LOGIC =======================
    % methods (Abstract)
    %     unit = inverseUnit(obj)
    % end
    
    % ======================= DEVELOPMENT TOOL =======================
    methods (Static)
        function validate(instance)
            assert(isa(instance, 'Unit'), ...
                   'This function only check validity of instance of class UNIT.');
            assert(SizeDescription.iscompact(instance.inputSizeRequirement), ...
                   'Input size requirement has redundent variable.');
            invars  = SizeDescription.symvar(instance.inputSizeDescription);
            outvars = SizeDescription.symvar(instance.outputSizeDescription);
            assert(all(ismember(outvars, invars)), ...
                   'Output description contains unknown variable.');
            assert(SizeDescription.match(obj.inputSizeRequirement, ...
                                         obj.inputSizeDescription), ...
                   'Input size description cannot fullfile the requirement');
        end
    end
end
