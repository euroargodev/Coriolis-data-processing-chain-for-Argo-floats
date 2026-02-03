% ------------------------------------------------------------------------------
% Check ICE collected data (in g_decArgo_iceData) to set the float status
% (breakup, forced or none) and associated ICE flags (ISA, sat mask or hanging)
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
%   check_ice_algorithm_cts5_osean(a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
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
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
   check_ice_algorithm_cts5_osean(a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)

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
% 3- ascent start time
% 4- slow ascent start time
% 5- ascent end time
% 6- final pump action start time
% 7- ICE_D_DATE
% 8- NB_ICE_DET
% 9- LAST_ICE
% 10- abort cycle received cmd time
% 11- abort cycle ack time
% 12- abort cycle ack flag
% 13- GPS time
% 14- TST
% 15- TET
% 16- Transmission timeout
% 17- SYSTEM.P8 changed
% 18- min profile PRES meas
% 19- pump switch off from configs
% 20- Surface PRES offset

tabAst = nan(length(tabCyNum), 1);
tabAst(idMap) = g_decArgo_iceData(:, 3);
tabSlowAst = nan(length(tabCyNum), 1);
tabSlowAst(idMap) = g_decArgo_iceData(:, 4);
tabAet = nan(length(tabCyNum), 1);
tabAet(idMap) = g_decArgo_iceData(:, 5);
tabFinalPumpTime = nan(length(tabCyNum), 1);
tabFinalPumpTime(idMap) = g_decArgo_iceData(:, 6);
tabIceDDate = nan(length(tabCyNum), 1);
tabNbIceDet = nan(length(tabCyNum), 1);
tabLastIce = nan(length(tabCyNum), 1);
tabBreakupFlag = nan(length(tabCyNum), 1);
tabBreakupStart = nan(length(tabCyNum), 1);
tabBreakupEnd = nan(length(tabCyNum), 1);
tabAc1Flag = nan(length(tabCyNum), 1);
tabIsaFlag = nan(length(tabCyNum), 1);
tabPayloadIceFlag = nan(length(tabCyNum), 1);
tabAbortCycleCmdTime = nan(length(tabCyNum), 1);
tabAbortCycleCmdTime(idMap) = g_decArgo_iceData(:, 10);
tabAbortCycleAckTime = nan(length(tabCyNum), 1);
tabAbortCycleAckTime(idMap) = g_decArgo_iceData(:, 11);
tabAbortCycleAckFlag = nan(length(tabCyNum), 1);
tabAbortCycleAckFlag(idMap) = g_decArgo_iceData(:, 12);
tabGpsTime = nan(length(tabCyNum), 1);
tabGpsTime(idMap) = g_decArgo_iceData(:, 13);
tabTransStartTime = nan(length(tabCyNum), 1);
tabTransStartTime(idMap) = g_decArgo_iceData(:, 14);
tabTransEndTime = nan(length(tabCyNum), 1);
tabTransEndTime(idMap) = g_decArgo_iceData(:, 15);
tabTimeoutTime = nan(length(tabCyNum), 1);
tabTimeoutTime(idMap) = g_decArgo_iceData(:, 16);
tabSysP8_2 = nan(length(tabCyNum), 1);
tabSysP8_2(idMap) = g_decArgo_iceData(:, 17);
tabProfPresMin = nan(length(tabCyNum), 1);
tabProfPresMin(idMap) = g_decArgo_iceData(:, 18);
tabSubSurfPres = nan(length(tabCyNum), 1);
tabSubSurfPres(idMap) = g_decArgo_iceData(:, 19);

tabSurfPres = nan(length(tabCyNum), 1);
tabSurfPresTmp = g_decArgo_iceData(:, 20);
idMap2 = idMap;
if (idMap2(1) == 1)
   idMap2(1) = [];
   tabSurfPresTmp(1) = [];
end
tabSurfPres(idMap2-1) = tabSurfPresTmp;

iceDDatePrev = nan;
for id = 1:size(g_decArgo_iceData, 1)
   iceDDate = g_decArgo_iceData(id, 7);
   if (iceDDate ~= iceDDatePrev)
      idF = find(iceDDate > tabAst, 1, 'last');
      if (~isempty(idF))
         tabIceDDate(idF) = g_decArgo_iceData(id, 7);
         tabNbIceDet(idF) = g_decArgo_iceData(id, 8);
         tabLastIce(idF) = g_decArgo_iceData(id, 9);
      end
   end
   iceDDatePrev = iceDDate;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION

% ISA configuration parameters
% PAYLOAD_ISA	P00_<i>	Spring inhibition ascent end pressure
% PAYLOAD_ISA	P01_<i>	Spring inhibition delay since last ISA detection
% PAYLOAD_ISA	P10_<i>	Nb of detection to confirm Ice at surface
% PAYLOAD_ISA	P02_<i>	ISA algorithm storing data start pressure
% PAYLOAD_ISA	P03_<i>	ISA algorithm storing data stop pressure
% PAYLOAD_ISA	P04_<i>	ISA algorithm storing data sampling period
% PAYLOAD_ISA	P05_<i>	ISA algorithm start pres
% PAYLOAD_ISA	P06_<i>	ISA algorithm reference temperature
% PAYLOAD_ISA	P07_<i>	ISA algorithm salinity coefficient
% PAYLOAD_ISA	P08_<i>	ISA algorithm applicable month

% AC1 configuration parameters
% PAYLOAD_AC1	P00_<i>	Pressure to abort ascent			AC1 - trig
% PAYLOAD_AC1	P01_<i>	Applicable month			ACTIF - month

% APMT configuration parameters (involved in ICE algorithm)
% APMT_SECURITY P02 Detection management method for snagging during ascent
% APMT_SYSTEM	P08 Feedback-related risk criterion

tabIsaP0 = nan(length(tabCyNum), 1);
tabIsaP1 = nan(length(tabCyNum), 1);
tabIsaP10 = nan(length(tabCyNum), 1);
tabIsaP2 = nan(length(tabCyNum), 1);
tabIsaP3 = nan(length(tabCyNum), 1);
tabIsaP4 = nan(length(tabCyNum), 1);
tabIsaP5 = nan(length(tabCyNum), 1);
tabIsaP6 = nan(length(tabCyNum), 1);
tabIsaP7 = nan(length(tabCyNum), 1);
tabIsaP8 = nan(length(tabCyNum), 1);
tabAc1P0 = nan(length(tabCyNum), 1);
tabAc1P1 = nan(length(tabCyNum), 1);
tabSecuP2 = nan(length(tabCyNum), 1);
tabSysP8 = nan(length(tabCyNum), 1);

for idC = 1:length(idMap)
   [configNames, configValues] = get_float_config_ir_rudics_sbd2(tabCyNum(idMap(idC)), tabPatNum(idMap(idC)));
   if (~isempty(configNames))
      isaP0 = get_config_value('CONFIG_PAYLOAD_ISA_P00_1', configNames, configValues);
      if (~isempty(isaP0))
         tabIsaP0(idMap(idC)) = isaP0;
      end
      isaP1 = get_config_value('CONFIG_PAYLOAD_ISA_P01_1', configNames, configValues);
      if (~isempty(isaP1))
         tabIsaP1(idMap(idC)) = isaP1;
      end
      isaP10 = get_config_value('CONFIG_PAYLOAD_ISA_P10_1', configNames, configValues);
      if (~isempty(isaP10))
         tabIsaP10(idMap(idC)) = isaP10;
      end
      isaP2 = get_config_value('CONFIG_PAYLOAD_ISA_P02_1', configNames, configValues);
      if (~isempty(isaP2))
         tabIsaP2(idMap(idC)) = isaP2;
      end
      isaP3 = get_config_value('CONFIG_PAYLOAD_ISA_P03_1', configNames, configValues);
      if (~isempty(isaP3))
         tabIsaP3(idMap(idC)) = isaP3;
      end
      isaP4 = get_config_value('CONFIG_PAYLOAD_ISA_P04_1', configNames, configValues);
      if (~isempty(isaP4))
         tabIsaP4(idMap(idC)) = isaP4;
      end
      isaP5 = get_config_value('CONFIG_PAYLOAD_ISA_P05_1', configNames, configValues);
      if (~isempty(isaP5))
         tabIsaP5(idMap(idC)) = isaP5;
      end
      isaP6 = get_config_value('CONFIG_PAYLOAD_ISA_P06_1', configNames, configValues);
      if (~isempty(isaP6))
         tabIsaP6(idMap(idC)) = isaP6;
      end
      isaP7 = get_config_value('CONFIG_PAYLOAD_ISA_P07_1', configNames, configValues);
      if (~isempty(isaP7))
         tabIsaP7(idMap(idC)) = isaP7;
      end
      isaP8 = get_config_value('CONFIG_PAYLOAD_ISA_P08_1', configNames, configValues);
      if (~isempty(isaP8))
         tabIsaP8(idMap(idC)) = isaP8;
      end

      if (~isempty(g_decArgo_outputCsvFileId))
         ac1P0 = get_config_value('CONFIG_PAYLOAD_AC1_P00_1', configNames, configValues);
         if (~isempty(ac1P0))
            tabAc1P0(idMap(idC)) = ac1P0;
         end
      end
      ac1P1 = get_config_value('CONFIG_PAYLOAD_AC1_P01_1', configNames, configValues);
      if (~isempty(ac1P1))
         tabAc1P1(idMap(idC)) = ac1P1;
      end

      if (~isempty(g_decArgo_outputCsvFileId))
         secuP2 = get_config_value('CONFIG_APMT_SECURITY_P02', configNames, configValues);
         if (~isempty(secuP2))
            tabSecuP2(idMap(idC)) = secuP2;
         end
      end
      sysP8 = get_config_value('CONFIG_APMT_SYSTEM_P08', configNames, configValues);
      if (~isempty(sysP8))
         tabSysP8(idMap(idC)) = sysP8;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the status of ICE algorithm

if (all(isnan(tabIsaP8)) && all(isnan(tabAc1P1)))
   return
end

fprintf('INFO: Float #%d: checking ICE information\n', ...
   g_decArgo_floatNum);

% specific
if (g_decArgo_floatNum == 6902953)
   % SYSTEM.P8 = 4 reported in SYSTEM file but not in apmt.ini
   % see mail "Re: Détection de glaces sur CTS5_OSEAN" from edouard on ven. 22/11/2024 13:17
   idF = find(ismember(tabCyNum, 164:166));
   tabSysP8(idF) = 4;
end

% set breakup flag
tabBreakupFlag(~isnan(tabCyNum)) = 0;
for id = 1:length(tabCyNum)
   if (~isnan(tabIceDDate(id)) && (tabNbIceDet(id) >= tabIsaP10(id)))
      breakupStart = tabIceDDate(id);
      breakupEnd = tabIceDDate(id) + tabIsaP1(id);
      idStop = find(tabAet > breakupEnd, 1, 'first');
      if (isempty(idStop))
         idStop = length(tabCyNum);
      end
      tabBreakupStart(id:idStop-1) = breakupStart;
      tabBreakupEnd(id:idStop-1) = breakupEnd;
      tabBreakupFlag(id+1:idStop-1) = 1;
   end
end

% set AC1 flag
for id = 1:length(tabCyNum)
   if (tabAc1P1(id) == 4095)
      tabAc1Flag(id) = 1;
   elseif (~isnan(tabAst(id)) && ~isnan(tabAc1P1(id)))
      iceMonths = dec2bin(tabAc1P1(id), 12);
      value = julian_2_gregorian_dec_argo(tabAst(id));
      monthNum = str2double(value(6:7));
      tabAc1Flag(id) = str2double(iceMonths(monthNum));
   end
end

% set ISA flag
for id = 1:length(tabCyNum)
   if (tabIsaP8(id) == 4095)
      tabIsaFlag(id) = 1;
   elseif (~isnan(tabAst(id)) && ~isnan(tabIsaP8(id)))
      iceMonths = dec2bin(tabIsaP8(id), 12);
      value = julian_2_gregorian_dec_argo(tabAst(id));
      monthNum = str2double(value(6:7));
      tabIsaFlag(id) = str2double(iceMonths(monthNum));
   end
end

% set APMT ICE flag
tabPayloadIceFlag(~isnan(tabCyNum)) = 0;
for id = 1:length(tabCyNum)
   if ((tabAc1Flag(id) == 1) || ((tabIsaFlag(id) == 1) && (~isnan(tabIceDDate(id)) || (tabBreakupFlag(id) == 1))))
      tabPayloadIceFlag(id) = 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find anomalies

if (~isempty(g_decArgo_outputCsvFileId))

   tabAnomaly = zeros(length(tabCyNum), 1);

   % when payload card set ICE flag an abort profile cmd should be received by APMT card
   idF = find((tabPayloadIceFlag == 1) & isnan(tabAbortCycleCmdTime));
   tabAnomaly(idF) = 1;

   % when payload card set ICE flag an abort profile cmd should be received by APMT card
   idF = find((tabPayloadIceFlag == 0) & ~isnan(tabAbortCycleCmdTime));
   tabAnomaly(idF) = 2;

   % when the feedback is refused the float reach the surface
   idF = find((tabAbortCycleAckFlag == 0) & isnan(tabTransStartTime));
   tabAnomaly(idF) = 3;

   % when the feedback is refused the float reach the surface
   idF = find((tabAbortCycleAckFlag == 1) & ~isnan(tabTransStartTime));
   tabAnomaly(idF) = 4;

   % when the float didn't surface there is no surf PRES offset
   idF = find((isnan(tabGpsTime) & (isnan(tabTransStartTime) | isnan(tabTransEndTime) & ~isnan(tabTimeoutTime))) & ~isnan(tabSurfPres));
   tabAnomaly(idF) = 5;

   idF = find(tabAnomaly == 1);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #1 ~(when payload card set ICE flag an abort profile cmd should be received by APMT card)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 2);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #2 ~(when payload card set ICE flag an abort profile cmd should be received by APMT card)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 3);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #3 ~(when the feedback is refused the float reach the surface)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 4);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #4 ~(when the feedback is refused the float reach the surface)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
   idF = find(tabAnomaly == 5);
   if (~isempty(idF))
      fprintf('INFO: Float #%d: Anomaly #5 ~(when the float didn''t surface there is no surf PRES offset)\n', ...
         g_decArgo_floatNum);
      for id = idF'
         fprintf('(%d,%d)\n', tabCyNum(id), tabPatNum(id));
      end
   end
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
      'WMO;Cycle #;Pattern #;' ...
      'ISA months;ISA start P;ISA stop P;ISA sampling;ISA depth;ISA T;' ...
      'SPR_INHIB-trig;SPR_INHIB-last;SPR_INHIB-nb_occ;' ...
      'AC1 months;AC1 P;' ...
      'SECU P2;' ...
      'AST;Slow AST;AET;Final pump time;' ...
      'ICE_D_DATE;NB_ICE_DET;LAST_ICE;' ...
      'Breakup flag;Breakup start;Breakup end;' ...
      'AC1 flag;ISA flag;Payload ICE flag;' ...
      'SYS P8;' ...
      'Abort cmd time;Abort ack time;Abort ack flag;' ...
      'Gps time;Trans start time;Trans end time;Trans timeout time;' ...
      'Surf PRES offset;Prof P min; Subsurface P;Anomaly' ...
      ];
   fprintf(fId, '%s\n', header);

   for id = 1:length(tabCyNum)
      if (~isnan(tabIsaP8(id)))
         iceMonthsIsaStr = dec2bin(tabIsaP8(id), 12);
      else
         iceMonthsIsaStr = num2str(tabIsaP8(id));
      end
      if (~isnan(tabAc1P1(id)))
         iceMonthsAc1Str = dec2bin(tabAc1P1(id), 12);
      else
         iceMonthsAc1Str = num2str(tabAc1P1(id));
      end
      fprintf(fId, '%d;%d;%d;''%s;%d;%d;%d;%d;%.2f;%d;%d;%d;''%s;%d;%d; %s; %s; %s; %s; %s;%d;%d;%d; %s; %s;%d;%d;%d;%d; %s; %s;%d; %s; %s; %s; %s;%.2f;%.2f;%.2f;%d\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         tabPatNum(id), ...
         iceMonthsIsaStr, ...
         tabIsaP2(id), ...
         tabIsaP3(id), ...
         tabIsaP4(id), ...
         tabIsaP5(id), ...
         tabIsaP6(id), ...
         tabIsaP0(id), ...
         tabIsaP1(id), ...
         tabIsaP10(id), ...
         iceMonthsAc1Str, ...
         tabAc1P0(id), ...
         tabSecuP2(id), ...
         julian_2_gregorian_dec_argo(tabAst(id)), ...
         julian_2_gregorian_dec_argo(tabSlowAst(id)), ...
         julian_2_gregorian_dec_argo(tabAet(id)), ...
         julian_2_gregorian_dec_argo(tabFinalPumpTime(id)), ...
         julian_2_gregorian_dec_argo(tabIceDDate(id)), ...
         tabNbIceDet(id), ...
         tabLastIce(id), ...
         tabBreakupFlag(id), ...
         julian_2_gregorian_dec_argo(tabBreakupStart(id)), ...
         julian_2_gregorian_dec_argo(tabBreakupEnd(id)), ...
         tabAc1Flag(id), ...
         tabIsaFlag(id), ...
         tabPayloadIceFlag(id), ...
         tabSysP8(id), ...
         julian_2_gregorian_dec_argo(tabAbortCycleCmdTime(id)), ...
         julian_2_gregorian_dec_argo(tabAbortCycleAckTime(id)), ...
         tabAbortCycleAckFlag(id), ...
         julian_2_gregorian_dec_argo(tabGpsTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransStartTime(id)), ...
         julian_2_gregorian_dec_argo(tabTransEndTime(id)), ...
         julian_2_gregorian_dec_argo(tabTimeoutTime(id)), ...
         tabSurfPres(id), ...
         tabProfPresMin(id), ...
         tabSubSurfPres(id), ...
         tabAnomaly(id) ...
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
   % AC1 activated
   idAc1Activated = (tabAc1Flag == 1);
   idAc1ActivatedNan = isnan(tabAc1Flag);
   % ISA activated
   idIsaActivated = (tabIsaFlag == 1);
   idIsaActivatedNan = isnan(tabIsaFlag);
   % algo ICE activated
   idIceActivated = (idAc1Activated | idIsaActivated);
   idIceActivatedNan = (isnan(tabAc1Flag) & isnan(tabIsaFlag));
   % no Iridium transmission flag
   idNoIrTrans = (isnan(tabTransStartTime) | isnan(tabTransEndTime) & ~isnan(tabTimeoutTime));
   idNoIrTransNan  = [];
   % no transmission flag
   idNoTrans = (idNoGps & idNoIrTrans);
   idNoTransNan = [];
   % no action flag
   idNoAction = (tabSysP8 == 0);
   idNoActionNan = isnan(tabSysP8);
   % payload ICE flag
   idPayloadIce = (tabPayloadIceFlag == 1);
   idPayloadIceNan = isnan(tabPayloadIceFlag);
   % profile aborted flag
   idProfAborted = (idPayloadIce & ~idNoAction);
   idProfAbortedNan = (isnan(tabPayloadIceFlag) | isnan(tabSysP8));
   % ISA detection flag
   idIsa = ~isnan(tabIceDDate);
   idIsaNan = [];
   % breakup period flag
   idBreakup = (~idIsa & (tabBreakupFlag == 1));
   idBreakupNan = (isnan(tabPayloadIceFlag) | isnan(tabBreakupFlag));
   % sat mask flag
   idSatMask = (idNoTrans & ~idProfAborted);
   idSatMaskNan = [];

   % Transmission flag
   tabTech1 = nan(length(tabCyNum), 1);
   tabTech1(~isnan(tabCyNum)) = 1;
   tabTech1(idNoTrans) = 0;
   tabTech1(idNoTransNan) = nan;

   % ICE algorithm activated flag
   tabTech2 = nan(length(tabCyNum), 1);
   tabTech2(~isnan(tabCyNum)) = 0;
   tabTech2(idIceActivated) = 1;
   tabTech2(idIceActivatedNan) = nan;

   % ICE surface avoidance flag
   tabTech3 = nan(length(tabCyNum), 1);
   tabTech3(~isnan(tabCyNum)) = 1;
   tabTech3(idNoAction) = 0;
   tabTech3(idNoActionNan) = nan;

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

   % Hanging flag => checked but no hanging detected by these (dead) floats
   tabTech7 = nan(length(tabCyNum), 1);
   tabTech7(~isnan(tabCyNum)) = 0;

   % Satellite mask flag
   tabTech8 = nan(length(tabCyNum), 1);
   tabTech8(~isnan(tabCyNum)) = 0;
   tabTech8(idSatMask) = 1;
   tabTech8(idSatMaskNan) = nan;

   % Forced ascent flag => does not exist with these floats
   tabTech9 = nan(length(tabCyNum), 1);
   tabTech9(~isnan(tabCyNum)) = 0;

   % AC1 activated flag
   tabTech10 = nan(length(tabCyNum), 1);
   tabTech10(~isnan(tabCyNum)) = 0;
   tabTech10(idAc1Activated) = 1;
   tabTech10(idAc1ActivatedNan) = nan;

   % FLAG_IceAlgorithmStatus_bit
   tabTechAll = nan(length(tabCyNum), 1);
   tabFlag = [tabTech10 tabTech9 tabTech8 tabTech7 tabTech6 tabTech5 tabTech4 tabTech3 tabTech2 tabTech1];
   idNonan = find(all(~isnan(tabFlag), 2));
   tabZero = nan(length(tabCyNum), 1);
   tabZero(idNonan, :) = 0;
   tabFlag = cat(2, tabZero, tabFlag);
   tabTechAll(idNonan) = bin2dec(num2str(tabFlag(idNonan, :)));

   % update TECH information with ICE data

   % TECH_AUX_FLAG_IceAlgorithmActivated_LOGICAL
   % TECH_AUX_FLAG_IceIsaAlgorithmActivated_LOGICAL
   % TECH_AUX_FLAG_IceAc1Activated_LOGICAL

   % TECH_AUX_FLAG_IceIsaDetectionAlarm_LOGICAL
   % TECH_AUX_CLOCK_IceIsaDetectionAlarm_YYYYMMDDHHMMSS

   % TECH_AUX_FLAG_IceNoSurfacePeriod_LOGICAL
   % TECH_AUX_FLAG_IceFeedbackCmdAccepted_LOGICAL
   % TECH_AUX_FLAG_IceProfileAbortAlarm_LOGICAL
   % TECH_AUX_FLAG_IceProfileAbortAlarm_YYYYMMDDHHMMSS

   % PRES_IceAvoidance_dbar
   % FLAG_IceDetected_bit

   % TECH_AUX_FLAG_IceAlgorithmStatus_bit

   % TRAJ event with MC=593 for ICE profile Abort time and associated PRES

   % ICE ISA algorithm activated flag
   tabTechIsaActivated = zeros(length(tabCyNum), 1);
   tabTechIsaActivated(idIsaActivated) = 1;
   tabTechIsaActivated(idIsaActivatedNan) = 1;

   for id = 1:length(tabCyNum)

      % look for cycle number
      idCyNum = find((o_tabNcTechIndex(:, 2) == tabCyNum(id)) & (o_tabNcTechIndex(:, 3) == tabPatNum(id)), 1);
      if (isempty(idCyNum))
         continue
      end
      cycleNumber = o_tabNcTechIndex(idCyNum, 6);

      % TECH_AUX_FLAG_IceAlgorithmActivated_LOGICAL
      if (~isnan(tabTech2(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 211 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech2(id);
      end

      % TECH_AUX_FLAG_IceIsaAlgorithmActivated_LOGICAL
      if (~isnan(tabTechIsaActivated(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 212 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTechIsaActivated(id);
      end

      % TECH_AUX_FLAG_IceAc1Activated_LOGICAL
      if (~isnan(tabTech10(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 213 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech10(id);
      end

      % TECH_AUX_FLAG_IceIsaDetectionAlarm_LOGICAL
      if (tabTech5(id) == 1)
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 214 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech5(id);
      end

      % TECH_AUX_CLOCK_IceIsaDetectionAlarm_YYYYMMDDHHMMSS
      if (~isnan(tabIceDDate(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 215 cycleNumber]);
         iceDDate = adjust_time_cts5(tabIceDDate(id));
         iceDDateStr = datestr(iceDDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
         o_tabNcTechVal{end+1} = iceDDateStr;
      end

      % TECH_AUX_FLAG_IceNoSurfacePeriod_LOGICAL
      if (tabTech6(id) == 1)
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 216 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech6(id);
      end
      
      % TECH_AUX_FLAG_IceFeedbackCmdAccepted_LOGICAL
      if (~isnan(tabTech3(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 217 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech3(id);
      end

      % TECH_AUX_FLAG_IceProfileAbortAlarm_LOGICAL
      if (tabTech4(id) == 1)
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 218 cycleNumber]);
         o_tabNcTechVal{end+1} = tabTech4(id);
      end

      % TECH_AUX_FLAG_IceProfileAbortAlarm_YYYYMMDDHHMMSS
      if ((tabTech4(id) == 1) && ~isnan(tabAbortCycleAckTime(id)))
         % new param
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 221 cycleNumber]);
         iceProfileAbortTime = adjust_time_cts5(tabAbortCycleAckTime(id));
         iceProfileAbortTimeStr = datestr(iceProfileAbortTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
         o_tabNcTechVal{end+1} = iceProfileAbortTimeStr;
      end

      % PRES_IceAvoidance_dbar
      if ((tabTech4(id) == 1) && ~isnan(tabProfPresMin(id)))
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 222 cycleNumber]);
         o_tabNcTechVal{end+1} = sprintf('%.2f', tabProfPresMin(id));
      end

      % FLAG_IceDetected_bit
      start = max(1, id-7);
      if (all(~isnan(tabTech4(start:id))))
         iceDetectedBit = num2str(tabTech4(start:id))';
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 219 cycleNumber]);
         o_tabNcTechVal{end+1} = iceDetectedBit;
      end

      % TECH_AUX_FLAG_IceAlgorithmStatus_bit
      if (~isnan(tabTechAll(id)))
         o_tabNcTechIndex = cat(1, o_tabNcTechIndex, [-1 tabCyNum(id) tabPatNum(id) 0 220 cycleNumber]);
         o_tabNcTechVal{end+1} = dec2bin(tabTechAll(id), 11);
      end

      % TRAJ event with MC=593
      if ((tabTech4(id) == 1) && ~isnan(tabAbortCycleAckTime(id)))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_IceAscentAbort, ...
            tabAbortCycleAckTime(id), ...
            adjust_time_cts5(tabAbortCycleAckTime(id)), ...
            g_JULD_STATUS_2);

         if (~isnan(tabProfPresMin(id)))
            paramPres = get_netcdf_param_attributes('PRES');
            measStruct.paramList = paramPres;
            measStruct.paramData = single(tabProfPresMin(id));
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
