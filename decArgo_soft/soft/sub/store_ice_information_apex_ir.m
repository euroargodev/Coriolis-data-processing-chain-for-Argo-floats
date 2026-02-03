% ------------------------------------------------------------------------------
% Store ICE related information for delayed check.
%
% SYNTAX :
% store_ice_information_apex_ir( ...
%   a_iceDetection, a_timeData, a_techData, ...
%   a_profLrData, a_profHrData, a_nearSurfData, a_surfDataMsg)
%
% INPUT PARAMETERS :
%   a_iceDetection : ice detection data
%   a_timeDataLog  : cycle timings
%   a_tabTech      : technical data
%   a_profLrData   : profile LR data
%   a_profHrData   : profile HR data
%   a_nearSurfData : NS data
%   a_surfDataMsg  : surface data from engineering data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/03/2025 - RNU - creation
% ------------------------------------------------------------------------------
function store_ice_information_apex_ir( ...
   a_iceDetection, a_timeData, a_techData, ...
   a_profLrData, a_profHrData, a_surfDataMsg)

% current cycle number
global g_decArgo_cycleNum;

% to store ICE data used for delayed processing
global g_decArgo_iceData;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


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
confVal = get_config_value_apx_ir('CONFIG_IEP_IceDetectionMinPres', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceEvasionP = confVal;
end
iceCriticalT = nan;
confVal = get_config_value_apx_ir('CONFIG_IMLT_IceDetectionTemperature', g_decArgo_cycleNum);
if (~isempty(confVal))
   iceCriticalT = confVal;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TECHNICAL

techIER = nan;
if (~isempty(a_techData))
   techDataAll = [a_techData{:}];
   idF = find([techDataAll.techId] == 1016);
   if (~isempty(idF))
      % IceEvasionRecord
      techIER = bin2dec(a_techData{idF(1)}.value);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVENTS

nbMlSample = nan;
isaTime = nan;
isaPres = nan;
evasionTime = nan;
evasionPres = nan;
evasionMlt = nan;
evasionNbMlSample = nan;
evasionIer = nan;
evasionPerigeeTime = nan;
evasionPerigeePres = nan;
satmaskFlag = nan;
breakupFlag = nan;
if (~isempty(a_iceDetection))
   if (~isempty(a_iceDetection.mlSample))
      nbMlSample = length(a_iceDetection.mlSample);
   end
   if (a_iceDetection.isaTime ~= g_decArgo_dateDef)
      isaTime = a_iceDetection.isaTime;
   end
   if (a_iceDetection.isaPres ~= g_decArgo_presDef)
      isaPres = a_iceDetection.isaPres;
   end
   if (a_iceDetection.evasionTime ~= g_decArgo_dateDef)
      evasionTime = a_iceDetection.evasionTime;
   end
   if (a_iceDetection.evasionPres ~= g_decArgo_presDef)
      evasionPres = a_iceDetection.evasionPres;
   end
   if (~isempty(a_iceDetection.evasionMlt))
      evasionMlt = a_iceDetection.evasionMlt;
   end
   if (~isempty(a_iceDetection.evasionNbSamp))
      evasionNbMlSample = a_iceDetection.evasionNbSamp;
   end
   if (~isempty(a_iceDetection.evasionIer))
      evasionIer = a_iceDetection.evasionIer;
   end
   if (a_iceDetection.evasionPerigeeTime ~= g_decArgo_dateDef)
      evasionPerigeeTime = a_iceDetection.evasionPerigeeTime;
   end
   if (a_iceDetection.evasionPerigeePres ~= g_decArgo_presDef)
      evasionPerigeePres = a_iceDetection.evasionPerigeePres;
   end
   if (a_iceDetection.satmaskFlag == 1)
      satmaskFlag = a_iceDetection.satmaskFlag;
   end
   if (a_iceDetection.breakupFlag == 1)
      breakupFlag = a_iceDetection.breakupFlag;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIMES

ascentStartTime = nan;
ascentEndTime = nan;
transStartTime = nan;
transEndTime = nan;
if (~isempty(a_timeData))
   if (~isempty(a_timeData.ascentStartDate))
      ascentStartTime = a_timeData.ascentStartDate;
   end
   if (~isempty(a_timeData.ascentEndDate))
      ascentEndTime = a_timeData.ascentEndDate;
   end
   if (~isempty(a_timeData.transStartDate))
      transStartTime = a_timeData.transStartDate;
   end
   if (~isempty(a_timeData.transEndDate))
      transEndTime = a_timeData.transEndDate;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRESSURE MEASUREMENTS

presMin = realmax("double");
paramPres = get_netcdf_param_attributes('PRES');
if (~isempty(a_profLrData))
   idPres = find(strcmp({a_profLrData.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      profPresMeas = a_profLrData.data(:, idPres);
      presMin = min([presMin min(profPresMeas(profPresMeas ~= paramPres.fillValue))]);
   end
end
if (~isempty(a_profHrData))
   idPres = find(strcmp({a_profHrData.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      profPresMeas = a_profHrData.data(:, idPres);
      presMin = min([presMin min(profPresMeas(profPresMeas ~= paramPres.fillValue))]);
   end
end
if (~isempty(a_surfDataMsg))
   if (iscell(a_surfDataMsg))
      a_surfDataMsg = a_surfDataMsg{:};
   end
   idPres = find(strcmp({a_surfDataMsg.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      profPresMeas = a_surfDataMsg.data(:, idPres);
      presMin = min([presMin min(profPresMeas(profPresMeas ~= paramPres.fillValue))]);
   end
end
if (presMin == realmax("double"))
   presMin = nan;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

% ICE data information
% 1- cycle number
% 2- ICE months
% 3- ICE detection PRES
% 4- ICE evasion PRES
% 5- ICE critical TEMP
% 6- nb sample
% 7- ISA time
% 8- ISA PRES
% 9- evasion time
% 10- evasion pres
% 11- evasion ml T
% 12- evasion nb sample
% 13- evasion IER
% 14- tech IER
% 15- evasion perigee time
% 16- evasion perigee pres
% 17- sat_mask flag
% 18- breakup flag
% 19- AST
% 20- AET
% 21- TST
% 22- TET
% 23- min PRES meas

g_decArgo_iceData = [g_decArgo_iceData; ...
   [g_decArgo_cycleNum, ...
   iceMonths, iceDetectionP, iceEvasionP, iceCriticalT, ...
   nbMlSample, isaTime, isaPres, ...
   evasionTime, evasionPres, evasionMlt, evasionNbMlSample, evasionIer, techIER, ...
   evasionPerigeeTime, evasionPerigeePres, ...
   satmaskFlag, breakupFlag, ...
   ascentStartTime, ascentEndTime, transStartTime, transEndTime, ...
   presMin ...
   ]];

return
