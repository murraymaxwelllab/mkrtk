function varargout = Segmentation(varargin)
% SEGMENTATION MATLAB code for Segmentation.fig
%      SEGMENTATION, by itself, creates a new SEGMENTATION or raises the existing
%      singleton*.
%
%      H = SEGMENTATION returns the handle to a new SEGMENTATION or the handle to
%      the existing singleton*.
%
%      SEGMENTATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEGMENTATION.M with the given input arguments.
%
%      SEGMENTATION('Property','Value',...) creates a new SEGMENTATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Segmentation_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Segmentation_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Segmentation

% Last Modified by GUIDE v2.5 24-Oct-2015 16:21:24

% ------------------------------------------------------------------------
% NOTES 
%
% BUGS
%   - 
%
% NEW FEATURES TO ADD:
%   - 
%   
% CHANGES / IMPROVEMENTS:
%   - Importing old ROIs which don't have a "phase" field?
%   - Improve workflow for exporting traces
%       > New gui
%           - Option to export as packaged file or exploded files
% 
% ------------------------------------------------------------------------

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Segmentation_OpeningFcn, ...
                   'gui_OutputFcn',  @Segmentation_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%=========================================================================
%               ESSENTIAL GUI FUNCTIONS
%=========================================================================
% --- Executes just before Segmentation is made visible.
function Segmentation_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Segmentation (see VARARGIN)

% Prevent re-launch:
if isfield(handles,'initialized')
    return
else
    handles.initialized = 1;
end

% Mode configuration for helper functions:
modestr = '2d';

% Include some important functions:
configurePaths(modestr);            % Add all necessary paths
check_dependencies(modestr);        % Check all external dependencies exist

% Disble work in progress:
if ~isdeveloper
    set(handles.Menu_Dev,'Enable','off')
end

% Choose default command line output for Segmentation
handles.output = hObject;

% Shorthand:
hf = handles.figure1;
ha = handles.axes1;

% Configure context menus:
handles.htmenu   = createContextMenu('roi');          % ROI context menu

% Axis
box(ha,'off');
set(ha,...
    'Visible','off',...
    'Units','normalized',...
    'Color','none',...
    'Position',[0 0 1 1]);

% Figure
set(hf,'WindowButtonMotionFcn',@infoWBMF)
set(hf,'WindowScrollWheelFcn',@swf2d)
set(hf,'WindowKeyPressFcn',@kpf2d)
set(hf,'WindowKeyReleaseFcn',@krf2d)
swf2d(hf,[])
set(hf,'Color',[0 0 0])

% 2D Annotations:
handles.AnnotationCanvas = annotationManager(...  %\_ Create a canvas (axes)
    ha,'NewCanvas','AnnotationCanvas2D');         %/
handles.StackAnnotation = annotationManager(...
    handles.AnnotationCanvas,'StackAnnotation','SouthWest');
handles.ImageAnnotation = annotationManager(...
    handles.AnnotationCanvas,'ImageAnnotation','NorthWest');

% Set up toolbars:
handles = initTools(handles,modestr);

% Initialise our session variables:
handles = Session.new(handles);

% Position gui nicely:
movegui(handles.figure1,'north')

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = Segmentation_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Position annotations:
annotationManager(handles.StackAnnotation);
annotationManager(handles.ImageAnnotation);




%=========================================================================
%               GUI USER FUNCTIONS
%=========================================================================


% ------------------------------------------------------------------------
function Menu_File_Callback(hObject, eventdata, handles)
% hObject    handle to Menu_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% ------------------------------------------------------------------------
function MI_OpenSession_Callback(hObject, eventdata, handles)
% hObject    handle to MI_OpenSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[handles,ok] = load_session(handles);

% Configure/reset the view
if ok
    configureView2(handles)
end


% ------------------------------------------------------------------------
function MI_SaveSession_Callback(hObject, eventdata, handles)
% hObject    handle to MI_SaveSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

save_session(hObject,handles);


% --------------------------------------------------------------------
function MI_SaveSessionAs_Callback(hObject, eventdata, handles)
% hObject    handle to MI_SaveSessionAs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

save_session(hObject,handles);


% --------------------------------------------------------------------
function MI_NewSession_Callback(hObject, eventdata, handles)
% hObject    handle to MI_NewSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = Session.reset('soft',handles);
if ~isempty(handles)
    configureView2(handles)
end

% ------------------------------------------------------------------------
function MI_Quit_Callback(hObject, eventdata, handles)
% hObject    handle to MI_Quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1)


% ------------------------------------------------------------------------
function MI_LoadDicom_Callback(hObject, eventdata, handles)
% hObject    handle to MI_LoadDicom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to see if we should erase traces when loading new Images:
if ~isempty(handles.traces)
    button = warncanceldlg('This will erase all the current traces.  Are you sure?','Erase Traces');
    if ~isequal(button,'Ok')
        % User wants to quit
        return
    else
        % Erase traces:
        handles.traces = roi([]);
    end
end    

% We don't want to over-write an old session with this new data, so clear
% the path:
handles.sessionPath = '';   
guidata(hObject,handles)
nameFig(handles.figure1)

% Now launch the gui & add update listener:
pthseed = handles.Images.pth;
hf = LoadDicomUtil({pthseed},'-detach');
addlistener(hf,'HitTest','PreSet',@dicomLoadUpdater);


% ------------------------------------------------------------------------
function Menu_Dev_Callback(hObject, eventdata, handles)
% hObject    handle to Menu_Dev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% ------------------------------------------------------------------------
function Menu_ROI_Callback(hObject, eventdata, handles)
% hObject    handle to Menu_ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% ------------------------------------------------------------------------
function MenuSegmentation_Callback(hObject, eventdata, handles)
% hObject    handle to MenuSegmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

toggleCheck(hObject)

hslices = get(handles.DICOM.hg,'Children');

if ischecked(hObject)
    % Add the callbacks
    set(hslices,'ButtonDownFcn',@sliceBDF);
    set(hslices,'HitTest','on')
else
    % Remove the callbacks
    set(hslices,'ButtonDownFcn',[])
end


% ------------------------------------------------------------------------
function MI_ROIcolour_Callback(hObject, eventdata, handles)
% This function is called by all of the colour menu items, so hObject is
% the handle of whichever menu item is clicked.

% Get handles:
hp = get(hObject,'Parent');
hclrs = get(hp,'Children');

% Set appropriate 'Checked' states:
checked = cell(numel(hclrs),1);
checked(:) = {'off'};
checked(hObject == hclrs) = {'on'};
set(hclrs,{'Checked'},checked)



% --------------------------------------------------------------------
function MI_RemapRoiColour_Callback(hObject, eventdata, handles)
% hObject    handle to MI_RemapRoiColour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

traces_old = handles.traces;
oldClrSet = unique({traces_old.Color})';


newClrSet = remapRoiColorsDialog(oldClrSet);

if isempty(newClrSet)
    return
end


traces_new = traces_old;  % starting point
all_old_clrs = {traces_old.Color};

for j = 1:numel(newClrSet)
    
    % Only need to map those that are specified; skip others
    if isempty( newClrSet{j} )
        continue
    end
    
    % Find all with the old colour
    tf = strcmp(all_old_clrs, oldClrSet{j});
    
    [traces_new(tf).Color] = deal(newClrSet{j});
end


% Push back to handles
handles.traces = traces_new;
guidata(handles.figure1,handles);

% Update
updateSlice(handles)



% --------------------------------------------------------------------
function MI_Navigator_Callback(hObject, eventdata, handles)
% hObject    handle to MI_Navigator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[ns,np] = handles.Images.stacksize();

% Launch the GUI
hf = Navigator(ns,np,handles.traces);
%set(hf,'WindowStyle','modal');  % Optional

% Add listener - When window closes, HitTest gets turned off, which
% triggers this listener, which does all the data & graphics updates for
% the loading of models.
%addlistener(hf,'HitTest','PreSet',@navigatorUpdater);

% ------------------------------------------------------------------------
function MI_ImportROIs_Callback(hObject, eventdata, handles)
% hObject    handle to MI_ImportROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fname,pthname] = uigetfile({'*.mat','Matlab MAT files (*.mat)'},...
    'Load traces',handles.userPath,'MultiSelect','off');

if isequal(pthname,0)
    return
end

button = 'Erase';
if ~isempty(handles.traces)
    button = questdlg('Do you want to ERASE the existing traces or KEEP them when loading the new traces?',...
        'Erase existing traces?','Erase','Keep','Cancel','Cancel');
end

% Handle the 'Cancel' case:
if strcmpi(button,'Cancel')
    return
end

[rois,msg] = roi.loadfromfile([pthname fname]);

% If any old versions were loaded that don't have patient data, load them
if any(~rois.haspatientcs)
    rois = rois.addpatientcs(handles.Images.info);              % Add the data
    msg(~cellfun(@isempty,strfind(msg,'PixelSpacing'))) = [];   % Drop the message
end
    

for j = 1:numel(msg)
    warndlg(msg{j},'Load warning','modal')
end

% Put into handles:
switch button        
    case 'Erase'
        % Do nothing special
        
    otherwise
        % Include current traces:
        rois = [handles.traces rois];
        
end


% Place in handles:
handles.traces = rois;

% Refresh traces:
updateSlice(handles);

% Update handles:
handles.userPath = pthname;
guidata(hObject,handles)


% ------------------------------------------------------------------------
function MI_ExportROIs_Callback(hObject, eventdata, handles)
% hObject    handle to MI_ExportROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Export RIOs by colour

if isempty(handles.traces)
    return
end
clrs = unique({handles.traces.Color});
[colorstrings, pathstrings] = exportRoiDialog(clrs);

% Special cases:
if isempty(colorstrings)    % If user cancelled:
    return                  % exit
elseif ischar(colorstrings)     % Only one item in list
    colorstrings = {colorstrings};
end

% Save ROIs according to color
n = numel(colorstrings);
all_clrs = {handles.traces.Color};
for j = 1:n
    % Select ROIs of single color:
    inds = strcmpi(all_clrs,colorstrings{j});
    ROI = handles.traces(inds); %#ok<NASGU>
    
    
    % Save - check if file exists:
    pthj = pathstrings{j};
    if exist(pthj,'file') == 2
        [~,f,e] = fileparts(pthj);
        qstr = ['The file: "' [f e] '" exists. Do you want to overwrite?'];
        choice = questdlg(qstr,'Overwrite?','Yes','No','No');
        
        % Anything other than "Yes" will skip the save
        if ~isequal(choice,'Yes')
            continue
        end
    end
    
    save(pthj,'ROI');
end

% Update path:
handles.userPath = fileparts(pathstrings{end}); 
guidata(hObject,handles)


% --------------------------------------------------------------------
function MI_PreviewROIs_Callback(hObject, eventdata, handles)
% hObject    handle to MI_PreviewROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

previewROIs3d(handles)


% ------------------------------------------------------------------------
function MI_DicomHeader_Callback(hObject, eventdata, handles)
% hObject    handle to MI_DicomHeader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.Images.X)
    return
end

% Display the file metadata:
s = current('slice',handles.axes1);
p = current('phase',handles.axes1);
dinfo = handles.Images.info(s,p);
assignin('base','dinfo',dinfo)
disp(dinfo)
openvar('dinfo');


% --------------------------------------------------------------------
function MI_PublishHandles_Callback(hObject, eventdata, handles)
% hObject    handle to MI_PublishHandles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

assignin('base','handles',handles)
evalin('base','handles')


% --------------------------------------------------------------------
function MI_EnableCursor_Callback(hObject, eventdata, handles)
% hObject    handle to MI_EnableCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

show_hide_edit_cursor(hObject)

% --------------------------------------------------------------------
function MI_Test_Callback(hObject, eventdata, handles)
% hObject    handle to MI_Test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Empty menu item available for use in testing new functions






%=========================================================================
%               TOOLBAR CALLBACKS & FUNCTIONS
%=========================================================================

  

% ------------------------------------------------------------------------
function TraceTool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to TraceButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Can't use the pen when there aren't any images:
if isempty(handles.Images.X)
    set(hObject,'State','off')
    return
end

% Switch pointer & Window Button Down Fcn on button presses:
if isdown(hObject)
    set(handles.figure1,'pointer','crosshair')                  
    set(handles.figure1,'WindowButtonDownFcn',  @traceWBDF);    
else
    set(handles.figure1,'pointer','arrow')
    set(handles.figure1,'WindowButtonDownFcn',  [])
end


% ------------------------------------------------------------------------
function DeleteTraceTool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to DeleteTraceButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check if traces exist:
if numel(handles.traces) == 0
    return
end

% Construct a questdlg with three options
choice = questdlg('Are you sure you sure you want to delete ALL the ROIs?', ...
 'Clear ROIs?', ...
 'Yes','No','No');

% Handle the response:
switch choice
    case 'Yes'
        handles.traces = roi([]);       % Clear all rois
        guidata(hObject,handles)        % Update data
        swf2d(handles.figure1,[])       % refresh display
        
    case 'No'
        % do nothing
end


% ------------------------------------------------------------------------
function AutoBcTool_ClickedCallback(hObject, eventdata, handles)

if isempty(handles.Images.CLim)
    set(hObject,'State','off')
    return
end

clim = imlimits(handles.Images.X,0.999);
set(handles.axes1,'CLim',clim)
% Use toggle button with pause so user gets some feedback on button press:
pause(0.05)
set(hObject,'State','off')


% ------------------------------------------------------------------------
function CalibrateImageTool_ClickedCallback(hObject, eventdata, handles)

% Retrieve data:
ax = handles.axes1;

% This creates an interactive gui and returns immediately.  That gui sends
% changes back to handles as required.
manual_image_calibration(ax,handles.Images.s)



% ------------------------------------------------------------------------
function clim = imlimits(X,frac)
% See the code of STRETCHLIM.  It returns the limits in percentage of the
% data range, so we need to multiply this by the number of bins to return
% the actual intensity value
if isa(X,'uint8')
	nbins = 256;
else
    nbins = 65536;
end
lowhigh = stretchlim(X(:),[0 frac]); % discard 0.01% of outliers;
clim = lowhigh*nbins;
clim = clim(:)';


% ------------------------------------------------------------------------
function imcontrastWorkaround(opt,ha)
% This function makes a workaround so we don't see the silly question
% dialog from imcontrast telling us that the display range is not correct.
% To circumvent it, do two calls to this function.  On the first call
% ('prepare') we check to see if the there is going to be a problem with
% the limits, and if so, we adjust CLim to be compliant.  Then on the
% second call, we revert CLim to its original value.
% 
% This solution is not ideal because it may cause the image to flash with
% a different intensity, but it's a work-around for the moment.

persistent clim

switch opt
    case 'prepare'
        % Store the information:
        him = findobj(ha,'type','image');
        I   = get(him,'CData');
        clim = get(ha,'CLim');
        % Set the temporary value, if necessary
        maxI = max(I(:));
        if maxI < max(get(ha,'CLim'));
            set(ha,'CLim', [clim(1), maxI]);
        end
        
    case 'revert'
        % Revert to original value:
        set(ha,'CLim',clim);
end
        

% ------------------------------------------------------------------------
function ResetBcTool_ClickedCallback(hObject, eventdata, handles)

if ~isempty(handles.Images.CLim)
    % Revert to default limits:
    set(handles.axes1,'CLim',handles.Images.CLim)
    guidata(hObject,handles)
end

% Use toggle button with pause so user gets some feedback on button press:
pause(0.05)
set(hObject,'State','off')


% ------------------------------------------------------------------------
function AdjustBcTool_ClickedCallback(hObject, eventdata, handles)

% Only allow the tool to work if images are loaded:
if isempty(handles.Images.CLim)
    set(hObject,'State','off')
    return
end


% IMCONTRAST creates a level window, which interacts with the tool.  On
% closing the window, the interactive controls are disposed of.  We handle
% the tool with this window and store its handles in the UserData of the
% current object, AdjustBcTool

switch get(hObject,'State')
    case 'on'   % Tool pressed - activate imcontrast.  
        % Need to ensure that other tools aren't active:
        htt = findall(handles.toolset,'type','uitoggletool');
        set(htt(htt~=hObject),'State','off')
        % Then we need to sort a few things out in order to use Mathworks'
        % imcontrast tool.
        imcontrastWorkaround('prepare',handles.axes1)
        hict = imcontrast(handles.figure1);
        set(hict,'Visible','off')       % Don't want to see the level window
        imcontrastWorkaround('revert',handles.axes1)
        % Special case if there was a problem:
        if isempty(hict)
            set(hObject,'State','off')
            return
        end
        
        set(hObject,'UserData',hict)    % Store the handle
        
        
        % Now make it so the function is escaped whenever the tool is
        % de-activated:
        set(hict,'UserData',hObject)
        set(hict,'CloseRequestFcn',...
            'set( get(gcf,''UserData''), ''State'',''off''),closereq');
        
    case 'off'
        try %#ok<TRYNC>
            delete( get(hObject,'UserData') );  % Handle to imcontrast window
        end
        set(hObject,'UserData',[])  % Clear the handle
        
end
guidata(hObject,handles)




%=========================================================================
%               CUSTOM HELPER FUNCTIONS
%=========================================================================



% ------------------------------------------------------------------------
function [handles,guiOutput] = getGuiOutput(event)
%GETGUIOUTPUT Get output from GUI which is closing, and handles to main GUI

% Get the handle to the main GUI (Segmentation)
%   (This function will not receive handles as an input, neither will the
%   main invoking function be in the debug stack because it is invoked by
%   the closing funcitons of the GUI which is closing, so we have to do it
%   another way):  
hmain = findobj('-regexp','Filename',[mfilename '.fig']);   % Get the fig associated with this file
handles = guidata(hmain);                                   % Get it's guidata

% Now get the outputs of the assisting GUI, which has actually invoked this
% function:
loaderhdls = guidata(event.AffectedObject);
guiOutput = loaderhdls.output;


% ------------------------------------------------------------------------
function dicomLoadUpdater(~,event)
%DICOMLOADUPDATER Listener callback for getting output from LOADDICOMUTIL
%
% This function is a listener callback which gets invoked during the window
% closing process of LOADDICOMUTIL.  The listener needs to be added by any
% function which invokes LOADDICOMUTIL and this function gets the output of
% that GUI and saves/updates all the info in the handles of Segmentation (on
% successful close)

% Get handles of main GUI & output from closing GUI
[handles,flist] = getGuiOutput(event);

if isempty(flist)                       % No files selected
    return
end

% Load images into ImageStack object:
handles.Images = ImageStack.LoadFiles(flist);

% Remove all displayed traces
updateSlice(handles,[],[]); 

% Update user path:
handles.userPath = handles.Images.pth;

% Update guidata
guidata(handles.figure1,handles)

% Now that the guidata is updated, configure the view:
configureView2(handles);
set(handles.axes1,'CLim',handles.Images.CLim)



% ------------------------------------------------------------------------
function updateDisplayStack(hinvoker,hgstack,stack,zvals)

% Reshape
zvals = zvals(:);

% Get handles to each slice 'surface' element
hslices = findobj(hgstack,'type','surface','tag','slice');

% Get the currently displayed z-vals
zcurrent = cell2mat(get(hslices,'UserData'));

% Check that nothing funky has happened:
assert(isequal(sort(zcurrent),sort(zvals)),'Cannot change the slices when using this function')

% Now update the texture mapping:
for j = 1:numel(zvals)
    sid = (zvals(j)==zcurrent);
    % So now: zvals(j) == zcurrent(sid)
    set(hslices(sid),'CData',stack(:,:,j)) 
end

