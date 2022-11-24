% ------------------------------------------------------------------------------
% Retrieve meta-data needed to compute the cycle number associated to the Argos
% input file.
%
% SYNTAX :
%  [o_launchDate, o_delayBeforeMission, o_preludeDuration, o_firstProfileEndDate, ...
%    o_cycleDuration, o_nbCyclesFirstMission] = ...
%    get_meta_data_for_cycle_number_determination( ...
%    a_floatNum, a_floatDecId, a_floatLaunchDate, a_floatCycleTime, a_floatRefDay)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_floatDecId      : float decoder Id
%   a_floatLaunchDate : float launch date
%   a_floatCycleTime  : cycle duration
%   a_floatRefDay     : reference day
%
% OUTPUT PARAMETERS :
%   o_launchDate           : float launch date
%   o_delayBeforeMission   : delay before mission start
%   o_preludeDuration      : duration of the prelude phase
%   o_firstProfileEndDate  : expected date of the end of the first ascending
%                            profile
%   o_cycleDuration        : cycle duration
%   o_nbCyclesFirstMission : number of cycles with o_cycleDuration(1) duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
%   04/30/2015 - RNU - Output added for Arvor ARN 2013 Argos floats
% ------------------------------------------------------------------------------
function [o_launchDate, o_delayBeforeMission, o_preludeDuration, o_firstProfileEndDate, ...
   o_cycleDuration, o_nbCyclesFirstMission] = ...
   get_meta_data_for_cycle_number_determination( ...
   a_floatNum, a_floatDecId, a_floatLaunchDate, a_floatCycleTime, a_floatRefDay)

% output parameters initialization
o_launchDate = [];
o_delayBeforeMission = [];
o_preludeDuration = [];
o_firstProfileEndDate = [];
o_cycleDuration = [];
o_nbCyclesFirstMission = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;
global g_decArgo_durationDef;
global g_decArgo_janFirst1950InMatlab;


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
delayBeforeMissionPos = -1;
preludeDurationPos = -1;
cycleDurationPos = -1;
nbCyclesFirstMissionPos = -1;
cycleDuration1Pos = -1;
cycleDuration2Pos = -1;
refDayPos = -1;
startEndProfHourPos = -1;
profPresPos = -1;
idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData) == 1);
if (~isempty(idVal))
   configStruct = metaData{idVal+1};
   fieldNames = fieldnames(configStruct);
   
   for id = 1:length(fieldNames)
      valueStr = getfield(configStruct, fieldNames{id});
      if (strfind(getfield(configStruct, fieldNames{id}), 'MC6_'))
         delayBeforeMissionPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'PM4_'))
         delayBeforeMissionPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'PA6_'))
         preludeDurationPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'AC6_'))
         preludeDurationPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'PM1_'))
         cycleDurationPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'MC1_'))
         nbCyclesFirstMissionPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'MC2_'))
         cycleDuration1Pos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'MC3_'))
         cycleDuration2Pos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'PM2_'))
         refDayPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'MC4_'))
         refDayPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'PM3_'))
         startEndProfHourPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'MC5_'))
         startEndProfHourPos = id;
      elseif (strfind(getfield(configStruct, fieldNames{id}), 'PM9_'))
         profPresPos = id;
      end
   end
end

delayBeforeMission = g_decArgo_durationDef;
preludeDuration = g_decArgo_durationDef;
cycleDuration = g_decArgo_durationDef;
nbCyclesFirstMission = -1;
cycleDuration1 = g_decArgo_durationDef;
cycleDuration2 = g_decArgo_durationDef;
refDay = g_decArgo_durationDef;
startEndProfHour = -1;
profPres = g_decArgo_presDef;
idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData) == 1);
if (~isempty(idVal))
   tabStruct = metaData{idVal+1};
   
   tabDelayBeforeMission = [];
   tabPreludeDuration = [];
   tabCycleDuration = [];
   tabNbCyclesFirstMission = [];
   tabCycleDuration1 = [];
   tabCycleDuration2 = [];
   tabRefDay = [];
   tabStartEndProfHour = [];
   tabProfPres = [];
   
   if (length(tabStruct) > 1)
      
      for id = 1:length(tabStruct)
         if (delayBeforeMissionPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               delayBeforeMissionPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabDelayBeforeMission = [tabDelayBeforeMission str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (preludeDurationPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               preludeDurationPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabPreludeDuration = [tabPreludeDuration str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (cycleDurationPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               cycleDurationPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabCycleDuration = [tabCycleDuration str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (nbCyclesFirstMissionPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               nbCyclesFirstMissionPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabNbCyclesFirstMission = [tabNbCyclesFirstMission str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (cycleDuration1Pos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               cycleDuration1Pos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabCycleDuration1 = [tabCycleDuration1 str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (cycleDuration2Pos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               cycleDuration2Pos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabCycleDuration2 = [tabCycleDuration2 str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (refDayPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               refDayPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabRefDay = [tabRefDay str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (startEndProfHourPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               startEndProfHourPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabStartEndProfHour = [tabStartEndProfHour str2num(tabStruct{id}.(fieldName))];
            end
         end
         if (profPresPos ~= -1)
            fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d_%d', ...
               profPresPos, id);
            if (~isempty(tabStruct{id}.(fieldName)))
               tabProfPres = [tabProfPres str2num(tabStruct{id}.(fieldName))];
            end
         end
      end
      
      if (~isempty(tabDelayBeforeMission))
         delayBeforeMission = tabDelayBeforeMission(1);
      end
      if (~isempty(tabPreludeDuration))
         preludeDuration = tabPreludeDuration(1);
      end
      if (~isempty(tabCycleDuration))
         cycleDuration = tabCycleDuration(end);
      end
      if (~isempty(tabNbCyclesFirstMission))
         nbCyclesFirstMission = tabNbCyclesFirstMission(end);
      end
      if (~isempty(tabCycleDuration1))
         cycleDuration1 = tabCycleDuration1(end);
      end
      if (~isempty(tabCycleDuration2))
         cycleDuration2 = tabCycleDuration2(end);
      end
      if (~isempty(tabRefDay))
         refDay = tabRefDay(1);
      end
      if (~isempty(tabStartEndProfHour))
         startEndProfHour = tabStartEndProfHour(1);
      end
      if (~isempty(tabProfPres))
         profPres = tabProfPres(1);
      end
      
   else
      
      if (delayBeforeMissionPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            delayBeforeMissionPos);
         if (~isempty(tabStruct.(fieldName)))
            delayBeforeMission = str2num(tabStruct.(fieldName));
         end
      end
      if (preludeDurationPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            preludeDurationPos);
         if (~isempty(tabStruct.(fieldName)))
            preludeDuration = str2num(tabStruct.(fieldName));
         end
      end
      if (cycleDurationPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            cycleDurationPos);
         if (~isempty(tabStruct.(fieldName)))
            cycleDuration = str2num(tabStruct.(fieldName));
         end
      end
      if (nbCyclesFirstMissionPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            nbCyclesFirstMissionPos);
         if (~isempty(tabStruct.(fieldName)))
            nbCyclesFirstMission = str2num(tabStruct.(fieldName));
         end
      end
      if (cycleDuration1Pos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            cycleDuration1Pos);
         if (~isempty(tabStruct.(fieldName)))
            cycleDuration1 = str2num(tabStruct.(fieldName));
         end
      end
      if (cycleDuration2Pos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            cycleDuration2Pos);
         if (~isempty(tabStruct.(fieldName)))
            cycleDuration2 = str2num(tabStruct.(fieldName));
         end
      end
      if (refDayPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            refDayPos);
         if (~isempty(tabStruct.(fieldName)))
            refDay = str2num(tabStruct.(fieldName));
         end
      end
      if (startEndProfHourPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            startEndProfHourPos);
         if (~isempty(tabStruct.(fieldName)))
            startEndProfHour = str2num(tabStruct.(fieldName));
         end
      end
      if (profPresPos ~= -1)
         fieldName = sprintf('CONFIG_PARAMETER_VALUE_%d', ...
            profPresPos);
         if (~isempty(tabStruct.(fieldName)))
            profPres = str2num(tabStruct.(fieldName));
         end
      end
      
   end
end

if (delayBeforeMission == g_decArgo_durationDef)
   delayBeforeMission = 0;
end

if (preludeDuration == g_decArgo_durationDef)
   preludeDuration = get_default_prelude_duration(a_floatDecId);
end

if ((cycleDuration == g_decArgo_durationDef) && (nbCyclesFirstMission == 0))
   cycleDuration = a_floatCycleTime/24;
end

% estimate the date of the end of the first profile
firstProfileEndDate = g_decArgo_dateDef;
switch (a_floatDecId)
   
   case {1, 11, 12, 4, 19, 3}
      % PM3 is the hour of the start of the profile
      if ((refDay ~= g_decArgo_durationDef) && (startEndProfHour ~= -1) && (profPres ~= g_decArgo_presDef)) 
         firstProfileEndDate = a_floatRefDay + refDay + startEndProfHour/24 + profPres/8640;
      end

   case {24, 27, 25, 28, 29, 17, 30, 31}
      % PM3 (MC5) is the hour of the end of the profile
      if ((refDay ~= g_decArgo_durationDef) && (startEndProfHour ~= -1)) 
         firstProfileEndDate = a_floatRefDay + refDay + startEndProfHour/24;
      end

   otherwise
      fprintf('WARNING: No rules to compute first profile end date for decoderId #%d\n', a_floatDecId);
      
end

% configuration parameters
if ~((launchDate == g_decArgo_dateDef) || ...
      (delayBeforeMission == g_decArgo_durationDef) || ...
      (preludeDuration == g_decArgo_durationDef) || ...
      (firstProfileEndDate == g_decArgo_dateDef) || ...
      (cycleDuration == g_decArgo_durationDef))
   o_launchDate = launchDate;
   o_delayBeforeMission = delayBeforeMission;
   o_preludeDuration = preludeDuration;
   o_firstProfileEndDate = firstProfileEndDate;
   o_cycleDuration = cycleDuration;
elseif ~((launchDate == g_decArgo_dateDef) || ...
      (delayBeforeMission == g_decArgo_durationDef) || ...
      (preludeDuration == g_decArgo_durationDef) || ...
      (firstProfileEndDate == g_decArgo_dateDef) || ...
      (nbCyclesFirstMission == -1) || ...
      (cycleDuration1 == g_decArgo_durationDef) || ...
      (cycleDuration2 == g_decArgo_durationDef))
   o_launchDate = launchDate;
   o_delayBeforeMission = delayBeforeMission;
   o_preludeDuration = preludeDuration;
   o_firstProfileEndDate = firstProfileEndDate;
   o_nbCyclesFirstMission = nbCyclesFirstMission;
   o_cycleDuration = [cycleDuration1 cycleDuration2]/24;
end

return;
