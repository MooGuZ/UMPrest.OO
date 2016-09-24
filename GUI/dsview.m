function f = dsview(folder)
    pos = layout();

    % data structure in GUI
    ws = struct();

    ws.folder = folder;
    ws.flist  = listFileWithExt(folder, '.gif');
    ws.ibase  = 1;
    ws.base   = gifread(fullfile(ws.folder, ws.flist{1}));
    ws.anim.nframe = size(ws.base, 3);
    ws.anim.duration = 3;
    ws.anim.progress = 1;
    ws.dmode = 'Real';
    ws.bgcolor = [0.94, 0.94, 0.94];
        
    icnpath = fullfile(fileparts(mfilename('fullpath')), 'material');
    
    ws.icon.play  = imresize( ...
        imread(fullfile(icnpath, 'play.png'), 'png', 'BackgroundColor', ws.bgcolor), ...
        pos.ppButton(3:4));
    ws.icon.pause = imresize( ...
        imread(fullfile(icnpath, 'pause.png'), 'png', 'BackgroundColor', ws.bgcolor), ...
        pos.ppButton(3:4));

    % create figure
    f = figure( ...
        'Name',            'Complex Base Inspector', ...
        'Position',        pos.figure,  ...
        'Visible',         'off', ...
        'Color',           ws.bgcolor, ...
        'CLoseRequestFcn', @close);

    ws.animAxes = axes( ...
        'Units', 'Pixels', ...
        'xtick', [], ...
        'ytick', [], ...
        'Position', pos.animAxes);

    switch lower(ws.dmode)
        case {'real'}
            ws.hanim = imshow(ws.base(:, :, ws.anim.progress));
            
        case {'complex'}
            ws.hanim = imshow(ws.base(:, :, ws.anim.progress));
            
        otherwise
            error('Something wrong in the program');
    end
    
    ws.prevButton = uicontrol( ...
        'Parent', f, ...
        'Style', 'pushbutton', ...
        'String', 'PREV', ...
        'Position', pos.prevButton, ...
        'Callback', @prevBase);
    
    ws.nextButton = uicontrol( ...
        'Parent', f, ...
        'Style', 'pushbutton', ...
        'String', 'NEXT', ...
        'Position', pos.nextButton, ...
        'Callback', @nextBase);
    
    ws.bindexText = uicontrol( ...
        'Parent', f, ...
        'Style',  'text', ...
        'String', ['Sample - ', num2str(ws.ibase)], ...
        'FontSize', round(0.8 * pos.bindexText(4)), ...
        'Position', pos.bindexText, ...
        'Enable', 'inactive', ...
        'ButtonDownFcn', @editBaseIndex, ...
        'Visible', 'on');
        
    ws.bindexEdit = uicontrol( ...
        'Parent', f, ...
        'Style',  'edit', ...
        'String', '', ...
        'Position', pos.bindexEdit, ...
        'Callback', @gotoBase, ...
        'Visible', 'off');
    
    ws.ppButton  = uicontrol( ...
        'Parent',   f, ...
        'Style',    'pushbutton', ...
        'String',   '', ...
        'CData',    ws.icon.pause, ...
        'Position', pos.ppButton, ...
        'Callback', @playpause);
    
    if (ws.anim.nframe < 10)
        sliderstep = (1 / ws.anim.nframe) * [1, 1];
    else
        sliderstep = [1 / ws.anim.nframe, 0.1];
    end
    
    ws.animSlider = uicontrol( ...
        'Parent',     f, ...
        'Style',      'slider', ...
        'Value',      ws.anim.progress, ...
        'Max',        ws.anim.nframe, ...
        'Min',        1, ...
        'SliderStep', sliderstep, ...
        'Position',   pos.animSlider, ...
        'Callback',   @jumpToFrame);
    
    ws.listener = addlistener(ws.animSlider, 'ContinuousValueChange', @jumpToFrame);
    
    ws.speedSelector = uibuttongroup( ...
        'Parent', f, ...
        'Units', 'Pixels', ...
        'Title', 'Animation Speed', ...
        'Position', pos.speedSelector, ...
        'SelectionChangedFcn', @selectSpeed);
    
    ws.speedSlow = uicontrol( ...
        'Parent', ws.speedSelector, ...
        'Units', 'Normalized', ...
        'Style', 'radiobutton', ...
        'String', 'Slow', ...
        'Position', [0.1, 0.1, 0.2, 0.8], ...
        'HandleVisibility', 'off');
    
    ws.speedNormal = uicontrol( ...
        'Parent', ws.speedSelector, ...
        'Units', 'Normalized', ...
        'Style', 'radiobutton', ...
        'String', 'Normal', ...
        'Position', [0.4, 0.1, 0.2, 0.8], ...
        'HandleVisibility', 'off');
    
    ws.speedFast = uicontrol( ...
        'Parent', ws.speedSelector, ...
        'Units', 'Normalized', ...
        'Style', 'radiobutton', ...
        'String', 'Fast', ...
        'Position', [0.7, 0.1, 0.2, 0.8], ...
        'HandleVisibility', 'off');
    
    set(ws.speedSelector, 'SelectedObject', ws.speedNormal);
    
    ws.dmodeSelector = uibuttongroup( ...
        'Parent', f, ...
        'Units', 'Pixels', ...
        'Title', 'Display Mode', ...
        'Position', pos.dmodeSelector, ...
        'SelectionChangedFcn', @selectDMode);
    
    ws.dmodeReal = uicontrol( ...
        'Parent', ws.dmodeSelector, ...
        'Units', 'Normalized', ...
        'Style', 'radiobutton', ...
        'String', 'Real', ...
        'Position', [0.1, 0.1, 0.35, 0.8], ...
        'HandleVisibility', 'off');
    
    ws.dmodeComplex = uicontrol( ...
        'Parent', ws.dmodeSelector, ...
        'Units', 'Normalized', ...
        'Style', 'radiobutton', ...
        'String', 'Complex', ...
        'Position', [0.55, 0.1, 0.35, 0.8], ...
        'HandleVisibility', 'off');
    
    set(ws.dmodeSelector, 'SelectedObject', ws.dmodeReal);
    
    ws.tmr = timer( ...
        'TimerFcn', {@animateBase, f}, ...
        'BusyMode', 'queue', ...
        'ExecutionMode', 'fixedRate', ...
        'Period', floor(ws.anim.duration / ws.anim.nframe * 1000) / 1000);

    guidata(f, ws);
    movegui(f, 'center');
    set(f, 'ResizeFcn', @layout);
    set(f, 'Visible',   'on');
    
    start(ws.tmr);
end

function pos = layout(hObject, ~)
    a = 512; % anim-axes size
    o = 16;  % object size
    b = 20;  % border width
    v = 10;  % interval width between objects
    
    pos = struct();
    
    % size of fixed-size objects
    objsz = struct();
    objsz.prevButton = [50, 1.5*o];
    objsz.nextButton = objsz.prevButton;
    objsz.bindexText = [100, o];
    objsz.bindexEdit = objsz.bindexText;
    objsz.ppButton   = [o, o];
    objsz.speedSelector = [300, 3*o];
    objsz.dmodeSelector = [200, 3*o];
    
    % position of figure and size of animation axes
    fixedSpace = [2*b, 2*b + 3*v + ...
        objsz.ppButton(2) + objsz.prevButton(2) + objsz.speedSelector(2)];
    if exist('hObject', 'var')
        pos.figure = get(hObject, 'Position');
        objsz.animAxes = pos.figure(3 : 4) - fixedSpace;
    else
        objsz.animAxes = [a, a];
        pos.figure = [0, 0, objsz.animAxes + fixedSpace];
    end
    
    % size of flexible-size objects
    objsz.animSlider = [objsz.animAxes(1)- objsz.ppButton(1) - v, o];
    
    % calculate objects' position
    pos.speedSelector = [b, b, objsz.speedSelector];
    pos.dmodeSelector = [pos.figure(3) - b - objsz.dmodeSelector(1), b, objsz.dmodeSelector];
    pos.prevButton = [b, sum(pos.speedSelector([2, 4])) + v, objsz.prevButton];
    pos.nextButton = [pos.figure(3) - b - objsz.nextButton(1), pos.prevButton(2), objsz.nextButton];
    pos.bindexText = [round((pos.figure(3) - objsz.bindexText(1))/2), pos.prevButton(2), objsz.bindexText];
    pos.bindexEdit = pos.bindexText;
    pos.ppButton   = [b, sum(pos.prevButton([2, 4])) + v, objsz.ppButton];
    pos.animSlider = [sum(pos.ppButton([1, 3])) + v, pos.ppButton(2), objsz.animSlider];
    pos.animAxes   = [b, sum(pos.ppButton([2, 4])) + v, objsz.animAxes];
    
    % arrange objects if capable
    if exist('hObject', 'var')
        ws = guidata(hObject); 
        % assistant vector to prevent negative width/height
        threshold = [-Inf, -Inf, eps, eps];   
        set(ws.animAxes,   'Position', max(pos.animAxes, threshold));
        set(ws.prevButton, 'Position', max(pos.prevButton, threshold));
        set(ws.nextButton, 'Position', max(pos.nextButton, threshold));
        set(ws.bindexText, 'Position', max(pos.bindexText, threshold));
        set(ws.bindexEdit, 'Position', max(pos.bindexEdit, threshold));
        set(ws.ppButton,   'Position', max(pos.ppButton, threshold));
        set(ws.animSlider, 'Position', max(pos.animSlider, threshold));
        set(ws.speedSelector, 'Position', max(pos.speedSelector, threshold));
        set(ws.dmodeSelector, 'Position', max(pos.dmodeSelector, threshold));
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

function animateBase(~, ~, f)
    ws = guidata(f);
    setAnimProgress(f, ws.anim.progress + 1);
end

function setBaseIndex(hObject, index)
    ws = guidata(hObject);
    ws.ibase = MathLib.bound(round(index), [1, numel(ws.flist)]);
    ws.base = gifread(fullfile(ws.folder, ws.flist{ws.ibase}));
    ws.anim.nframe = size(ws.base, 3);
    set(ws.animSlider, 'Max', ws.anim.nframe);
    set(ws.bindexText, 'String', ['Sample - ', num2str(ws.ibase)]);
    guidata(hObject, ws);
    setAnimProgress(hObject, 1);
end

function setAnimProgress(hObject, progress)
    ws = guidata(hObject);
    ws.anim.progress = mod(round(progress) - 1, ws.anim.nframe) + 1;
    I = ws.base(:, :, ws.anim.progress);
    set(ws.hanim, 'CData', I);
    set(ws.animSlider, 'Value', ws.anim.progress);
    guidata(hObject, ws);
end

function prevBase(hObject, ~)
    ws = guidata(hObject);
    setBaseIndex(hObject, ws.ibase - 1);
end

function nextBase(hObject, ~)
    ws = guidata(hObject);
    setBaseIndex(hObject, ws.ibase + 1);
end

function gotoBase(hObject, ~)
    ws = guidata(hObject);
    indexString = get(ws.bindexEdit, 'String');
    if not(isempty(indexString))
        index = round(str2double(indexString));
        if isnan(index)
            warning('Input is not a valid index');
        else
            setBaseIndex(hObject, index);
        end
    end
    set(ws.bindexEdit, 'Visible', 'off');
    set(ws.bindexText, 'Visible', 'on');
    uicontrol(ws.bindexText);
end

function editBaseIndex(hObject, ~)
    ws = guidata(hObject);
    set(ws.bindexEdit, 'String', '');
    set(ws.bindexText, 'Visible', 'off');
    set(ws.bindexEdit, 'Visible', 'on');
    uicontrol(ws.bindexEdit);
end

function playpause(hObject, ~)
    ws = guidata(hObject);
    switch get(ws.tmr, 'Running')
      case 'on'
        stop(ws.tmr);
        set(ws.ppButton, 'CData', ws.icon.play);
        
      case 'off'
        start(ws.tmr);
        set(ws.ppButton, 'CData', ws.icon.pause);
    end
end

function jumpToFrame(hObject, ~)
    setAnimProgress(hObject, get(hObject, 'Value'));
end

function selectSpeed(hObject, eventData)
    ws = guidata(hObject);
    wasRunning = strcmpi(get(ws.tmr, 'Running'), 'on');
    if wasRunning
        stop(ws.tmr);
    end
    switch eventData.NewValue.String
        case {'Slow'}
            ws.anim.duration = 10;
            
        case {'Normal'}
            ws.anim.duration = 3;
            
        case {'Fast'}
            ws.anim.duration = 1;
            
        otherwise
            error('This cannot happend');
    end
    set(ws.tmr, 'Period', floor(ws.anim.duration / ws.anim.nframe * 1000) / 1000);
    guidata(hObject, ws);
    if wasRunning
        start(ws.tmr);
    end
end

function selectDMode(hObject, eventData)
    ws = guidata(hObject);
    ws.dmode = eventData.NewValue.String;
    guidata(hObject, ws);
    if strcmpi(get(ws.tmr, 'Running'), 'off')
        setAnimProgress(hObject, ws.anim.progress);
    end
end
