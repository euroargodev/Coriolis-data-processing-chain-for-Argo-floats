% ------------------------------------------------------------------------------
% Retrieve meta-data needed to compute the cycle number associated to the Apex
% Argos input file.
%
% SYNTAX :
%  [o_launchDate, o_preludeDuration, o_profilePressure, ...
%    o_cycleDuration, o_dpfFloatFlag] = ...
%    get_apx_meta_data_for_cycle_number_determination( ...
%    a_floatNum, a_floatLaunchDate, a_floatCycleTime, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_floatLaunchDate : float launch date
%   a_floatCycleTime  : cycle duration
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_launchDate      : float launch date
%   o_preludeDuration : duration of the prelude phase
%   o_profilePressure : profile pressure
%   o_cycleDuration   : cycle duration
%   o_dpfFloatFlag    : DPF float flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_launchDate, o_preludeDuration, o_profilePressure, ...
   o_cycleDuration, o_dpfFloatFlag] = ...
   get_apx_meta_data_for_cycle_number_determination( ...
   a_floatNum, a_floatLaunchDate, a_floatCycleTime, a_decoderId)

% output parameters initialization
o_launchDate = [];
o_preludeDuration = [];
o_profilePressure = [];
o_cycleDuration = [];
o_dpfFloatFlag = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;
global g_decArgo_durationDef;
global g_decArgo_janFirst1950InMatlab;

% lists of managed decoders
global g_decArgo_decoderIdListApexApf11Argos;


% meta-data used for cycle number estimation
wantedMetaNames = [ ...
   {'LAUNCH_DATE'} ...
   {'CONFIG_PARAMETER_NAME'} ...
   {'CONFIG_PARAMETER_VALUE'} ...
   ];

% retrieve information from json meta-data file
[metaData] = get_meta_data_from_json_file(a_floatNum, wantedMetaNames);

% launch date
launchDate = g_decArgo_dateDef;
idVal = find(strcmp('LAUNCH_DATE', metaData) == 1);
if (~isempty(idVal))
   valueStr = char(metaData{idVal+1});
   if (~isempty(valueStr))
      launchDate = datenum(valueStr, 'dd/mm/yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   end
end
if (launchDate == g_decArgo_dateDef)
   launchDate = datenum(a_floatLaunchDate, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
end

% configuration parameters
preludeDurationPos = -1;
profilePressurePos = -1;
cycleDurationPos = -1;
dpfFloatFlagPos = -1;
idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData) == 1);
if (~isempty(idVal))
   configStruct = metaData{idVal+1};
   fieldNames = fieldnames(configStruct);
   
   for id = 1:length(fieldNames)
      valueStr = configStruct.(fieldNames{id});
      if (strfind(valueStr, 'CONFIG_PRE_'))
         preludeDurationPos = id;
      elseif (strfind(valueStr, 'CONFIG_TP_'))
         profilePressurePos = id;
      elseif (strfind(valueStr, 'CONFIG_CT_'))
         cycleDurationPos = id;
      elseif (strfind(valueStr, 'CONFIG_DPF_'))
         dpfFloatFlagPos = id;
      end
   end
end

preludeDuration = g_decArgo_durationDef;
profilePressure = g_decArgo_presDef;
cycleDuration = g_decArgo_durationDef;
dpfFloatFlag = -1;
idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData) == 1);
if (~isempty(idVal))
   tabStruct = metaData{idVal+1};
   
   tabPreludeDuration = [];
   tabProfilePressure = [];
   tabCycleDuration = [];
   tabDpfFloatFlag = [];
   
   if (length(tabStruct) > 1)
      
      for id = 1:length(tabStruct)
         if (preludeDurationPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               preludeDurationPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabPreludeDuration = [tabPreludeDuration str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (profilePressurePos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               profilePressurePos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabProfilePressure = [tabProfilePressure str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (cycleDurationPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               cycleDurationPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabCycleDuration = [tabCycleDuration str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (dpfFloatFlagPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               dpfFloatFlagPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabDpfFloatFlag = [tabCycleDuration str2num(tabStruct{id}.(fieldName))];
            end
         end
      end
      
      if (~isempty(tabPreludeDuration))
         preludeDuration = tabPreludeDuration(1);
      end
      if (~isempty(tabProfPres))
         profilePressure = max(tabProfilePressure);
      end
      if (~isempty(tabCycleDuration))
         cycleDuration = tabCycleDuration(end);
      end
      if (~isempty(tabDpfFloatFlag))
         dpfFloatFlag = tabDpfFloatFlag(1);
      end
      
   else
      
      if (preludeDurationPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            preludeDurationPos);
         if (~isempty(tabStruct.(fieldName)))
            preludeDuration = str2num(tabStruct.(fieldName));
         end
      end
      if (profilePressurePos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            profilePressurePos);
         if (~isempty(tabStruct.(fieldName)))
            profilePressure = str2num(tabStruct.(fieldName));
         end
      end
      if (cycleDurationPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            cycleDurationPos);
         if (~isempty(tabStruct.(fieldName)))
            cycleDuration = str2num(tabStruct.(fieldName));
         end
      end
      if (dpfFloatFlagPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            dpfFloatFlagPos);
         if (~isempty(tabStruct.(fieldName)))
            dpfFloatFlag = str2num(tabStruct.(fieldName));
         end
      end
      
   end
end

if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Argos))
   if (preludeDuration ~= g_decArgo_durationDef)
      preludeDuration = preludeDuration/60; % PRELUDE duration is in minutes in the APF11 float configuration
   end
end

if (preludeDuration == g_decArgo_durationDef)
   preludeDuration = 6;
end

if (cycleDuration == g_decArgo_durationDef)
   cycleDuration = a_floatCycleTime;
end

o_launchDate = launchDate;
o_preludeDuration = preludeDuration;
o_profilePressure = profilePressure;
o_cycleDuration = cycleDuration;
o_dpfFloatFlag = dpfFloatFlag;

return
