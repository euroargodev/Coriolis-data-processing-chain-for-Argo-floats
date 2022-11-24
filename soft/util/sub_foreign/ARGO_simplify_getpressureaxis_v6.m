function synth=ARGO_simplify_getpressureaxis_v6(varargin)
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
%
%
% inputs: - 'bfilepath' (mandatory)
%         - 'cfilepath', 'metafilepath' (optional)
% 
% usage: 
% out=ARGO_simplify_getpressureaxis_v2('bfilepath','BR6901485_050.nc');
% out=ARGO_simplify_getpressureaxis('bfilepath','6901485/profiles/BR6901485_050.nc');
%
%
% Henry Bittig, LOV
% 18.01.2018
% 05.03.2018, updated
% 19.04.2018, use b- and c- files instead of m-files
% 15.06.2018, modify input to name/value pairs
% 27.06.2018, make approach more robust: Union of PARAMETER and STATION_PARAMETERS, 
%             only apply vertical offsets for sensors with data, be tolerant towards 
%             older, pre-v3.1 meta files
% 29.06.2018, separate PARAM and PARAM_ADJUSTED overlap determination, using no bad PRES_QC

includeTSflag=0;
addTSeverywhere=1;
verbose=0;
fieldsuffixvarname={'PRES';'BBP[0-9]+';'BISULFIDE';'CDOM';'CHLA';'CP[0-9]+';'DOWN_IRRADIANCE[0-9]+';'DOWNWELLING_PAR';'DOXY';'NITRATE';'PH_IN_SITU_TOTAL';'TURBIDITY';'UP_RADIANCE[0-9]+';};

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

%if nargin<1, filepath='files/profiles/MR6901585_002.nc'; end
if nargin<1, bfilepath='files/profiles/BR6901585_013.nc'; end
%if nargin<2 || isempty(medfiltsize), medfiltsize=5; end
%if nargin<2 || isempty(addoffsetflag), 
addoffsetflag=1;  % add pressure sensor vertical pressure offset to PRES
%end

% load b-file netcdf into convenient structure
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

C=lov_netcdf_pickprod(cfilepath); % load core file
fnamec=setdiff(fieldnames(C),fieldnames(S)); % find core parameter names
for i=1:length(fnamec), S.(fnamec{i})=C.(fnamec{i}); end % copy core data to bio data
% make sure first dimension is size of field (e.g. CS 1901348: 2nd
% dimension)
imain=find(size(C.PARAMETER.value)==16,1,'first');
if imain==1 % keep everything like this, assume fliplr of 
    % 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING16);'
elseif imain==ndims(C.PARAMETER.value) % fliplr, assume inverted order of 
    % 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING16);'
    C.PARAMETER.value=permute(C.PARAMETER.value,imain:-1:1);
else % put STRING16 first and hope the rest falls into place
    disp(['Could not figure out N_DIMs order of core file PARAMETER field'])
    C.PARAMETER.value=permute(C.PARAMETER.value,[imain setdiff(1:ndims(C.PARAMETER.value),imain)]);
end
imain=find(size(C.STATION_PARAMETERS.value)==16,1,'first');
if imain==1 % keep everything like this, assume fliplr of 
    % 'char STATION_PARAMETERS(N_PROF, N_PARAM, STRING16);'
elseif imain==ndims(C.STATION_PARAMETERS.value) % fliplr, assume inverted order of 
    % 'char STATION_PARAMETERS(N_PROF, N_PARAM, STRING16);'
    if imain>2, C.STATION_PARAMETERS.value=permute(C.STATION_PARAMETERS.value,(imain-1):-1:1);
    elseif imain==2, C.STATION_PARAMETERS.value=C.STATION_PARAMETERS.value'; end % only 2 dims
else % put STRING16 first and hope the rest falls into place
    disp(['Could not figure out N_DIMs order of core file STATION_PARAMETERS field'])
    C.STATION_PARAMETERS.value=permute(C.STATION_PARAMETERS.value,[imain setdiff(1:ndims(C.STATION_PARAMETERS.value),imain)]);
end
imain=find(size(S.PARAMETER.value)==64,1,'first');
if imain==1 % keep everything like this, assume fliplr of 
    % 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING64);'
elseif imain==ndims(S.PARAMETER.value) % fliplr, assume inverted order of 
    % 'char PARAMETER(N_PROF, N_CALIB, N_PARAM, STRING64);'
    S.PARAMETER.value=permute(S.PARAMETER.value,imain:-1:1);
else % put STRING64 first and hope the rest falls into place
    disp(['Could not figure out N_DIMs order of bio file PARAMETER field'])
    S.PARAMETER.value=permute(S.PARAMETER.value,[imain setdiff(1:ndims(S.PARAMETER.value),imain)]);
end
imain=find(size(S.STATION_PARAMETERS.value)==64,1,'first');
if imain==1 % keep everything like this, assume fliplr of 
    % 'char STATION_PARAMETERS(N_PROF, N_PARAM, STRING64);'
elseif imain==ndims(S.STATION_PARAMETERS.value) % fliplr, assume inverted order of 
    % 'char STATION_PARAMETERS(N_PROF, N_PARAM, STRING64);'
    if imain>2, S.STATION_PARAMETERS.value=permute(S.STATION_PARAMETERS.value,(imain-1):-1:1); 
    elseif imain==2, S.STATION_PARAMETERS.value=S.STATION_PARAMETERS.value'; end % only 2 dims
else % put STRING64 first and hope the rest falls into place
    disp(['Could not figure out N_DIMs order of bio file STATION_PARAMETERS field'])
    S.STATION_PARAMETERS.value=permute(S.STATION_PARAMETERS.value,[imain setdiff(1:ndims(S.STATION_PARAMETERS.value),imain)]);
end
%%{
% and merge PARAMETER and STATION_PARAMETERS field 
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

% get bgcparams names and N_PROFs
[~,noNPROFs]=size(S.PRES_QC.value);
bgcflag=false(1,noNPROFs);
bgcparams=cell(1,noNPROFs);
% check that there are params different than PRES, TEMP, PSAL in N_PROF
for i=1:noNPROFs
    inparams=union(cellstr(S.PARAMETER.value(:,:,1,i)'),cellstr(S.STATION_PARAMETERS.value(:,:,i)')); % check PARAMETER and STATION_PARAMETERS
    bgcparams{i}=setdiff(inparams,{'PRES';'TEMP';'PSAL';''});
    bgcflag(i)=~isempty(bgcparams{i});
end
% unique BGC parameters
ubgcparams=unique(cat(1, bgcparams{:}));
% and kick out the i-parameters again
fnamesind=true(size(ubgcparams));
for k=1:length(fieldsuffixvarname)
fnamesind(~cellfun(@isempty,regexp(ubgcparams,['^' fieldsuffixvarname{k} '$*'])))=0; % normal variable
fnamesind(~cellfun(@isempty,regexp(ubgcparams,['^' fieldsuffixvarname{k} '[0-9]+$*'])))=0; % multiple variable
fnamesind(~cellfun(@isempty,regexp(ubgcparams,['^' fieldsuffixvarname{k} '_[0-9]+$*'])))=0; % multiple variable with underscore
end
ubgcparams=ubgcparams(~fnamesind);

if isempty(ubgcparams) % there are no bgc-params to align
disp(['No b-parameters found in ' bfilepath])
synth=[];
else % there are b-params to align, do the actual work

if isempty(metafilepath)
% figure out location of the corresponding meta file
[basepath,~]=fileparts(bfilepath);
metafilepath=[basepath filesep strtrim(S.PLATFORM_NUMBER.value(1,:)) '_meta.nc'];
if ~(exist(metafilepath,'file'))
metafilepath=[basepath filesep '..' filesep strtrim(S.PLATFORM_NUMBER.value(1,:)) '_meta.nc'];
end
end

% check meta file for vertical pressure offsets
C=[];
%infields={'LAUNCH_CONFIG_PARAMETER_NAME';'LAUNCH_CONFIG_PARAMETER_VALUE';'CONFIG_MISSION_NUMBER';'CONFIG_PARAMETER_NAME';'CONFIG_PARAMETER_VALUE'};
infields={'LAUNCH_CONFIG_PARAMETER_NAME';'LAUNCH_CONFIG_PARAMETER_VALUE';'PARAMETER';'PARAMETER_SENSOR';'FORMAT_VERSION'};
flagdone=false(1,size(S.PRES.value,2));
try 
    C=lov_netcdf_pickprod(metafilepath,infields);
catch me
    % failed to locate meta file
end
if isempty(C)
    disp(['Could not find meta file ' strtrim(S.PLATFORM_NUMBER.value(1,:)) '_meta.nc in current or parent folder.'])
else
    if addoffsetflag
        if isfield(C,'LAUNCH_CONFIG_PARAMETER_NAME') % pre-v3.1 meta files might not have this field
    names=C.LAUNCH_CONFIG_PARAMETER_NAME.value;
    values=C.LAUNCH_CONFIG_PARAMETER_VALUE.value;
    %{
    % and replace all updates in CONFIG_PARAMETER with respect to the current mission number
    mission=S.CONFIG_MISSION_NUMBER.value(1);
    ind=find(C.CONFIG_MISSION_NUMBER.value==mission);
    for k=1:size(C.CONFIG_PARAMETER_NAME.value,1)
        values(strcmp(cellstr(names),strtrim(C.CONFIG_PARAMETER_NAME.value(k,:))))=C.CONFIG_PARAMETER_VALUE.value(k,ind);
    end
    % enforce all-caps writing for Ctd
    names=char(strrep(cellstr(names),'Ctd','CTD'));
    %}
    
    sensors={'CTD';'Optode';'Ocr';'Eco';'FLNTU';'Crover';'Suna'};
    %params={'PSAL';'DOXY';'DOWNWELLING_PAR';'CHLA';'CHLA';'CP660';'NITRATE'};
    params={'PSAL';'DOXY';'WELLING_';{'CHLA','BBP','CDOM'};{'CHLA','BBP'};'CP660';'NITRATE'};
    % find occurences of search parameter
    cnames={'VerticalPressureOffset_dbar'};
    ind=find(~cellfun(@isempty,strfind(cellstr(lower(names)),lower(cnames{1}))));
    if any(ind)
        if verbose, disp(['Found ' num2str(length(ind)) ' VerticalOffsets']); end
        % get short sensor names and vertical offsets
        cpnames=strrep(strrep(cellstr(lower(names(ind,:))),lower(cnames{1}),''),lower('CONFIG_'),'');
        voffset=values(ind);
        % get which parameters in which N_PROFs
        npnames=cell(1,noNPROFs);
        for i=1:length(npnames)
            %dummy=cellstr(squeeze(S.PARAMETER.value(:,:,1,i))');
            dummy=union(cellstr(S.PARAMETER.value(:,:,1,i)'),cellstr(S.STATION_PARAMETERS.value(:,:,i)'));
            npnames{i}=dummy(~cellfun(@isempty,dummy));
        end
        % and match with profile N_PROFs
        for i=1:length(cpnames)
            ind=strcmpi(cpnames{i},sensors);
            if ~any(ind), disp(['Could not identify short sensor name ' cpnames{i}])
                %keyboard
                synth=[];
                return
            else
                % check that sensor is actually switched on during this cycle
                if iscell(params{ind})
                    flagpowered=any(cellfun(@(y)any(cellfun(@(x)~isempty(strfind(y,x)),params{ind})),ubgcparams));
                else % char
                	flagpowered=any(cellfun(@(y)any(~isempty(strfind(y,params{ind}))),ubgcparams));
                end
                if flagpowered
                    % find associated N_PROFs
                    numparams=zeros(size(npnames));
                    for j=1:length(npnames)
                        if iscell(params{ind})
                            numparams(j)=sum(cellfun(@(y)any(cellfun(@(x)~isempty(strfind(y,x)),params{ind})),npnames{j}));
                        else % char
                            numparams(j)=sum(cellfun(@(y)any(~isempty(strfind(y,params{ind}))),npnames{j}));
                        end
                    end
                    if any(flagdone & logical(numparams)) % check wether done before
                        disp(['N_PROF ' num2str(find(any(flagdone & logical(numparams)))) ' has got a vertical offset before - now a 2nd time? Please check!'])
                        %keyboard
                        synth=[];
                        return
                    elseif ~any(logical(numparams)) % no N_PROF identified, but sensor is not switched off...!
                        disp(['Could not find associated N_PROF for ' cpnames{i} '? Please check!'])
                        %keyboard
                        synth=[];
                        return
                    else
                        % and apply offset
                        S.PRES.value(:,logical(numparams))=S.PRES.value(:,logical(numparams))+voffset(i);
                        flagdone=flagdone | logical(numparams);
                    end % apply only once
                end % sensor is not switched off
            end % short sensor name known 
        end % cycle all found config names
    else
        if verbose, disp(['Found no verticalOffsets']), end
    end % config name found
        else
            disp(['Could not find LAUNCH_CONFIG_PARAMETER_NAME in meta file (FORMAT_VERSION ' C.FORMAT_VERSION.value '). No vertical sensor offsets corrected.'])
        end % LAUNCH_CONFIG_PARAMETER_NAME
    end % addoffsetflag
end % config file opened
%}
clear cnames dummy ind infields mission names values npnames numparams params sensors 

% rearrange nprofs according to priority (alphabetical by sensor name)
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
    disp(['Could not find PARAMETER_SENSOR in meta file (FORMAT_VERSION ' C.FORMAT_VERSION.value '). Kept N_PROF order as in profile file.'])
    asort=1:noNPROFs;
end % define N_PROF priority
clear C 

%inpres=round(1000*S.PRES.value)/1000; % use copy of pressure to work with; rounded to 1/1000 to avoid numerical ..1e-6 issues
%inpres(~pflag)=NaN; 
FV=-99999;
%inpres=int32(1000*S.PRES.value); % use copy of pressure to work with; cast truly to "1/1000" integer to avoid numerical ..1e-6 issues
S.PRES.value=int32(1000*S.PRES.value); % cast truly to "1/1000" integer to avoid numerical ..1e-6 issues

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
    disp(['Found ' num2str(sum(pinversion(:))) ' levels with unflagged pressure inversions. Flag with PRES_QC=4.'])
    S.PRES_QC.value(pinversion)=4;
end
clear pinversion ind

% sort out pressure axis and which N_PROF to use
% only use PRES_QC 0..3, ignore PRES_QC=4
pflag=ismember(S.PRES_QC.value,[0 1 2 3]); 

inpres=S.PRES.value; % use copy of pressure to work with
inpres(~pflag)=FV; 

if addoffsetflag
% check wether all bgc n_profs had a vertical offset config entry?
if any(bgcflag & ~flagdone) && verbose
    ind=find(bgcflag & ~flagdone);
	for i=1:length(ind)
	    disp(['No vertical offset for N_PROF ' num2str(ind(i)) ' - ' strjoin(bgcparams{ind(i)},', ')])
	end
end
end
% check where BGC samples are present (and not all NaN)
bgcpresence=false(size(S.PRES.value));
for i=1:length(ubgcparams)
    bgcpresence=bgcpresence | ~isnan(S.(ubgcparams{i}).value);
end

% if ~includeTSflag: only use N_PROFs that have biogeochemical data, 
% ignore TEMP/PSAL-only N_PROFs for construction of synthetic axis
%if ~includeTSflag, inpres(:,~bgcflag)=NaN; end
if ~includeTSflag, inpres(:,~bgcflag)=FV; inpres(~bgcpresence)=FV; end

% get unique pressures (with or without TEMP/PSAL-only levels; see above)
%upres=unique(inpres(~isnan(inpres)));
upres=unique(inpres(inpres~=FV));
if isempty(upres)
    disp(['Found BGC N_PROF(s) with b-parameter(s) ' strjoin(ubgcparams,' ') ', but without any PRES_QC=0..3. Don''t create synthetic profile.'])
    synth=[];
    return
end
% and check which pressure levels are present in which profile
prespresent=false(length(upres),noNPROFs);
for i=1:noNPROFs,prespresent(:,i)=ismember(upres,inpres(:,i));end

% verify that there are BGC observations, not just BGC N_PROFs
if ~any(prespresent(:))
    disp(['Found BGC N_PROF(s) with b-parameter(s) ' strjoin(ubgcparams,' ') ', but without any non-FillValue data. Don''t create synthetic profile.'])
    synth=[];
    return
end

% get pressure differences between the levels in each N_PROF; use the
% minimum of preceeding/succeeding deltaPRES
valdp=ones(length(upres),noNPROFs)*NaN;
for i=1:noNPROFs
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
            disp(['Trouble during creation of synthetic pressure axis'])
            synth=[];
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
        disp(['Exceeded maximum number of iterations in selection of synthetic pressure levels. Should not happen...'])
        synth=[];
        return
    end
end
clear niter nitermax
presaxis=upres(useind);
end % pressure axis cycle from bottom possible?
%presaxis=double(upres(useind))./1000; % and put back on 1/1000 float value

%%{
% include PRES, TEMP and PSAL in interpolation
ubgcparams=cat(1,{'PRES';'TEMP';'PSAL'},ubgcparams);
% add adjusted fields
%ubgcparams=reshape(cat(2,ubgcparams,cellfun(@(c)[c '_ADJUSTED'],ubgcparams,'uniform',0))',[],1);

isynth=(1:length(presaxis))'; % index 1..length synthetic pressure axis
nos=length(isynth);
% DOXY/<PARAM> can sit in more than one N_PROF, so need to be a bit more
% clunky than just simply interpolating a single N_PROF which contains
% <PARAM>
xpres=S.PRES.value(:,asort); % rearrange pressure obeying nprof priority
xpresqc=pflag(:,asort); % and flag to pressure that are not QC=4
% fill in data in synthetic profile
for i=1:length(ubgcparams)
    
    % extract data
    y=S.(ubgcparams{i}).value(:,asort);
    yqc=S.([ubgcparams{i} '_QC']).value(:,asort);
    yadj=S.([ubgcparams{i} '_ADJUSTED']).value(:,asort);
    yadjqc=S.([ubgcparams{i} '_ADJUSTED_QC']).value(:,asort);
    yadjerr=S.([ubgcparams{i} '_ADJUSTED_ERROR']).value(:,asort);
    % check for overlapping portion of nprofs
    if ismember(ubgcparams{i},{'PRES'})
        overlap=~isnan(y); % should be ~=FV?
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
        
    else
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
    end
    % do not use <PARAM>_QC of 8 or FillValue
    yflagqc=ismember(yqc,[0 1 2 3 4 5]);
    if ismember(ubgcparams{i},{'PRES'}), yflagnoFV=y~=FV; % double check PRES FV
    else yflagnoFV=~isnan(y); end % and other FV (e.g., BR5900952_157, DOXY all NaN but QC=0)
    % except for CHLA_ADJUSTED...(otherwise no surface data:NPQ correction)
    %if ismember(ubgcparams{i},'CHLA'), yadjqc(yadjqc==8)=5; end
    yflagadjqc=ismember(yadjqc,[0 1 2 3 4 5]);
    yflagadjnoFV=~isnan(yadj); % double check FV
    
    % clean up: only data of current parameter without QC 8, only pflag
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
    
    
    % preallocate
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
    % copy data for levels that are part of the synthetic pressure axis:
    % get indices to which data to copy
    % take only 'first' occurence (in nprof-priority sorted record!) and
    % toss away repeated occurences (e.g., MD5904767_004.nc PSAL @ 46.0 dbar) 
    [~,fillind,cpind]=intersect(presaxis,x);
    synth.(ubgcparams{i}).value(fillind)=y(cpind);
    synth.([ubgcparams{i} '_QC']).value(fillind)=yqc(cpind);
    synth.([ubgcparams{i} '_dPRES']).value(fillind)=0;
    clear fillind cpind
    
    
    % use only overlapping portion 
    x=x(overlap);y=y(overlap);yqc=yqc(overlap);
    clear overlap
    % make monotonic for interpolation (looses nprof priority!)
    [~,ind]=sort(x); % monotonic sorting
    x=x(ind);y=y(ind);yqc=yqc(ind);
    
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
    %{
    %% check dPRES assignment
    % and add pressure difference where it is missing (and there are data)
    nearind=dsearchn(x(uind),presaxis);
    %%synth.([ubgcparams{i} '_dPRES']).value(isnan(synth.([ubgcparams{i} '_dPRES']).value))=x(uind(nearind(isnan(synth.([ubgcparams{i} '_dPRES']).value))))-presaxis(isnan(synth.([ubgcparams{i} '_dPRES']).value));
    %synth.([ubgcparams{i} '_dPRES']).value(synth.([ubgcparams{i} '_dPRES']).value==FV)=x(uind(nearind(synth.([ubgcparams{i} '_dPRES']).value==FV)))-presaxis(synth.([ubgcparams{i} '_dPRES']).value==FV);
    nos=length(isynth);
    % if there are two nearest samples, take the deeper one..
    for k=1:nos
        %synth.([ubgcparams{i} '_dPRES']).value(synth.([ubgcparams{i} '_dPRES']).value==FV)=x(uind(nearind(synth.([ubgcparams{i} '_dPRES']).value==FV)))-presaxis(synth.([ubgcparams{i} '_dPRES']).value==FV);
        dpind=abs(x-presaxis(k))==abs(x(uind(nearind(k)))-presaxis(k)); % points with same distance and to be used (not in low priority nprofs)
        synth.([ubgcparams{i} '_dPRES']).value(k)=max(x(dpind))-presaxis(k); % take deeper value if there are any two samples at +/- the same distance
        clear dpind
    end
    clear nearind
    %% check dPRES assignment
    %}
    % and kick out unmatched data
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
    % but only if it's not an isolated hole between data
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
    synth.([ubgcparams{i} '_dPRES']).value(iremove)=FV;
    synth.([ubgcparams{i} '_QC']).value(inomatch & ~iremove)=8;
    clear y yqc uind inomatch iremove
    
    %% check dPRES assignment
    % and add pressure difference where it is missing (and there are data)
    fillind=find(~isnan(synth.([ubgcparams{i} '_QC']).value) & synth.([ubgcparams{i} '_dPRES']).value==FV);
    
    %nearind=dsearchn(x(uind),presaxis);
    %%synth.([ubgcparams{i} '_dPRES']).value(isnan(synth.([ubgcparams{i} '_dPRES']).value))=x(uind(nearind(isnan(synth.([ubgcparams{i} '_dPRES']).value))))-presaxis(isnan(synth.([ubgcparams{i} '_dPRES']).value));
    %synth.([ubgcparams{i} '_dPRES']).value(synth.([ubgcparams{i} '_dPRES']).value==FV)=x(uind(nearind(synth.([ubgcparams{i} '_dPRES']).value==FV)))-presaxis(synth.([ubgcparams{i} '_dPRES']).value==FV);
    %nos=length(isynth);
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
    % do the same with adjusted fields
    % copy data for levels that are part of the synthetic pressure axis:
    [~,fillindadj,cpindadj]=intersect(presaxis,xadj);
    synth.([ubgcparams{i} '_ADJUSTED']).value(fillindadj)=yadj(cpindadj);
    synth.([ubgcparams{i} '_ADJUSTED_QC']).value(fillindadj)=yadjqc(cpindadj);
    synth.([ubgcparams{i} '_ADJUSTED_ERROR']).value(fillindadj)=yadjerr(cpindadj);
    clear fillindadj cpindadj
    
    % use only overlapping portion 
    xadj=xadj(overlapadj);yadj=yadj(overlapadj);yadjqc=yadjqc(overlapadj);yadjerr=yadjerr(overlapadj);
    clear overlapadj
    % make monotonic for interpolation (looses nprof priority!)
    [~,ind]=sort(xadj); % monotonic sorting
    xadj=xadj(ind);yadj=yadj(ind);yadjqc=yadjqc(ind);yadjerr=yadjerr(ind);
    
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
    
    % and kick out unmatched data
    inomatch=true(nos,1);
    neardp=abs(synth.PRES.value(dsearchn(synth.PRES.value,xadj(uindadj)))-xadj(uindadj)); % on original sampling axis
    for k=1:length(uindadj), 
        inomatch(abs(synth.PRES.value-xadj(uindadj(k)))==neardp(k))=0; 
    end
    % but only if it's not an isolated hole between data
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
    % and convert dPRES back to proper 1/1000 double
    fillind=synth.([ubgcparams{i} '_dPRES']).value==FV;
	synth.([ubgcparams{i} '_dPRES']).value=double(synth.([ubgcparams{i} '_dPRES']).value)./1000;
    synth.([ubgcparams{i} '_dPRES']).value(fillind)=NaN;
    clear fillind
end
% and convert dPRES back to proper 1/1000 double
fillind=synth.PRES.value==FV;
synth.PRES.value=double(synth.PRES.value)./1000;
synth.PRES.value(fillind)=NaN;
%fillind=synth.PRES_ADJUSTED.value==FV;
%synth.PRES_ADJUSTED.value=double(synth.PRES_ADJUSTED.value)./1000;
%synth.PRES_ADJUSTED.value(fillind)=NaN;

end % there are bgc-params to align
