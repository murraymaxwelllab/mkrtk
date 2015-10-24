function studyname = getStudyName(pth)
%GETSTUDYNAME Get the study name from the filepath.  
%
% Input should be either:
%   a) a path containing a DICOM folder, or 
%   b) a path to a file used in registration
%
% Otherwise a random name will be made up from the path
%
% Trailing file separator can either be present or not

studyname = new_method(gcbf);

if isempty(studyname)
    studyname = old_method(pth);
end

% Insure it's a variable safe string
studyname = variablize(studyname);

assert(~isempty(studyname),...
    'GETSTUDYNAME could not create a study name from the path')


%--------- New way of finding / contriving a study name ----
function str = new_method(fig)

% Use the figure name / title
name = get(fig,'Name');


exprs = {'MGR_\d*','mgr_\d*','MGR \d*','mgr \d*'};

str = '';

% Consecutively look for one of the above expressions until one is found,
% or the list is exhausted
for j = 1:numel(exprs)
    
    c = regexp(name,exprs{j},'match');
    
    if ~isempty(c)
        str = c{1};
        return
    end
end




%--------- Old way of finding / contriving a study name ----
function str = old_method(pth)

c = path2cell(pth);


% Case sensitive: 'DICOM'
if any( strcmp(c,'DICOM') )
    idx = find( strcmp(c,'DICOM') );
    
    % Case insensitive: 'dicom'
elseif any( strcmpi(c,'dicom') )
    idx = find( strcmpi(c,'dicom') );
    
    % Case insensitive 'mgr'
elseif any( strcmpi(c,'mgr') )
    idx = find( strcmpi(c,'dicom') );
   
    % Case insensitive 'phantom'
elseif any( strcmpi(c,'phantom') )
    idx = find( strcmpi(c,'phantom') );
    
    % Case insensitive 'pilot'
elseif any( strcmpi(c,'pilot') )
    idx = find( strcmpi(c,'pilot') );
    
else
    
    % All known searches failed,
    %  return up to 2 levels of parent directories:
    n = 2;
    if numel(c) >= (n+1)
        idx = numel(c)-n:numel(c)-1;
    else
        idx = 1:numel(c)-1;
    end
    
end

str = c(idx);