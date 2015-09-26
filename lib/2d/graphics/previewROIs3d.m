function previewROIs3d(handles)


if isempty(handles.traces)
    warndlg('There are no ROIs defined to preview','3D Preview of ROIs','modal')
    return
end

% Instigate the figure
figname = '3D ROI Preview';
hf = findobj('Type','figure','Name',figname);
if isempty(hf)
    hf = figure('Name',figname,'NumberTitle','off','Tag','Prev3D_fig','Visible','off');
    hax = axes('Parent',hf,'Tag','Prev3D_axes');
    xlabel(hax,'x');
    ylabel(hax,'y');
    zlabel(hax,'z');
    hold(hax,'on')
    grid(hax,'on')
    view(hax,3)
    
    % Add listener which will update this display whenever the main program
    % updates its display.  We hang it on the userdata of the image in the
    % main program since this is the method UPDATESLICE provides for triggering
    % listeners. We also store the handle to the listener so that it can be
    % deleted when this figure is closed:
    him = findobj(handles.axes1,'Type','image');
    li = addlistener(him,'UserData','PostSet',@prev3DListener);
    li.CallbackTarget = handles.figure1;  % Store this
    
    % Now store the listener handle in the UserData of the preview figure
    % so it can be destroyed when the figure is closed:
    %set(hf,'UserData',li)       % Store listener so we can delete it
    %set(hf,'CloseRequestFcn',...% On figure close...
    %    'delete(get(gcbf,''UserData''));closereq') % delete the listener
    
    setappdata(hf,'DisplayListner',li)
    set(hf,'CloseRequestFcn',...
        'delete(getappdata(gcbf,''DisplayListner''));closereq')
    
    % Now store the handle to the main prog:
    setappdata(hf,'MainGUIFigure',handles.figure1)
    
    set(hf,'Visible','on')
    
else
    figure(hf)
    
end

% Trigger the listener
prev3DListener(handles)


% ------------------------------------------------------------------------
function prev3DListener(varargin)
% This function updates the 3D ROI preview window which has the tag
% 'Prev3D_fig' 
% 
% Usage:
% ------
%   prev3DListener(handles)         % Initialisation call
%   prev3DListener(hTarget,event)   % Call from a lister which has 'CallbackTarget' set


if nargin == 1
    handles = varargin{:};
elseif nargin == 2
    handles = guidata(varargin{1});
end

% Get the handles to figure and axes:
hf = findobj('Type','figure','tag','Prev3D_fig');
hax = findobj(hf,'Type','axes');        
 
% Get traces for just this current phase:
p = current('phase',handles.axes1);
tf = [handles.traces.Phase] == p;
R = handles.traces(tf);             % ROIS for phase p

% Graphics problem: % 2011b on mac doesn't display '.' markers that are
% 6pts or less.  Or is this just because it's a 27" iMac?
if verLessThan('matlab','7.13')
    lopts = {'Marker','.'}; % default: MarkerSize==6
else
    lopts = {'Marker','.','MarkerSize',7};
end

% Now clean the axes and plot:
delete(findobj(hax,'Type','line'));     % Delete all lines
ht = zeros(size(R));
for j = 1:numel(R)
    xyz = R(j).to3d;
    ht(j) = plot3(xyz(:,1),xyz(:,2),xyz(:,3),...
        'Parent',hax,...
        lopts{:},...            % Fallback / fix
        'Color',R(j).Color,...
        'LineStyle',R(j).LineStyle,...
        'ButtonDownFcn',@clickBDF,...
        'Tag', R(j).Tag);
end
axis(hax,'tight','equal')
ns = numel(unique([R.Slice]));
nr = max([0 j]); % circumvent j = [] problem when no ROIs present
title(hax,sprintf('Phase %d:  %d ROIs on %d slices',p,nr,ns))

% Now add context menu & actions

hctxt = uicontextmenu('Parent',hf,'Callback',@contextCallback);

item0 = uimenu(hctxt,...
    'Label','ROI-',...
    'Enable','off',...
    'Tag','context_title');
item1 = uimenu(hctxt,...
    'Label','Delete',...
    'Callback',@deleteSelectedROI,...
    'Separator','on',...
    'Tag','deleteTrace');
%set(h,'UIContextMenu',hctxt)



for j = 1:numel(ht)
    set(ht(j), 'UIContextMenu',hctxt)
end



% ------------------------------------------------------------------------
function contextCallback(hmenu,eventdata)
% This function sets the title of the uicontext menu to the currently
% selected ROI
% The title is actually the first list item of the uicontextmenu, which is
% disabled.  It has the tag: context_title

htrace = gco;
tagname = get(htrace,'Tag');

hctxtitle = findobj(get(hmenu,'Children'),'Tag','context_title');
set(hctxtitle,'Label',tagname)




% ------------------------------------------------------------------------
function deleteSelectedROI(hobj,eventdata)

% Get the tag trace that has been clicked:
htrace = gco;
tagname = get(htrace,'Tag');


% Get handles
hf = getappdata(gcf,'MainGUIFigure');
handles = guidata(hf);

% Remove the selected trace:
t = handles.traces;
id = strcmp(tagname,{t.Tag});
t(id) = [];

% Push back to handles
handles.traces = t;
guidata(handles.figure1,handles)

% Update picutre
delete(htrace)

% Ideally we would refresh the main GUI too

disp(['Deleted ' tagname])


% ------------------------------------------------------------------------
function clickBDF(hobj,eventdata)

lw = get(hobj,'LineWidth');
mk = get(hobj,'Marker');
set(hobj,'LineWidth',5,'Marker','*')
pause(0.2)
set(hobj,'LineWidth',lw,'Marker',mk)
title(gca,get(hobj,'Tag'))

