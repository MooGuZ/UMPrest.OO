classdef FileTree < handle
    methods
        % EXP: call GET function through ARRAYFUN with continuous index is
        % much much faster than an array of random integers (order
        % difference is greater than linear). So, a speedup method to GET
        % random items is get the continuous items from the smallest-index
        % item to largest-index item before fetch random-index items.
        % However this method would introduce memory problem in some cases.
        % More investigation is needed in the implementation.
        function fname = get(obj, index)
            assert(0 < index && index <= obj.volumn);
            if index <= numel(obj.subfile)
                fname = fullfile(obj.root, obj.subfile{index});
            else
                nfile = cumsum([numel(obj.subfile), ...
                    cellfun(@(tree) tree.volumn, obj.subfolder)]);
                ifolder = find(index <= nfile, 1, 'first') - 1;
                fname = obj.subfolder{ifolder}.get(index - nfile(ifolder));
            end
        end
        
        function delete(obj, index)
            assert(0 < index && index <= obj.volumn);
            if index <= numel(obj.subfile)
                obj.subfile(index) = [];
                obj.refresh();
            else
                nfile = cumsum([numel(obj.subfile), ...
                    cellfun(@(tree) tree.volumn, obj.subfolder)]);
                ifolder = find(index <= nfile, 1, 'first') - 1;
                obj.subfolder{ifolder}.delete(index - nfile(ifolder));
            end
        end
        
        function tf = match(obj, fname)
            [~,~,ext] = fileparts(fname);
            tf = strcmpi(ext, obj.pattern);
        end
        
        function explore(obj)
            % search for subtree and subfile
            finfolist = dir(obj.root)';
            % remove hidden file/folder and '.'/'..'
            finfolist = finfolist(arrayfun(@(f) f.name(1) ~= '.', finfolist));
            % record pattern-matched file
            index = arrayfun(@(f) obj.match(f.name), finfolist);
            obj.subfile = arrayfun(@(f) f.name, finfolist(index), 'UniformOutput', false);
            % create FileTree for subfolders
            index = arrayfun(@(f) f.isdir, finfolist);
            flist = arrayfun(@(f) fullfile(obj.root, f.name), finfolist(index), ...
                'UniformOutput', false);
            obj.subfolder = cellfun( ...
                @(f) FileTree(f, 'parent', obj, 'pattern', obj.pattern), flist, ...
                'UniformOutput', false);
            % remove empty subfolder
            obj.subfolder(cellfun(@(f) f.volumn == 0, obj.subfolder)) = [];
            % calculate volumn
            obj.volumn = sum(cellfun(@(tree) tree.volumn, obj.subfolder)) ...
                + numel(obj.subfile);
        end
        
        function refresh(obj)
            % calculate volumn
            obj.volumn = sum(cellfun(@(tree) tree.volumn, obj.subfolder)) ...
                + numel(obj.subfile);
            % propagate information to upper level
            if not(isempty(obj.parent))
                obj.parent.refresh();
            end
        end
    end
    
    methods
        function obj = FileTree(root, varargin)
            assert(isdir(root));
            obj.root = abspath(root);
%             obj.root = root;
            conf = Config(varargin);
            obj.pattern = conf.pop('Pattern', '.gif');
            obj.parent  = conf.pop('Parent', []);
            obj.explore();
        end
    end
    
    properties
        root, parent
        subfolder, subfile
        pattern, volumn
    end
    methods

    end
end