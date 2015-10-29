function animshow(anim,frmsz,duration,swColor)
% ANIMSHOW show animation in a frame till close it up
%
% Vihang Patil, Oct 2006
% Copyright 2006-2007 Vihang Patil
% Email: vihang_patil@yahoo.com
% Created: 17th Oct 2006
%
% Revision:
% Date: 19th Oct 2006..Removed the setappdata and getappdata and used
% functions handling property. Multiple Gif's can be called upon which can
% be opened in new figure window.
% ex: figure;gifplayer;
% ex: figure;gifplayer('abcd.gif',0.1); and so on
% 
% P.N: PLease make sure to close the existing window in which the gif is
% currently being played and open a separate window for another GIF
% image.If another GIF is opened in the same window then the first timer
% continues to run even if you close the figure window.
%
% Date: Nov 3rd, 2014
% Modified by MooGu Z. to show gif data in 3D matrix
%
% Date: Jan 29th, 2015
% Modified by MooGu Z. to show animation data
%
% Data: Jun 26th, 2015
% Modified by MooGu Z. to support 3D matrix as b&w animation

warning('OFF','MATLAB:TIMER:RATEPRECISION');
% check input quantity
if nargin == 0 || nargin > 3
    error('Syntax : ANIMSHOW(ANIM[,DURATION])');
end
% set color switcher to default value
if ~exist('swColor', 'var'), swColor = false; end
% check availability of animation
switch numel(size(anim))
    case 2
        [npixel,nframe] = size(anim);
        
    case 3
        % specified to show colors
        if swColor
            [npixel,nframe,ncolor] = size(anim);
            assert(ncolor==3, ...
                'the 3rd dimension of color animation should be size of 3.')
        else
            [nrow, ncol, nframe] = size(anim);
            frmsz = [nrow, ncol];
        end
        
    otherwise
        error('animation should by 2D or 3D matrix');
end
% initialize frame size
if ~exist('frmsz','var')
    frmsz = sqrt(npixel) * [1,1];
    assert(prod(frmsz) == npixel, ...
        'Please specify frame size for this animation');
end
% initialize duration
if ~exist('duration','var')
    duration = nframe / 23.97;
end

% convert animation from RGB space into index and colormap format
if swColor
    [anim,cmap] = rgb2ind(anim,256);
end

% display animation
f = figure();
handles.im  = reshape(anim,[frmsz,nframe]);
handles.len = size(handles.im,3);
if swColor
    handles.h1 = imshow(handles.im(:,:,1),cmap);
else
    handles.h1 = imshow(handles.im(:,:,1));
end
handles.guifig = f;
handles.count  = 1;
handles.tmr = timer('TimerFcn', {@TmrFcn,handles.guifig},'BusyMode','Queue',...
    'ExecutionMode','FixedRate','Period',duration / handles.len);
guidata(handles.guifig,handles);
start(handles.tmr);

set(handles.guifig,'CloseRequestFcn',{@CloseFigure,handles});


function TmrFcn(~,~,handles)
%Timer Function to animate the GIF

handles = guidata(handles);
%update the frame in the axis
set(handles.h1,'CData',handles.im(:,:,handles.count)); 
%increment to next frame
handles.count = handles.count + 1;
%if the last frame is achieved intialise to first frame
if handles.count > handles.len 
    handles.count = 1;
end
guidata(handles.guifig, handles);


function CloseFigure(~,~,handles)
% Function CloseFigure(varargin)
stop(handles.tmr);
%removes the timer from memory
delete(handles.tmr);
closereq;


