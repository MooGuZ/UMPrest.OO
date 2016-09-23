function f = animviewer(data, cmap, resolution)
% ANIMVIEWER create a GUI object to play given animation with support of
% play/pause button and frame-corresponding slider.
%
%   F = ANIMVIEWER(DATA) create a GUI object with figure handle F to play
%   animation in DATA. Assuming DATA is a 2D or 3D matrix of float values
%   in range of [0,1] that representing a gray-scale animation. The last
%   dimension of DATA is considered as axes of animation frames. If DATA is
%   a 2D matrix, ANIMVIEWER would try to recover frames in the vectors into
%   NxN matrix automatically. If this operation failed, an error would be
%   raised.
%
%   F = ANIMVIWER(DATA, CMAP) create a GUI object with figure handle F to
%   play animation in DATA wich color map CMAP, which is a Nx3 matrix
%   containing RGB color value in each row. DATA here is an index matrix
%   with 2 or 3 dimension.
%
%   F = ANIMVIEWER(DATA, CMAP, RESOLUTION) add capability to recover frames
%   from vectors with specified resolution in RESOLUTION, which should be a
%   2 elements vector.
%
% See also, animcompare.

% MooGu Z. <hzhu@case.edu>
% Feb 20, 2016
    
    % ------------- PREPARATION -------------
    [fpos, apos, spos, bpos] = layout();
    
    % deal with GIF file
    if ischar(data) && exist(data, 'file')
        [~, ~, ext] = fileparts(data);
        assert(strcmpi(ext, '.gif'), ...
            'AnimViewer can only deal GIF animation at this version.');
        [data, cmap] = imread(data, 'gif');
        data = reshape(data, [size(data,1), size(data, 2), size(data, 4)]);
    end
    
    % formalize data
    if isstruct(data) || isa(data, 'DataPackage')
        data = data.data;
    end
    if numel(size(data)) == 2
        if ~exist('resolution', 'var')
            n = size(data, 1);
            assert(round(sqrt(n))^2 == n, ...
                   'Need resolution information');
            resolution = sqrt([n, n]);
        end
        data = reshape(data, [resolution, size(data, 2)]);
    end
    
    ws.animdata = data;
    
    ws.nframe = size(data, 3);
    ws.fcount = 1;
    
    ws.bgcolor = 0.94 * ones(1, 3);
    
    icnpath = fullfile(fileparts(mfilename('fullpath')), 'material');
    
    ws.icon.play  = imresize( ...
        imread(fullfile(icnpath, 'play.png'), 'png', 'BackgroundColor', ws.bgcolor), ...
        [16, 16]);
    ws.icon.pause = imresize( ...
        imread(fullfile(icnpath, 'pause.png'), 'png', 'BackgroundColor', ws.bgcolor), ...
        [16, 16]);
    
    % ------------- ELEMENTS -------------
    f = figure('Name',            'Animation Viewer', ...
               'Position',        fpos,  ...
               'Visible',         'off', ...
               'Color',           ws.bgcolor, ...
               'CLoseRequestFcn', @close);

    ws.animAxes = axes('Units',    'Pixels', ...
                       'xtick',    [], ...
                       'ytick',    [], ...
                       'Position', apos);
    
    if exist('cmap', 'var')
        ws.hanim = imshow(ws.animdata(:, :, 1), cmap);
    else
        ws.hanim = imshow(ws.animdata(:, :, 1));
    end
    
    if (ws.nframe < 10)
        sliderstep = (1 / ws.nframe) * [1, 1];
    else
        sliderstep = [1 / ws.nframe, 0.1];
    end
    
    ws.slider = uicontrol('Parent',     f, ...
                          'Style',      'Slider', ...
                          'Value',      1, ...
                          'Max',        ws.nframe, ...
                          'Min',        1, ...
                          'SliderStep', sliderstep, ...
                          'Position',   spos, ...
                          'Callback',   @jumpToFrame);
    
    ws.listener = addlistener(ws.slider, 'ContinuousValueChange', @jumpToFrame);
    
    ws.ppButton  = uicontrol('Parent',   f, ...
                             'Style',    'pushbutton', ...
                             'String',   '', ...
                             'CData',    ws.icon.pause, ...
                             'Position', bpos, ...
                             'Callback', @playpause);    
    
    ws.tmr = timer('TimerFcn', {@showFrame, f}, ...
                   'BusyMode', 'Queue', ...
                   'ExecutionMode', 'FixedRate', ...
                   'Period', 0.1);
    
    guidata(f, ws);
    
    movegui(f, 'center');
    
    set(f, 'ResizeFcn', @layout);
    set(f, 'Visible',   'on');
    
    start(ws.tmr);
end

function [fpos, apos, spos, bpos] = layout(hObject, ~)
    a = 512;                            % anim-axes size
    b = 16;                             % button size
    d = 20;                             % border width
    v = 10;                             % interval width between objects
    
    % obtain figure position
    if exist('hObject', 'var')
        fpos = get(hObject, 'Position');
        awid = fpos(3) - 2*d;
        ahgt = fpos(4) - 2*d - b - v;
    else
        fpos = [0, 0, 2*d + a, 2*d + a + v + b];
        awid = a;
        ahgt = a;
    end
    
    % calculate each objects position
    apos = [d, d + b + v, awid, ahgt];
    spos = [d + b + v, d, awid - b - v, b];
    bpos = [d, d, b, b];
    
    % arrange objects if capable
    if exist('hObject', 'var')
        ws = guidata(hObject); 
        % assistant vector to prevent negative width/height
        threshold = [-inf, -inf, eps, eps];   
        set(ws.animAxes, 'Position', max(apos, threshold));
        set(ws.slider,   'Position', max(spos, threshold));
        set(ws.ppButton, 'Position', bpos);
    end
end

function close(hObject, ~)
    ws = guidata(hObject);
    if isfield(ws, 'tmr')
        stop(ws.tmr);
        delete(ws.tmr);
    end
    closereq
end

function jumpToFrame(hObject, ~)
    ws = guidata(hObject);
    
    ws.fcount = round(get(hObject, 'Value'));
    set(ws.hanim, 'CData', ws.animdata(:, :, ws.fcount));
    
    guidata(hObject, ws);
end

function playpause(hObject, ~)
    ws = guidata(hObject);
    switch ws.tmr.Running
      case 'on'
        stop(ws.tmr);
        set(ws.ppButton, 'CData', ws.icon.play);
        
      case 'off'
        start(ws.tmr);
        set(ws.ppButton, 'CData', ws.icon.pause);
    end
end

function showFrame(~, ~, f)
    ws = guidata(f);
    set(ws.hanim, 'CData', ws.animdata(:, :, ws.fcount));
    set(ws.slider, 'Value', ws.fcount);
    ws.fcount = mod(ws.fcount, ws.nframe) + 1;
    guidata(f, ws);
end
