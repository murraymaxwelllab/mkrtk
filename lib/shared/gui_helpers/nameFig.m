function nameFig(fig)
%NAMEFIG(fig)
%
% Set the figure name of GUI and append session name if available in handles
% 
% Functions on Segmentation.fig and Registration.fig

handles = guidata(fig);

if isempty(handles) 
    return 
end

% Base name:  'Segmentation' or 'Registration'
[~,n,~] = fileparts( get(handles.figure1,'filename') );

% Get session name to append:
f = [];
if isfield(handles,'sessionPath')
    [~,f,ex] = fileparts(handles.sessionPath);
    f = [f ex];
end

% Append session file name to figure name:
if ~isempty(f)
    n = [n ': ' f];
end

% Set figure name:
set(handles.figure1,'Name',n)
