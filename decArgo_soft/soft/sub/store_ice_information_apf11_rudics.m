% ------------------------------------------------------------------------------
% Store ICE related information for delayed check.
%
% SYNTAX :
% store_ice_information_apf11_rudics(a_iceDetection, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_iceDetection  : ice detection data
%   a_cycleTimeData : cycle timings data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/07/2024 - RNU - creation
% ------------------------------------------------------------------------------
function store_ice_information_apf11_rudics(a_iceDetection, a_cycleTimeData)

% current cycle number
global g_decArgo_cycleNum;

% to store ICE data used for delayed processing
global g_decArgo_iceData;


if (g_decArgo_cycleNum == 0)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION

% retrieve ICE configuration values
iceMonths = nan;
confVal = get_config_value_apx_ir('CONFIG_ICEM_IceDetectionMask', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceMonths = confVal;
end

if (isnan(iceMonths) && isempty(g_decArgo_iceData)) % the ICE algorithm may have been switched on and off
   return
end

iceDetectionP = nan;
confVal = get_config_value_apx_ir('CONFIG_IDP_IceDetectionMaxPres', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceDetectionP = confVal;
end
iceEvasionP = nan;
confVal = get_config_value_apx_ir('CONFIG_IEP_IceEvasionPressure', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceEvasionP = confVal;
end
iceCriticalT = nan;
confVal = get_config_value_apx_ir('CONFIG_IMLT_IceDetectionTemperature', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceCriticalT = confVal;
end
iceBreakupDays = nan;
confVal = get_config_value_apx_ir('CONFIG_IBD_IceBreakupDays', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceBreakupDays = confVal;
end
iceDescentCycles = nan;
confVal = get_config_value_apx_ir('CONFIG_IDC_IceDescentCycles', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceDescentCycles = confVal;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICE EVENTS

isaFlag = 0;
isaTime = nan;
isaPres = nan;
breakupFlag = nan;
breakupTime = nan;
satMaskFlag = 0;
satMaskTime = nan;
satMaskPres = nan;
profAbortType = 0;
profAbortTime = nan;
profAbortPerigeeTime = nan;
profAbortPerigeePres = nan;
iceCycleNumber = nan;
iceAvoidanceEnabledFlag = nan;
foundSkyFlag = nan;

if (~isempty(a_iceDetection))
   if (~isempty(a_iceDetection.thermalDetect))
      if (~isempty(a_iceDetection.thermalDetect(end).detectTime))
         isaFlag = 1;
         isaTime = a_iceDetection.thermalDetect(end).detectTime;
         isaPres = a_iceDetection.thermalDetect(end).detectPres;
      end
   end
   if (~isempty(a_iceDetection.breakupDetect))
      if (a_iceDetection.breakupDetect(end).detectFlag == 1)
         breakupFlag = 1;
         breakupTime = a_iceDetection.breakupDetect(end).detectTime;
      else
         breakupFlag = 0;
      end
   end
   if (~isempty(a_iceDetection.capDetect))
      satMaskFlag = 1;
      satMaskTime = a_iceDetection.capDetect(end).detectTime;
      satMaskPres = a_iceDetection.capDetect(end).detectPres;
   end
   if (~isempty(a_iceDetection.ascentAbort))
      profAbortType = a_iceDetection.ascentAbort.abortType;
      profAbortTime = a_iceDetection.ascentAbort.abortTypeTime;
   end
   if (~isempty(a_iceDetection.ascentPerigeeTime))
      profAbortPerigeeTime = a_iceDetection.ascentPerigeeTime;
      profAbortPerigeePres = a_iceDetection.ascentPerigeePres;
   end
   if (~isempty(a_iceDetection.iceCycleNumbers))
      iceCycleNumber = max(a_iceDetection.iceCycleNumbers);
   end
   if (~isempty(a_iceDetection.iceAvoidanceEnabledFlag))
      iceAvoidanceEnabledFlag = a_iceDetection.iceAvoidanceEnabledFlag;
   end
   if (~isempty(a_iceDetection.foundSkyFlag))
      foundSkyFlag = a_iceDetection.foundSkyFlag;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIMES

ascentStartTime = nan;
ascentEndTime = nan;
transStartTime = nan;

if (~isempty(a_cycleTimeData))
   if (~isempty(a_cycleTimeData.ascentStartDateSci))
      ascentStartTime = a_cycleTimeData.ascentStartDateSci;
   elseif (~isempty(a_cycleTimeData.ascentStartDateSys))
      ascentStartTime = a_cycleTimeData.ascentStartDateSys;
   end
   if (~isempty(a_cycleTimeData.ascentEndDate))
      ascentEndTime = a_cycleTimeData.ascentEndDate;
   end
   if (~isempty(a_cycleTimeData.transStartDate))
      transStartTime = a_cycleTimeData.transStartDate;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

% ICE data information
% 1- cycle number
% 2- ICE months
% 3- ICE detection PRES
% 4- ICE evasion PRES
% 5- ICE critical TEMP
% 6- ICE breakup days
% 7- ICE descent cycles
% 8- ISA flag
% 9- ISA time
% 10- ISA PRES
% 11- breakup flag
% 12- breakup time
% 13- sat mask flag
% 14- sat mask time
% 15- sat mask pres
% 16- profile aborted type
% 17- profile aborted time
% 18- profile aborted perigee time
% 19- profile aborted perigee pres
% 20- ICE avoidance enable
% 21- nb ICE cycles
% 22- found sky flag
% 23- AST
% 24- AET
% 25- TST

g_decArgo_iceData = [g_decArgo_iceData; ...
   [g_decArgo_cycleNum, ...
   iceMonths, iceDetectionP, iceEvasionP, iceCriticalT, iceBreakupDays, iceDescentCycles, ...
   isaFlag, isaTime, isaPres, ...
   breakupFlag, breakupTime, ...
   satMaskFlag, satMaskTime, satMaskPres, ...
   profAbortType, profAbortTime, profAbortPerigeeTime, profAbortPerigeePres, ...
   iceAvoidanceEnabledFlag, iceCycleNumber, foundSkyFlag, ...
   ascentStartTime, ascentEndTime, transStartTime ...
   ]];

return
