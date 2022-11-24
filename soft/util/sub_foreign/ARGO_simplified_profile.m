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
% - interleave non-BGC level T/s profile for full T/S resolution
%
% inputs: - 'bfilepath' (mandatory)
%         - 'cfilepath', 'metafilepath' (optional)
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


if nargin<1 || isempty(varargin)
    varargin{1}='bfilepath';varargin{2}='D:\Science\resources\Bio-Argo\files\BR6901485_049.nc';
    %varargin{1}='bfilepath';varargin{2}='D:\Science\resources\Bio-Argo\files\BR6901585_013.nc';
    %varargin{1}='bfilepath';varargin{2}='D:\Science\resources\Bio-Argo\files\BD5904104_004.nc';
    %varargin{1}='bfilepath';varargin{2}='D:\Science\resources\Bio-Argo\files\BD1901348_008.nc';
    %varargin{1}='bfilepath';varargin{2}='D:\Science\resources\Bio-Argo\files\BR6900889_016.nc';
    %varargin{1}='bfilepath';varargin{2}='D:\Science\resources\Bio-Argo\files\BR4900484_003.nc';
end

includeTSflag=0;
addTSeverywhere=1;
verbose=0;
addoffsetflag=1;  % add pressure sensor vertical pressure offset to PRES

fieldsuffixvarname={'PRES';'BBP[0-9]+';'BISULFIDE';'CDOM';'CHLA';'CP[0-9]+';'DOWN_IRRADIANCE[0-9]+';'DOWNWELLING_PAR';'DOXY';'NITRATE';'PH_IN_SITU_TOTAL';'TURBIDITY';'UP_RADIANCE[0-9]+';};
%% get file names
bfilepath='';cfilepath='';metafilepath='';
for i=1:floor(length(varargin)/2)
    switch varargin{2*i-1}
        case 'bfilepath'
            bfilepath=varargin{2*i};
        case 'cfilepath'
            cfilepath=varargin{2*i};
        case 'metafilepath'
            metafilepath=varargin{2*i};
    end
end
if isempty(cfilepath) 
% figure out name of the corresponding core file
[basepath,fname]=fileparts(bfilepath);
fnamec=dir([basepath filesep 'R' fname(3:end) '.nc']);
if isempty(fnamec), fnamec=dir([basepath filesep 'D' fname(3:end) '.nc']); end
cfilepath=[basepath filesep fnamec.name];
end    

%% load b-file netcdf into convenient structure
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
S=rmfield(S,fnames(fnamesind));
%% load c-file netcdf and add core data into convenient structure
C=lov_netcdf_pickprod(cfilepath); % load core file
fnamec=setdiff(fieldnames(C),fieldnames(S)); % find core parameter names
for i=1:length(fnamec), S.(fnamec{i})=C.(fnamec{i}); end % copy core data to bio data
%% make sure first dimension is size of field, i.e., STRING16/STRING64 for
% PARAMETER and STATION_PARAMETER in c- and b-file
% (e.g. CS 1901348: 2nd dimension)
%% core file
% dimnames must be fliplr of user manual description:
% 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING16);'
indstr={'STRING16';'N_PARAM';'N_CALIB';'N_PROF'};
indperm=ones(ndims(C.PARAMETER.value),1)*NaN; 
try
    for i=1:length(indperm), indperm(i)=find(strcmpi(C.PARAMETER.dimname,indstr{i})); end
catch me
    disp(['S-PROF_ERROR: Could not figure out N_DIMs order of core file PARAMETER field with dimensions: ' strjoin(C.PARAMETER.dimname,', ')])
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
    disp(['S-PROF_ERROR: Could not figure out N_DIMs order of core file STATION_PARAMETERS field with dimensions: ' strjoin(C.PARAMETER.dimname,', ')])
end
C.STATION_PARAMETERS.value=permute(C.STATION_PARAMETERS.value,indperm);
C.STATION_PARAMETERS.dimname=C.STATION_PARAMETERS.dimname(indperm);
C.STATION_PARAMETERS.dimvalue=C.STATION_PARAMETERS.dimvalue(indperm);
%% b-file
% 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING64);'
indstr={'STRING64';'N_PARAM';'N_CALIB';'N_PROF'};
indperm=ones(ndims(S.PARAMETER.value),1)*NaN; 
try
    for i=1:length(indperm), indperm(i)=find(strcmpi(S.PARAMETER.dimname,indstr{i})); end
catch me
    disp(['S-PROF_ERROR: Could not figure out N_DIMs order of bio file PARAMETER field with dimensions: ' strjoin(C.PARAMETER.dimname,', ')])
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
    disp(['S-PROF_ERROR: Could not figure out N_DIMs order of bio file STATION_PARAMETERS field with dimensions: ' strjoin(C.PARAMETER.dimname,', ')])
end
S.STATION_PARAMETERS.value=permute(S.STATION_PARAMETERS.value,indperm);
S.STATION_PARAMETERS.dimname=S.STATION_PARAMETERS.dimname(indperm);
S.STATION_PARAMETERS.dimvalue=S.STATION_PARAMETERS.dimvalue(indperm);
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
        
    else % core and bio N_PROF: Join core and bio parameters
        S.PARAMETER.value(1:size(C.PARAMETER.value(:,:,1,i),1),size(S.PARAMETER.value(:,:,1,i),2)+(2:size(C.PARAMETER.value(:,:,1,i),2))-1,1:size(C.PARAMETER.value(:,:,1,i),3),i)=C.PARAMETER.value(:,2:end,1,i);
    end
end
%%}
clear fnamec C fnames fnamesind

%% get bgcparams names and N_PROFs
[noNLEVELs,noNPROFs]=size(S.PRES_QC.value);
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

%% make check: are there bgc-params in the file??
if isempty(ubgcparams) % there are no bgc-params to align
disp(['S-PROF_INFO: No b-parameters found in ' bfilepath])
synthfull=[];
return
end

%% load meta file / check existence
if isempty(metafilepath)
% figure out location of the corresponding meta file
[basepath,~]=fileparts(bfilepath);
metafilepath=[basepath filesep char(cellstr(S.PLATFORM_NUMBER.value(1,:))) '_meta.nc'];
if ~(exist(metafilepath,'file'))
metafilepath=[basepath filesep '..' filesep char(cellstr(S.PLATFORM_NUMBER.value(1,:))) '_meta.nc'];
end
end

C=[];
%infields={'LAUNCH_CONFIG_PARAMETER_NAME';'LAUNCH_CONFIG_PARAMETER_VALUE';'CONFIG_MISSION_NUMBER';'CONFIG_PARAMETER_NAME';'CONFIG_PARAMETER_VALUE'};
infields={'LAUNCH_CONFIG_PARAMETER_NAME';'LAUNCH_CONFIG_PARAMETER_VALUE';'PARAMETER';'PARAMETER_SENSOR';'FORMAT_VERSION'};
try 
    C=lov_netcdf_pickprod(metafilepath,infields);
catch me
    % failed to locate meta file
    disp(['S-PROF_ERROR: Could not find meta file ' metafilepath])
    synthfull=[];
    return
end
if isempty(C)
    disp(['S-PROF_ERROR: Could not find meta file ' strtrim(S.PLATFORM_NUMBER.value(1,:)) '_meta.nc in current or parent folder.'])
    synthfull=[];
    return
end % meta file exists


%% there are b-params to align and all infos are there, do the actual work

%% use copy of pressure to work with; rounded to 1/1000 to avoid numerical ..1e-6 issues
FV=-99999;
S.PRES.value=int32(1000*S.PRES.value); % cast truly to "1/1000" integer to avoid numerical ..1e-6 issues
inpres0=S.PRES.value; % keep a copy of pressure without vertical offset correction
inpres=S.PRES.value; % use copy of pressure to work with

% double check pressure inversion test in profile (in a simplistic way): 
% Mustn't have repeated pressure levels with PRES_QC 0..3
% sometimes not properly flagged, e.g., D5903712_149.nc
pinversion=false(size(S.PRES.value));
if any(size(S.PRES.value)~=size(S.PRES_QC.value))
    disp(['S-PROF_ERROR: PRES (bio) and PRES_QC (core) dimensions don''t match ' bfilepath])
    synthfull=[];
    return
end

ind=~isnan(S.PRES.value) & ismember(S.PRES_QC.value,[0 1 2 3]);
for i=1:size(S.PRES.value,2)
    pinversion(ind(:,i),i)=[diff(S.PRES.value(ind(:,i),i))<=0;0];
end
%pinversion=pinversion & ismember(S.PRES_QC.value,[0 1 2 3]);
if any(pinversion(:))
    disp(['S-PROF_WARNING: Found ' num2str(sum(pinversion(:))) ' levels with unflagged pressure inversions. Flag with PRES_QC=4.'])
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
            %disp(['S-PROF_WARNING: Found ' num2str(sum(pinversion(:))) ' more levels with unflagged pressure inversions. Flag with PRES_QC=4.'])
            S.PRES_QC.value(pinversion)=4;
            pnum=pnum+sum(pinversion(:));
        end
    end % while
    if pnum, disp(['S-PROF_WARNING: Found ' num2str(pnum) ' more levels with unflagged pressure inversions. Flag with PRES_QC=4.']), end
end % first iteration
clear pinversion ind pnum

% sort out pressure axis and which N_PROF to use
% only use PRES_QC 0..3, ignore PRES_QC=4
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
        if verbose, disp(['S-PROF_INFO: Found ' num2str(length(ind)) ' VerticalOffsets']); end
        % get short sensor names and vertical offsets
        cpnames=strrep(strrep(cellstr(lower(names(ind,:))),lower(cnames{1}),''),lower('CONFIG_'),'');
        voffset=values(ind);
        try % get corresponding full-length sensor name: index to param_sensors / sensors
            sensorind=cellfun(@(x)find(~cellfun(@isempty,strfind(lower(sensors),lower(x)))),cpnames);
        catch me
            disp(['S-PROF_ERROR: Could not identify some short sensor name ' strjoin(cpnames,'; ')])
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
                %disp(['S-PROF_ERROR: Could not identify parameter with sensor name(s) ' strjoin(cellstr(snames),', ')])
                %disp(['S-PROF_ERROR: Skipping vertical offset of ' num2str(voffset(i)) ' dbar for ' strjoin(cellstr(snames),', ')])
                %keyboard
                %synthfull=[];
                %return
                disp(['S-PROF_WARNING: Could not identify parameter with sensor name(s) ' strjoin(cellstr(snames),', ') '; Skipping vertical offset of ' num2str(voffset(i)) ' dbar'])
                
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
        if verbose, disp(['S-PROF_INFO: Found no verticalOffsets']), end
        voff.linbgcparams={};voff.linvoffset=[];
    end % config name found
    clear ind cnames names values
else
	disp(['S-PROF_INFO: Could not find LAUNCH_CONFIG_PARAMETER_NAME in meta file (FORMAT_VERSION ' C.FORMAT_VERSION.value '). No vertical sensor offsets corrected.'])
    voff.linbgcparams={};voff.linvoffset=[];
end % LAUNCH_CONFIG_PARAMETER_NAME
end % addoffsetflag
%%}
%clear C 

% get unique pressures (with or without TEMP/PSAL-only levels; see above)
%upres=unique(inpres(~isnan(inpres)));
upres=unique(inpres(inpres~=FV));
if isempty(upres)
    disp(['S-PROF_INFO: Found BGC N_PROF(s) with b-parameter(s) ' strjoin(ubgcparams,' ') ', but without any PRES_QC=0..3 and non-FillValue BGC data. Don''t create synthetic profile.'])
    synthfull=[];
    return
end
% and check which pressure levels are present in which profile
prespresent=false(length(upres),size(inpres,2));
for i=1:size(inpres,2),prespresent(:,i)=ismember(upres,inpres(:,i));end

% verify that there are BGC observations, not just BGC N_PROFs
if ~any(prespresent(:))
    disp(['S-PROF_INFO: Found BGC N_PROF(s) with b-parameter(s) ' strjoin(ubgcparams,' ') ', but without any non-FillValue data. Don''t create synthetic profile.'])
    synthfull=[];
    return
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
            disp(['S-PROF_ERROR: Trouble during creation of synthetic pressure axis'])
            synthfull=[];
            return
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
        disp(['S-PROF_ERROR: Exceeded maximum number of iterations in selection of synthetic pressure levels. Should not happen...'])
        synthfull=[];
        return
    end
end
clear niter nitermax
presaxis=upres(useind);
end % pressure axis cycle from bottom possible?
%% done with synthetic pressure axis construction, now fill/align BGC data


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
    disp(['S-PROF_WARNING: Could not find PARAMETER_SENSOR in meta file (FORMAT_VERSION ' C.FORMAT_VERSION.value '). Kept N_PROF order as in profile file.'])
    asort=1:noNPROFs;
end % define N_PROF priority

%% define core parameters
coreparams={'PRES';'TEMP';'PSAL'};

%% start to fill in data
%ubgcparams=cat(1,{'PRES';'TEMP';'PSAL'},ubgcparams);

isynth=(1:length(presaxis))'; % index 1..length synthetic pressure axis
nos=length(isynth);
% DOXY/<PARAM> can sit in more than one N_PROF, so need to be a bit more
% clunky than just simply interpolating a single N_PROF which contains
% <PARAM>
%xpres=S.PRES.value(:,asort); % rearrange pressure obeying nprof priority
xpresqc=pflag(:,asort); % and flag to pressure that are not QC=4
synth.PRES.value=presaxis;
% fill in data in synthetic profile
for i=1:length(ubgcparams)
    
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
        indadj=~isnan(yadj(:,k)) & xpresqc(:,k);
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
        indadj=~isnan(yadj(:,k)) & xpresqc(:,k);
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
    end % check for overlapping portion
    %% do not use <PARAM>_QC of 8 or FillValue
    yflagqc=ismember(yqc,[0 1 2 3 4 5]);
    if ismember(ubgcparams{i},{'PRES'}), yflagnoFV=y~=FV; % double check PRES FV
    else, yflagnoFV=~isnan(y); end % and other FV (e.g., BR5900952_157, DOXY all NaN but QC=0)
    yflagadjqc=ismember(yadjqc,[0 1 2 3 4 5]);
    yflagadjnoFV=~isnan(yadj); % double check FV
    
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
    
    %% preallocate
    if ismember(ubgcparams{i},{'PRES'})
        synth.(ubgcparams{i}).value=int32(ones(size(presaxis))*FV);
    else
        synth.(ubgcparams{i}).value=double(presaxis)*NaN;
    end
    synth.([ubgcparams{i} '_QC']).value=double(presaxis)*NaN;
    %if ~isempty(yadj) % preallocate only if present
    synth.([ubgcparams{i} '_ADJUSTED']).value=double(presaxis)*NaN;
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value=double(presaxis)*NaN;
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value=double(presaxis)*NaN;
    %end
    synth.([ubgcparams{i} '_dPRES']).value=int32(ones(size(presaxis))*FV);
        
    if ~isempty(y) % not only NaN/FV data
    %% copy data for levels that are part of the synthetic pressure axis:
    % get indices to which data to copy
    % take only 'first' occurence (in nprof-priority sorted record!) and
    % toss away repeated occurences (e.g., MD5904767_004.nc PSAL @ 46.0 dbar) 
    [~,fillind,cpind]=intersect(presaxis,x);
    synth.(ubgcparams{i}).value(fillind)=y(cpind);
    synth.([ubgcparams{i} '_QC']).value(fillind)=yqc(cpind);
    synth.([ubgcparams{i} '_dPRES']).value(fillind)=0;
    if ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'}) % keep which BGC PTS were truly measured for later
        full.(ubgcparams{i}).fillind=fillind;
    end
    clear fillind cpind
    
    %% rest of data:
    % use only non-overlapping portion 
    x=x(overlap);y=y(overlap);yqc=yqc(overlap);
    clear overlap
    % make monotonic for interpolation (looses nprof priority! But non-overlapping anyway)
    [~,ind]=sort(x); % monotonic sorting
    x=x(ind);y=y(ind);yqc=yqc(ind);
    % and make sure that they are column vectors
    x=x(:);y=y(:);yqc=yqc(:);
    % interpolate data for other levels of the synthetic pressure axis:
    % toss away repeated occurence of pressures: e.g., MD5904767_004.nc PSAL @ 46.0 dbar
    if ismember(ubgcparams{i},{'PRES'})
        [~,uind]=unique(x);
    else
        uind=1:length(x); % should have been dealt with by overlapping portions already
    end
    if length(x)>1 
    % data interpolation: linear, no extrapolation
    synth.(ubgcparams{i}).value(isnan(synth.(ubgcparams{i}).value))=interp1(double(x(uind)),double(y(uind)),double(presaxis(isnan(synth.(ubgcparams{i}).value))),'linear',NaN);
    % data extrapolation: nearest-neighbour
    synth.(ubgcparams{i}).value(isnan(synth.(ubgcparams{i}).value))=interp1(double(x(uind)),double(y(uind)),double(presaxis(isnan(synth.(ubgcparams{i}).value))),'nearest','extrap');
    % deal with qc
    % qc interpolation: next and previous, no extrapolation
    qcnext=interp1(double(x(uind)),yqc(uind),double(presaxis),'next',NaN);
    qcprevious=interp1(double(x(uind)),yqc(uind),double(presaxis),'previous',NaN);
    % take maximum of QC; order 1 < 2 < 5 < 3 < 4
    qcnext(qcnext==5)=2.5; qcprevious(qcprevious==5)=2.5; % replace QC 5 with 2.5: 
    qcfill=max(qcnext,qcprevious); % max for interpolated QC
    synth.([ubgcparams{i} '_QC']).value(isnan(synth.([ubgcparams{i} '_QC']).value))=qcfill(isnan(synth.([ubgcparams{i} '_QC']).value));
    synth.([ubgcparams{i} '_QC']).value(synth.([ubgcparams{i} '_QC']).value==2.5)=5; % and reverse QC 5
    % qc extrapolation: nearest-neighbour
    synth.([ubgcparams{i} '_QC']).value(isnan(synth.([ubgcparams{i} '_QC']).value))=interp1(double(x(uind)),yqc(uind),double(presaxis(isnan(synth.([ubgcparams{i} '_QC']).value))),'nearest','extrap');
    clear qcnext qcprevious qcfill
    else % only one value, keep this value as well as its QC, and place it closest to the original pressure
        [~,ifill]=min(abs(presaxis-x));
        synth.(ubgcparams{i}).value(ifill)=y;
        synth.([ubgcparams{i} '_QC']).value(ifill)=yqc;
    end
    %% and kick out unmatched data
    %inomatch=false(nos,1); inomatch(setdiff(isynth,dsearchn(synth.PRES.value,x)))=1;
    % keep nearest data (can be two points) and remove all other that
    % are further away
    inomatch=true(nos,1);
    if length(presaxis)==1
    neardp=abs(synth.PRES.value-x(uind)); % on original sampling axis
    else
    neardp=abs(synth.PRES.value(dsearchn(synth.PRES.value,x(uind)))-x(uind)); % on original sampling axis
    end
    for k=1:length(uind), 
        inomatch(abs(synth.PRES.value-x(uind(k)))==neardp(k))=0; 
    end
    %% but only if it's not an isolated hole between data
    iremove=inomatch;
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
        iremove(find(inomatch(1) & ~inomatch(2) & ~inomatch(3) & diff(synth.PRES.value([1 2]))<=2*1000))=0;
        iremove(find(inomatch(nos) & ~inomatch(nos-2) & ~inomatch(nos-1) & diff(synth.PRES.value([nos-1 nos]))<=1*1000)+nos-1)=0;
    end
    if addTSeverywhere
        if ismember(ubgcparams{i},{'TEMP';'PSAL'})
            iremove(:)=0; % don't remove any interpolated data, but give them a QC 8
        end
    end
    if ismember(ubgcparams{i},{'PRES'})
        synth.(ubgcparams{i}).value(iremove)=FV;
    else
        synth.(ubgcparams{i}).value(iremove)=NaN;
    end % PRES (int) or not (double)
    synth.([ubgcparams{i} '_QC']).value(iremove)=NaN;
    %synth.([ubgcparams{i} '_dPRES']).value(iremove)=FV;
    synth.([ubgcparams{i} '_QC']).value(inomatch & ~iremove)=8;
    clear y yqc uind inomatch iremove
    
    %% check dPRES assignment
    % and add pressure difference where it is missing (and there are data)
    fillind=find(~isnan(synth.([ubgcparams{i} '_QC']).value) & synth.([ubgcparams{i} '_dPRES']).value==FV);
    % if there are two nearest samples, take the deeper one..
    for k=1:length(fillind)
        dp=x-presaxis(fillind(k)); % deeper sample of minimum pressure difference
        synth.([ubgcparams{i} '_dPRES']).value(fillind(k))=dp(find(abs(dp)==min(abs(dp)),1,'last'));
        %%synth.([ubgcparams{i} '_dPRES']).value(synth.([ubgcparams{i} '_dPRES']).value==FV)=x(uind(nearind(synth.([ubgcparams{i} '_dPRES']).value==FV)))-presaxis(synth.([ubgcparams{i} '_dPRES']).value==FV);
        %dpind=abs(x-presaxis(k))==abs(x(uind(nearind(k)))-presaxis(k)); % points with same distance and to be used (not in low priority nprofs)
        %synth.([ubgcparams{i} '_dPRES']).value(k)=max(x(dpind))-presaxis(k); % take deeper value if there are any two samples at +/- the same distance
        %clear dpind
    end
    clear x xqc fillind dp
    %% check dPRES assignment    
    
    if ~isempty(yadj) % not only NaN/FV adjusted data
    %% do the same with adjusted fields
    %% copy data for levels that are part of the synthetic pressure axis:
    [~,fillindadj,cpindadj]=intersect(presaxis,xadj);
    synth.([ubgcparams{i} '_ADJUSTED']).value(fillindadj)=yadj(cpindadj);
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(fillindadj)=yadjqc(cpindadj);
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=yadjerr(cpindadj);
    if ismember(ubgcparams{i},{'PRES';'TEMP';'PSAL'}) % keep which BGC PTS were truly measured for later
        full.(ubgcparams{i}).fillindadj=fillindadj;
    end
    clear fillindadj cpindadj
    
    %% rest of data:
    % use only non-overlapping portion 
    xadj=xadj(overlapadj);yadj=yadj(overlapadj);yadjqc=yadjqc(overlapadj);yadjerr=yadjerr(overlapadj);
    clear overlapadj
    % make monotonic for interpolation (looses nprof priority!)
    [~,ind]=sort(xadj); % monotonic sorting
    xadj=xadj(ind);yadj=yadj(ind);yadjqc=yadjqc(ind);yadjerr=yadjerr(ind);
    % and make sure that they are column vectors
    xadj=xadj(:);yadj=yadj(:);yadjqc=yadjqc(:);yadjerr=yadjerr(:);
    % interpolate data for other levels of the synthetic pressure axis:
    % toss away repeated occurence of pressures: e.g., MD5904767_004.nc PSAL @ 46.0 dbar
    if ismember(ubgcparams{i},{'PRES'})
        [~,uindadj]=unique(xadj);
    else
        uindadj=1:length(xadj);
    end
    if length(xadj)>1
    % data interpolation: linear, no extrapolation
    synth.([ubgcparams{i} '_ADJUSTED']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))=interp1(double(xadj(uindadj)),double(yadj(uindadj)),double(presaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))),'linear',NaN);
    % data extrapolation: nearest-neighbour
    synth.([ubgcparams{i} '_ADJUSTED']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))=interp1(double(xadj(uindadj)),double(yadj(uindadj)),double(presaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED']).value))),'nearest','extrap');
    if yadjerrpresence % same with errors if any
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))=interp1(double(xadj(uindadj)),double(yadjerr(uindadj)),double(presaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))),'linear',NaN);
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))=interp1(double(xadj(uindadj)),double(yadjerr(uindadj)),double(presaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value))),'nearest','extrap');
    end
    % deal with qc
    % qc interpolation: next and previous, no extrapolation
    qcnextadj=interp1(double(xadj(uindadj)),yadjqc(uindadj),double(presaxis),'next',NaN);
    qcpreviousadj=interp1(double(xadj(uindadj)),yadjqc(uindadj),double(presaxis),'previous',NaN);
    % take maximum of QC; order 1 < 2 < 5 < 3 < 4
    qcnextadj(qcnextadj==5)=2.5; qcpreviousadj(qcpreviousadj==5)=2.5; % replace QC 5 with 2.5: 
    qcfilladj=max(qcnextadj,qcpreviousadj); % max for interpolated QC
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value))=qcfilladj(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value));
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(synth.([ubgcparams{i} '_ADJUSTED_QC']).value==2.5)=5; % and reverse QC 5
    % qc extrapolation: nearest-neighbour
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value))=interp1(double(xadj(uindadj)),yadjqc(uindadj),double(presaxis(isnan(synth.([ubgcparams{i} '_ADJUSTED_QC']).value))),'nearest','extrap');
    clear qcnextadj qcpreviousadj qcfilladj
    elseif ~isempty(xadj) % only one value, keep this value, its error, and its QC, and place it closest to the original pressure
        [~,ifill]=min(abs(presaxis-xadj));
        synth.([ubgcparams{i} '_ADJUSTED']).value(ifill)=yadj;
        if yadjerrpresence % same with errors if any
        synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(ifill)=yadjerr;
        end
        synth.([ubgcparams{i} '_ADJUSTED_QC']).value(ifill)=yadjqc;
    else % no adjusted value left from overlapping portions
        % do nothing
    end    
    %% and kick out unmatched data
    inomatch=true(nos,1);
    neardp=abs(synth.PRES.value(dsearchn(synth.PRES.value,xadj(uindadj)))-xadj(uindadj)); % on original sampling axis
    for k=1:length(uindadj), 
        inomatch(abs(synth.PRES.value-xadj(uindadj(k)))==neardp(k))=0; 
    end
    %% but only if it's not an isolated hole between data
    iremove=inomatch;
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
        iremove(find(inomatch(1) & ~inomatch(2) & ~inomatch(3) & diff(synth.PRES.value([1 2]))<=2*1000))=0;
        iremove(find(inomatch(nos) & ~inomatch(nos-2) & ~inomatch(nos-1) & diff(synth.PRES.value([nos-1 nos]))<=1*1000)+nos-1)=0;
    end
    if addTSeverywhere
        if ismember(ubgcparams{i},{'TEMP';'PSAL'})
            iremove(:)=0; % don't remove any interpolated data, but give them a QC 8
        end
    end
    %if ismember(ubgcparams{i},{'PRES'})
    %    synth.(ubgcparams{i}).value(iremove)=FV;
    %else
        synth.([ubgcparams{i} '_ADJUSTED']).value(iremove)=NaN;
    %end % PRES (int) or not (double)
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(iremove)=NaN;
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(inomatch & ~iremove)=8;
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(iremove)=NaN;
    clear xadj xadjqc yadj yadjqc yadjerr yadjerrpresence uindadj inomatch
    end % ~isempty(yadj) : some adjusted data available
    end % ~isempty(y) : some data available
    %% and convert dPRES back to proper 1/1000 double
    fillind=synth.([ubgcparams{i} '_dPRES']).value==FV;
	synth.([ubgcparams{i} '_dPRES']).value=double(synth.([ubgcparams{i} '_dPRES']).value)./1000;
    synth.([ubgcparams{i} '_dPRES']).value(fillind)=NaN;
    clear fillind
end


%% collect core parameters (similar as BGC, i.e., only non-overlapping portion, 
%% but different, i.e., no vertical offset, no data/QC interpolation, no dPRES assignment at this stage)

xpres=inpres0(:,asort); % keep original pressure
for i=1:length(coreparams)
    
    %% extract data
    y=S.(coreparams{i}).value(:,asort);
    yqc=S.([coreparams{i} '_QC']).value(:,asort);
    yadj=S.([coreparams{i} '_ADJUSTED']).value(:,asort);
    yadjqc=S.([coreparams{i} '_ADJUSTED_QC']).value(:,asort);
    yadjerr=S.([coreparams{i} '_ADJUSTED_ERROR']).value(:,asort);
    %% check for overlapping portion of N_PROFs
    if ismember(coreparams{i},{'PRES'})
    overlap=true(size(y)); % pressures of different N_PROFs (almost) necessarily overlap
    % get max and min ranges per nprof for adjusted anyway
    xrangeadj=ones(2,1+noNPROFs)*NaN;
    overlapadj=false(size(yadj)); % and flag portions that don't overlap for adjusted data
    for k=1:noNPROFs 
        % and adjusted
        indadj=~isnan(yadj(:,k)) & xpresqc(:,k);
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
        indadj=~isnan(yadj(:,k)) & xpresqc(:,k);
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
    end % overlapping portion
    %% do not use <PARAM>_QC of 8 or FillValue
    yflagqc=ismember(yqc,[0 1 2 3 4 5]);
    if ismember(coreparams{i},{'PRES'}), yflagnoFV=y~=FV; % double check PRES FV
    else, yflagnoFV=~isnan(y); end % and other FV (e.g., BR5900952_157, DOXY all NaN but QC=0)
    yflagadjqc=ismember(yadjqc,[0 1 2 3 4 5]);
    yflagadjnoFV=~isnan(yadj); % double check FV
    
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
    %yadjerrpresence=~all(isnan(yadjerr)); % error not mandatory for adjusted fields..
    
    if ~isempty(y) % not only NaN/FV data
    % use only non-overlapping portion 
    x=x(overlap);y=y(overlap);yqc=yqc(overlap);
    clear overlap
    % make monotonic for interpolation (looses nprof priority!)
    [~,ind]=sort(x); % monotonic sorting
    x=x(ind);y=y(ind);yqc=yqc(ind);
    full.(coreparams{i}).x=x;
    full.(coreparams{i}).y=y;
    full.(coreparams{i}).yqc=yqc;
    end % not only NaN/FV data
    
    if ~isempty(yadj) % not only NaN/FV adjusted data
    % do the same with adjusted fields
    % use only overlapping portion 
    xadj=xadj(overlapadj);yadj=yadj(overlapadj);yadjqc=yadjqc(overlapadj);yadjerr=yadjerr(overlapadj);
    clear overlapadj
    % make monotonic for interpolation (looses nprof priority!)
    [~,ind]=sort(xadj); % monotonic sorting
    xadj=xadj(ind);yadj=yadj(ind);yadjqc=yadjqc(ind);yadjerr=yadjerr(ind);
    full.(coreparams{i}).xadj=xadj;
    full.(coreparams{i}).yadj=yadj;
    full.(coreparams{i}).yadjqc=yadjqc;
    full.(coreparams{i}).yadjerr=yadjerr;
    end % not only NaN/FV adjusted data
end

%% merge core-full resolution and BGC-synthetic pressure axis

if ~isfield(full,'TEMP'), full.TEMP.x=int32([]);full.TEMP.y=int32([]);full.TEMP.ygc=[]; end % make sure fields exist, even if no usable data (BR2902088_051)
if ~isfield(full,'PSAL'), full.PSAL.x=int32([]);full.PSAL.y=int32([]);full.PSAL.ygc=[]; end

% get all non-overlapping TEMP/PSAL levels and pressure axis levels
presmerge=union(union(full.TEMP.x,full.PSAL.x),presaxis); % 'HR' T/S pressure axis and presaxis
% get indices for synthetic pressure axis
nosf=length(presmerge);
[~,synthind]=intersect(presmerge,presaxis);

%% fill in PRES, TEMP, and PSAL fields
% preallocate
for i=1:length(coreparams)
    if ismember(coreparams{i},{'PRES'})
        synthfull.(coreparams{i}).value=int32(ones(nosf,1)*FV);
    else
        synthfull.(coreparams{i}).value=ones(nosf,1)*NaN;
    end
    synthfull.([coreparams{i} '_QC']).value=ones(nosf,1)*NaN;
    synthfull.([coreparams{i} '_ADJUSTED']).value=ones(nosf,1)*NaN;
    synthfull.([coreparams{i} '_ADJUSTED_QC']).value=ones(nosf,1)*NaN;
    synthfull.([coreparams{i} '_ADJUSTED_ERROR']).value=ones(nosf,1)*NaN;
    synthfull.([coreparams{i} '_dPRES']).value=ones(nosf,1)*NaN;
end
% add synthetic pressure levels
synthfull.PRES.value(synthind)=presaxis;
synthfull.PRES_QC.value(synthind)=1; % default to '1'
synthfull.PRES_dPRES.value(synthind)=0; % default to 0.0 dbar

% and fill in data for PRES/TEMP/PSAL (on full merge axis)
for i=1:length(coreparams)
    if ~isempty(full.(coreparams{i}).y) % not only NaN/FV data
    [~,fillind,cpind]=intersect(presmerge,full.(coreparams{i}).x);
    synthfull.(coreparams{i}).value(fillind)=full.(coreparams{i}).y(cpind);
    synthfull.([coreparams{i} '_QC']).value(fillind)=full.(coreparams{i}).yqc(cpind);
    synthfull.([coreparams{i} '_dPRES']).value(fillind)=0;
    % interpolate missing data
    fillind=isnan(synthfull.(coreparams{i}).value);
    if any(fillind) && length(full.(coreparams{i}).x)>1 % and not just spurious single sample
    synthfull.(coreparams{i}).value(fillind)=interp1(double(full.(coreparams{i}).x),double(full.(coreparams{i}).y),double(synthfull.PRES.value(fillind)),'linear');
    synthfull.([coreparams{i} '_QC']).value(fillind)=8;
    end
    % extrapolate by nearest neighbour missing data
    fillind=isnan(synthfull.(coreparams{i}).value);
    if any(fillind) && length(full.(coreparams{i}).x)>1 % and not just spurious single sample
    synthfull.(coreparams{i}).value(fillind)=interp1(double(full.(coreparams{i}).x),double(full.(coreparams{i}).y),double(synthfull.PRES.value(fillind)),'nearest','extrap');
    synthfull.([coreparams{i} '_QC']).value(fillind)=8;
    end
    % add dPRES where it is missing (for some levels of the synthetic axis)
    
    clear fillind cpind
    end % data exists
    if isfield(full.(coreparams{i}),'yadj') % not only NaN/FV adjusted data
    % do the same with adjusted fields
    [~,fillindadj,cpindadj]=intersect(presmerge,full.(coreparams{i}).xadj);
    synthfull.([coreparams{i} '_ADJUSTED']).value(fillindadj)=full.(coreparams{i}).yadj(cpindadj);
    synthfull.([coreparams{i} '_ADJUSTED_QC']).value(fillindadj)=full.(coreparams{i}).yadjqc(cpindadj);
    synthfull.([coreparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=full.(coreparams{i}).yadjerr(cpindadj);
    % interpolate missing data
    fillindadj=isnan(synthfull.([coreparams{i} '_ADJUSTED']).value);
    if any(fillindadj) && ismember(coreparams{i},{'PRES'}) % deal with PRES in special way
        % make sure that PRES_ADJUSTED-PRES is one unique value for entire profile
        dp=unique(int32(1e3*synthfull.PRES_ADJUSTED.value(~fillindadj))-synthfull.PRES.value(~fillindadj));
        if length(dp)==1
            synthfull.PRES_ADJUSTED.value(fillindadj)=double(synthfull.PRES.value(fillindadj)+dp)/1e3;
            synthfull.([coreparams{i} '_ADJUSTED_QC']).value(fillindadj)=8;
            dp=unique(synthfull.PRES_ADJUSTED_ERROR.value(~fillindadj)); % same with adjusted error
            if length(dp)==1
                synthfull.PRES_ADJUSTED_ERROR.value(fillindadj)=dp;
            else
                synthfull.([coreparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=interp1(double(full.(coreparams{i}).xadj),full.(coreparams{i}).yadjerr,double(synthfull.PRES.value(fillindadj)),'linear');
            end
            fillindadj=isnan(synthfull.([coreparams{i} '_ADJUSTED']).value);
        end
    end % deal with pressure in a special way
    if any(fillindadj) && length(full.(coreparams{i}).xadj)>1 % and not just spurious single sample
    synthfull.([coreparams{i} '_ADJUSTED']).value(fillindadj)=interp1(double(full.(coreparams{i}).xadj),full.(coreparams{i}).yadj,double(synthfull.PRES.value(fillindadj)),'linear');
    synthfull.([coreparams{i} '_ADJUSTED_QC']).value(fillindadj)=8;
    synthfull.([coreparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=interp1(double(full.(coreparams{i}).xadj),full.(coreparams{i}).yadjerr,double(synthfull.PRES.value(fillindadj)),'linear');
    end
    % extrapolate by nearest neighbour missing data
    fillindadj=isnan(synthfull.([coreparams{i} '_ADJUSTED']).value);
    if any(fillindadj) && length(full.(coreparams{i}).xadj)>1
    synthfull.([coreparams{i} '_ADJUSTED']).value(fillindadj)=interp1(double(full.(coreparams{i}).xadj),full.(coreparams{i}).yadj,double(synthfull.PRES.value(fillindadj)),'nearest','extrap');
    synthfull.([coreparams{i} '_QC']).value(fillindadj)=8;
    synthfull.([coreparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=interp1(double(full.(coreparams{i}).xadj),full.(coreparams{i}).yadjerr,double(synthfull.PRES.value(fillindadj)),'nearest','extrap');
    end
    clear fillindadj cpindadj
    end % adjusted data exists
    
end % cycle PRES/TEMP/PSAL

%% check/add dPRES assignment for inter-/extrapolated PRES/TEMP/PSAL data
for i=1:length(coreparams)
    % and add pressure difference where it is missing (and there are data)
    fillind=find(~isnan(synthfull.([coreparams{i} '_QC']).value) & isnan(synthfull.([coreparams{i} '_dPRES']).value));
    % if there are two nearest samples, take the deeper one..
    for k=1:length(fillind)
        dp=full.(coreparams{i}).x-presmerge(fillind(k)); % deeper sample of minimum pressure difference
        synthfull.([coreparams{i} '_dPRES']).value(fillind(k))=double(dp(find(abs(dp)==min(abs(dp)),1,'last')))./1e3;
    end
    clear x xqc fillind dp
end % cycle PRES/TEMP/PSAL

%% add synthetic profile to merged data
fnames=fieldnames(synth); % use non-interleaved profile as template; fill gaps with NaN
for i=2:length(fnames) % start at index 2: first one is PRES=presaxis -> already present
    synthfull.(fnames{i}).value=ones(nosf,1)*NaN;
    synthfull.(fnames{i}).value(synthind)=synth.(fnames{i}).value;
end

%% and convert PRES back to proper 1/1000 double
fillind=synthfull.PRES.value==FV;
synthfull.PRES.value=double(synthfull.PRES.value)./1000;
synthfull.PRES.value(fillind)=NaN;



