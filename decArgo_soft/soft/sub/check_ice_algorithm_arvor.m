% ------------------------------------------------------------------------------
% Check ICE collected data (in g_decArgo_iceData) to set the float status
% (breakup, forced or none) and associated ICE flags (ISA, sat mask or hanging)
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
%   check_ice_algorithm_arvor(a_decoderId, ...
%   a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_decoderId      : float decoder Id
%   a_tabProfiles    : input decoded profiles
%   a_tabTrajNMeas   : input trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input trajectory N_CYCLE data
%   a_tabNcTechIndex : input technical index information
%   a_tabNcTechVal   : input technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output decoded profiles
%   o_tabTrajNMeas   : output trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : output trajectory N_CYCLE data
%   o_tabNcTechIndex : output technical index information
%   o_tabNcTechVal   : output technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
   check_ice_algorithm_arvor(a_decoderId, ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;

% float configuration
global g_decArgo_floatConfig;

% to store ICE data used to simulate ICE algorithm (in CSV output only)
global g_decArgo_iceData;

% configuration values
global g_decArgo_dirOutputCsvFile;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% to store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag is
% not the same as the final one)
global g_decArgo_cycleTimeData;

% array to store GPS data
global g_decArgo_gpsData;

% default values
global g_decArgo_ncDateDef;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% global measurement codes
global g_MC_IceAscentAbort;
global g_MC_AET;
global g_MC_TST;
global g_MC_TET;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_9;


% decId concerned by ICE algorithm
% 212 5.45 : ARVOR ARN Ir Ice
% 217 5.46 : ARVOR-ARN-DO Ir Ice
% 222 5.47 : ARVOR-ARN Ir Ice
% 223 5.48 : ARVOR-ARN-DO Ir Ice
% 224 5.49 : ARVOR ARN Ir Ice with RBR
% 225 5.76 : ARVOR-ARN-DO Ir Ice
% 226 5.51 : ARVOR ARN Ir Ice with RBR 1 Hz
% 227 5.52 : Arvor-ARN-Ice RBR 1 Hz + auto corrected PSAL
% 231 5.53 : ARVOR-ARN-Ice SBE Iridium
% 232 5.54 : ARVOR-ARN Ir Ice
%
% 214 5.75 : PROVOR ARN DO Ir Ice
%
% 216 5.65 : ARVOR_DEEP 4000
% 218 5.66 : ARVOR_DEEP 4000
% 221 5.67 : ARVOR_DEEP 4000
% 228 5.68 : ARVOR_DEEP 4000 3T => not used not implemented
% 229 5.69 : ARVOR_DEEP 4000 2T => not used not implemented

if (~ismember(a_decoderId, [212, 217, 222:227, 231, 232, 214, 216, 218, 221]))
   return
end

if (a_decoderId == 216)
   % ICE mode is supposed to be activated
   g_decArgo_7TypePacketReceivedCyNum = 0;
end

% check if ICE mode has been activated
if (isempty(g_decArgo_7TypePacketReceivedCyNum))
   return
end

fprintf('INFO: Float #%d: checking ICE information\n', ...
   g_decArgo_floatNum);

if (isempty(g_decArgo_iceData))
   fprintf('INFO: Float #%d: no ICE information to check\n', ...
      g_decArgo_floatNum);
   return
end

if (isempty(g_decArgo_7TypePacketReceivedCyNum))
   % ICE algorithm not activated
   return
end

% remove cycle #0
idFC0 = find(g_decArgo_iceData(:, 2) == 0);
g_decArgo_iceData(idFC0, :) = [];

% remove multiple cycles (keep only the first item and useful information from
% the second one)
tabTmpCyNum = g_decArgo_iceData(:, 2);

g_decArgo_iceData = cat(2, g_decArgo_iceData, nan(size(g_decArgo_iceData, 1), 2));
if (length(tabTmpCyNum) ~= length(unique(tabTmpCyNum)))
   uTabTmpCyNum = unique(tabTmpCyNum);
   nbElts = hist(tabTmpCyNum, uTabTmpCyNum);
   idMulti = find(nbElts > 1);
   idDel = [];
   for id = idMulti
      idF = find(tabTmpCyNum == uTabTmpCyNum(id));
      % store "nb SBD Rx" and "nb SBD Tx" of the second item before removing
      if (~isnan(g_decArgo_iceData(idF(2), 18)))
         g_decArgo_iceData(idF(1), end-1) = g_decArgo_iceData(idF(2), 18);
      end
      if (~isnan(g_decArgo_iceData(idF(2), 19)))
         g_decArgo_iceData(idF(1), end) = g_decArgo_iceData(idF(2), 19);
      end
      idDel = [idDel; idF(2:end)];
   end
   g_decArgo_iceData(idDel, :) = [];
   tabTmpCyNum = g_decArgo_iceData(:, 2);
end

% retrieve configuration parameter values
confLabelIc0 = '';
confLabelIc1 = '';
confLabelIc2 = '';
confLabelIc3 = '';
confLabelIc4 = '';
confLabelIc11 = '';
confLabelTc23 = '';
switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      confLabelIc0 = 'CONFIG_IC00_';
      confLabelIc1 = 'CONFIG_IC01_';
      confLabelIc2 = 'CONFIG_IC02_';
      confLabelIc3 = 'CONFIG_IC03_';
      confLabelIc4 = 'CONFIG_IC04_';
      confLabelIc11 = 'CONFIG_IC11_';
      confLabelTc23 = 'CONFIG_TC23_';
   case {216}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc1 = 'CONFIG_PG01';
      confLabelIc2 = '';
      confLabelIc3 = 'CONFIG_PG02';
      confLabelIc4 = 'CONFIG_PG03';
      confLabelIc11 = '';
      confLabelTc23 = 'CONFIG_PT34';
   case {218}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc1 = 'CONFIG_PG01';
      confLabelIc2 = 'CONFIG_PG02';
      confLabelIc3 = 'CONFIG_PG03';
      confLabelIc4 = 'CONFIG_PG04';
      confLabelIc11 = 'CONFIG_PG11';
      confLabelTc23 = '';
   case {221}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc1 = 'CONFIG_PG01';
      confLabelIc2 = 'CONFIG_PG02';
      confLabelIc3 = 'CONFIG_PG03';
      confLabelIc4 = 'CONFIG_PG04';
      confLabelIc11 = 'CONFIG_PG11';
      confLabelTc23 = 'CONFIG_PT34';
end

tabTmpIc0 = nan(length(tabTmpCyNum), 1);
tabTmpIc1 = nan(length(tabTmpCyNum), 1);
tabTmpIc2 = nan(length(tabTmpCyNum), 1);
tabTmpIc3 = nan(length(tabTmpCyNum), 1);
tabTmpIc4 = nan(length(tabTmpCyNum), 1);
tabTmpIc11 = nan(length(tabTmpCyNum), 1);
tabTmpTc23 = nan(length(tabTmpCyNum), 1);
for idC = 1:length(tabTmpCyNum)
   cyNum = tabTmpCyNum(idC);
   configNames = [];
   while (cyNum >= 0)
      if (any(g_decArgo_floatConfig.USE.CYCLE == cyNum))
         [configNames, configValues] = get_float_config_ir_sbd(cyNum);
         break
      end
      cyNum = cyNum - 1;
   end
   if (isempty(configNames))
      % there is no configuration assigned yet
      % retrieve the last temporary one
      configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
      configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
   end
   if (~isempty(confLabelIc0))
      tabTmpIc0(idC) = get_config_value2(confLabelIc0, configNames, configValues);
   end
   if (~isempty(confLabelIc1))
      tabTmpIc1(idC) = get_config_value2(confLabelIc1, configNames, configValues);
   end
   if (~isempty(confLabelIc2))
      tabTmpIc2(idC) = get_config_value2(confLabelIc2, configNames, configValues);
   elseif (a_decoderId == 216)
      tabTmpIc2(idC) = 1;
   end
   if (~isempty(confLabelIc3))
      tabTmpIc3(idC) = get_config_value2(confLabelIc3, configNames, configValues);
   end
   if (~isempty(confLabelIc4))
      tabTmpIc4(idC) = get_config_value2(confLabelIc4, configNames, configValues);
   end
   if (~isempty(confLabelIc11))
      tabTmpIc11(idC) = get_config_value2(confLabelIc11, configNames, configValues);
   end
   if (~isempty(confLabelTc23))
      tabTmpTc23(idC) = get_config_value2(confLabelTc23, configNames, configValues);
   end
end

% retrieve techId for
% PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar information
offsetTechId = '';
switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      offsetTechId = 127;
   case {216, 218, 221, 228, 229, 230}
      offsetTechId = 124;
end

% set final cycle number data array
cyNumList = g_decArgo_iceData(:, 2);
tabCyNum = (min(cyNumList):max(cyNumList))';
idMap = nan(size(cyNumList));
for idC = 1:length(cyNumList)
   idMap(idC) = find(tabCyNum == cyNumList(idC));
end

% ICE data information
% 1- float number
% 2- cycle number
% 3- deep cycle flag
% 4- Iridium session number
% 5- Ascent Start Time
% 6- float time
% 7- reported ICE detection flag
% 8- GPS/Iridium transmission flag
% 9- min PRES measurement of profile, NS, IA or subsurface measurement
% 10- nb inAir measurements
% 11- pressure of subsurface measurement
% 12- min PRES measurement of profile
% 13- pump switch off from config
% 14- Transmission Start Time
% 15- GPS valid fix
% 16- GPS session duration
% 17- GPS session timeout
% 18- nb SBD Rx
% 19- nb SBD Tx
% 20- Iridium session duration
% 21- Surface PRES offset
% 22- RT aborted flag

tabIc0 = nan(length(tabCyNum), 1);
tabIc0(idMap) = tabTmpIc0;
tabIc1 = nan(length(tabCyNum), 1);
tabIc1(idMap) = tabTmpIc1;
tabIc2 = nan(length(tabCyNum), 1);
tabIc2(idMap) = tabTmpIc2;
tabIc11 = nan(length(tabCyNum), 1);
tabIc11(idMap) = tabTmpIc11;
tabTc23 = nan(length(tabCyNum), 1);
tabTc23(idMap) = tabTmpTc23;
tabIceActivatedFlag = nan(length(tabCyNum), 1); % set to 1 when IC0 > 0
tabAst = nan(length(tabCyNum), 1);
tabAst(idMap) = g_decArgo_iceData(:, 5);
tabFloatTime = nan(length(tabCyNum), 1);
tabFloatTime(idMap) = g_decArgo_iceData(:, 6);
tabIceFlag = nan(length(tabCyNum), 1);
tabIceFlag(idMap) = g_decArgo_iceData(:, 7);
tabIsaFlag = nan(length(tabCyNum), 1);
tabSatMaskFlag = nan(length(tabCyNum), 1); % deduced from float transmitted ICE flag
tabSatMaskFlag2 = nan(length(tabCyNum), 1); % computed from "GPS valid fix", "nb SBD Rx" and "nb SBD Tx"
tabHangingFlag = nan(length(tabCyNum), 1);
tabIsaCount = nan(length(tabCyNum), 1);
tabBreakupFlag = nan(length(tabCyNum), 1);
tabForcedFlag = nan(length(tabCyNum), 1); % computed from inputs
tabForcedFlag2 = nan(length(tabCyNum), 1); % deduced from validFix = 255 when in breakup
tabBreakupStart = nan(length(tabCyNum), 1);
tabBreakupEnd = nan(length(tabCyNum), 1);
tabForcedRefTime = nan(length(tabCyNum), 1);
tabForcedGoTime = nan(length(tabCyNum), 1);
tabProfAbortedFlag = nan(length(tabCyNum), 1); % 1 if ascent should be aborted
tabNoSurfFlag = nan(length(tabCyNum), 1); % 1 if no transmission is supposed to occur
tabTransFlag = nan(length(tabCyNum), 1); % 1 if any GPS or Iridium message is available
tabTransFlag(idMap) = g_decArgo_iceData(:, 8);
tabMinPres = nan(length(tabCyNum), 1); % min PRES sampled from profile, NS, IA and subsurface measurements
tabMinPres(idMap) = g_decArgo_iceData(:, 9);
tabAnomaly = nan(length(tabCyNum), 1); % consistency between tabNoSurfFlag and tabTransFlag
tabAnomaly2 = nan(length(tabCyNum), 1); % comprison of  RT flag and delayed one (tabRtAborted and tabProfAbortedFlag)
tabAnomaly3 = nan(length(tabCyNum), 1); % check that surf PRES offset is 0 when tabTransFlag = 0 (no resetoffset performed)
tabNbInAir = nan(length(tabCyNum), 1); % number of IN AIR measurements
tabNbInAir(idMap) = g_decArgo_iceData(:, 10);
tabSubsurfPres = nan(length(tabCyNum), 1); % PRES of last profile pumped raw measurement
tabSubsurfPres(idMap) = g_decArgo_iceData(:, 11);
tabMinProfPres = nan(length(tabCyNum), 1); % min PRES of ascending profile
tabMinProfPres(idMap) = g_decArgo_iceData(:, 12);
tabPumpSwitchOffPresCfg = nan(length(tabCyNum), 1); % configured PUMP switch off pressure
tabPumpSwitchOffPresCfg(idMap) = g_decArgo_iceData(:, 13);
tabTst = nan(length(tabCyNum), 1);
tabTst(idMap) = g_decArgo_iceData(:, 14);
tabIsaStartPres = nan(length(tabCyNum), 1); % configured start PRES for ISA detection
tabIsaStartPres(idMap) = tabTmpIc3;
tabIsaStopPres = nan(length(tabCyNum), 1); % configured stop PRES for ISA detection
tabIsaStopPres(idMap) = tabTmpIc4;
tabGpsValidFix = nan(length(tabCyNum), 1);
tabGpsValidFix(idMap) = g_decArgo_iceData(:, 15);
tabGpsSessionDuration = nan(length(tabCyNum), 1);
tabGpsSessionDuration(idMap) = g_decArgo_iceData(:, 16);
tabGpsSessionTimeout = nan(length(tabCyNum), 1);
tabGpsSessionTimeout(idMap) = g_decArgo_iceData(:, 17);
tabIrSessionDuration = nan(length(tabCyNum), 1);
tabIrSessionDuration(idMap) = g_decArgo_iceData(:, 20);
tabIrSessionDuration2 = nan(length(tabCyNum), 1);
tabNbSbdRx = nan(length(tabCyNum), 1);
tabNbSbdRx(idMap) = g_decArgo_iceData(:, 18);
tabNbSbdRx2 = nan(length(tabCyNum), 1);
tabNbSbdRx3 = nan(length(tabCyNum), 1);
tabNbSbdRx3(idMap) = g_decArgo_iceData(:, end-1);
tabNbSbdTx = nan(length(tabCyNum), 1);
tabNbSbdTx(idMap) = g_decArgo_iceData(:, 19);
tabNbSbdTx2 = nan(length(tabCyNum), 1);
tabNbSbdTx3 = nan(length(tabCyNum), 1);
tabNbSbdTx3(idMap) = g_decArgo_iceData(:, end);
tabSurfPres = nan(length(tabCyNum), 1);
tabSurfPres(idMap) = g_decArgo_iceData(:, 21);
tabSurfPres2 = nan(length(tabCyNum), 1);
tabRtAborted = nan(length(tabCyNum), 1);
tabRtAborted(idMap) = g_decArgo_iceData(:, 22);

% set tabIrSessionDuration2 and tabSurfPres2
for id = 1:length(tabCyNum)
   idNext = find(tabCyNum == tabCyNum(id) + 1);
   if (~isempty(idNext))
      tabIrSessionDuration2(id) = tabIrSessionDuration(idNext);
      tabSurfPres2(id) = tabSurfPres(idNext);
   end
end

% set ICE activated flag (IC0 > 0)
tabIceActivatedFlag(~isnan(tabCyNum)) = 0;
tabIceActivatedFlag(tabIc0 > 0) = 1;
if (all(tabIceActivatedFlag(~isnan(tabIceActivatedFlag)) == 0))
   fprintf('WARNING: Float #%d: ICE algorithm is never activated (IC0 = 0)\n', ...
      g_decArgo_floatNum);
end

% set ISA, sat mask and hanging flags
for id = 1:length(tabCyNum)
   idPrev = find(tabCyNum == tabCyNum(id) - 1);
   if (tabIceFlag(id) == 0)
      tabIsaFlag(id) = 0;
      if (~isempty(idPrev))
         tabSatMaskFlag(idPrev) = 0;
      end
      tabHangingFlag(id) = 0;
   elseif (tabIceFlag(id) == 1)
      tabIsaFlag(id) = 1;
      if (~isempty(idPrev))
         tabSatMaskFlag(idPrev) = 0;
      end
      tabHangingFlag(id) = 0;
   elseif (tabIceFlag(id) == 2)
      tabIsaFlag(id) = 0;
      if (~isempty(idPrev))
         tabSatMaskFlag(idPrev) = 1;
      end
      tabHangingFlag(id) = 0;
   elseif (tabIceFlag(id) == 3)
      tabIsaFlag(id) = 1;
      if (~isempty(idPrev))
         tabSatMaskFlag(idPrev) = 1;
      end
      tabHangingFlag(id) = 0;
   elseif (tabIceFlag(id) == 4)
      tabIsaFlag(id) = 0;
      if (~isempty(idPrev))
         tabSatMaskFlag(idPrev) = 0;
      end
      tabHangingFlag(id) = 1;
   end
end

% set ISA detection counter
tabIsaCount(~isnan(tabCyNum)) = 0;
for id = 1:length(tabCyNum)
   if (tabIsaFlag(id) == 1)
      idPrev = find(tabCyNum == tabCyNum(id) - 1);
      if (~isempty(idPrev))
         tabIsaCount(id) = tabIsaCount(idPrev) + 1;
      else
         tabIsaCount(id) = 1;
      end
   end
end

% set tabNbSbdRx2, tabNbSbdTx2 and tabSatMaskFlag2
tabSatMaskFlag2(~isnan(tabCyNum)) = 0;
for id = 1:length(tabCyNum)
   done = 0;
   if (~isnan(tabNbSbdRx3(id)) && ~isnan(tabNbSbdTx3(id)))
      % recovered from removed items
      tabNbSbdRx2(id) = tabNbSbdRx3(id);
      tabNbSbdTx2(id) = tabNbSbdTx3(id);
   else
      idNext = find(tabCyNum == tabCyNum(id) + 1);
      if (~isempty(idNext))
         tabNbSbdRx2(id) = tabNbSbdRx(idNext);
         tabNbSbdTx2(id) = tabNbSbdTx(idNext);
      elseif (id == length(tabCyNum))
         if ((tabGpsValidFix(id) == 0)  && ...
               (isnan(tabNbSbdRx2(id)) && isnan(tabNbSbdTx2(id)))) % 6903230
            % we don't know, we assume the non transmission is due to a sat mask
            if (tabTransFlag(id) == 0)
               tabSatMaskFlag2(id) = 1;
            end
            done = 1;
         end
      end
   end

   if (~done)
      if ((tabGpsValidFix(id) == 0)  && ...
            (((tabNbSbdRx2(id) == 12) || (tabNbSbdRx2(id) == 16)) && (tabNbSbdTx2(id) == 0) && (~isnan(tabIrSessionDuration2(id)) && (tabIrSessionDuration2(id) < tabIc11(id)*60)))) % 16 for 3901644 #52
         tabSatMaskFlag2(id) = 1;
      elseif ((tabGpsValidFix(id) == 0)  && ...
            (isnan(tabNbSbdRx2(id)) && isnan(tabNbSbdTx2(id)))) % 3902103, the following cycle is missing
         % we don't know, we assume the non transmission is due to a sat mask
         if (tabTransFlag(id) == 0)
            tabSatMaskFlag2(id) = 1;
         end
      elseif ((tabGpsValidFix(id) == 0) && (tabSatMaskFlag2(id) == 0) && (tabTransFlag(id) == 0))
         tabSatMaskFlag2(id) = 1; % 6903230
      end
   end
end

% set breakup dates
tabBreakupFlag(~isnan(tabCyNum)) = 0;
if (ismember(a_decoderId, [212, 217]))
   for id = 1:length(tabCyNum)
      if (((tabIsaFlag(id) == 1) && (tabIsaCount(id) >= tabIc2(id))) || ...
            (tabSatMaskFlag2(id) == 1) || (tabHangingFlag(id) == 1))
         breakupStart = fix(tabFloatTime(id));
         breakupEnd = fix(tabFloatTime(id)) + tabIc0(id);
         idStop = find(fix(tabAst) > breakupEnd, 1, 'first');
         if (isempty(idStop))
            idStop = length(tabCyNum);
         end
         tabBreakupStart(id:idStop-1) = breakupStart;
         tabBreakupEnd(id:idStop-1) = breakupEnd;
         tabBreakupFlag(id+1:idStop-1) = 1;
      else
         if ((tabIsaFlag(id) == 1) && (tabIsaCount(id) < tabIc2(id)))
            tabBreakupStart(id:end) = nan;
            tabBreakupEnd(id:end) = nan;
            tabBreakupFlag(id:end) = 0; % breakupEnd date removed (YLA5900A04)
         end
      end
   end
else
   for id = 1:length(tabCyNum)
      if (((tabIsaFlag(id) == 1) && (tabIsaCount(id) >= tabIc2(id))) || ...
            (tabSatMaskFlag2(id) == 1) || (tabHangingFlag(id) == 1))
         breakupStart = fix(tabFloatTime(id));
         breakupEnd = fix(tabFloatTime(id)) + tabIc0(id);
         idStop = find(fix(tabAst) > breakupEnd, 1, 'first');
         if (isempty(idStop))
            idStop = length(tabCyNum);
         end
         tabBreakupStart(id:idStop-1) = breakupStart;
         tabBreakupEnd(id:idStop-1) = breakupEnd;
         tabBreakupFlag(id+1:idStop-1) = 1;
      end
   end
end
% use "GPS valid fix" to finalize breakup flags (ex: 6902728)
for id = 1:length(tabCyNum)
   if ((tabBreakupFlag(id) == 0) && (tabGpsValidFix(id) == 255))
      tabBreakupFlag(id) = 1;
   end
end

% set forced surfacing date and flag
tabForcedFlag(~isnan(tabCyNum)) = 0;
cpt = 1;
for id = 1:length(tabCyNum)
   set = 0;
   if (tabIc0(id) > 0)
      if (tabForcedFlag(id) > 0)
         if ((tabSatMaskFlag2(id) == 1) || (tabHangingFlag(id) == 1))
            set = 1;
         end
      else
         if ((tabIsaFlag(id) == 1) && (tabIsaCount(id) == tabIc2(id)))
            set = 1;
         end
      end
   end

   if (set)
      forcedRefTime = fix(tabFloatTime(id));
      forcedGoTime = fix(tabFloatTime(id)) + tabIc1(id);
      idStop = find(fix(tabFloatTime) <= forcedGoTime, 1, 'last');
      if (isempty(idStop))
         idStop = length(tabCyNum);
      end
      tabForcedRefTime(id:idStop) = forcedRefTime;
      tabForcedGoTime(id:idStop) = forcedGoTime;
      tabForcedFlag(id+1:idStop) = 0;
      if (length(tabForcedFlag) > idStop)
         tabForcedFlag(idStop+1) = cpt;
         cpt = cpt + 1;
      end
   end
end

tabForcedFlag2(~isnan(tabCyNum)) = 0;
cpt = 1;
if (ismember(a_decoderId, [216, 218]))
   for id = 1:length(tabCyNum)
      if ((tabBreakupFlag(id) == 1) && ...
            ~((tabGpsValidFix(id) == 0) && (tabGpsSessionDuration(id) == 0) && ...
            (tabGpsSessionTimeout(id) == 0) && (tabNbSbdRx2(id) == 0) && (tabNbSbdTx2(id) == 0)))
         tabForcedFlag2(id) = cpt;
         cpt = cpt + 1;
      end
   end
else
   for id = 1:length(tabCyNum)
      if (((tabIsaFlag(id) == 1) || (tabBreakupFlag(id) == 1)) && ~isnan(tabGpsValidFix(id)) && (tabGpsValidFix(id) ~= 255))
         tabForcedFlag2(id) = cpt;
         cpt = cpt + 1;
      end
   end
end

% set prof aborted flag
tabProfAbortedFlag(~isnan(tabCyNum)) = 0;
for id = 1:length(tabCyNum)
   if (tabIc0(id) > 0)
      if (((tabIsaFlag(id) == 1) || (tabBreakupFlag(id) == 1)) && (tabForcedFlag2(id) == 0))
         tabProfAbortedFlag(id) = 1;
      end
   end
end

% set no surf flag
tabNoSurfFlag(~isnan(tabCyNum)) = 0;
for id = 1:length(tabCyNum)
   if (tabForcedFlag2(id) == 0)
      if ((tabIsaFlag(id) == 1) || (tabSatMaskFlag2(id) == 1) || ...
            (tabHangingFlag(id) == 1) || (tabBreakupFlag(id) == 1))
         tabNoSurfFlag(id) = 1;
      end
   elseif (tabForcedFlag2(id) > 0)
      if ((tabSatMaskFlag2(id) == 1) || (tabHangingFlag(id) == 1))
         tabNoSurfFlag(id) = 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find anomalies

if (~isempty(g_decArgo_outputCsvFileId))

   if (any(tabIceFlag ~= 0))
      fprintf('INFO: Float #%d: ICE detected\n', ...
         g_decArgo_floatNum);
   end

   tabAnomaly(~isnan(tabCyNum)) = 0;
   for id = 1:length(tabCyNum)
      if ((tabTransFlag(id) == 0) && (tabNoSurfFlag(id) == 0)) % no transmission but no flag to detect it
         tabAnomaly(id) = 1;
      elseif ((tabTransFlag(id) == 1) && (tabNoSurfFlag(id) == 1)) % transmission but the flags says not transmission
         tabAnomaly(id) = 2;
      end
   end
   id = find(tabAnomaly == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #1_1 at cycles:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
   id = find(tabAnomaly == 2);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #1_2 at cycles:%s\n', ...
         g_decArgo_floatNum, cycleListStr);

      for idA = id'
         if ((tabSatMaskFlag2(idA) == 1) && (tabTransFlag(idA) == 1))
            fprintf('INFO: Float #%d cycle %d: anomaly tabSatMaskFlag2 = 1 et tabTransFlag = 1\n', ...
               g_decArgo_floatNum, tabCyNum(idA));
         end
      end
   end

   % compare RT flag and delayed one
   tabAnomaly2(~isnan(tabCyNum)) = 0;
   for id = 1:length(tabCyNum)
      if ((tabProfAbortedFlag(id) == 0) && (tabRtAborted(id) == 1))
         tabAnomaly2(id) = 1;
      elseif ((tabProfAbortedFlag(id) == 1) && (tabRtAborted(id) == 0))
         tabAnomaly2(id) = 2;
      end
   end
   id = find(tabAnomaly2 == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #2_1 (RT and DM flags not consistents) at cycles:%s\n', ...
         g_decArgo_floatNum, cycleListStr);

      for idA = id'
         if ((tabGpsValidFix(idA) == 0) && (tabGpsSessionTimeout(idA) > 0) && ...
               (tabNbSbdRx2(idA) == 12) && (tabNbSbdTx2(idA) == 0) && (tabTransFlag(idA) == 1))
            fprintf('INFO: Float #%d cycle %d: anomaly ok1\n', ...
               g_decArgo_floatNum, tabCyNum(idA));
         end
         if ((tabHangingFlag(idA) == 1) && (tabTransFlag(idA) == 1))
            fprintf('INFO: Float #%d cycle %d: anomaly ok2\n', ...
               g_decArgo_floatNum, tabCyNum(idA));
         end
      end
   end
   id = find(tabAnomaly2 == 2);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: anomaly #2_2 (RT and DM flags not consistents) at cycles:%s\n', ...
         g_decArgo_floatNum, cycleListStr);

      for idA = id'
         if ((tabGpsValidFix(idA) == 0) && (tabGpsSessionTimeout(idA) > 0) && ...
               (tabNbSbdRx2(idA) == 12) && (tabNbSbdTx2(idA) == 0) && (tabTransFlag(idA) == 1))
            fprintf('INFO: Float #%d cycle %d: anomaly ok1\n', ...
               g_decArgo_floatNum, tabCyNum(idA));
         end
         if ((tabHangingFlag(idA) == 1) && (tabTransFlag(idA) == 1))
            fprintf('INFO: Float #%d cycle %d: anomaly ok2\n', ...
               g_decArgo_floatNum, tabCyNum(idA));
         end
      end
   end

   % check that surf PRES offset is 0 when tabTransFlag = 0 (no resetoffset performed)
   tabAnomaly3(~isnan(tabCyNum)) = 0;
   for id = 1:length(tabCyNum)
      if ((tabNoSurfFlag(id) == 1) && ~isnan(tabSurfPres2(id)) && (tabSurfPres2(id) ~= 0))
         tabAnomaly3(id) = 1;
      end
   end
   id = find(tabAnomaly3 == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d (%.1f dbar)', [tabCyNum(id)'; tabSurfPres2(id)']);
      offsetMean = tabSurfPres2;
      offsetMean(tabNoSurfFlag == 1) = [];
      offsetMean(isnan(offsetMean)) = [];
      fprintf('INFO: Float #%d: anomaly #3 (Surf PRES offset not null while the float didn''t surface) at cycles:%s (mean of surf offsets when float surfaced: %.1f)\n', ...
         g_decArgo_floatNum, cycleListStr, mean(offsetMean));
   end

   % list of hanging cycles
   id = find(tabHangingFlag == 1);
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: hanging detected:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % check min PRES when cycle aborted
   id = find( ...
      (((tabIsaFlag == 1) | (tabBreakupFlag == 1)) & (tabForcedFlag2 == 0)) & ... % profile aborted
      (tabMinPres < 5));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: inconsistency detected (min pres prof aborted):%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % check min PRES with breakup
   id = find( ...
      ((tabIsaFlag == 0) & (tabBreakupFlag == 1) & (tabForcedFlag2 == 0)) & ... % profile aborted due to breakup
      (tabMinPres < 5));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: inconsistency detected (min pres breakup only):%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % hanging only
   id = find( ...
      ((tabIsaFlag == 0) & (tabBreakupFlag == 0)  & (tabHangingFlag == 1) & (tabForcedFlag2 == 0))); % hanging only
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: hanging only:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % check min PRES with hanging only
   id = find( ...
      ((tabIsaFlag == 0) & (tabBreakupFlag == 0)  & (tabHangingFlag == 1) & (tabForcedFlag2 == 0)) & ... % hanging only
      (tabMinPres < 5));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: inconsistency detected (min pres hanging):%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % hanging only with transmission
   id = find( ...
      ((tabHangingFlag == 1) & (tabTransFlag == 1)));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: hanging with transmission:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end

   % ISA with IC0
   id = find( ...
      ((tabIc0 == 0) & (tabIsaFlag == 1)));
   if (~isempty(id))
      cycleListStr = sprintf(' %d', tabCyNum(id));
      fprintf('INFO: Float #%d: ISA with IC0=0:%s\n', ...
         g_decArgo_floatNum, cycleListStr);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CSV output

if (~isempty(g_decArgo_outputCsvFileId))

   % create output CSV file
   csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_ICE_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fId = fopen(csvFilepathName, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
      return
   end
   header = [ ...
      'WMO;Cycle#;IC0;IC1;IC2;IC11;TC23;Ice activated;' ...
      'AST;TST;Float time;Ice flag;ISA;Sat mask;' ...
      'Valid fix;GPS session duration;GPS session timeout;Ir session duration;' ...
      'Nb SBD Rx; NbSBD Tx;Sat mask 2;Hanging;ISA count;Breakup flag;' ...
      'Forced flag;Forced flag2;Breakup start;Breakup end;Forced ref;Forced go;Prof aborted flag;' ...
      'No surf flag;Trans flag;Surf PRES offset;Anomaly3;Min PRES meas;Anomaly;RT aborted;Anomaly2;Nb In Air;' ...
      'Pump switch off;Last pumped PRES;Min prof PRES;ISA start PRES;ISA stop PRES'];
   fprintf(fId, '%s\n', header);

   for id = 1:length(tabCyNum)
      breakupStart = julian_2_gregorian_dec_argo(tabBreakupStart(id));
      breakupStart = breakupStart(1:10);
      breakupEnd = julian_2_gregorian_dec_argo(tabBreakupEnd(id));
      breakupEnd = breakupEnd(1:10);
      forcedRefTime = julian_2_gregorian_dec_argo(tabForcedRefTime(id));
      forcedRefTime = forcedRefTime(1:10);
      forcedGoTime = julian_2_gregorian_dec_argo(tabForcedGoTime(id));
      forcedGoTime = forcedGoTime(1:10);
      fprintf(fId, '%d;%d;%d;%d;%d;%d;%d;%d; %s; %s; %s;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d; %s; %s; %s; %s;%d;%d;%d;%.1f;%d;%.1f;%d;%d;%d;%d;%.1f;%.1f;%.1f;%d;%d\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         tabIc0(id), ...
         tabIc1(id), ...
         tabIc2(id), ...
         tabIc11(id), ...
         tabTc23(id), ...
         tabIceActivatedFlag(id), ...
         julian_2_gregorian_dec_argo(tabAst(id)), ...
         julian_2_gregorian_dec_argo(tabTst(id)), ...
         julian_2_gregorian_dec_argo(tabFloatTime(id)), ...
         tabIceFlag(id), ...
         tabIsaFlag(id), ...
         tabSatMaskFlag(id), ...
         tabGpsValidFix(id), ...
         tabGpsSessionDuration(id), ...
         tabGpsSessionTimeout(id), ...
         tabIrSessionDuration2(id), ...
         tabNbSbdRx2(id), ...
         tabNbSbdTx2(id), ...
         tabSatMaskFlag2(id), ...
         tabHangingFlag(id), ...
         tabIsaCount(id), ...
         tabBreakupFlag(id), ...
         tabForcedFlag(id), ...
         tabForcedFlag2(id), ...
         breakupStart, ...
         breakupEnd, ...
         forcedRefTime, ...
         forcedGoTime, ...
         tabProfAbortedFlag(id), ...
         tabNoSurfFlag(id), ...
         tabTransFlag(id), ...
         tabSurfPres2(id), ...
         tabAnomaly3(id), ...
         tabMinPres(id), ...
         tabAnomaly(id), ...
         tabRtAborted(id), ...
         tabAnomaly2(id), ...
         tabNbInAir(id), ...
         tabPumpSwitchOffPresCfg(id), ...
         tabSubsurfPres(id), ...
         tabMinProfPres(id), ...
         tabIsaStartPres(id), ...
         tabIsaStopPres(id) ...
         );
   end

   fclose(fId);

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % NETCDF OUTPUT

   % create the 9 bits TECH_AUX parameter use to report Ice Algorithm Status

   % Transmission flag
   tabTech1 = tabTransFlag;

   % ICE algorithm activated flag
   % the information is provided from the first cycle we received the ICE
   % configuration paquet
   % we set ICE algorithm always activated from this cycle because even
   % when IC0 = 0, sat_mask is reported
   tabTech2 = nan(length(tabCyNum), 1);
   tabTech2(~isnan(tabCyNum)) = 1;

   % ICE surface avoidance flag
   % the ICE algorithm can act on float behaviour only when IC0 > 0
   tabTech3 = tabIceActivatedFlag;

   % Aborted profile flag
   tabTech4 = tabProfAbortedFlag;

   % ISA flag
   tabTech5 = tabIsaFlag;

   % Breakup period flag
   tabTech6 = tabBreakupFlag;

   % Hanging flag
   tabTech7 = tabHangingFlag;

   % Satellite mask flag
   tabTech8 = tabSatMaskFlag2;

   % Forced ascent flag
   tabTech9 = nan(length(tabCyNum), 1);
   tabTech9(~isnan(tabCyNum)) = 0;
   tabTech9(~isnan(tabForcedFlag2) & (tabForcedFlag2 > 0)) = 1;

   % FLAG_IceAlgorithmStatus_bit
   tabTechAll = nan(length(tabCyNum), 1);
   tabFlag = [tabTech9 tabTech8 tabTech7 tabTech6 tabTech5 tabTech4 tabTech3 tabTech2 tabTech1];
   idNonan = find(all(~isnan(tabFlag), 2));
   tabZero = nan(length(tabCyNum), 2);
   tabZero(idNonan, :) = 0;
   tabFlag = cat(2, tabZero, tabFlag);
   tabTechAll(idNonan) = bin2dec(num2str(tabFlag(idNonan, :)));

   % set additionnal ICE information

   % TECH_AUX_FLAG_IceIsaDetectionAlarm_LOGICAL
   % TECH_AUX_FLAG_IceHangingDetectionAlarm_LOGICAL
   % TECH_AUX_FLAG_IceNoSurfacePeriod_LOGICAL
   % TECH_AUX_FLAG_IceForcedAscentAlarm_LOGICAL
   % TECH_AUX_FLAG_IceSatMaskDetectionAlarm_LOGICAL
   % TECH_AUX_FLAG_IceProfileAbortAlarm_LOGICAL
   % PRES_IceAvoidance_dbar
   % FLAG_IceDetected_bit
   % TECH_AUX_FLAG_IceAlgorithmStatus_bit

   % remove PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar for
   % aborted profiles (the resetoffset is performed in that case)
   % the erroneous resetoffset will be managed in manage_erroneous_resetoffset

   % TRAJ event with MC=593 for ICE profile Abort time and associated PRES

   updatedTrajFlag = 0;
   for id = 1:length(tabCyNum)

      % look for cycle number
      cycleNumber = tabCyNum(id);
      idCyNum = find(o_tabNcTechIndex(:, 2) == cycleNumber, 1);
      if (isempty(idCyNum))
         continue
      end

      % TECH_AUX_FLAG_IceIsaDetectionAlarm_LOGICAL
      if (tabIsaFlag(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 400 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % TECH_AUX_FLAG_IceHangingDetectionAlarm_LOGICAL
      if (tabHangingFlag(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 401 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % TECH_AUX_FLAG_IceNoSurfacePeriod_LOGICAL
      if (tabBreakupFlag(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 402 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % TECH_AUX_FLAG_IceForcedAscentAlarm_LOGICAL
      if (tabTech9(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 403 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % TECH_AUX_FLAG_IceSatMaskDetectionAlarm_LOGICAL
      if (tabSatMaskFlag2(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 404 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % TECH_AUX_FLAG_IceProfileAbortAlarm_LOGICAL
      if (tabProfAbortedFlag(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 405 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % PRES_IceAvoidance_dbar
      if ((tabProfAbortedFlag(id) == 1) && ~isnan(tabMinPres(id)))
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 406 cycleNumber]);
         o_tabNcTechVal{end+1} = sprintf('%.2f', tabMinPres(id));
      end

      % FLAG_IceDetected_bit
      % already set but possibly erroneous
      start = max(1, id-7);
      if (all(~isnan(tabProfAbortedFlag(start:id))))
         iceDetectedBit = num2str(tabProfAbortedFlag(start:id))';
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 407 cycleNumber]);
         o_tabNcTechVal{end+1} = iceDetectedBit;
      end

      % TECH_AUX_FLAG_IceAlgorithmStatus_bit
      if (~isnan(tabTechAll(id)))
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 cycleNumber -1 -1 408 cycleNumber]);
         o_tabNcTechVal{end+1} = dec2bin(tabTechAll(id), 11);
      end

      % remove PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar
      % for aborted profiles (the resetoffset is performed in that case)
      if (tabProfAbortedFlag(id) == 1)
         idF = find(([o_tabNcTechIndex(:, 6)] == cycleNumber + 1) & ([o_tabNcTechIndex(:, 5)] == offsetTechId));
         if (~isempty(idF))
            o_tabNcTechIndex(idF, :) = [];
            o_tabNcTechVal(idF) = [];
         end
         % and the surface version of the TECH parameter
         idF = find(([o_tabNcTechIndex(:, 6)] == cycleNumber + 1) & ([o_tabNcTechIndex(:, 5)] == 10000 + offsetTechId));
         if (~isempty(idF))
            o_tabNcTechIndex(idF, :) = [];
            o_tabNcTechVal(idF) = [];
         end
      end

      % TRAJ event with MC=593
      if (tabProfAbortedFlag(id) == 1)

         % retrieve timeData structure of the concerned cycle
         idTimeData = find(([cell2mat(g_decArgo_cycleTimeData).cycleNum] == cycleNumber));
         if (~isempty(idTimeData))
            timeData = g_decArgo_cycleTimeData{idTimeData};

            if (~isempty(timeData.ascentEndDate))

               % clock drift is provided in seconds
               if (~isempty(timeData.cycleClockOffset))
                  floatClockDriftSec = timeData.cycleClockOffset/86400;
                  floatClockDriftMin = round(floatClockDriftSec/60)/1440;
               else
                  floatClockDriftMin = 0;
               end

               profAbortTime = timeData.ascentEndDate;
               [measStruct, ~] = create_one_meas_float_time_ter(...
                  g_MC_IceAscentAbort, profAbortTime, g_JULD_STATUS_2, floatClockDriftMin);

               if (~isnan(tabMinPres(id)))
                  paramPres = get_netcdf_param_attributes('PRES');
                  measStruct.paramList = paramPres;
                  measStruct.paramData = tabMinPres(id);
               end

               idNMeas = find([o_tabTrajNMeas.outputCycleNumber] == cycleNumber);
               if (~isempty(idNMeas))
                  tabMeas = o_tabTrajNMeas(idNMeas).tabMeas;
                  tabMeas = [tabMeas; measStruct];
                  o_tabTrajNMeas(idNMeas).tabMeas = tabMeas;

                  updatedTrajFlag = 1;
               end
            end
         end
      end

      % remove TSD and TED
      if (tabTransFlag(id) == 0)
         idNMeas = find([o_tabTrajNMeas.outputCycleNumber] == cycleNumber);
         if (~isempty(idNMeas))

            tabMeas = o_tabTrajNMeas(idNMeas).tabMeas;
            idTSD = find([tabMeas.measCode] == g_MC_TST);
            if (~isempty(idTSD))
               tabMeas(idTSD) = create_one_meas_float_time(g_MC_TST, -1, g_JULD_STATUS_9, 0);
            end
            idTED = find([tabMeas.measCode] == g_MC_TET);
            if (~isempty(idTED))
               tabMeas(idTED) = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, 0);
            end
            o_tabTrajNMeas(idNMeas).tabMeas = tabMeas;
         end

         idNCy = find([o_tabTrajNCycle.outputCycleNumber] == cycleNumber);
         if (~isempty(idNCy))

            o_tabTrajNCycle(idNCy).juldTransmissionStart = g_decArgo_ncDateDef;
            o_tabTrajNCycle(idNCy).juldTransmissionStartStatus = g_JULD_STATUS_9;
            o_tabTrajNCycle(idNCy).juldTransmissionEnd = g_decArgo_ncDateDef;
            o_tabTrajNCycle(idNCy).juldTransmissionEndStatus = g_JULD_STATUS_9;
         end
      end
   end
   if (updatedTrajFlag)
      % sort trajectory data structures according to the predefined
      % measurement code order
      [o_tabTrajNMeas] = sort_trajectory_data(o_tabTrajNMeas, a_decoderId);
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % UPDATE OF NETCDF DATA

   % if RT ascentAbortedFlag differs from the final one

   updatedProfFlag = 0;
   paramJuld = '';
   for id = 1:length(tabCyNum)

      if ((tabProfAbortedFlag(id) == 0) && (tabRtAborted(id) == 1))

         % most of the examples are due to missing of float time
         if (~isnan(tabTransFlag))
            fprintf('INFO: Float #%d Cycle #%d: missing time information to report ICE information in NetCDF TRAJ and PROF files\n', ...
               g_decArgo_floatNum, tabCyNum(id));
         end

      elseif ((tabProfAbortedFlag(id) == 1) && (tabRtAborted(id) == 0))

         % the ascending profile has been aborted
         cycleNum = tabCyNum(id);

         % retrieve timeData structure of the concerned cycle
         idTimeData = find(([cell2mat(g_decArgo_cycleTimeData).cycleNum] == cycleNum));
         if (~isempty(idTimeData))

            timeData = g_decArgo_cycleTimeData{idTimeData};

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % UPDATE NETCDF PROFILE

            % update profile date
            idProf = find(([o_tabProfiles.outputCycleNumber] == cycleNum) & ...
               ([o_tabProfiles.direction] == 'A'));
            if (~isempty(idProf))

               % if profile date is AED, replace it by TSD (the AED when ascent
               % has been aborted)
               if (~isempty(timeData.ascentEndDateAdj))
                  ascentEndDate = timeData.ascentEndDateAdj;
               else
                  ascentEndDate = timeData.ascentEndDate;
               end
               if (~isempty(timeData.transStartDateAdj))
                  transStartDate = timeData.transStartDateAdj;
               else
                  transStartDate = timeData.transStartDate;
               end
               if (~isempty(ascentEndDate) && ~isempty(transStartDate))
                  if (strcmp(julian_2_gregorian_dec_argo(o_tabProfiles(idProf).date), ...
                        julian_2_gregorian_dec_argo(ascentEndDate)))

                     % update profile date
                     o_tabProfiles(idProf).date = transStartDate;
                     o_tabProfiles(idProf).locationDate = g_decArgo_dateDef;
                     o_tabProfiles(idProf).locationLon = g_decArgo_argosLonDef;
                     o_tabProfiles(idProf).locationLat = g_decArgo_argosLatDef;
                     o_tabProfiles(idProf).locationQc = ' ';

                     % update MTIME data
                     idMtime = find(strcmp({o_tabProfiles(idProf).paramList.name}, 'MTIME'), 1);
                     if (~isempty(idMtime))
                        if (isempty(paramJuld))
                           paramJuld = get_netcdf_param_attributes('JULD');
                        end
                        idDated = find(o_tabProfiles(idProf).dates ~= paramJuld.fillValue);
                        o_tabProfiles(idProf).data(idDated, idMtime) = o_tabProfiles(idProf).dates(idDated) - o_tabProfiles(idProf).date;
                     end

                     % perform PARAMETER adjustment
                     % not done because the correction applied is only few
                     % minutes (this will not modify the number of profiles to
                     % be adjusted from a DB linear adjustment)

                     updatedProfFlag = 1;
                  end
               end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % UPDATE NETCDF TRAJECTORY

            idNMeas = find([o_tabTrajNMeas.outputCycleNumber] == cycleNum);
            if (~isempty(idNMeas))
               tabMeas = o_tabTrajNMeas(idNMeas).tabMeas;

               idAED = find([tabMeas.measCode] == g_MC_AET);
               idTSD = find([tabMeas.measCode] == g_MC_TST);
               idTED = find([tabMeas.measCode] == g_MC_TET);
               if (~isempty(idAED) && ~isempty(idTSD))

                  % replace AED by TSD (the AED when ascent has been aborted)
                  if (tabMeas(idTSD).juld ~= g_decArgo_ncDateDef)
                     tabMeas(idAED) = tabMeas(idTSD);
                     tabMeas(idAED).measCode = g_MC_AET;
                  else
                     tabMeas(idAED) = create_one_meas_float_time(g_MC_AET, -1, g_JULD_STATUS_9, 0);
                  end

                  % remove TSD and TED
                  tabMeas(idTSD) = create_one_meas_float_time(g_MC_TST, -1, g_JULD_STATUS_9, 0);
                  tabMeas(idTED) = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, 0);
               end
               o_tabTrajNMeas(idNMeas).tabMeas = tabMeas;
            end

            idNCy = find([o_tabTrajNCycle.outputCycleNumber] == cycleNum);
            if (~isempty(idNCy))

               % replace AED by TSD (the AED when ascent has been aborted)
               o_tabTrajNCycle(idNCy).juldAscentEnd = o_tabTrajNCycle(idNCy).juldTransmissionStart;
               o_tabTrajNCycle(idNCy).juldAscentEndStatus = o_tabTrajNCycle(idNCy).juldTransmissionStartStatus;

               % remove TSD and TED
               o_tabTrajNCycle(idNCy).juldTransmissionStart = g_decArgo_ncDateDef;
               o_tabTrajNCycle(idNCy).juldTransmissionStartStatus = g_JULD_STATUS_9;
               o_tabTrajNCycle(idNCy).juldTransmissionEnd = g_decArgo_ncDateDef;
               o_tabTrajNCycle(idNCy).juldTransmissionEndStatus = g_JULD_STATUS_9;
            end
         end
      end
   end
   if (updatedProfFlag)
      % add interpolated/extrapolated profile locations
      [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(g_decArgo_gpsData, o_tabProfiles);
   end
end

return
