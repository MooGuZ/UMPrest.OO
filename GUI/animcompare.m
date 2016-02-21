function f = animcompare(dataL, dataR, cmap, resolution)
% ANIMCOMPARE create a GUI object to comparing two animation by playing them
% synchronously. Currently this function can only deal with two animations with same
% colormap and resolution.
    
% MooGu Z. <hzhu@case.edu>
% Feb 20, 2016

    % ------------- PREPARATION -------------
    [fpos, alpos, arpos, spos, bpos] = layout();
    
    % deal with GIF file (Left Side)
    if ischar(dataL) && exist(dataL, 'file')
        [~, ~, ext] = fileparts(dataL);
        assert(strcmpi(ext, '.gif'), ...
            'AnimViewer can only deal GIF animation at this version.');
        [dataL, cmap] = imread(dataL, 'gif');
        dataL = reshape(dataL, [size(dataL,1), size(dataL, 2), size(dataL, 4)]);
        dataL = ind2gray(dataL, cmap); clear cmap
    end
    % deal with GIF file (Right Side)
    if ischar(dataR) && exist(dataR, 'file')
        [~, ~, ext] = fileparts(dataR);
        assert(strcmpi(ext, '.gif'), ...
            'AnimViewer can only deal GIF animation at this version.');
        [dataR, cmap] = imread(dataR, 'gif');
        dataR = reshape(dataR, [size(dataR,1), size(dataR, 2), size(dataR, 4)]);
        dataR = ind2gray(dataR, cmap); clear cmap
    end
    
    % formalize data (Left Side)
    if isstruct(dataL)
        dataL = dataL.data;
    end
    if numel(size(dataL)) == 2
        if ~exist('resolution', 'var')
            n = size(dataL, 1);
            assert(round(sqrt(n))^2 == n, ...
                   'Need resolution information');
            resolution = sqrt([n, n]);
        end
        dataL = reshape(dataL, [resolution, size(dataL, 2)]);
    end
    % formalize data (Right Side)    
    if isstruct(dataR)
        dataR = dataR.data;
    end
    if numel(size(dataR)) == 2
        if ~exist('resolution', 'var')
            n = size(dataR, 1);
            assert(round(sqrt(n))^2 == n, ...
                   'Need resolution information');
            resolution = sqrt([n, n]);
        end
        dataR = reshape(dataR, [resolution, size(dataR, 2)]);
    end
    
    ws.animdataL = dataL;
    ws.animdataR = dataR;
    
    ws.nframe = min(size(dataL, 3), size(dataR, 3));
    ws.fcount = 1;
    
    ws.icon.play  = imresize(imread('./material/play.png', 'png'), [16, 16]);
    ws.icon.pause = imresize(imread('./material/pause.png', 'png'), [16, 16]);
    
    % ------------- ELEMENTS -------------
    f = figure('Name',            'Animation Viewer', ...
               'Position',        fpos,  ...
               'Visible',         'off', ...
               'Color',           [0, 0, 0], ...
               'CLoseRequestFcn', @close);

    ws.animAxesL = axes('Units',    'Pixels', ...
                        'xtick',    [], ...
                        'ytick',    [], ...
                        'Position', alpos);
    
    if exist('cmap', 'var')
        ws.hanimL = imshow(ws.animdataL(:, :, 1), cmap);
    else
        ws.hanimL = imshow(ws.animdataL(:, :, 1));
    end
    
    ws.animAxesR = axes('Units',    'Pixels', ...
                        'xtick',    [], ...
                        'ytick',    [], ...
                        'Position', arpos);
    
    if exist('cmap', 'var')
        ws.hanimR = imshow(ws.animdataR(:, :, 1), cmap);
    else
        ws.hanimR = imshow(ws.animdataR(:, :, 1));
    end
    
    ws.slider = uicontrol('Parent',     f, ...
                          'Style',      'Slider', ...
                          'Value',      1, ...
                          'Max',        ws.nframe, ...
                          'Min',        1, ...
                          'SliderStep', [1 / ws.nframe, 0.1], ...
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

    % ------------- RUN -------------
    movegui(f, 'center');
    
    set(f, 'ResizeFcn', @layout);
    set(f, 'Visible',   'on');
    
    start(ws.tmr);
end

function [fpos, alpos, arpos, spos, bpos] = layout(hObject, ~)
    a = 512;                            % anim-axes size
    b = 16;                             % button size
    d = 20;                             % border width
    v = 10;                             % interval width between objects
    
    % obtain figure position
    if exist('hObject', 'var')
        fpos = get(hObject, 'Position');
        awid = (fpos(3) - 2*d - v) / 2;
        ahgt = fpos(4) - 2*d - b - v;
    else
        fpos = [0, 0, 2*d + 2*a + v, 2*d + a + v + b];
        awid = a;
        ahgt = a;
    end
    
    % calculate each objects position
    alpos = [d, d + b + v, awid, ahgt];
    arpos = [d + awid + v, d + b + v, awid, ahgt];
    spos  = [d + b + v, d, 2*awid - b, b];
    bpos  = [d, d, b, b];
    
    % arrange objects if capable
    if exist('hObject', 'var')
        ws = guidata(hObject);
        % assistant vector to prevent negative width/height
        threshold = [-inf, -inf, eps, eps];   
        set(ws.animAxesL, 'Position', max(alpos, threshold));
        set(ws.animAxesR, 'Position', max(arpos, threshold));
        set(ws.slider,    'Position', max(spos,  threshold));
        set(ws.ppButton,  'Position', max(bpos,  threshold));
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
    set(ws.hanimL, 'CData', ws.animdataL(:, :, ws.fcount));
    set(ws.hanimR, 'CData', ws.animdataR(:, :, ws.fcount));
    
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
    set(ws.hanimL, 'CData', ws.animdataL(:, :, ws.fcount));
    set(ws.hanimR, 'CData', ws.animdataR(:, :, ws.fcount));
    set(ws.slider, 'Value', ws.fcount);
    ws.fcount = mod(ws.fcount, ws.nframe) + 1;
    guidata(f, ws);
end
