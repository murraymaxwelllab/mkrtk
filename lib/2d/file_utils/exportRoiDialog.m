function [colorcell, pathcell] = exportRoiDialog(clrCell,defaultDir)


% Get invoking figure & its position:
hfi = gcbf;
hfi_psn = get(hfi,'Position');

% Get the colours 
clrs = ColourSpec('ToLongnames',clrCell);
n = numel(clrs);

% Now build the dialog
w = 260;
h = 330;  % This will be adjusted later

hf = figure('Name','Export ROIs',...
    'NumberTitle','off',...
    'Toolbar','none',...
    'Menubar','none',...
    'Resize','off',...
    'Position',[200 300 w h]);
bkgclr = get(hf,'Color');

% Store invoking figure
setappdata(hf,'hInvoker',hfi);

% Build items from the base up:
xpad = 10;
ypad = 10;
btnh = 30;
btnw = (w - 3*xpad)/2;

y = 15;

fontsize = 12;

% OK & Cancel buttons:
hok = uicontrol(hf, 'style','pushbutton','String','OK',...
    'Callback',@doOK,...
    'FontSize',fontsize,...
    'Tag','ok_btn',...
    'position',[xpad, y, btnw, btnh]);
hcancel = uicontrol(hf, 'style','pushbutton','String','Cancel',...
    'Callback',@doCancel,...
    'FontSize',fontsize,...
    'Tag','cancel_btn',...
    'position',[2*xpad+btnw, y, btnw, btnh]);
y = y+btnh;

% Create Text for the different colours:
ht = zeros(1,n);
he = zeros(1,n);

tw = 7*fontsize;  % text width - 7 letters (magenta), convert to pix
ew = 130;  % edit width
x1 = xpad*2;
x2 = x1+tw+xpad;

th = fontsize*1.3*1.5;  % text height - font ht convert to pix, pad
eh = th;  % edit height

y = y + ypad*2;
for j = 1:n
    y = y+ypad;
    ht(j) = uicontrol(hf,'style','text',...
        'string',clrs{j},...
        'ForegroundColor',clrs{j},...
        'BackgroundColor',[0 0 0],...
        'FontWeight','bold',...
        'FontSize',fontsize,...
        'Tag',['_text_' clrs{j}],... % eg, _text_magenta
        'position',[x1 y tw th]);
    he(j) = uicontrol(hf,'style','edit','string','',...
        'FontSize',fontsize,...
        'HorizontalAlignment','left',...
        'BackgroundColor',[1 1 1],...
        'Tag',['_edit_' clrs{j}],... % eg, _edit_magenta
        'position',[x2, y, ew, eh]);
    y = y+th;
    uistack(he(j),'bottom')
end

% Now make column headers (plain text):
%y = y+ypad;
uicontrol(hf,'style','text','string','Trace:',...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'FontWeight','bold',...
    'HorizontalAlignment','Left',...
    'position',[x1,y,tw,th]);

uicontrol(hf,'style','text','string','Filename:',...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'FontWeight','bold',...
    'HorizontalAlignment','Left',...
    'position',[x2,y,ew,th]);
y = y+th;

y = y+ypad;

% Add gui header text:
hti2 = uicontrol(hf,'style','text',...
    'string',{'Enter filenames to save the ROIs.:'; 'All ROIs of the color will be saved.  Do not include the file extension'},...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'HorizontalAlignment','Left',...
    'position',[x2,y,ew,th]);
hti1 = uicontrol(hf,'style','text',...
    'string','Export ROIs',...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'FontWeight','bold',...
    'HorizontalAlignment','Left',...
    'position',[x2,y,ew,th]);

set(hti2,'position',[xpad,y,w-2*ypad,th*2])
set(hti1,'position',[xpad,y+6*ypad,w-2*xpad,th])

% Set position of the gui to the upper-right corner of the main gui:
psn = get(hf,'Position');
x0 = hfi_psn(1) + hfi_psn(3) - w;
y0 = hfi_psn(2) + hfi_psn(4) - h;
psn(1:2) = [x0 y0];
set(hf,'Position',psn)


% Cancel with escape or button press:
set([hf, hok, hcancel], 'KeyPressFcn', {@doKeypress, hf});


% Set active uicontrol
uicontrol(he(end))

% Make visible and wait for user response
set(hf,'Visible','on')
uiwait(hf);


% Set outputs:
if isappdata(0,'ExportDialogAppData__')
    % write to outputs
    ad = getappdata(0,'ExportDialogAppData__');
    colorcell = ad.colorcell;
    pathcell = ad.pathcell;
    % remove from 0:
    rmappdata(0,'ExportDialogAppData__')
else
    colorcell = [];
    pathcell = [];  
end



%% figure, OK and Cancel KeyPressFcn
function doKeypress(src, evd, fig) %#ok
switch evd.Key
 case 'escape'
  doCancel([],[]);
end


%% Cancel callback
function doCancel(cancel_btn, evd) %#ok

% Ensure no residual appdata:
if isappdata(0,'ExportDialogAppData__')
    rmappdata(0,'ExportDialogAppData__');
end
delete(gcbf);


function pth = setPath()
% Get the path to save to
% Could return 0 -> cancel

fig = gcbf;

try
    % Try to use userPath first:
    hi = getappdata(fig,'hInvoker');
    handles = guidata(hi);
    pth = fileparts(handles.userPath);
    
    if ~isdir(pth)  % if that didn't work
        pth = handles.sessionPath;
        
        if ~isdir(pth)  % if that didn't work, set as pwd
            pth = pwd;
        end
    end
catch
    pth = pwd;
end

% This could return 0
[pth] = uigetdir(pth,'Save traces to:');


%% OK callback
function doOK(ok_btn, evd) %#ok

fig = gcbf;

% Find all the edit boxes and get their strings
hedits = findobj(fig,'-regexp','Tag','_edit_');
tags = get(hedits,'Tag');
clrs = regexprep(tags,'_edit_','');
fnames = get(hedits,'String');

% Force fnames to be cell array:
if ischar(fnames)
    fnames = {fnames};
end

% Remove ones with empty names:
id = cellfun(@isempty,fnames);
clrs(id) = [];
fnames(id) = [];

% Now check that we still have some:
if isempty(clrs)
    errordlg('You need to enter filenames for at least one of the traces, or cancel.',...
        'No file names specified')
    return
end

% Get path to save to:
pth = setPath();
if isequal(pth,0)   % If user cancelled
    return
end

% Ensure path contains the trailing filesep
if ~isequal(pth(end),filesep)
    pth(end+1) = filesep;
end

% Inject path:
fnames = cellsmash(pth,fnames);
fnames = cellsmash(fnames,'.mat');

% Store info in appdata of 0:
ad.colorcell = clrs;
ad.pathcell = fnames;
setappdata(0,'ExportDialogAppData__',ad)
delete(gcbf);



