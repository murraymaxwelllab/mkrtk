function [clrsOut] = remapRoiColorsDialog(clrsIn)

n = numel(clrsIn);

clrOpts = ColourSpec;  
clrOpts = clrOpts(:,1);         % select only long names
clrOpts = [{''};clrOpts(:)];    % Add empty selection as first item

% Get invoking figure & its position:
hfi = gcbf;
hfi_psn = get(hfi,'Position');

% Now build the dialog
w = 260;
h = 330;  % This will be adjusted later

hf = figure('Name','Recolor ROIs',...
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


% Selection popups
popupw = btnw;
popuph = fontsize*1.5;

% Create Text for the different colours:
ht = zeros(1,n);
hp = zeros(1,n);

tw = 7*fontsize;  % text width - 7 letters (magenta), convert to pix
ew = 130;  % edit width
x1 = xpad*2;
x2 = x1+tw+xpad;

th = fontsize*1.3*1.5;  % text height - font ht convert to pix, pad
eh = th;  % edit height

y = y + ypad*3;

for j = 1:n
    y = y+ypad;
    ht(j) = uicontrol(hf,'style','text',...
        'string',clrsIn{j},...
        'ForegroundColor',clrsIn{j},...
        'BackgroundColor',[0 0 0],...
        'FontWeight','bold',...
        'FontSize',fontsize,...
        'Tag',['_text_' clrsIn{j}],... % eg, _text_magenta
        'position',[x1 y tw th]);
    hp(j) = uicontrol(hf,'style','popup','string',clrOpts,...
        'FontSize',fontsize,...
        'Tag',['_popup_' clrsIn{j}],... % eg, _edit_magenta
        'position',[x2, y, ew, eh]);
    y = y+th;
    uistack(hp(j),'bottom')
end


% Now make column headers (plain text):
%y = y+ypad;
uicontrol(hf,'style','text','string','ROIs:',...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'FontWeight','bold',...
    'HorizontalAlignment','Left',...
    'position',[x1,y,tw,th]);

uicontrol(hf,'style','text','string','New Color:',...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'FontWeight','bold',...
    'HorizontalAlignment','Left',...
    'position',[x2,y,ew,th]);
y = y+ypad*3;


% Add gui header text:
hw = w-2*xpad;
hti2 = uicontrol(hf,'style','text',...
    'string',{'Select new colors for ROIs:'; 'All ROIs of the color will be re-mapped.  Leave blank to keep unchanged.'},...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'HorizontalAlignment','Left',...
    'position',[xpad,y,hw,th*2]);  
y = y + th*2;
hti1 = uicontrol(hf,'style','text',...
    'string','Recolor ROIs',...
    'BackgroundColor',bkgclr,...
    'FontSize',fontsize,...
    'FontWeight','bold',...
    'HorizontalAlignment','Left',...
    'position',[xpad,y,hw,th]);

% Set position of the gui to the upper-right corner of the main gui:
psn = get(hf,'Position');
x0 = hfi_psn(1) + hfi_psn(3) - w;
y0 = hfi_psn(2) + hfi_psn(4) - h;
psn(1:2) = [x0 y0];
set(hf,'Position',psn)

% Cancel with escape or button press:
set([hf, hok, hcancel], 'KeyPressFcn', {@doKeypress, hf});


% Set active uicontrol
uicontrol(hp(end))

% Make visible and wait for user response
set(hf,'Visible','on')
uiwait(hf);



% Set outputs:

if isappdata(0,'RecolorDialogAppData__')
    % write to outputs
    ad = getappdata(0,'RecolorDialogAppData__');
    clrMap = ad.clrMap;
    % remove from 0:
    rmappdata(0,'RecolorDialogAppData__')
    
    % Now just sort outputs the same as inputs
    
    % Get forward sort order of clrsIn
    [~,idx_in] = sort_nat(clrsIn);
    
    % Ensure map is sorted alphabetically
    [~,idx_out] = sort_nat(clrMap(:,1));
    clrMapS = clrMap(idx_out,:);
    
    % Apply reverse sort from clrsIn to sorted clrsOut to get correct
    % mapping:
    clrsOut = clrMapS( (idx_in), 2 );
    clrsOut = reshape( clrsOut, size(clrsIn) );
    
else
    clrsOut = {};
end

return



%% figure, OK and Cancel KeyPressFcn
function doKeypress(src, evd, fig) %#ok
switch evd.Key
 case 'escape'
  doCancel([],[]);
end


%% Cancel callback
function doCancel(cancel_btn, evd) %#ok

% Ensure no residual appdata:
if isappdata(0,'RecolorDialogAppData__')
    rmappdata(0,'RecolorDialogAppData__');
end
delete(gcbf);


function hobjs = sortObjectsByTag(hobjs)
tags = get(hobjs,'Tag');
[~,idx] = sort_nat(tags);
hobjs = hobjs(idx);


%% OK callback
function doOK(ok_btn, evd) %#ok

fig = gcbf;

% Find all the text boxes & sort in order
htexts = findobj(fig,'-regexp','Tag','_text_');
htexts = sortObjectsByTag(htexts);

% Find all the popup boxes & sort in order
hpopups = findobj(fig,'-regexp','Tag','_popup_');
hpopups = sortObjectsByTag(hpopups);

% Match the two & pass back a map
clrsIn = get(htexts,'String');
for j = numel(hpopups):-1:1
    clrList = get(hpopups(j),'String');
    clrsOut{j,1} = clrList{ get(hpopups(j),'Value') };
end
clrMap = [clrsIn, clrsOut];


% Store info in appdata of 0:
ad.clrMap = clrMap;
setappdata(0,'RecolorDialogAppData__',ad)
delete(gcbf);



