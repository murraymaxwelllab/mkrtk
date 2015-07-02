function [handles,ok] = load_session(handles)

ok = false;

% Lock figure:
locker = FigLocker.Lock(handles.figure1);

% Get file from user - seed with current session path
[p,~,~] = fileparts(handles.sessionPath);
[filename, pathname] = uigetfile(...
    {'*.mat','MAT-files (*.mat)'},'Load session',p);

if isequal(filename,0)
    locker.unlock
    return
end

% Determine the invoking file:
ds = dbstack(1);
[~,caller,~] = fileparts(ds(1).file);

% Load the session, specifying the caller (and hence fields that should be
% loaded):
[handles,ok] = Session.load(handles,[pathname filename],caller);

% Check for success:
if ok
    % Update guidata:
    guidata(handles.figure1,handles)
    
    % Name the figure with the loaded mat file
    nameFig(handles.figure1)
end

locker.unlock;

