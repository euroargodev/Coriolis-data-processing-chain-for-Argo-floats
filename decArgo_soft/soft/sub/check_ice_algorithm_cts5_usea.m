% ------------------------------------------------------------------------------
% Check ICE collected data (in g_decArgo_iceData) to set the float status
% (breakup, forced or none) and associated ICE flags (ISA, sat mask or hanging)
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
%   check_ice_algorithm_cts5_usea(a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas   : input trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input trajectory N_CYCLE data
%   a_tabNcTechIndex : input technical index information
%   a_tabNcTechVal   : input technical data
%
% OUTPUT PARAMETERS :
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
%   11/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
   check_ice_algorithm_cts5_usea(a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

% to store ICE data used to simulate ICE algorithm (in CSV output only)
global g_decArgo_iceData;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_ncDateDef;

% global measurement codes
global g_MC_AscProf;
global g_MC_IceAscentAbort;
global g_MC_TST;
global g_MC_TET;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_9;

% cycle phases
global g_decArgo_phaseSatTrans;


if (isempty(g_decArgo_iceData))
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CYCLE AND PATTERN NUMBERS

% set final cycle number data array
cyNumList = g_decArgo_iceData(:, 1);
patNumList = g_decArgo_iceData(:, 2);
tabCyNum = [];
tabPatNum = [];
idMap = nan(size(cyNumList));
cpt = 1;
for idC = 1:length(cyNumList)
   if ((idC > 1) && (cyNumList(idC) - max(tabCyNum)) > 1)
      for id = max(tabCyNum)+1:cyNumList(idC)-1
         tabCyNum(cpt) = id;
         tabPatNum(cpt) = -1;
         cpt = cpt + 1;
      end
   end
   idMap(idC) = cpt;
   tabCyNum(cpt) = cyNumList(idC);
   tabPatNum(cpt) = patNumList(idC);
   cpt = cpt + 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COLLECTED ICE INFORMATION

% ICE data information
% 1- cycle number
% 2- pattern number
% 3- ALARM_28: Ice avoidance (ISA detection)
% 4- ALARM_29: Ice avoidance (collision detection)
% 5- ALARM_30: Ice avoidance (aborting profile)
% 6- ALARM_31: Ice avoidance (cover detection)
% 7- ALARM_32: Ice avoidance (no surface period)
% 8- slow ascent start time
% 9- Ice abort time
% 10- Ice abort pressure
% 11- Ice perigee time
% 12- Ice perigee pressure
% 13- hanging start time
% 14- hanging start pressure
% 15- hanging end time
% 16- surface time
% 17- GPS time
% 18- trans start time
% 19- trans end time
% 20- trans timeout time
% 21- min PRES meas
% 22- min profile PRES meas
% 23- pressure of subsurface measurement
% 24- hanging start time (from evts)
% 25- ISA start time (from evts)
% 26- sat mask start time (from evts)
% 27- breakup start time (from evts)
% 28- forced ascent start time (from evts)
% 28- forced ascent start time (from evts)
% 29- Surface PRES offset
% 30- RT aborted flag

tabAlarm28 = nan(length(tabCyNum), 1);
tabAlarm28(idMap) = g_decArgo_iceData(:, 3);
tabAlarm29 = nan(length(tabCyNum), 1);
tabAlarm29(idMap) = g_decArgo_iceData(:, 4);
tabAlarm30 = nan(length(tabCyNum), 1);
tabAlarm30(idMap) = g_decArgo_iceData(:, 5);
tabAlarm31 = nan(length(tabCyNum), 1);
tabAlarm31Tmp = g_decArgo_iceData(:, 6);
idMap2 = idMap;
if (idMap2(1) == 1)
   idMap2(1) = [];
   tabAlarm31Tmp(1) = [];
end
tabAlarm31(idMap2-1) = tabAlarm31Tmp;
tabAlarm32 = nan(length(tabCyNum), 1);
tabAlarm32(idMap) = g_decArgo_iceData(:, 7);

tabSlowAscentStartTime = nan(length(tabCyNum), 1);
tabSlowAscentStartTime(idMap) = g_decArgo_iceData(:, 8);
tabIceAbortTime = nan(length(tabCyNum), 1);
tabIceAbortTime(idMap) = g_decArgo_iceData(:, 9);
tabIceAbortPres = nan(length(tabCyNum), 1);
tabIceAbortPres(idMap) = g_decArgo_iceData(:, 10);
tabIcePerigeeTime = nan(length(tabCyNum), 1);
tabIcePerigeeTime(idMap) = g_decArgo_iceData(:, 11);
tabIcePerigeePres = nan(length(tabCyNum), 1);
tabIcePerigeePres(idMap) = g_decArgo_iceData(:, 12);
tabHangingStartTime = nan(length(tabCyNum), 1);
tabHangingStartTime(idMap) = g_decArgo_iceData(:, 13);
tabHangingStartPres = nan(length(tabCyNum), 1);
tabHangingStartPres(idMap) = g_decArgo_iceData(:, 14);
tabHangingEndTime = nan(length(tabCyNum), 1);
tabHangingEndTime(idMap) = g_decArgo_iceData(:, 15);
tabSurfaceTime = nan(length(tabCyNum), 1);
tabSurfaceTime(idMap) = g_decArgo_iceData(:, 16);
tabGpsTime = nan(length(tabCyNum), 1);
tabGpsTime(idMap) = g_decArgo_iceData(:, 17);
tabTransStartTime = nan(length(tabCyNum), 1);
tabTransStartTime(idMap) = g_decArgo_iceData(:, 18);
tabTransEndTime = nan(length(tabCyNum), 1);
tabTransEndTime(idMap) = g_decArgo_iceData(:, 19);
tabTimeoutTime = nan(length(tabCyNum), 1);
tabTimeoutTime(idMap) = g_decArgo_iceData(:, 20);
tabMinPresMeas = nan(length(tabCyNum), 1);
tabMinPresMeas(idMap) = g_decArgo_iceData(:, 21);
tabMinProfPresMeas = nan(length(tabCyNum), 1);
tabMinProfPresMeas(idMap) = g_decArgo_iceData(:, 22);
tabSubsurfMeasPres = nan(length(tabCyNum), 1);
tabSubsurfMeasPres(idMap) = g_decArgo_iceData(:, 23);
tabEvtHangingTime = nan(length(tabCyNum), 1);
tabEvtHangingTime(idMap) = g_decArgo_iceData(:, 24);
tabEvtIsaTime = nan(length(tabCyNum), 1);
tabEvtIsaTime(idMap) = g_decArgo_iceData(:, 25);
tabEvtSatMaskTime = nan(length(tabCyNum), 1);
tabEvtSatMaskTime(idMap) = g_decArgo_iceData(:, 26);
tabEvtBreakupTime = nan(length(tabCyNum), 1);
tabEvtBreakupTime(idMap) = g_decArgo_iceData(:, 27);
tabEvtForcedTime = nan(length(tabCyNum), 1);
tabEvtForcedTime(idMap) = g_decArgo_iceData(:, 28);

tabSurfPres = nan(length(tabCyNum), 1);
tabSurfPresTmp = g_decArgo_iceData(:, 29);
idMap2 = idMap;
if (idMap2(1) == 1)
   idMap2(1) = [];
   tabSurfPresTmp(1) = [];
end
tabSurfPres(idMap2-1) = tabSurfPresTmp;

tabRtAbortedFlag = nan(length(tabCyNum), 1);
tabRtAbortedFlag(idMap) = g_decArgo_iceData(:, 30);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION

% retrieve ICE_AVOIDANCE configuration values
tabIAV0 = nan(length(tabCyNum), 1);
tabIAV1 = nan(length(tabCyNum), 1);
tabIAV2 = nan(length(tabCyNum), 1);
tabIAV3 = nan(length(tabCyNum), 1);
tabIAV4 = nan(length(tabCyNum), 1);

% retrieve ISA configuration values
tabISA0 = nan(length(tabCyNum), 1);
tabISA1 = nan(length(tabCyNum), 1);
tabISA2 = nan(length(tabCyNum), 1);
tabISA3 = nan(length(tabCyNum), 1);
tabISA4 = nan(length(tabCyNum), 1);

% retrieve SYSTEM.P8 configuration value
tabSysP8 = nan(length(tabCyNum), 1);

% retrieve switch off pressure of the CTD pump
tabPumpOffConfig = nan(length(tabCyNum), 1);

for idC = 1:length(idMap)
   [configNames, configValues] = get_float_config_ir_rudics_sbd2(tabCyNum(idMap(idC)), tabPatNum(idMap(idC)));
   if (~isempty(configNames))

      iceAdv0 = get_config_value('CONFIG_APMT_ICE_AVOIDANCE_P00', configNames, configValues);
      if (~isempty(iceAdv0))
         tabIAV0(idMap(idC)) = iceAdv0;
      end
      if (~isempty(g_decArgo_outputCsvFileId))
         iceAdv1 = get_config_value('CONFIG_APMT_ICE_AVOIDANCE_P01', configNames, configValues);
         if (~isempty(iceAdv1))
            tabIAV1(idMap(idC)) = iceAdv1;
         end
         iceAdv2 = get_config_value('CONFIG_APMT_ICE_AVOIDANCE_P02', configNames, configValues);
         if (~isempty(iceAdv2))
            tabIAV2(idMap(idC)) = iceAdv2/86400;
         end
         iceAdv3 = get_config_value('CONFIG_APMT_ICE_AVOIDANCE_P03', configNames, configValues);
         if (~isempty(iceAdv3))
            tabIAV3(idMap(idC)) = iceAdv3/86400;
         end
         iceAdv4 = get_config_value('CONFIG_APMT_ICE_AVOIDANCE_P04', configNames, configValues);
         if (~isempty(iceAdv4))
            tabIAV4(idMap(idC)) = iceAdv4/86400;
         end
      end

      isa0 = get_config_value('CONFIG_APMT_ISA_P00', configNames, configValues);
      if (~isempty(isa0))
         tabISA0(idMap(idC)) = isa0;
      end
      if (~isempty(g_decArgo_outputCsvFileId))
         isa1 = get_config_value('CONFIG_APMT_ISA_P01', configNames, configValues);
         if (~isempty(isa1))
            tabISA1(idMap(idC)) = isa1;
         end
         isa2 = get_config_value('CONFIG_APMT_ISA_P02', configNames, configValues);
         if (~isempty(isa2))
            tabISA2(idMap(idC)) = isa2;
         end
         isa3 = get_config_value('CONFIG_APMT_ISA_P03', configNames, configValues);
         if (~isempty(isa3))
            tabISA3(idMap(idC)) = isa3;
         end
         isa4 = get_config_value('CONFIG_APMT_ISA_P04', configNames, configValues);
         if (~isempty(isa4))
            tabISA4(idMap(idC)) = isa4;
         end
      end

      if (~isempty(g_decArgo_outputCsvFileId))
         sysP8 = get_config_value('CONFIG_APMT_SYSTEM_P08', configNames, configValues);
         if (~isempty(sysP8))
            tabSysP8(idMap(idC)) = sysP8;
         end
      end

      if (~isempty(g_decArgo_outputCsvFileId))
         presPumpSwitchOffConfig = get_config_value('CONFIG_APMT_SENSOR_01_P54', configNames, configValues);
         if (~isempty(presPumpSwitchOffConfig))
            tabPumpOffConfig(idMap(idC)) = presPumpSwitchOffConfig;
         end
      end
   
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the status of ICE algorithm

tabStatus = repmat({'NONE'}, length(tabCyNum), 1);
idF = find((tabIAV0 == 0) & (tabISA0 == 0));
tabStatus(idF) = repmat({'OFF'}, length(idF), 1);
idF = find((tabIAV0 == 1) | (tabISA0 == 1));
tabStatus(idF) = repmat({'ON'}, length(idF), 1);

if (all(isnan(tabIAV0)) && all(isnan(tabISA0)))
   return
end

fprintf('INFO: Float #%d: checking ICE information\n', ...
   g_decArgo_floatNum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find anomalies

if (~isempty(g_decArgo_outputCsvFileId))

   tabAnomaly = zeros(size(g_decArgo_iceData, 1), 1);

   % ISA detection without profile aborted => forced
   idF = find((tabAlarm28 == 1) & (tabAlarm30 ~= 1));
   tabAnomaly(idF) = 1;

   % profile aborted but no "Ice abort time"
   idF = find((tabAlarm30 == 1) & isnan(tabIceAbortTime));
   tabAnomaly(idF) = 2;

   % profile aborted but "GPS time"
   idF = find((tabAlarm30 == 1) & ~isnan(tabGpsTime));
   tabAnomaly(idF) = 3;

   % profile aborted but TST
   idF = find((tabAlarm30 == 1) & ~isnan(tabTransStartTime));
   tabAnomaly(idF) = 4;

   % ICE_ADVOIDANCE vs ISA on/off
   idF = find(~isnan(tabIAV0) & ~isnan(tabISA0) & (tabIAV0 ~= tabISA0));
   tabAnomaly(idF) = 5;

   % when the float didn't surface there is no surf PRES offset
   idNoGps = isnan(tabGpsTime);
   idIceActivated = ((tabIAV0 == 1) | (tabISA0 == 1));
   idProfAborted = ((tabAlarm30 == 1) | ~isnan(tabIceAbortTime));
   idSatMask = ((tabAlarm31 == 1) | ~isnan(tabEvtSatMaskTime));
   idF = find(((idNoGps & idIceActivated & idProfAborted | idSatMask)) & ~isnan(tabSurfPres));
   tabAnomaly(idF) = 6;

   idF = find(tabAnomaly == 1);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #1 (ISA detection without profile aborted => forced)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 2);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #2 (profile aborted but no "Ice abort time")\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 3);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #3 (profile aborted but "GPS time")\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 4);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #4 (profile aborted but TST)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 5);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #5 (ICE_ADVOIDANCE vs ISA on/off)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 6);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #6 ~(when the float didn''t surface there is no surf PRES offset)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end

   % alarm #29
   idF = find(tabAlarm29 == 1);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Alarm #29\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end

   % forced cycle
   idF = find(~isnan(tabEvtForcedTime));
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Forced cycle\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end

   % alarm #31
   % idF = find(tabAlarm31 == 1);
   % if (~isempty(idF))
   %    fprintf('INFO: Float #%d: Alarm #31\n', ...
   %       g_decArgo_floatNum);
   %    for id = idF'
   %       fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
   %    end
   % end

   % alarm #32
   % idF = find(tabAlarm32 == 1);
   % if (~isempty(idF))
   %    fprintf('INFO: Float #%d: Alarm #32\n', ...
   %       g_decArgo_floatNum);
   %    for id = idF'
   %       fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
   %    end
   % end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

if (~isempty(g_decArgo_outputCsvFileId))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CSV OUTPUT

   % create output CSV file
   csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_ICE_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fId = fopen(csvFilepathName, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
      return
   end

   header = [ ...
      'WMO;Cycle#;Pattern#;' ...
      'IAV0;IAV1;IAV2;IAV3;IAV4;' ...
      'ISA0;ISA1;ISA2;ISA3;ISA4;' ...
      'Status;' ...
      'A28-ISA;A29-hang;A30-abort;A31-sat_mask;A32-breakup;' ...
      'Ev ISA time;Ev hang time;Ev sat_mask time;Ev breakup time;Ev forced time;' ...
      'Slow ascent;Ice abort;Ice abort P;Ice perigee;Ice perigee P;' ...
      'Hanging start;Hanging start P;Hanging stop;SYS.P8;Surface (AET);'...
      'Gps time;Trans start time;Trans end time;Trans timeout time;' ...
      'Surf PRES offset;Min P;Min prof P;Pump switch off;Last pumped PRES;Anomaly;Prof aborted flag' ...
      ];
   fprintf(fId, '%s\n', header);

   for id = 1:size(g_decArgo_iceData, 1)
      fprintf(fId, '%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%.1f;%d;%s;%d;%d;%d;%d;%d; %s; %s; %s; %s; %s; %s; %s;%.1f; %s;%.1f; %s;%.1f; %s;%d; %s; %s; %s; %s; %s;%.1f;%.1f;%.1f;%.1f;%.1f;%d;%d\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         tabPatNum(id), ...
         tabIAV0(id), ...
         tabIAV1(id), ...
         tabIAV2(id), ...
         tabIAV3(id), ...
         tabIAV4(id), ...
         tabISA0(id), ...
         tabISA1(id), ...
         tabISA2(id), ...
         tabISA3(id), ...
         tabISA4(id), ...
         tabStatus{id}, ...
         tabAlarm28(id), ...
         tabAlarm29(id), ...
         tabAlarm30(id), ...
         tabAlarm31(id), ...
         tabAlarm32(id), ...
         julian_2_gregorian_dec_argo(tabEvtIsaTime(id)), ...
         julian_2_gregorian_dec_argo(tabEvtHangingTime(id)), ...
         julian_2_gregorian_dec_argo(tabEvtSatMaskTime(id)), ...
         julian_2_gregorian_dec_argo(tabEvtBreakupTime(id)), ...
         julian_2_gregorian_dec_argo(tabEvtForcedTime(id)), ...
         julian_2_gregorian_dec_argo(tabSlowAscentStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabIceAbortTime(id)), ...
         tabIceAbortPres(id), ...
         julian_2_gregorian_dec_argo(tabIcePerigeeTime(id)), ...
         tabIcePerigeePres(id), ...
         julian_2_gregorian_dec_argo(tabHangingStartTime(id)), ...
         tabHangingStartPres(id), ...
         julian_2_gregorian_dec_argo(tabHangingEndTime(id)), ...
         tabSysP8(id), ...
         julian_2_gregorian_dec_argo(tabSurfaceTime(id)), ...
         julian_2_gregorian_dec_argo(tabGpsTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransEndTime(id)), ...
         julian_2_gregorian_dec_argo(tabTimeoutTime(id)), ...
         tabSurfPres(id), ...
         tabMinPresMeas(id), ...
         tabMinProfPresMeas(id), ...
         tabPumpOffConfig(id), ...
         tabSubsurfMeasPres(id), ...
         tabAnomaly(id), ...
         tabRtAbortedFlag(id) ...
      );
   end

   fclose(fId);

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % NETCDF OUTPUT

   % create the 9 bits TECH_AUX parameter use to report Ice Algorithm Status

   % no GPS flag
   idNoGps = isnan(tabGpsTime);
   idNoGpsNan = [];
   % algo ICE activated
   idIceActivated = ((tabIAV0 == 1) | (tabISA0 == 1));
   idIceActivatedNan = (isnan(tabIAV0) & isnan(tabISA0));

   % sometimes TECH file not provided, sometimes SYSTEM information missing
   % => we should check the alarm (TECH) and the associated Evt (SYSTEM)

   % profile aborted flag
   idProfAborted = ((tabAlarm30 == 1) | ~isnan(tabIceAbortTime));
   idProfAbortedNan = (isnan(tabAlarm30) & isnan(tabIceAbortTime));
   % ISA detection flag
   idIsa = ((tabAlarm28 == 1) | ~isnan(tabEvtIsaTime));
   idIsaNan = (isnan(tabAlarm28) & isnan(tabEvtIsaTime));
   % breakup period flag
   idBreakup = ((tabAlarm32 == 1) | ~isnan(tabEvtBreakupTime));
   idBreakupNan = (isnan(tabAlarm32) & isnan(tabEvtBreakupTime));
   % hanging flag
   idHanging = ((tabAlarm29 == 1) | ~isnan(tabEvtHangingTime));
   idHangingNan = (isnan(tabAlarm29) & isnan(tabEvtHangingTime));
   % sat mask flag
   idSatMask = ((tabAlarm31 == 1) | ~isnan(tabEvtSatMaskTime));
   idSatMaskNan = (isnan(tabAlarm31) & isnan(tabEvtSatMaskTime));
   % sat mask flag
   idForced = (~isnan(tabEvtForcedTime));
   idForcedNan = [];

   % Transmission flag
   tabTech1 = nan(length(tabCyNum), 1);
   tabTech1(~isnan(tabCyNum)) = 1;
   tabTech1(idNoGps & idIceActivated & idProfAborted | idSatMask) = 0;
   tabTech1(idIceActivatedNan | idProfAbortedNan & idSatMaskNan) = nan;

   % ICE algorithm activated flag
   tabTech2 = nan(length(tabCyNum), 1);
   tabTech2(~isnan(tabCyNum)) = 0;
   tabTech2(idIceActivated) = 1;
   tabTech2(idIceActivatedNan) = nan;

   % ICE surface avoidance flag
   tabTech3 = tabTech2; % SYS.P8 seems to be unused for CTS5-USEA

   % Aborted profile flag
   tabTech4 = nan(length(tabCyNum), 1);
   tabTech4(~isnan(tabCyNum)) = 0;
   tabTech4(idProfAborted) = 1;
   tabTech4(idProfAbortedNan) = nan;

   % ISA flag
   tabTech5 = nan(length(tabCyNum), 1);
   tabTech5(~isnan(tabCyNum)) = 0;
   tabTech5(idIsa) = 1;
   tabTech5(idIsaNan) = nan;

   % Breakup period flag
   tabTech6 = nan(length(tabCyNum), 1);
   tabTech6(~isnan(tabCyNum)) = 0;
   tabTech6(idBreakup) = 1;
   tabTech6(idBreakupNan) = nan;

   % Hanging flag
   tabTech7 = nan(length(tabCyNum), 1);
   tabTech7(~isnan(tabCyNum)) = 0;
   tabTech7(idHanging) = 1;
   tabTech7(idHangingNan) = nan;

   % Satellite mask flag
   tabTech8 = nan(length(tabCyNum), 1);
   tabTech8(~isnan(tabCyNum)) = 0;
   tabTech8(idSatMask) = 1;
   tabTech8(idSatMaskNan) = nan;

   % Forced ascent flag
   tabTech9 = nan(length(tabCyNum), 1);
   tabTech9(~isnan(tabCyNum)) = 0;
   tabTech9(idForced) = 1;
   tabTech9(idForcedNan) = nan;

   % FLAG_IceAlgorithmStatus_bit
   tabTechAll = nan(length(tabCyNum), 1);
   tabFlag = [tabTech9 tabTech8 tabTech7 tabTech6 tabTech5 tabTech4 tabTech3 tabTech2 tabTech1];
   idNonan = find(all(~isnan(tabFlag), 2));
   tabZero = nan(length(tabCyNum), 2);
   tabZero(idNonan, :) = 0;
   tabFlag = cat(2, tabZero, tabFlag);
   tabTechAll(idNonan) = bin2dec(num2str(tabFlag(idNonan, :)));

   % update TECH information with ICE data
   % FLAG_IceAlgorithmActivated_LOGICAL

   % TECH_AUX_CLOCK_IceAdvoidance_YYYYMMDDHHMMSS
   % TECH_AUX_VOLUME_OilVolumeTransferredWhenIceAvoidance_cm^3
   % TECH_AUX_PRES_IceAdvoidance_dbar

   % TECH_AUX_CLOCK_IceAdvoidancePerigee_YYYYMMDDHHMMSS
   % TECH_AUX_PRES_IceAdvoidancePerigee_dbar

   % TECH_AUX_FLAG_IceProfileAbortAlarm_LOGICAL
   % TECH_AUX_FLAG_IceProfileAbortAlarm_YYYYMMDDHHMMSS

   % TECH_AUX_FLAG_IceHangingDetectionAlarm_LOGICAL
   % TECH_AUX_CLOCK_IceHangingDetectionAlarm_YYYYMMDDHHMMSS

   % TECH_AUX_FLAG_IceIsaDetectionAlarm_LOGICAL
   % TECH_AUX_CLOCK_IceIsaDetectionAlarm_YYYYMMDDHHMMSS

   % TECH_AUX_FLAG_IceNoSurfacePeriod_LOGICAL
   % TECH_AUX_CLOCK_IceNoSurfacePeriod_YYYYMMDDHHMMSS

   % TECH_AUX_FLAG_IceSatMaskDetectionAlarm_LOGICAL

   % remove existing TECH_AUX_FLAG_IceSatMaskDetectionAlarm_LOGICAL because
   % assigned to the wrong cycle
   idToDel = find(o_tabNcTechIndex(:, 5) == 226);
   o_tabNcTechIndex(idToDel, :) = [];
   o_tabNcTechVal(idToDel) = [];

   % TECH_AUX_CLOCK_IceSatMaskDetectionAlarm_YYYYMMDDHHMMSS

   % TECH_AUX_FLAG_IceForcedProfileAlarm_LOGICAL
   % TECH_AUX_CLOCK_IceForcedProfileAlarm_YYYYMMDDHHMMSS

   % PRES_IceAvoidance_dbar = min(TECH_AUX_PRES_IceAdvoidance_dbar, TECH_AUX_PRES_IceAdvoidancePerigee_dbar)

   % FLAG_IceDetected_bit

   % TECH_AUX_FLAG_IceAlgorithmStatus_bit

   % TRAJ event with MC=593 for ICE profile Abort time and associated PRES

   for id = 1:length(tabCyNum)

      % look for cycle number
      idCyNum = find((o_tabNcTechIndex(:, 2) == tabCyNum(id)) & (o_tabNcTechIndex(:, 3) == tabPatNum(id)), 1);
      if (isempty(idCyNum))
         continue
      end
      cycleNumber = o_tabNcTechIndex(idCyNum, 6);

      % FLAG_IceAlgorithmActivated_LOGICAL
      if (~isnan(tabTech2(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 261 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech2(id);
      end

      % TECH_AUX_CLOCK_IceAdvoidance_YYYYMMDDHHMMSS
      % already set
      % TECH_AUX_VOLUME_OilVolumeTransferredWhenIceAvoidance_cm^3
      % already set
      % TECH_AUX_PRES_IceAdvoidance_dbar
      % already set

      % TECH_AUX_CLOCK_IceAdvoidancePerigee_YYYYMMDDHHMMSS
      % already set
      % TECH_AUX_PRES_IceAdvoidancePerigee_dbar
      % already set

      % TECH_AUX_FLAG_IceProfileAbortAlarm_LOGICAL
      % already set

      % TECH_AUX_FLAG_IceProfileAbortAlarm_YYYYMMDDHHMMSS
      if (~isnan(tabIcePerigeeTime(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 270 cycleNumber]);
         icePerigeeTime = adjust_time_cts5(tabIcePerigeeTime(id));
         icePerigeeTimeStr = datestr(icePerigeeTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
         o_tabNcTechVal{end+1} = icePerigeeTimeStr;
      end

      % TECH_AUX_FLAG_IceHangingDetectionAlarm_LOGICAL
      % already set
      % TECH_AUX_CLOCK_IceHangingDetectionAlarm_YYYYMMDDHHMMSS
      % already set

      % TECH_AUX_FLAG_IceIsaDetectionAlarm_LOGICAL
      % already set
      % TECH_AUX_CLOCK_IceIsaDetectionAlarm_YYYYMMDDHHMMSS
      % already set

      % TECH_AUX_FLAG_IceNoSurfacePeriod_LOGICAL
      % already set
      % TECH_AUX_CLOCK_IceNoSurfacePeriod_YYYYMMDDHHMMSS
      % already set

      % TECH_AUX_FLAG_IceSatMaskDetectionAlarm_LOGICAL
      if (tabTech8(id) == 1)
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 226 cycleNumber]);
         o_tabNcTechVal{end+1} = '1';
      end

      % TECH_AUX_CLOCK_IceSatMaskDetectionAlarm_YYYYMMDDHHMMSS
      % already set

      % TECH_AUX_FLAG_IceForcedProfileAlarm_LOGICAL
      % already set
      % TECH_AUX_CLOCK_IceForcedProfileAlarm_YYYYMMDDHHMMSS
      % already set

      % PRES_IceAvoidance_dbar = min(TECH_AUX_PRES_IceAdvoidance_dbar, TECH_AUX_PRES_IceAdvoidancePerigee_dbar)
      if (~isnan(tabIceAbortPres(id)) || ~isnan(tabIcePerigeePres(id)))
         iceAbortPres = min([tabIceAbortPres(id) tabIcePerigeePres(id)], [], 'omitnan');
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 268 cycleNumber]);
         o_tabNcTechVal{end+1} = num2str(iceAbortPres);
      end

      % FLAG_IceDetected_bit
      % already set but possibly erroneous
      start = max(1, id-7);
      if (all(~isnan(tabTech4(start:id))))
         iceDetectedBit = num2str(tabTech4(start:id))';
         idF = find((o_tabNcTechIndex(:, 6) == cycleNumber) & (o_tabNcTechIndex(:, 5) == 249), 1);
         if (~isempty(idF))
            o_tabNcTechVal{idF} = iceDetectedBit;
         else
            o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 249 cycleNumber]);
            o_tabNcTechVal{end+1} = iceDetectedBit;
         end
      end

      % TECH_AUX_FLAG_IceAlgorithmStatus_bit
      if (~isnan(tabTechAll(id)))
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 269 cycleNumber]);
         o_tabNcTechVal{end+1} = dec2bin(tabTechAll(id), 11);
      end

      % TRAJ event with MC=593
      if (~isnan(tabIcePerigeeTime(id)))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_IceAscentAbort, ...
            tabIcePerigeeTime(id), ...
            adjust_time_cts5(tabIcePerigeeTime(id)), ...
            g_JULD_STATUS_2);

         if (~isnan(tabIcePerigeePres(id)))
            paramPres = get_netcdf_param_attributes('PRES');
            measStruct.paramList = paramPres;
            measStruct.paramData = single(tabIcePerigeePres(id));
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         end

         idNMeas = find([o_tabTrajNMeas.outputCycleNumber] == cycleNumber);
         if (~isempty(idNMeas))
            tabMeas = o_tabTrajNMeas(idNMeas).tabMeas;
            idF = find([tabMeas.measCode] == g_MC_AscProf, 1, 'last');
            if (~isempty(idF))
               tabMeas = [tabMeas(1:idF); measStruct; tabMeas(idF+1:end)];
            else
               tabMeas = [tabMeas; measStruct];
            end
            o_tabTrajNMeas(idNMeas).tabMeas = tabMeas;
         end
      end

      % remove TSD and TED
      if (tabTech1(id) == 0)
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
end

return
