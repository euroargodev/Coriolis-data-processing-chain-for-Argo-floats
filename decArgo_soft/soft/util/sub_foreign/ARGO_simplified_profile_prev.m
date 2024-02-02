function synthfull=ARGO_simplified_profile(varargin)
%
%
% create simplified Biogeochemical-Argo single cycle file from DAC c- and
% b- files with synthetic pressure axis
%
% - synthetic axis constructed from data
% - include CONFIG_<short_sensor_name>VerticalPressureOffset_dbar from
% WMO_meta.nc if present in meta file
% - obey n_prof priorities (needs WMO_meta.nc)
% - single gaps in series of 5 filled with interpolated data
% - interleave non-BGC level T/S profile for full T/S resolution
%
% inputs: - 'bfilepath', 'cfilepath' (one of them is mandatory)
%         - 'metafilepath' (optional)
%         - 'bgcFloatFlag' (optional; default true): by setting to zero,
%            all parts on synthetic axis construction can be skipped in
%            case the float is core-only and N_PROFs of core data should be
%            combined anyway
% 
% usage: 
% out=ARGO_simplified_profile('bfilepath','BR6901485_050.nc');
% out=ARGO_simplified_profile('bfilepath','6901485/profiles/BR6901485_050.nc');
% out=ARGO_simplified_profile('bfilepath','argo/coriolis/6901485/profiles/BR6901485_050.nc','cfilepath','argo/coriolis/6901485/profiles/R6901485_050.nc','metafilepath','argo/coriolis/6901485/6901485_meta.nc');
%
%
% Henry Bittig, LOV/IOW
% 18.01.2018
% 05.03.2018, updated
% 19.04.2018, use b- and c- files instead of m-files
% 15.06.2018, modify input to name/value pairs
% 27.06.2018, make approach more robust: Union of PARAMETER and STATION_PARAMETERS, 
%             only apply vertical offsets for sensors with data, be tolerant towards 
%             older, pre-v3.1 meta files
% 29.06.2018, separate PARAM and PARAM_ADJUSTED overlap determination, using no bad PRES_QC
% 11.02.2019, following ADMT in San Diego: include HR T/S profile at end;
%             rework code for R2018b; recognize netcdf dim order
% 18.02.2019, streamlining of code
% 30.06.2020, create s-profile also in absence of BGC-levels or in the
%             absence of either core- or b-profile, gap data do not get a
%             QC of '8' if either bounding point has QC '3' or '4', PRES/
%             PRES_ADJUSTED do not get a QC of '8' either, add file name to
%             all info messages, correct treatment of levels with QC '4' in
%             adjusted fields, add bgcFloatFlag as optional input
% 01.04.2022, gap data do not get a QC of '8' if either bounding point has
%             QC '0', PRES/PRES_ADJUSTED do not get a QC of '8' either
% 09.06.2022, add Coriolis csv export accessories to git-controlled local version
% 09.06.2022, remove ic parameters TEMP_CNDC, MTIME, NB_sample_... and
%             statistical parameters ..._MED, ..._STD from parameter selection
% 01.12.2023, fix to keep vertical pressure offset on PRES for profiles
%             with only one synthetic pressure level

% output CSV file information
global g_cocs_fidCsvFile;
global g_cocs_dacName;
global g_cocs_floatWmoStr;
global g_cocs_cycleNumStr;
global g_cocs_cycleDir;
global g_cocs_inputFile;

if nargin<1 || isempty(varargin)
    varargin{1}='bfilepath';varargin{2}='\argo\dac\coriolis\6901485\profiles\BR6901485_049.nc';
end

includeTSflag=0;
addTSeverywhere=1;
verbose=1;
addoffsetflag=1;  % add pressure sensor vertical pressure offset to PRES

fieldsuffixvarname={'PRES';'BBP[0-9]+';'BISULFIDE';'CDOM';'CHLA';'CP[0-9]+';'DOWN_IRRADIANCE[0-9]+';'DOWNWELLING_PAR';'DOXY';'NITRATE';'PH_IN_SITU_TOTAL';'TURBIDITY';'UP_RADIANCE[0-9]+';};
%% get file names
bfilepath='';cfilepath='';metafilepath='';
bgcfloatflag=true(1);
for i=1:floor(length(varargin)/2)
    switch varargin{2*i-1}
        case 'bfilepath'
            bfilepath=varargin{2*i};
        case 'cfilepath'
            cfilepath=varargin{2*i};
        case 'metafilepath'
            metafilepath=varargin{2*i};
        case 'bgcFloatFlag'
            bgcfloatflag=varargin{2*i};
    end
end
if isempty(cfilepath) && isempty(bfilepath) % either profile file must be present
    if verbose>-2, disp(['S-PROF_ERROR: Either core-profile or b-profile path must be specified. Abort..']), end
    synthfull=[];
    return
end
if isempty(cfilepath)
% figure out name of the corresponding core file
[basepath,fname]=fileparts(bfilepath);
fnamec=dir([basepath filesep 'R' fname(3:end) '.nc']);
if isempty(fnamec), fnamec=dir([basepath filesep 'D' fname(3:end) '.nc']); end
if ~isempty(fnamec), cfilepath=[basepath filesep fnamec.name]; end
clear fnamec fname basepath
end
if isempty(bfilepath) && bgcfloatflag
% figure out name of the corresponding bgc file
[basepath,fname]=fileparts(cfilepath);
fnameb=dir([basepath filesep 'BR' fname(2:end) '.nc']);
if isempty(fnameb), fnameb=dir([basepath filesep 'BD' fname(2:end) '.nc']); end
if ~isempty(fnameb), bfilepath=[basepath filesep fnameb.name]; end
clear fnameb fname basepath
end
% keep b- and core-file names for error/warning/info reporting
[~,bfilestr]=fileparts(bfilepath);
[~,cfilestr]=fileparts(cfilepath);

%% load b-file netcdf into convenient structure
if ~isempty(bfilepath) % b-file exists
    S=lov_netcdf_pickprod(bfilepath);
    % remove everything but PRES and b-parameters
    fnames=fieldnames(S);
    fnamesind=true(size(fnames));
    for k=1:length(fieldsuffixvarname)
        fnamesind(~cellfun(@isempty,regexp(fnames,['^' fieldsuffixvarname{k} '$*'])))=0; % normal variable
        fnamesind(~cellfun(@isempty,regexp(fnames,['^' fieldsuffixvarname{k} '[0-9]+$*'])))=0; % multiple variable
        fnamesind(~cellfun(@isempty,regexp(fnames,['^' fieldsuffixvarname{k} '_[0-9]+$*'])))=0; % multiple variable with underscore
    end
    fnamesind(ismember(fnames,'PARAMETER'))=0; % keep PARAMETER field, too: Used for N_PROF identification
    fnamesind(ismember(fnames,'STATION_PARAMETERS'))=0; % keep STATION_PARAMETERS field, too: Used for backup N_PROF identification
    if isempty(cfilepath) % c-file does not exists
        %fnamesind(:)=0; % keep all other meta fields, too; Can't be copied from core file...
        fnamesind(ismember(fnames,'PLATFORM_NUMBER'))=0; % keep WMO
    end
    S=rmfield(S,fnames(fnamesind));
else % b-file does not exist
    S.empty=[];
end
%% load c-file netcdf and add core data into convenient structure
if ~isempty(cfilepath) % c-file exists
    C=lov_netcdf_pickprod(cfilepath); % load core file
    fnamec=setdiff(fieldnames(C),fieldnames(S)); % find core parameter names
    for i=1:length(fnamec), S.(fnamec{i})=C.(fnamec{i}); end % copy core data to bio data
else
    if (verbose>-2)
       disp(['S-PROF_WARNING: File ' bfilestr '.nc: No corresponding core file found. Create empty s-profile.'])
       
       % CSV output
       msgType = 'warning_s-prof';
       message = 'No corresponding core file found. Create empty s-profile.';
       [~, fileName, fileExt] = fileparts(bfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    S.PRES_QC.value=ones(size(S.PRES.value))*4; % mimic core PRES_QC: all bad, because no info
end
if isfield(S,'empty') && bgcfloatflag
    if (verbose>-2)
       disp(['S-PROF_WARNING: File ' cfilestr '.nc: No corresponding bio file found. Use only the core file.'])
       
       % CSV output
       msgType = 'warning_s-prof';
       message = 'No corresponding bio file found. Use only the core file.';
       [~, fileName, fileExt] = fileparts(cfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    S=rmfield(S,'empty');
end

%% make sure first dimension is size of field, i.e., STRING16/STRING64 for
% PARAMETER and STATION_PARAMETER in c- and b-file
% (e.g. CS 1901348: 2nd dimension)
%% core file
% dimnames must be fliplr of user manual description:
% 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING16);'
if ~isempty(cfilepath) % core file exists
indstr={'STRING16';'N_PARAM';'N_CALIB';'N_PROF'};
indperm=ones(ndims(C.PARAMETER.value),1)*NaN; 
try
    for i=1:length(indperm), indperm(i)=find(strcmpi(C.PARAMETER.dimname,indstr{i})); end
catch me
    if (verbose>-1)
       disp(['S-PROF_WARNING: File ' cfilestr '.nc: Could not figure out N_DIMs order of core file PARAMETER field with dimensions: ' strjoin(C.PARAMETER.dimname,', ')])
       
       % CSV output
       msgType = 'warning_s-prof';
       message = sprintf('Could not figure out N_DIMs order of core file PARAMETER field with dimensions: %s.', ...
          strjoin(C.PARAMETER.dimname,' '));
       [~, fileName, fileExt] = fileparts(cfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    indperm=1:ndims(C.PARAMETER.value);
end
C.PARAMETER.value=permute(C.PARAMETER.value,indperm);
C.PARAMETER.dimname=C.PARAMETER.dimname(indperm);
C.PARAMETER.dimvalue=C.PARAMETER.dimvalue(indperm);
% 'char STATION_PARAMETERS(N_PROF, N_PARAM, STRING16);'
indstr={'STRING16';'N_PARAM';'N_PROF'};
indperm=ones(ndims(C.STATION_PARAMETERS.value),1)*NaN; 
try
    for i=1:length(indperm), indperm(i)=find(strcmpi(C.STATION_PARAMETERS.dimname,indstr{i})); end
catch me
    if (verbose>-1)
       disp(['S-PROF_WARNING: File ' cfilestr '.nc: Could not figure out N_DIMs order of core file STATION_PARAMETERS field with dimensions: ' strjoin(C.PARAMETER.dimname,', ')])
    
       % CSV output
       msgType = 'warning_s-prof';
       message = sprintf('Could not figure out N_DIMs order of core file STATION_PARAMETERS field with dimensions: %s.', ...
          strjoin(C.PARAMETER.dimname,' '));
       [~, fileName, fileExt] = fileparts(cfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    indperm=1:ndims(C.STATION_PARAMETERS.value);
end
C.STATION_PARAMETERS.value=permute(C.STATION_PARAMETERS.value,indperm);
C.STATION_PARAMETERS.dimname=C.STATION_PARAMETERS.dimname(indperm);
C.STATION_PARAMETERS.dimvalue=C.STATION_PARAMETERS.dimvalue(indperm);
else % core file does not exist
    C.PARAMETER.value(:,1,1,1)='PRES'; % mimic only-PRES entry for smooth operation of code below
    C.STATION_PARAMETERS.value(:,1,1)=C.PARAMETER.value(:,:,1,:);
end % core file exists
%% b-file
% 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING64);'
if ~isempty(bfilepath) % bio file exists
indstr={'STRING64';'N_PARAM';'N_CALIB';'N_PROF'};
indperm=ones(ndims(S.PARAMETER.value),1)*NaN; 
try
    for i=1:length(indperm), indperm(i)=find(strcmpi(S.PARAMETER.dimname,indstr{i})); end
catch me
    if (verbose>-1)
       disp(['S-PROF_WARNING: File ' bfilestr '.nc: Could not figure out N_DIMs order of bio file PARAMETER field with dimensions: ' strjoin(S.PARAMETER.dimname,', ')])
       
       % CSV output
       msgType = 'warning_s-prof';
       message = sprintf('Could not figure out N_DIMs order of bio file PARAMETER field with dimensions: %s.', ...
          strjoin(S.PARAMETER.dimname,' '));
       [~, fileName, fileExt] = fileparts(bfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    indperm=1:ndims(S.PARAMETER.value);
end
S.PARAMETER.value=permute(S.PARAMETER.value,indperm);
S.PARAMETER.dimname=S.PARAMETER.dimname(indperm);
S.PARAMETER.dimvalue=S.PARAMETER.dimvalue(indperm);
% 'char STATION_PARAMETERS(N_PROF, N_PARAM, STRING64);'
indstr={'STRING64';'N_PARAM';'N_PROF'};
indperm=ones(ndims(S.STATION_PARAMETERS.value),1)*NaN; 
try
    for i=1:length(indperm), indperm(i)=find(strcmpi(S.STATION_PARAMETERS.dimname,indstr{i})); end
catch me
    if (verbose>-1)
       disp(['S-PROF_WARNING: File ' bfilestr '.nc: Could not figure out N_DIMs order of bio file STATION_PARAMETERS field with dimensions: ' strjoin(S.PARAMETER.dimname,', ')])
       
       % CSV output
       msgType = 'warning_s-prof';
       message = sprintf('Could not figure out N_DIMs order of bio file STATION_PARAMETERS field with dimensions: %s.', strjoin(S.PARAMETER.dimname,' '));
       [~, fileName, fileExt] = fileparts(bfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    indperm=1:ndims(S.STATION_PARAMETERS.value);
end
S.STATION_PARAMETERS.value=permute(S.STATION_PARAMETERS.value,indperm);
S.STATION_PARAMETERS.dimname=S.STATION_PARAMETERS.dimname(indperm);
S.STATION_PARAMETERS.dimvalue=S.STATION_PARAMETERS.dimvalue(indperm);
end % bio file exists
clear indperm indstr
%%{
%% merge PARAMETER and STATION_PARAMETERS field for each N_PROF
% (used for variable identification later on)
for i=1:size(C.PARAMETER.value,4) % cycle N_PROFs, use first N_CALIB (necessarily contains all bgc variables)
    % check PARAMETER and STATION_PARAMETERS
    inparams=union(cellstr(squeeze(S.PARAMETER.value(:,:,1,i))'),cellstr(squeeze(S.STATION_PARAMETERS.value(:,:,i))'));
    inparamsC=union(cellstr(squeeze(C.PARAMETER.value(:,:,1,i))'),cellstr(squeeze(C.STATION_PARAMETERS.value(:,:,i))'));
    if isempty(char(setdiff(inparams,{'PRES';'TEMP';'PSAL';''}))) % only PRES/TEMP/PSAL -> core N_PROF: Copy core parameters
        S.PARAMETER.value(1:size(C.PARAMETER.value(:,:,1,i),1),1:size(C.PARAMETER.value(:,:,1,i),2),1:size(C.PARAMETER.value(:,:,1,i),3),i)=C.PARAMETER.value(:,:,1,i);
        %S.PARAMETER_DATA_MODE.value(i,1:size(C.PARAMETER.value(:,:,1,i),2))=C.DATA_MODE.value(i);
    elseif isempty(char(strrep(inparamsC,'PRES',''))) % only PRES & bio -> bio N_PROF: Keep bio parameters
        % nothing to do, PRES & bio already in S.PARAMETER.value
    else % core and bio N_PROF: Join core and bio parameters
        S.PARAMETER.value(1:size(C.PARAMETER.value(:,:,1,i),1),size(S.PARAMETER.value(:,:,1,i),2)+(2:size(C.PARAMETER.value(:,:,1,i),2))-1,1:size(C.PARAMETER.value(:,:,1,i),3),i)=C.PARAMETER.value(:,2:end,1,i);
    end
end
%%}
clear fnamec fnames fnamesind

%% get bgcparams names and N_PROFs
[noNLEVELs,noNPROFs]=size(S.PRES.value);
bgcflag=false(1,noNPROFs);
bgcparams=cell(1,noNPROFs);
% check that there are params different than PRES, TEMP, PSAL in N_PROF
for i=1:noNPROFs
    inparams=union(cellstr(S.PARAMETER.value(:,:,1,i)'),cellstr(S.STATION_PARAMETERS.value(:,:,i)')); % check PARAMETER and STATION_PARAMETERS
    bgcparams{i}=setdiff(inparams,{'PRES';'TEMP';'PSAL';''});
    bgcflag(i)=~isempty(bgcparams{i});
end
% and kick out the i-parameters again / keep only the b-parameters
fnamesind=cellfun(@(x)false(size(x)),bgcparams,'uniform',0);
for k=1:length(fieldsuffixvarname)
    fnamesind=cellfun(@(x,y)y | ~cellfun(@isempty,regexp(x,['^' fieldsuffixvarname{k} '$*'])),bgcparams,fnamesind,'uniform',0); % normal variable
    fnamesind=cellfun(@(x,y)y | ~cellfun(@isempty,regexp(x,['^' fieldsuffixvarname{k} '[0-9]+$*'])),bgcparams,fnamesind,'uniform',0);  % multiple variable
    fnamesind=cellfun(@(x,y)y | ~cellfun(@isempty,regexp(x,['^' fieldsuffixvarname{k} '_[0-9]+$*'])),bgcparams,fnamesind,'uniform',0);  % multiple variable with underscore
end
bgcparams=cellfun(@(x,y)x(y),bgcparams,fnamesind,'uniform',0);
% unique BGC parameters
ubgcparams=unique(cat(1, bgcparams{:}));
% without any intermediate core ic parameter: TEMP_CNDC, MTIME, NB_sample_...,
ikeep=~ismember(ubgcparams,{'TEMP_CNDC';'MTIME'}) & cellfun(@isempty,regexpi(ubgcparams,'^NB_SAMPLE_'));
ubgcparams=ubgcparams(ikeep);
% without any statistical parameter: ..._MED, ..._STD
ikeep=cellfun(@isempty,regexpi(ubgcparams,'_MED$')) & cellfun(@isempty,regexpi(ubgcparams,'_STD$'));
ubgcparams=ubgcparams(ikeep);
clear ikeep
% --> unique BGC b parameters


%% make check: are there bgc-params in the file??
if isempty(ubgcparams) % there are no bgc-params to align
    %if verbose>-1, disp(['S-PROF_INFO: File ' bfilestr '.nc: No b-parameters found in ' bfilepath]), end
    %synthfull=[]; return
    addoffsetflag=0; % then skip vertical offset stuff for BGC sensors, only CTD (TEMP_MED/STD, PSAL_MED/STD, or MTIME)
end


%% there are b-params to align and all infos are there, do the actual work

%% use copy of pressure to work with; rounded to 1/1000 to avoid numerical ..1e-6 issues
FV=-99999;
S.PRES.value=int32(1000*S.PRES.value); % cast truly to "1/1000" integer to avoid numerical ..1e-6 issues

% check that b-PRES and c-PRES_QC sizes match
if any(size(S.PRES.value)~=size(S.PRES_QC.value))
    %{
    if verbose>-2, disp(['S-PROF_ERROR: File ' bfilestr '.nc: PRES (bio) and PRES_QC (core) dimensions don''t match. Set all PRES_QC=4 and create empty s-profile.']), end
    %synthfull=[];
    %return
    S.PRES_QC.value=ones(size(S.PRES.value))*4;
    if isfield(S,'TEMP'), S=rmfield(S,'TEMP'); end
    if isfield(S,'PSAL'), S=rmfield(S,'PSAL'); end
    %}
    if (verbose>-2)
       disp(['S-PROF_WARNING: File ' bfilestr '.nc: PRES (bio) and PRES_QC (core) dimensions don''t match. Create synthetic profile only with available core data.'])
       
       % CSV output
       msgType = 'warning_s-prof';
       message = 'PRES (bio) and PRES_QC (core) dimensions don''t match. Create synthetic profile only with available core data.';
       [~, fileName, fileExt] = fileparts(bfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    S.PRES.value=int32(C.PRES.value);
    [noNLEVELs,noNPROFs]=size(S.PRES.value);
    for i=1:length(ubgcparams)
        S.(ubgcparams{i}).value=S.PRES_QC.value*NaN;
        S.([ubgcparams{i} '_QC']).value=S.PRES_QC.value*NaN;
        S.([ubgcparams{i} '_ADJUSTED']).value=S.PRES_QC.value*NaN;
        S.([ubgcparams{i} '_ADJUSTED_QC']).value=S.PRES_QC.value*NaN;
        S.([ubgcparams{i} '_ADJUSTED_ERROR']).value=S.PRES_QC.value*NaN;    
    end
    addoffsetflag=0;
end
clear C

% double check pressure inversion test in profile (in a simplistic way): 
% Mustn't have repeated pressure levels with PRES_QC 0..3
% sometimes not properly flagged, e.g., D5903712_149.nc
pinversion=false(size(S.PRES.value));
ind=~isnan(S.PRES.value) & ismember(S.PRES_QC.value,[0 1 2 3]);
for i=1:size(S.PRES.value,2)
    pinversion(ind(:,i),i)=[diff(S.PRES.value(ind(:,i),i))<=0;0];
end
%pinversion=pinversion & ismember(S.PRES_QC.value,[0 1 2 3]);
if any(pinversion(:))
   if (verbose>1)
      disp(['S-PROF_INFO: File ' cfilestr '.nc: Found ' num2str(sum(pinversion(:))) ' levels with unflagged pressure inversions. Flag with PRES_QC=4.'])
      
      % CSV output
      msgType = 'info_s-prof';
      message = sprintf('Found %s levels with unflagged pressure inversions. Flag with PRES_QC=4.', ...
         num2str(sum(pinversion(:))));
      [~, fileName, fileExt] = fileparts(cfilepath);
      g_cocs_inputFile  = [fileName fileExt];
      fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
         g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    S.PRES_QC.value(pinversion)=4;
    % check if there are more
    pnum=0;
    while any(pinversion(:))
        pinversion=false(size(S.PRES.value));
        ind=~isnan(S.PRES.value) & ismember(S.PRES_QC.value,[0 1 2 3]);
        for i=1:size(S.PRES.value,2)
            pinversion(ind(:,i),i)=[diff(S.PRES.value(ind(:,i),i))<=0;0];
        end
        if any(pinversion(:))
            %disp(['S-PROF_WARNING: File ' cfilestr '.nc: Found ' num2str(sum(pinversion(:))) ' more levels with unflagged pressure inversions. Flag with PRES_QC=4.'])
            S.PRES_QC.value(pinversion)=4;
            pnum=pnum+sum(pinversion(:));
        end
    end % while
    if (verbose>1 && pnum)
       disp(['S-PROF_INFO: File ' cfilestr '.nc: Found ' num2str(pnum) ' more levels with unflagged pressure inversions. Flag with PRES_QC=4.'])
       
       % CSV output
       msgType = 'info_s-prof';
       message = sprintf('Found %s more levels with unflagged pressure inversions. Flag with PRES_QC=4.', ...
          num2str(pnum));
       [~, fileName, fileExt] = fileparts(cfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
end % first iteration
clear pinversion ind pnum

% sort out pressure axis and which N_PROF to use
% only use PRES_QC 0..3, ignore PRES_QC=4
inpres0=S.PRES.value; % keep a copy of pressure without vertical offset correction
inpres=S.PRES.value; % use copy of pressure to work with
pflag=ismember(S.PRES_QC.value,[0 1 2 3]); 
inpres(~pflag)=FV; 
inpres0(~pflag)=FV; 

% check where BGC samples are present (and not all NaN)
bgcpresence=false(size(S.PRES.value));
for i=1:length(ubgcparams)
    bgcpresence=bgcpresence | ~isnan(S.(ubgcparams{i}).value);
end

% ~includeTSflag: only use N_PROFs that have biogeochemical data, 
%                 ignore TEMP/PSAL-only N_PROFs for construction of synthetic axis
%if ~includeTSflag, inpres(:,~bgcflag)=NaN; end
if ~includeTSflag, inpres(:,~bgcflag)=FV; inpres(~bgcpresence)=FV; end

%% load meta file / check existence
if isempty(metafilepath)
% figure out location of the corresponding meta file
if ~isempty(bfilepath)
    [basepath,~]=fileparts(bfilepath);
else
    [basepath,~]=fileparts(cfilepath);
end
metafilepath=[basepath filesep char(cellstr(S.PLATFORM_NUMBER.value(1,:))) '_meta.nc'];
if ~(exist(metafilepath,'file'))
metafilepath=[basepath filesep '..' filesep char(cellstr(S.PLATFORM_NUMBER.value(1,:))) '_meta.nc'];
end
end
% keep meta-file names for error/warning/info reporting
[~,metafilestr]=fileparts(metafilepath);

C=[];
%infields={'LAUNCH_CONFIG_PARAMETER_NAME';'LAUNCH_CONFIG_PARAMETER_VALUE';'CONFIG_MISSION_NUMBER';'CONFIG_PARAMETER_NAME';'CONFIG_PARAMETER_VALUE'};
infields={'LAUNCH_CONFIG_PARAMETER_NAME';'LAUNCH_CONFIG_PARAMETER_VALUE';'PARAMETER';'PARAMETER_SENSOR';'FORMAT_VERSION'};
try 
    C=lov_netcdf_pickprod(metafilepath,infields);
catch me
    % failed to locate meta file
    if (verbose>-2)
       disp(['S-PROF_ERROR: Float ' strtrim(S.PLATFORM_NUMBER.value(1,:)) ': Could not find meta file ' metafilepath '. Abort..']);
       
      % CSV output
      msgType = 'error';
      message = 'File not found.';
      [~, fileName, fileExt] = fileparts(metafilepath);
      g_cocs_inputFile  = [fileName fileExt];
      fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
         g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    synthfull=[];
    return
end
if isempty(C)
    if (verbose>-2)
       disp(['S-PROF_ERROR: Float ' strtrim(S.PLATFORM_NUMBER.value(1,:)) ': Could not find meta file ' strtrim(S.PLATFORM_NUMBER.value(1,:)) '_meta.nc in current or parent folder. Abort..']);
       
      % CSV output
      msgType = 'error';
      message = 'File not found.';
      g_cocs_inputFile  = [strtrim(S.PLATFORM_NUMBER.value(1,:)) '_meta.nc'];
      fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
         g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    synthfull=[];
    return
end % meta file exists


%% split up pressure in each N_PROF for each parameter/sensor
% e.g. NITRATE and DOXY in same N_PROF can have different vertical offsets
if addoffsetflag
    linind=cellfun(@(x,y)repmat(x,length(y),1),num2cell(1:noNPROFs,1),bgcparams,'uniform',0); % index to N_PROF in #repetitions like bgcparams
    linbgcparams=cat(1, bgcparams{:});
    linind=cat(1, linind{:});
    inpres=inpres(:,linind); % repeat pressure for each b-parameter
end % split up N_PROFs only if vertical offsets are added per sensor

%%{
    %% check meta file for vertical pressure offsets
if addoffsetflag
if isfield(C,'LAUNCH_CONFIG_PARAMETER_NAME') % pre-v3.1 meta files might not have this field
    names=C.LAUNCH_CONFIG_PARAMETER_NAME.value;
    values=C.LAUNCH_CONFIG_PARAMETER_VALUE.value;
    %{
    % enforce all-caps writing for Ctd
    names=char(strrep(cellstr(names),'Ctd','CTD'));
    %}
    %% check each sensor short name for vertical offsets
    sensors={'CTD';'Optode';'Ocr';'Eco';'MCOMS';'FLNTU';'Crover';'Suna';'Isus'}; % sensor short name
    param_sensors={{'CTD_PRES';'CTD_TEMP';'CTD_CNDC';'CTD_PSAL'};...
        'OPTODE_DOXY';...
        {'RADIOMETER_DOWN_IRR<nnn>';'RADIOMETER_PAR'};...
        {'FLUOROMETER_CHLA';'FLUOROMETER_CDOM';'BACKSCATTERINGMETER_BBP<nnn>'};...
        {'FLUOROMETER_CHLA';'FLUOROMETER_CDOM';'BACKSCATTERINGMETER_BBP<nnn>'};...
        {'FLUOROMETER_CHLA';'BACKSCATTERINGMETER_TURBIDITY'};...
        'TRANSMISSOMETER_CP<nnn>';...
        {'SPECTROPHOTOMETER_NITRATE';'SPECTROPHOTOMETER_BISULFIDE'};...
        'SPECTROPHOTOMETER_NITRATE'};
    %params={'PSAL';'DOXY';'WELLING_';{'CHLA','BBP','CDOM'};{'CHLA','BBP'};'CP660';'NITRATE'}; % associated parameter
    % find occurences of search parameter
    cnames={'VerticalPressureOffset_dbar'};
    ind=find(~cellfun(@isempty,strfind(cellstr(lower(names)),lower(cnames{1})))); % ignore upper/lower case
    
    if any(ind)
        if (verbose>1)
           disp(['S-PROF_INFO: File ' metafilestr '.nc: Found ' num2str(length(ind)) ' VerticalOffsets'])
        
           % CSV output
           msgType = 'info_s-prof';
           message = sprintf('Found %s VerticalOffsets.', ...
              num2str(length(ind)));
           [~, fileName, fileExt] = fileparts(metafilestr);
           g_cocs_inputFile  = [fileName fileExt];
           fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
              g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
        end
        % get short sensor names and vertical offsets
        cpnames=strrep(strrep(cellstr(lower(names(ind,:))),lower(cnames{1}),''),lower('CONFIG_'),'');
        voffset=values(ind);
        try % get corresponding full-length sensor name: index to param_sensors / sensors
            sensorind=cellfun(@(x)find(~cellfun(@isempty,strfind(lower(sensors),lower(x)))),cpnames);
        catch me
           if (verbose>0)
              disp(['S-PROF_WARNING: File ' bfilestr '.nc: Could not identify some short sensor name in meta file ' strjoin(cpnames,'; ')])
              
              % CSV output
              msgType = 'warning_s-prof';
              message = sprintf('Could not identify some short sensor name in meta file %s.', strjoin(cpnames,' '));
              [~, fileName, fileExt] = fileparts(bfilepath);
              g_cocs_inputFile  = [fileName fileExt];
              fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
                 g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
           end
        end
        % and assign vertical offset via full-length sensor name to
        % bgc parameters
        linvoffset=zeros(size(linbgcparams));
        C.PARAMETER.value=cellstr(C.PARAMETER.value); % make cellstr
        for i=1:length(sensorind) % cycle all vertical offsets
            snames=param_sensors{sensorind(i)}; % associated param_sensor long names
            if iscell(snames) % sensor has multiple param_sensor names
                pind=false(length(C.PARAMETER.value),1);
                for k=1:length(snames) % find occurence of param_sensor name in meta file
                    %pind=pind | ~cellfun(@isempty,regexp(cellstr(C.PARAMETER_SENSOR.value),['^' strrep(snames{k},'<nnn>','[0-9][0-9][0-9]') '$*'])); % include secondary sensors..
                    pind=pind | ~cellfun(@isempty,regexp(cellstr(C.PARAMETER_SENSOR.value),['^' strrep(snames{k},'<nnn>','[0-9][0-9][0-9]') '$'])); % exclude secondary sensors
                end
            else
                %pind=~cellfun(@isempty,regexp(cellstr(C.PARAMETER_SENSOR.value),['^' strrep(snames,'<nnn>','[0-9][0-9][0-9]') '$*'])); % include secondary sensors..
                pind=~cellfun(@isempty,regexp(cellstr(C.PARAMETER_SENSOR.value),['^' strrep(snames,'<nnn>','[0-9][0-9][0-9]') '$'])); % exclude secondary sensors
            end % multiple or single param_sensor name
            %% does ignore second sensors, e.g., DOXY and DOXY2 !!!
            %% 
            if ~any(pind)
                %disp(['S-PROF_WARNING: File ' metafilestr '.nc: Could not identify parameter with sensor name(s) ' strjoin(cellstr(snames),', ')])
                %disp(['S-PROF_WARNING: File ' metafilestr '.nc: Skipping vertical offset of ' num2str(voffset(i)) ' dbar for ' strjoin(cellstr(snames),', ')])
                %keyboard
                %synthfull=[];
                %return
                if (verbose>0)
                   disp(['S-PROF_WARNING: File ' bfilestr '.nc: Could not identify parameter with sensor name(s) ' strjoin(cellstr(snames),', ') '; Skipping vertical offset of ' num2str(voffset(i)) ' dbar from LAUNCH_CONFIG'])
                
                   % CSV output
                   msgType = 'warning_s-prof';
                   message = sprintf('Could not identify parameter with sensor name(s) %s. Skipping vertical offset of %s dbar from LAUNCH_CONFIG.', ...
                      strjoin(cellstr(snames),' '), num2str(voffset(i)));
                   [~, fileName, fileExt] = fileparts(bfilepath);
                   g_cocs_inputFile  = [fileName fileExt];
                   fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
                      g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
                end
                
            else % found 
                pnames=C.PARAMETER.value(pind); % get i- and b- parameter names
                % fill in vertical offset
                linvoffset(ismember(linbgcparams,pnames))=voffset(i);
            end
            
            clear snames pind pnames 
        end % cycle all vertical offsets
            
        % and apply offset
        inpflag=inpres==FV;
        inpres=inpres+int32(1e3*ones(size(inpres,1),1)*linvoffset(:)');
        inpres(inpflag)=FV;
        
        % do some housekeeping
        voff.cpnames=cpnames;voff.voffset=voffset;
        voff.linbgcparams=reshape(linbgcparams,1,[]); voff.linvoffset=reshape(linvoffset,1,[]);
        clear inpflag cpnames sensorind voffset sensors param_sensors
    else
        if (verbose>1)
           disp(['S-PROF_INFO: File ' bfilestr '.nc: Found no verticalOffsets in meta file'])
        
           % CSV output
           msgType = 'info_s-prof';
           message = 'Found no VerticalOffsets in meta file.';
           [~, fileName, fileExt] = fileparts(bfilepath);
           g_cocs_inputFile  = [fileName fileExt];
           fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
              g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
        end
        voff.linbgcparams={};voff.linvoffset=[];
    end % config name found
    clear ind cnames names values
else
   if (verbose>-1)
      disp(['S-PROF_INFO: File ' bfilestr '.nc: Could not find LAUNCH_CONFIG_PARAMETER_NAME in meta file (FORMAT_VERSION ' C.FORMAT_VERSION.value '). No vertical sensor offsets corrected.'])
      
      % CSV output
      msgType = 'info_s-prof';
      message = sprintf('Could not find LAUNCH_CONFIG_PARAMETER_NAME in meta file (FORMAT_VERSION %s). No vertical sensor offsets corrected.', ...
         C.FORMAT_VERSION.value);
      [~, fileName, fileExt] = fileparts(bfilepath);
      g_cocs_inputFile  = [fileName fileExt];
      fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
         g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
   end
    voff.linbgcparams={};voff.linvoffset=[];
end % LAUNCH_CONFIG_PARAMETER_NAME
end % addoffsetflag
%%}
%clear C 

%% try to construct synthetic pressure axis only for BGC floats, not if already known that it's a core-only float
if bgcfloatflag % BGC float
    
%% put extra loop around synthetic pressure axis construction - if failed, revert to core-only profile
for pconstr=1:1 % extra loop around presaxis construction
% get unique pressures (with or without TEMP/PSAL-only levels; see above)
%upres=unique(inpres(~isnan(inpres)));
upres=unique(inpres(inpres~=FV));
if isempty(upres)
    if verbose>0
        if isempty(ubgcparams)
            disp(['S-PROF_WARNING: File ' bfilestr '.nc: Found no b-parameters. Create synthetic profile only with available core data.'])
            
            % CSV output
            msgType = 'warning';
            message = 'Found no b-parameters. Create synthetic profile only with available core data.';
            [~, fileName, fileExt] = fileparts(bfilepath);
            g_cocs_inputFile  = [fileName fileExt];
            fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
               g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
        else
            disp(['S-PROF_WARNING: File ' bfilestr '.nc: Found b-parameter(s) ' strjoin(ubgcparams,' ') ', but without any PRES_QC=0..3 and non-FillValue BGC data. Create synthetic profile only with available core data.'])
            
            % CSV output
            msgType = 'warning';
            message = sprintf('Found b-parameter(s) %s but without any PRES_QC=0..3 and non-FillValue BGC data. Create synthetic profile only with available core data.', ...
               strjoin(ubgcparams,' '));
            [~, fileName, fileExt] = fileparts(bfilepath);
            g_cocs_inputFile  = [fileName fileExt];
            fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
               g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
        end
    end
    %synthfull=[]; return
    presaxis=[]; % default to empty presaxis
    break % extra loop around presaxis construction
end
% and check which pressure levels are present in which profile
prespresent=false(length(upres),size(inpres,2));
for i=1:size(inpres,2),prespresent(:,i)=ismember(upres,inpres(:,i));end

% verify that there are BGC observations, not just BGC N_PROFs
if ~any(prespresent(:)) % may not be needed; redundant
    if (verbose>0)
       disp(['S-PROF_WARNING: File ' bfilestr '.nc: Found b-parameter(s) ' strjoin(ubgcparams,' ') ', but without any non-FillValue data. Create synthetic profile only with available core data.'])
       
       % CSV output
       msgType = 'warning';
       message = sprintf('Found b-parameter(s) %s but without any non-FillValue data. Create synthetic profile only with available core data.', ...
          strjoin(ubgcparams,' '));
       [~, fileName, fileExt] = fileparts(bfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    %synthfull=[]; return
    presaxis=[]; % default to empty presaxis
    break % extra loop around presaxis construction
end

% get pressure differences between the levels in each N_PROF; use the
% minimum of preceeding/succeeding deltaPRES
valdp=ones(length(upres),size(inpres,2))*NaN;
for i=1:size(inpres,2)
    %pres=inpres(~isnan(inpres(:,i)),i); 
    pres=inpres(inpres(:,i)~=FV,i); 
    if ~isempty(pres)
        if length(pres)>1
            dpres=diff(pres);
            valdp(prespresent(:,i),i)=min(abs([dpres(1);dpres]),abs([dpres;dpres(end)]));
        else
            %valdp(prespresent(:,i),i)=0;
            valdp(prespresent(:,i),i)=NaN;
        end
    end
    clear pres dpres
end

% cycle through record from bottom
useind=false(size(upres));
i=length(upres); % start at bottom
niter=0;nitermax=length(upres)+1;
if all(isnan(valdp(:))) % each BGC obs has only one level - no way to jump/construct synthetic pressure axis
%presaxis=median(upres); % take median pressure
presaxis=upres(end); % take deepest pressure and align rest to this level
else % cycle pressure record
while ~isempty(i)
    niter=niter+1;
    useind(i)=1; % add current level to synthetic axis
    ind=find(upres>upres(i)-min(valdp(i,:)) & upres<=upres(i)); % get pressures that are within current level (included) and probably next level-min(dPRES) (excluded)
    % check if any of the intermittent levels has such a small dPRES, that
    % there will be a second observation within the current level-min(dPRES) "jump"
    obspresence=~isnan(valdp(ind,:)); % make presence of non-FillValue a logical array
    if ~isempty(ind) && any(sum(obspresence,1)>1) % there are other levels in between and they have more than one observation, i.e., a denser sampling interval
        % go to deepest upres that features a second observation in the
        % same N_PROF: sum #obs from bottom in each N_PROF, get max in each
        % line (upres), and jump to (deepest) line that has >1        
        i=ind(find(max(flipud(cumsum(flipud(obspresence),1)),[],2)>1,1,'last'));
        if isempty(i)
            %keyboard % should not happen?? Check code..
            if (verbose>-3)
               disp(['S-PROF_WARNING: File ' bfilestr '.nc: Trouble during creation of synthetic pressure axis. Create synthetic profile only with available core data.'])
               
               % CSV output
               msgType = 'warning';
               message = 'Trouble during creation of synthetic pressure axis. Create synthetic profile only with available core data.';
               [~, fileName, fileExt] = fileparts(bfilepath);
               g_cocs_inputFile  = [fileName fileExt];
               fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
                  g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
            end
            %synthfull=[]; return
            useind=[]; % default to empty presaxis if failed
            break % loop of pressure levels from bottom
        end
    else % jump by at least current level+min(dPRES)
        if all(isnan(valdp(i,:))) % no min(dPRES) available for current level: 
            % jump to next level that has a non-NaN valdp
            i=find(upres<upres(i) & any(~isnan(valdp),2),1,'last');
        else % jump by at least current level+min(dPRES)
            i=find(upres<=upres(i)-min(valdp(i,:)),1,'last');
        end
    end
    clear obspresence
    if niter>nitermax
       if (verbose>-3)
          disp(['S-PROF_WARNING: File ' bfilestr '.nc: Exceeded maximum number of iterations in selection of synthetic pressure levels. Should not happen... Create synthetic profile only with available core data.'])
          
          % CSV output
          msgType = 'warning';
          message = 'Exceeded maximum number of iterations in selection of synthetic pressure levels. Should not happen... Create synthetic profile only with available core data.';
          [~, fileName, fileExt] = fileparts(bfilepath);
          g_cocs_inputFile  = [fileName fileExt];
          fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
             g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
       end
        %synthfull=[]; return
        useind=[]; % default to empty presaxis if failed
        break % loop of pressure levels from bottom
    end
end
clear niter nitermax
presaxis=upres(useind);
end % pressure axis cycle from bottom possible?

end % extra loop around presaxis construction, default to empty presaxis if failed
%% done with synthetic pressure axis construction, now prepare to fill/align BGC data

else % no BGC float, core only; no additional messages for failed synthetic axis construction
    presaxis=[]; % default to empty presaxis
end % extra check for BGC float via function input parameter 'bgcFloatFlag'


%% get N_PROF priority from meta file (alphabetical by sensor name)
nprofstr=cell(1,noNPROFs);
params=cellstr(C.PARAMETER.value);
if isfield(C,'PARAMETER_SENSOR') % not a very old meta file
    paramsensors=cellstr(C.PARAMETER_SENSOR.value);
    for i=1:noNPROFs
        dummy=union(cellstr(S.PARAMETER.value(:,:,1,i)'),cellstr(S.STATION_PARAMETERS.value(:,:,i)'));
        nprofstr{i}=strjoin(sort(paramsensors(ismember(params,setdiff(dummy,'')))),'_');
    end
    % and bring into order but keeping nprof 1 at first position
    [~,asort]=sort(nprofstr(2:end));asort=[1 asort+1];
else % pre-v3.1 meta file
    if (verbose>0)
       disp(['S-PROF_WARNING: File ' bfilestr '.nc: Could not find PARAMETER_SENSOR in meta file (FORMAT_VERSION ' C.FORMAT_VERSION.value '). Kept N_PROF order as in profile file.'])
    
       % CSV output
       msgType = 'warning';
       message = sprintf('Could not find PARAMETER_SENSOR in meta file (FORMAT_VERSION %s). Kept N_PROF order as in profile file.', ...
          C.FORMAT_VERSION.value);
       [~, fileName, fileExt] = fileparts(bfilepath);
       g_cocs_inputFile  = [fileName fileExt];
       fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
          g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
    end
    asort=1:noNPROFs;
end % define N_PROF priority

%% define core parameters
%coreparams={'PRES';'TEMP';'PSAL'};
coreparams=intersect(fieldnames(S),{'PRES';'TEMP';'PSAL'});

% get non-overlapping pressure axis for core parameters
xpres=inpres0(:,asort); % keep original pressure
xpresqc=pflag(:,asort); % and flag to pressure that are not QC=4
for i=1:length(coreparams)
    
    %% extract data
    y=S.(coreparams{i}).value(:,asort);
    yqc=S.([coreparams{i} '_QC']).value(:,asort);
    %% check for overlapping portion of N_PROFs
    if ismember(coreparams{i},{'PRES'})
        overlap=true(size(y)); % pressures of different N_PROFs (almost) necessarily overlap
    else % not PRES
        % get max and min ranges per nprof
        xrange=ones(2,1+noNPROFs)*NaN;
        overlap=false(size(y)); % and flag portions that don't overlap
        for k=1:noNPROFs 
            ind=~isnan(y(:,k)) & xpresqc(:,k);
            if any(ind) % data in current nprof and with proper pres
                xrange(:,1+k)=[min(xpres(ind,k)); max(xpres(ind,k))]; 
                % check if it should be added or not
                if isnan(xrange(1,1)) % first nprof with data
                    xrange(:,1)=xrange(:,1+k);
                    overlap(:,k)=ind;
                else % more than one nprof with data: keep only data outside existing range
                    overlap(:,k)=ind & (xpres(:,k)>xrange(2,1) | xpres(:,k)<xrange(1,1));
                    xrange(1,1)=min([xrange(1,1) xrange(1,1+k)]);
                    xrange(2,1)=max([xrange(2,1) xrange(2,1+k)]);
                end
            end
        end % cycle all nprofs
        clear ind xrange
    end % overlapping portion
    %% do not use <PARAM>_QC of 8 or FillValue
    yflagqc=ismember(yqc,[0 1 2 3 4 5]);
    if ismember(coreparams{i},{'PRES'}), yflagnoFV=y~=FV; % double check PRES FV
    else, yflagnoFV=~isnan(y); end % and other FV (e.g., BR5900952_157, DOXY all NaN but QC=0)
    
    %% clean up: only data of current parameter without QC 8, only pflag
    x=xpres(xpresqc & yflagqc & yflagnoFV);
    %xqc=xpresqc(xpresqc & yflagqc);
    y=y(xpresqc & yflagqc & yflagnoFV);
    overlap=overlap(xpresqc & yflagqc & yflagnoFV);
    %yadjerrpresence=~all(isnan(yadjerr)); % error not mandatory for adjusted fields..
    clear yflagqc yflagnoFV yqc
    
    if ~isempty(y) % not only NaN/FV data
        % use only non-overlapping portion 
        x=x(overlap);
        clear overlap
        % make monotonic for interpolation (looses nprof priority!)
        [~,ind]=sort(x); % monotonic sorting
        x=x(ind);
        full.(coreparams{i}).x=x;
    else % empty pressure axis
        full.(coreparams{i}).x=int32([]);
    end % not only NaN/FV data
    clear x y 
end
clear xpres xpresqc
if ~isfield(full,'TEMP'), full.TEMP.x=[]; end % no core TEMP data (e.g. because of missing core file: kordi\2900608\profiles\BR2900608_077.nc
if ~isfield(full,'PSAL'), full.PSAL.x=[]; end % no core PSAL data (e.g. because of missing core file: kordi\2900608\profiles\BR2900608_077.nc

%% get all non-overlapping (HR-)TEMP/PSAL levels and synthetic pressure axis levels
presmerge=union(union(full.TEMP.x,full.PSAL.x),presaxis); % 'HR' T/S pressure axis and presaxis
% get indices for synthetic pressure axis
nosf=length(presmerge);
[~,synthind]=intersect(presmerge,presaxis);
%clear full

%% start to fill in data
ubgcparams=cat(1, {'PRES';'TEMP';'PSAL'},ubgcparams(:));

isynth=(1:length(presaxis))'; % index 1..length synthetic pressure axis
nos=length(isynth);
% DOXY/<PARAM> can sit in more than one N_PROF, so need to be a bit more
% clunky than just simply interpolating a single N_PROF which contains
% <PARAM>
%xpres=S.PRES.value(:,asort); % rearrange pressure obeying nprof priority
xpresqc=pflag(:,asort); % and flag to pressure that are not QC=4
synth.PRES.value=presaxis;

if isempty(presmerge) % core and presaxis empty
    for i=1:length(ubgcparams) % tap all with FillValue (avoid N_LEVEL dimension of 0)
        if ismember(ubgcparams{i},{'PRES'})
            synth.(ubgcparams{i}).value=int32(FV);
        else
            synth.(ubgcparams{i}).value=NaN;
        end
        synth.([ubgcparams{i} '_QC']).value=NaN;
        synth.([ubgcparams{i} '_ADJUSTED']).value=NaN;
        synth.([ubgcparams{i} '_ADJUSTED_QC']).value=NaN;
        synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value=NaN;
        synth.([ubgcparams{i} '_dPRES']).value=NaN;
    end
    nosf=1;synthind=1; % avoid N_LEVEL dimension of 0 for BGC parameters
else
% fill in data in synthetic profile
for i=1:length(ubgcparams)
    
    if ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'}) % check which pressure axis to use
        sind=1:length(presmerge); % synthetic levels and full-HR PTS data for core
    else % BGC
        sind=synthind; % synthetic levels only
    end
    spresaxis=presmerge(sind); % pressure axis for current parameter
    spresaxis=spresaxis(:); % make sure it's a column vector
    
    if addoffsetflag
        %% re-apply vertical offset from scratch for particular parameter
        % e.g., N_PROF with SUNA & CTD has large offset for NITRATE, but none
        % for TEMP & PSAL, and only one S.PRES.value / inpres for both
        if ismember(ubgcparams{i},voff.linbgcparams)
            % check to which N_PROF the current parameter  fits
            ind=cellfun(@(x)ismember(ubgcparams{i},x),bgcparams);
            xpres=inpres0;
            xpres(:,ind)=xpres(:,ind)+int32(ones(noNLEVELs,1)*1e3*voff.linvoffset(ismember(voff.linbgcparams,ubgcparams{i})));
            xpres(inpres0==FV)=FV; % keep FV
            xpres=xpres(:,asort);
            clear ind
        else % no match found
            xpres=inpres0(:,asort); % keep original pressure
        end % found vertical offsets in config 
        if strcmp(ubgcparams{i},'PRES')
            xpres=inpres0(:,asort); % forget everything above, use all unadjusted pressures
            %xpres=S.PRES.value(:,asort); % forget everything above, use all unadjusted pressures
        end
    else % no addoffsetflag
        xpres=inpres0(:,asort); % keep original pressure
    end % addoffsetflag
    
    %% extract data
    y=S.(ubgcparams{i}).value(:,asort);
    yqc=S.([ubgcparams{i} '_QC']).value(:,asort);
    yadj=S.([ubgcparams{i} '_ADJUSTED']).value(:,asort);
    yadjqc=S.([ubgcparams{i} '_ADJUSTED_QC']).value(:,asort);
    yadjerr=S.([ubgcparams{i} '_ADJUSTED_ERROR']).value(:,asort);
    %% check for overlapping portion of N_PROFs
    if ismember(ubgcparams{i},{'PRES'})
        overlap=true(size(y)); % pressures of different N_PROFs (almost) necessarily overlap
        % get max and min ranges per nprof for adjusted anyway
        xrangeadj=ones(2,1+noNPROFs)*NaN;
        overlapadj=false(size(yadj)); % and flag portions that don't overlap for adjusted data
        for k=1:noNPROFs 
            % and adjusted
            %indadj=~isnan(yadj(:,k)) & xpresqc(:,k); % use only levels without FillValue and with useful PRES_QC
            indadj=(~isnan(yadj(:,k)) | ismember(yadjqc(:,k),4)) & xpresqc(:,k); % consider that adjusted_QC 4 may have FillValue adjusted data
            if any(indadj) % data in current nprof and with proper pres
                xrangeadj(:,1+k)=[min(xpres(indadj,k)); max(xpres(indadj,k))]; 
                % check if it should be added or not
                if isnan(xrangeadj(1,1)) % first nprof with data
                    xrangeadj(:,1)=xrangeadj(:,1+k);
                    overlapadj(:,k)=indadj;
                else % more than one nprof with data: keep only data outside existing range
                    overlapadj(:,k)=indadj & (xpres(:,k)>xrangeadj(2,1) | xpres(:,k)<xrangeadj(1,1));
                    xrangeadj(1,1)=min([xrangeadj(1,1) xrangeadj(1,1+k)]);
                    xrangeadj(2,1)=max([xrangeadj(2,1) xrangeadj(2,1+k)]);
                end
            end
        end % cycle all nprofs
        clear indadj xrangeadj
        
    else % not PRES
        % get max and min ranges per nprof
        xrange=ones(2,1+noNPROFs)*NaN;
        xrangeadj=ones(2,1+noNPROFs)*NaN;
        overlap=false(size(y)); % and flag portions that don't overlap
        overlapadj=false(size(yadj)); % and flag portions that don't overlap for adjusted data
        for k=1:noNPROFs 
            ind=~isnan(y(:,k)) & xpresqc(:,k);
            if any(ind) % data in current nprof and with proper pres
                xrange(:,1+k)=[min(xpres(ind,k)); max(xpres(ind,k))]; 
                % check if it should be added or not
                if isnan(xrange(1,1)) % first nprof with data
                    xrange(:,1)=xrange(:,1+k);
                    overlap(:,k)=ind;
                else % more than one nprof with data: keep only data outside existing range
                    overlap(:,k)=ind & (xpres(:,k)>xrange(2,1) | xpres(:,k)<xrange(1,1));
                    xrange(1,1)=min([xrange(1,1) xrange(1,1+k)]);
                    xrange(2,1)=max([xrange(2,1) xrange(2,1+k)]);
                end
            end
            % and adjusted
            %indadj=~isnan(yadj(:,k)) & xpresqc(:,k); % use only levels without FillValue and with useful PRES_QC
            indadj=(~isnan(yadj(:,k)) | ismember(yadjqc(:,k),4)) & xpresqc(:,k); % consider that adjusted_QC 4 may have FillValue adjusted data
            if any(indadj) % data in current nprof and with proper pres
                xrangeadj(:,1+k)=[min(xpres(indadj,k)); max(xpres(indadj,k))]; 
                % check if it should be added or not
                if isnan(xrangeadj(1,1)) % first nprof with data
                    xrangeadj(:,1)=xrangeadj(:,1+k);
                    overlapadj(:,k)=indadj;
                else % more than one nprof with data: keep only data outside existing range
                    overlapadj(:,k)=indadj & (xpres(:,k)>xrangeadj(2,1) | xpres(:,k)<xrangeadj(1,1));
                    xrangeadj(1,1)=min([xrangeadj(1,1) xrangeadj(1,1+k)]);
                    xrangeadj(2,1)=max([xrangeadj(2,1) xrangeadj(2,1+k)]);
                end
            end
        end % cycle all nprofs
        clear ind xrange indadj xrangeadj
    end % check for overlapping portion of N_PROFs PRES (int32/FV) or other style (double/NaN)
    %% do not use <PARAM>_QC of 8 or FillValue
    yflagqc=ismember(yqc,[0 1 2 3 4 5]);
    if ismember(ubgcparams{i},{'PRES'}), yflagnoFV=y~=FV; % double check PRES FV
    else, yflagnoFV=~isnan(y); end % and other FV (e.g., BR5900952_157, DOXY all NaN but QC=0)
    yflagadjqc=ismember(yadjqc,[0 1 2 3 4 5]);
    %yflagadjnoFV=~isnan(yadj); % double check FV, use only levels without FillValue
    yflagadjnoFV=~isnan(yadj) | ismember(yadjqc,4);  % double check FV, consider adjusted QC 4 as exception to FillValue
    
    %% clean up: only data of current parameter without QC 8, only pflag
    x=xpres(xpresqc & yflagqc & yflagnoFV);
    xadj=xpres(xpresqc & yflagadjqc & yflagadjnoFV);
    %xqc=xpresqc(xpresqc & yflagqc);
    y=y(xpresqc & yflagqc & yflagnoFV);
    yqc=yqc(xpresqc & yflagqc & yflagnoFV);
    yadj=yadj(xpresqc & yflagadjqc & yflagadjnoFV);
    yadjqc=yadjqc(xpresqc & yflagadjqc & yflagadjnoFV);
    yadjerr=yadjerr(xpresqc & yflagadjqc & yflagadjnoFV);
    overlapadj=overlapadj(xpresqc & yflagadjqc & yflagadjnoFV);
    overlap=overlap(xpresqc & yflagqc & yflagnoFV);
    yadjerrpresence=~all(isnan(yadjerr)); % error not mandatory for adjusted fields..
    clear yflagqc yflagnoFV yflagadjqc yflagadjnoFV
    
    %% preallocate
    if ismember(ubgcparams{i},{'PRES'})
        synth.(ubgcparams{i}).value=int32(ones(size(spresaxis))*FV);
    else
        synth.(ubgcparams{i}).value=double(spresaxis)*NaN;
    end
    synth.([ubgcparams{i} '_QC']).value=double(spresaxis)*NaN;
    synth.([ubgcparams{i} '_ADJUSTED']).value=double(spresaxis)*NaN;
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value=double(spresaxis)*NaN;
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value=double(spresaxis)*NaN;
    synth.([ubgcparams{i} '_dPRES']).value=int32(ones(size(spresaxis))*FV);
    
    if ismember(ubgcparams{i},{'PRES'}) % add synthetic levels (incl. vertical offsets of BGC sensors)
        synth.PRES.value(synthind)=presaxis;
    end
        
    if ~isempty(y) % not only NaN/FV data
        % use only non-overlapping portion 
        x=x(overlap);y=y(overlap);yqc=yqc(overlap);
        clear overlap
        % make monotonic for interpolation (looses nprof priority! But non-overlapping anyway)
        [~,ind]=sort(x); % monotonic sorting
        x=x(ind);y=y(ind);yqc=yqc(ind);
        % and make sure that they are column vectors
        x=x(:);y=y(:);yqc=yqc(:);
        
        %% copy data for levels that are part of the synthetic pressure axis:
        % get indices to which data to copy
        % take only 'first' occurence (in nprof-priority sorted record!) and
        % toss away repeated occurences (e.g., MD5904767_004.nc PSAL @ 46.0 dbar) 
        [~,fillind,cpind]=intersect(spresaxis,x);
        synth.(ubgcparams{i}).value(fillind)=y(cpind);
        synth.([ubgcparams{i} '_QC']).value(fillind)=yqc(cpind);
        synth.([ubgcparams{i} '_dPRES']).value(fillind)=0;
        %if ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'}) % keep which BGC PTS were truly measured for later
        %    full.(ubgcparams{i}).fillind=fillind;
        %end
        clear fillind cpind
        
        %% rest of data:
        % interpolate data for other levels of the synthetic pressure axis:
        % toss away repeated occurence of pressures: e.g., MD5904767_004.nc PSAL @ 46.0 dbar
        if ismember(ubgcparams{i},{'PRES'})
            [~,uind]=unique(x);
        else
            uind=1:length(x); % should have been dealt with by overlapping portions already
        end
        if length(x(uind))>1 
            % data interpolation: linear, no extrapolation
            synth.(ubgcparams{i}).value(isnan(synth.(ubgcparams{i}).value))=interp1(double(x(uind)),double(y(uind)),double(spresaxis(isnan(synth.(ubgcparams{i}).value))),'linear',NaN);
            % data extrapolation: nearest-neighbour, no limit on extrapolation
            if ~ismember(ubgcparams{i},{'PRES'}) % PRES extrapolation as nearest-neighbour does not work..
                synth.(ubgcparams{i}).value(isnan(synth.(ubgcparams{i}).value))=interp1(double(x(uind)),double(y(uind)),double(spresaxis(isnan(synth.(ubgcparams{i}).value))),'nearest','extrap');
            end % should not occur for PRES field, either..
            % deal with qc
            % qc interpolation: next and previous, no extrapolation
            qcnext=interp1(double(x(uind)),yqc(uind),double(spresaxis),'next',NaN);
            qcprevious=interp1(double(x(uind)),yqc(uind),double(spresaxis),'previous',NaN);
            % take maximum of QC; order 1 < 2 < 5 < 3 < 4
            qcnext(qcnext==5)=2.5; qcprevious(qcprevious==5)=2.5; % replace QC 5 with 2.5: 
            qcfill=max(qcnext,qcprevious); % max for interpolated QC
            synth.([ubgcparams{i} '_QC']).value(isnan(synth.([ubgcparams{i} '_QC']).value))=qcfill(isnan(synth.([ubgcparams{i} '_QC']).value));
            synth.([ubgcparams{i} '_QC']).value(synth.([ubgcparams{i} '_QC']).value==2.5)=5; % and reverse QC 5
            % qc extrapolation: nearest-neighbour, no limit on extrapolation
            synth.([ubgcparams{i} '_QC']).value(isnan(synth.([ubgcparams{i} '_QC']).value))=interp1(double(x(uind)),yqc(uind),double(spresaxis(isnan(synth.([ubgcparams{i} '_QC']).value))),'nearest','extrap');
            clear qcnext qcprevious qcfill
        else % only one value, keep this value as well as its QC, and place it closest to the original pressure
            [~,ifill]=min(abs(spresaxis-x(uind)));
            if ~ismember(ubgcparams{i},{'PRES'}) % PRES already dealt with (incl. vertical offsets), which shouldn't be overwritten
                synth.(ubgcparams{i}).value(ifill)=y(uind);
            end
            synth.([ubgcparams{i} '_QC']).value(ifill)=yqc(uind);
            if addTSeverywhere && ismember(ubgcparams{i},{'TEMP';'PSAL'})
                % extrapolate T and S context by replication, no limit on extrapolation
                synth.(ubgcparams{i}).value(:)=y(uind);
                synth.([ubgcparams{i} '_QC']).value(:)=yqc(uind);
            end
        end
        %% and kick out unmatched data
        %inomatch=false(nos,1); inomatch(setdiff(isynth,dsearchn(synth.PRES.value,x)))=1;
        % keep nearest data (can be two points) and remove all other that
        % are further away
        inomatch=true(length(spresaxis),1);
        if length(spresaxis)==1 % just one value on synthetic pressure axis
            %neardp=abs(synth.PRES.value-x(uind)); % on original sampling axis
            neardp=abs(spresaxis-x(uind)); % on original sampling axis
        else % more than one value on synthetic pressure axis
            %neardp=abs(synth.PRES.value(dsearchn(synth.PRES.value/1e3,x(uind)/1e3))-x(uind)); % on original sampling axis
            neardp=abs(spresaxis(dsearchn(double(spresaxis)/1e3,double(x(uind))/1e3))-x(uind)); % on original sampling axis
        end
        for k=1:length(uind)
            %inomatch(abs(synth.PRES.value-x(uind(k)))==neardp(k))=0; 
            inomatch(abs(spresaxis-x(uind(k)))==neardp(k))=0; 
        end
        %% decide which data to really remove
        iremove=inomatch;
        % keep all interpolated core-data within [max(pres)-2 dbar float length; min(pres)+1 dbar antenna length]
        if addTSeverywhere && ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'})
            if ismember(ubgcparams{i},{'PRES'})
                iremove(:)=0; % don't remove any interpolated/extrapolated PRES
            else % TEMP, PSAL
                % if there are valid data before or after, keep those in between, too
                %iremove(cumsum(~iremove,'forward')>0 & cumsum(~iremove,'reverse')>0)=0;
                % keep all within pressure range: extrapolate deepest data
                % point up to 1 float length (2 dbar) deeper and shallowest
                % data point up to 1 antenna length (1 dbar) shallower
                iremove(spresaxis<=max(x)+2*1000 & spresaxis>=min(x)-1*1000)=0;
            end
        end
        
        % keep an isolated hole between data
        % standard case: 1 isolated hole between two data before and after
        if nos>=5
            iremove(find(inomatch(3:nos-2) & ~inomatch(1:nos-4) & ~inomatch(2:nos-3) & ~inomatch(4:nos-1) & ~inomatch(5:nos))+2)=0;
        end
        if nos>=4
            % special case: 'data point # 2' and 'data point # end-1'
            iremove(find(inomatch(2) & ~inomatch(1) & ~inomatch(3) & ~inomatch(4))+1)=0;
            iremove(find(inomatch(nos-1) & ~inomatch(nos-3) & ~inomatch(nos-2) & ~inomatch(nos))+nos-2)=0;
        end
        if nos>2
            % special case: shallowest data point: up to 1 float length (2
            % dbar) and deepest data point: up to 1 antenna length (1 dbar)
            %iremove(find(inomatch(1) & ~inomatch(2) & ~inomatch(3) & diff(synth.PRES.value([1 2]))<=2*1000))=0;
            %iremove(find(inomatch(nos) & ~inomatch(nos-2) & ~inomatch(nos-1) & diff(synth.PRES.value([nos-1 nos]))<=1*1000)+nos-1)=0;
            iremove(find(inomatch(1) & ~inomatch(2) & ~inomatch(3) & diff(spresaxis([1 2]))<=2*1000))=0;
            iremove(find(inomatch(nos) & ~inomatch(nos-2) & ~inomatch(nos-1) & diff(spresaxis([nos-1 nos]))<=1*1000)+nos-1)=0;
        end
        
        if ismember(ubgcparams{i},{'PRES'})
            %synth.(ubgcparams{i}).value(iremove)=FV;
        else
            synth.(ubgcparams{i}).value(iremove)=NaN;
            synth.([ubgcparams{i} '_QC']).value(iremove)=NaN;
            %synth.([ubgcparams{i} '_dPRES']).value(iremove)=FV;
            % assign QC flag to gap in a series points
            %synth.([ubgcparams{i} '_QC']).value(inomatch & ~iremove)=8;
            %fillind=inomatch & ~iremove & ~ismember(synth.([ubgcparams{i} '_QC']).value,[3 4]);
            %fillind=inomatch & ~iremove & ~(ismember(synth.([ubgcparams{i} '_QC']).value,[3 4]) | isnan(synth.(ubgcparams{i} ).value));
            fillind=inomatch & ~iremove & ~(ismember(synth.([ubgcparams{i} '_QC']).value,[0 3 4]) | isnan(synth.(ubgcparams{i} ).value));
            synth.([ubgcparams{i} '_QC']).value(fillind)=8;
        end % PRES (int32) or not (double)
        clear y yqc uind inomatch iremove fillind
        
        %% check dPRES assignment
        % and add pressure difference where it is missing (and there are data)
        fillind=find(~isnan(synth.([ubgcparams{i} '_QC']).value) & synth.([ubgcparams{i} '_dPRES']).value==FV);
        % if there are two nearest samples, take the deeper one..
        for k=1:length(fillind)
            dp=x-spresaxis(fillind(k)); % deeper sample of minimum pressure difference
            synth.([ubgcparams{i} '_dPRES']).value(fillind(k))=dp(find(abs(dp)==min(abs(dp)),1,'last'));
            %%synth.([ubgcparams{i} '_dPRES']).value(synth.([ubgcparams{i} '_dPRES']).value==FV)=x(uind(nearind(synth.([ubgcparams{i} '_dPRES']).value==FV)))-spresaxis(synth.([ubgcparams{i} '_dPRES']).value==FV);
            %dpind=abs(x-spresaxis(k))==abs(x(uind(nearind(k)))-spresaxis(k)); % points with same distance and to be used (not in low priority nprofs)
            %synth.([ubgcparams{i} '_dPRES']).value(k)=max(x(dpind))-spresaxis(k); % take deeper value if there are any two samples at +/- the same distance
            %clear dpind
        end
        clear x xqc fillind dp
    
    if ~isempty(yadj) % not only NaN/FV adjusted data
        % use only non-overlapping portion 
        xadj=xadj(overlapadj);yadj=yadj(overlapadj);yadjqc=yadjqc(overlapadj);yadjerr=yadjerr(overlapadj);
        clear overlapadj
        % make monotonic for interpolation (looses nprof priority!)
        [~,ind]=sort(xadj); % monotonic sorting
        xadj=xadj(ind);yadj=yadj(ind);yadjqc=yadjqc(ind);yadjerr=yadjerr(ind);
        % and make sure that they are column vectors
        xadj=xadj(:);yadj=yadj(:);yadjqc=yadjqc(:);yadjerr=yadjerr(:);
        
        %% do the same with adjusted fields
        %% copy data for levels that are part of the synthetic pressure axis:
        [~,fillindadj,cpindadj]=intersect(spresaxis,xadj);
        synth.([ubgcparams{i} '_ADJUSTED']).value(fillindadj)=yadj(cpindadj);
        synth.([ubgcparams{i} '_ADJUSTED_QC']).value(fillindadj)=yadjqc(cpindadj);
        synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=yadjerr(cpindadj);
        %if ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'}) % keep which BGC PTS were truly measured for later
        %    full.(ubgcparams{i}).fillindadj=fillindadj;
        %end
        clear fillindadj cpindadj
        
        %% rest of data:
        % interpolate data for other levels of the synthetic pressure axis:
        % toss away repeated occurence of pressures: e.g., MD5904767_004.nc PSAL @ 46.0 dbar
        if ismember(ubgcparams{i},{'PRES'})
            [~,uindadj]=unique(xadj);
        else
            uindadj=1:length(xadj); % should have been dealt with by overlapping portions already
        end
        if length(xadj(uindadj))>1
            % data interpolation: linear, no extrapolation
            synth.([ubgcparams{i} '_ADJUSTED']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))=interp1(double(xadj(uindadj)),double(yadj(uindadj)),double(spresaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))),'linear',NaN);
            % data extrapolation: nearest-neighbour, no limit on extrapolation
            if ismember(ubgcparams{i},{'PRES'}) % PRES_ADJUSTED extrapolation as nearest-neighbour does not work.. use linear extrapolation
                synth.([ubgcparams{i} '_ADJUSTED']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))=interp1(double(xadj(uindadj)),double(yadj(uindadj)),double(spresaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))),'linear','extrap');
            else % nearest-neighbour
                synth.([ubgcparams{i} '_ADJUSTED']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))=interp1(double(xadj(uindadj)),double(yadj(uindadj)),double(spresaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))),'nearest','extrap');
            end
            if yadjerrpresence % same with errors if any
                synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))=interp1(double(xadj(uindadj)),double(yadjerr(uindadj)),double(spresaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))),'linear',NaN);
                synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))=interp1(double(xadj(uindadj)),double(yadjerr(uindadj)),double(spresaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))),'nearest','extrap');
            end
            % deal with qc
            % qc interpolation: next and previous, no extrapolation
            qcnextadj=interp1(double(xadj(uindadj)),yadjqc(uindadj),double(spresaxis),'next',NaN);
            qcpreviousadj=interp1(double(xadj(uindadj)),yadjqc(uindadj),double(spresaxis),'previous',NaN);
            % take maximum of QC; order 1 < 2 < 5 < 3 < 4
            qcnextadj(qcnextadj==5)=2.5; qcpreviousadj(qcpreviousadj==5)=2.5; % replace QC 5 with 2.5: 
            qcfilladj=max(qcnextadj,qcpreviousadj); % max for interpolated QC
            synth.([ubgcparams{i} '_ADJUSTED_QC']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value))=qcfilladj(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value));
            synth.([ubgcparams{i} '_ADJUSTED_QC']).value(synth.([ubgcparams{i} '_ADJUSTED_QC']).value==2.5)=5; % and reverse QC 5
            % qc extrapolation: nearest-neighbour, no limit on extrapolation
            synth.([ubgcparams{i} '_ADJUSTED_QC']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value))=interp1(double(xadj(uindadj)),yadjqc(uindadj),double(spresaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value))),'nearest','extrap');
            clear qcnextadj qcpreviousadj qcfilladj
        elseif ~isempty(xadj) % only one value, keep this value, its error, and its QC, and place it closest to the original pressure
            [~,ifill]=min(abs(spresaxis-xadj));
            synth.([ubgcparams{i} '_ADJUSTED']).value(ifill)=yadj(uindadj);
            if yadjerrpresence % same with errors if any
                synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(ifill)=yadjerr(uindadj);
            end
            synth.([ubgcparams{i} '_ADJUSTED_QC']).value(ifill)=yadjqc(uindadj);
        else % no adjusted value left from overlapping portions
            % do nothing
        end    
        %% and kick out unmatched data
        inomatch=true(length(spresaxis),1);
        %neardp=abs(synth.PRES.value(dsearchn(synth.PRES.value/1e3,xadj(uindadj)/1e3))-xadj(uindadj)); % on original sampling axis
        neardp=abs(spresaxis(dsearchn(double(spresaxis)/1e3,double(xadj(uindadj))/1e3))-xadj(uindadj)); % on original sampling axis
        for k=1:length(uindadj)
            %inomatch(abs(synth.PRES.value-xadj(uindadj(k)))==neardp(k))=0; 
            inomatch(abs(spresaxis-xadj(uindadj(k)))==neardp(k))=0; 
        end
        %% decide which data to really remove
        iremove=inomatch;
        % keep all interpolated core-data within [max(pres)-2 dbar float length; min(pres)+1 dbar antenna length]
        if addTSeverywhere && ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'})
            if ismember(ubgcparams{i},{'PRES'})
                iremove(:)=0; % don't remove any interpolated/extrapolated PRES_ADJUSTED
            else % TEMP, PSAL
                % if there are valid data before or after, keep those in between, too
                %iremove(cumsum(~iremove,'forward')>0 & cumsum(~iremove,'reverse')>0)=0;
                % keep all within pressure range: extrapolate deepest data
                % point up to 1 float length (2 dbar) deeper and shallowest
                % data point up to 1 antenna length (1 dbar) shallower
                iremove(spresaxis<=max(xadj)+2*1000 & spresaxis>=min(xadj)-1*1000)=0;
            end
        end
        
        % but only if it's not an isolated hole between data
        % standard case: 1 isolated hole between two data before and after
        if nos>=5
            iremove(find(inomatch(3:nos-2) & ~inomatch(1:nos-4) & ~inomatch(2:nos-3) & ~inomatch(4:nos-1) & ~inomatch(5:nos))+2)=0;
        end
        if nos>=4
            % special case: 'data point # 2' and 'data point # end-1'
            iremove(find(inomatch(2) & ~inomatch(1) & ~inomatch(3) & ~inomatch(4))+1)=0;
            iremove(find(inomatch(nos-1) & ~inomatch(nos-3) & ~inomatch(nos-2) & ~inomatch(nos))+nos-2)=0;
        end
        if nos>2
            % special case: shallowest data point: up to 1 float length (2
            % dbar) and deepest data point: up to 1 antenna length (1 dbar)
            %iremove(find(inomatch(1) & ~inomatch(2) & ~inomatch(3) & diff(synth.PRES.value([1 2]))<=2*1000))=0;
            %iremove(find(inomatch(nos) & ~inomatch(nos-2) & ~inomatch(nos-1) & diff(synth.PRES.value([nos-1 nos]))<=1*1000)+nos-1)=0;
            iremove(find(inomatch(1) & ~inomatch(2) & ~inomatch(3) & diff(spresaxis([1 2]))<=2*1000))=0;
            iremove(find(inomatch(nos) & ~inomatch(nos-2) & ~inomatch(nos-1) & diff(spresaxis([nos-1 nos]))<=1*1000)+nos-1)=0;
        end
        %if ismember(ubgcparams{i},{'PRES'})
        %    synth.(ubgcparams{i}).value(iremove)=FV;
        %else
        synth.([ubgcparams{i} '_ADJUSTED']).value(iremove)=NaN;
        %end % PRES (int32) or not (double)
        synth.([ubgcparams{i} '_ADJUSTED_QC']).value(iremove)=NaN;
        % assign QC flag to gap in a series points
        %synth.([ubgcparams{i} '_ADJUSTED_QC']).value(inomatch & ~iremove)=8;
        %fillind=inomatch & ~iremove & ~ismember(synth.([ubgcparams{i} '_ADJUSTED_QC']).value,[3 4]);
        %fillind=inomatch & ~iremove & ~(ismember(synth.([ubgcparams{i} '_ADJUSTED_QC']).value,[3 4]) | isnan(synth.([ubgcparams{i} '_ADJUSTED']).value));
        fillind=inomatch & ~iremove & ~(ismember(synth.([ubgcparams{i} '_ADJUSTED_QC']).value,[0 3 4]) | isnan(synth.([ubgcparams{i} '_ADJUSTED']).value));
        if ~ismember(ubgcparams{i},{'PRES'}) % don't tap with '8' for PRES_ADJUSTED: location, not really data
        synth.([ubgcparams{i} '_ADJUSTED_QC']).value(fillind)=8;
        end
        synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(iremove)=NaN;
        clear xadj xadjqc yadj yadjqc yadjerr yadjerrpresence uindadj inomatch fillind
    end % ~isempty(yadj) : some adjusted data available
    end % ~isempty(y) : some data available
    %% and convert parameter dPRES back to proper 1/1000 double
    fillind=synth.([ubgcparams{i} '_dPRES']).value==FV;
	synth.([ubgcparams{i} '_dPRES']).value=double(synth.([ubgcparams{i} '_dPRES']).value)./1000;
    synth.([ubgcparams{i} '_dPRES']).value(fillind)=NaN;
    clear fillind
end % fill in data in synthetic profile

end % core and presaxis empty


%% add synthetic profile to merged data with full dimension, BGC levels interleaved
fnames=fieldnames(synth); % use non-interleaved profile as template; fill gaps with NaN
%for i=2:length(fnames) % start at index 2: first one is PRES=presaxis -> already present
for i=1:length(fnames) % start at index 1: first one is PRES=presmerge -> copy all to be sure
    synthfull.(fnames{i}).value=ones(nosf,1)*NaN;
    if ismember(fnames{i},{'PRES';'TEMP';'PSAL';'PRES_QC';'TEMP_QC';'PSAL_QC';'PRES_ADJUSTED';'TEMP_ADJUSTED';'PSAL_ADJUSTED';'PRES_ADJUSTED_QC';'TEMP_ADJUSTED_QC';'PSAL_ADJUSTED_QC';'PRES_ADJUSTED_ERROR';'TEMP_ADJUSTED_ERROR';'PSAL_ADJUSTED_ERROR';'PRES_dPRES';'TEMP_dPRES';'PSAL_dPRES'}) % core already on full axis
        synthfull.(fnames{i}).value=synth.(fnames{i}).value;
    else % BGC on synthetic pressure axis
        synthfull.(fnames{i}).value(synthind)=synth.(fnames{i}).value;
    end % already on full axis (core)?
end % cycle fields

%% and convert PRES back to proper 1/1000 double
fillind=synthfull.PRES.value==FV;
synthfull.PRES.value=double(synthfull.PRES.value)./1000;
synthfull.PRES.value(fillind)=NaN;

%% sanity-check ADJUSTED_QC in case of ADJUSTED=FV
for i=1:length(ubgcparams)
    if ~all(isnan(synthfull.([ubgcparams{i} '_ADJUSTED']).value)) && ~all(isnan(synthfull.([ubgcparams{i} '_ADJUSTED_QC']).value))
        fillind=~isnan(synthfull.(ubgcparams{i}).value) & isnan(synthfull.([ubgcparams{i} '_ADJUSTED']).value) & isnan(synthfull.([ubgcparams{i} '_ADJUSTED_QC']).value);
        synthfull.([ubgcparams{i} '_ADJUSTED_QC']).value(fillind)=4;
    end % adjusted data or adjusted_QC are present?
end


