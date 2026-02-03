% ------------------------------------------------------------------------------
% Use the last measurement sampled during ascent to decide if the it the ascent
% has been aborted (and collect information for delayed check).
%
% SYNTAX :
% [o_ascentAbortedFlag] = store_ice_information_arvor( ...
%   a_tabTech1, a_tabTech2, ...
%   a_deepCycleFlag, a_ascProfPres, a_nearSurfPres, a_inAirPres, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTech1     : decoded data of technical msg #1
%   a_tabTech2     : decoded data of technical msg #2
%   a_ascProfPres  : ascending profile PRES
%   a_nearSurfPres : near surface PRES
%   a_inAirPres    : in air PRES
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ascentAbortedFlag : 1 if the ascent has been aborted (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   21/12/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ascentAbortedFlag] = store_ice_information_arvor( ...
   a_tabTech1, a_tabTech2, ...
   a_deepCycleFlag, a_ascProfPres, a_nearSurfPres, a_inAirPres, a_decoderId)

% output parameters initialization
o_ascentAbortedFlag = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;

% float configuration
global g_decArgo_floatConfig;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% array to store GPS data
global g_decArgo_gpsData;

% default values
global g_decArgo_presDef;

% to store ICE data used for delayed processing
global g_decArgo_iceData;

% to store information for resetoffset check
global g_decArgo_resetOffsetData;


ID_OFFSET = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for all floats, retrieve information to check resetoffset

% technical message #1
idTech1 = '';
if (~isempty(a_tabTech1))
   idF1 = find(a_tabTech1(:, 1) == 0);
   if (length(idF1) == 1)
      idTech1 = idF1(1);
   end
end

% float current time
floatTime = nan;
if (~isempty(idTech1))
   floatTime = a_tabTech1(idTech1, end-3); % float time at the creation of the TECH packet
end

% check if any GPS or Iridium transmission has been done
transFlag = nan;
if (~isnan(floatTime))
   % floatTime is transmitted in TECH #1 paket with GPS location
   if (any(abs([g_decArgo_iridiumMailData.timeOfSessionJuld] - floatTime) < 1/24))
      transFlag = 1;
   else
      transFlag = 0;
      if (~isempty(g_decArgo_gpsData))
         gpsLocDate = g_decArgo_gpsData{4};
         if (any(abs(gpsLocDate - floatTime) < 1/24))
            transFlag = 1;
         end
      end
   end
else
   % if TECH #1 packet is not received
   if (any([g_decArgo_iridiumMailData.cycleNumber] == g_decArgo_cycleNum))
      transFlag = 1;
   else
      transFlag = 0;
   end
end

% store information for resetoffset check
if (isempty(g_decArgo_resetOffsetData))
   g_decArgo_resetOffsetData.cyNum = g_decArgo_cycleNum;
   g_decArgo_resetOffsetData.transFlag = transFlag;
else
   if (~any(g_decArgo_resetOffsetData.cyNum == g_decArgo_cycleNum))
      g_decArgo_resetOffsetData.cyNum = [g_decArgo_resetOffsetData.cyNum g_decArgo_cycleNum];
      g_decArgo_resetOffsetData.transFlag = [g_decArgo_resetOffsetData.transFlag transFlag];
   else
      idF = find(g_decArgo_resetOffsetData.cyNum == g_decArgo_cycleNum);
      if ((g_decArgo_resetOffsetData.transFlag(idF) == 0) && (transFlag == 1))
         g_decArgo_resetOffsetData.transFlag(idF) = 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
% 230 5.77 : ARVOR_DEEP 4000 2DO => not used not implemented

if (~ismember(a_decoderId, [212, 217, 222:227, 231, 232, 214, 216, 218, 221]))
   return
end

if (a_decoderId == 216)
   % ICE mode is supposed to be activated
   g_decArgo_7TypePacketReceivedCyNum = 0;
end

if (isempty(g_decArgo_7TypePacketReceivedCyNum))
   % ICE algorithm not activated
   return
end

confLabelIc0 = '';
confLabelIc4 = '';
confLabelPumpSwitchOff = '';

tech1TransStartHour = '';
tech1AscentStartHour = '';
tech1GpsValidFix = '';
tech1GpsSessionDuration = '';
tech1GpsSessionTimeout = '';
tech1NbSbdRx = '';
tech1NbSbdTx = '';
tech1IrSession = '';
tech1IrSessionDuration = '';
tech1PresOffset = '';

tech2IceDetectionFlagId = '';
tech2NbInAir = '';
tech2SubSurfPres = '';
tech2SubSurfTemp = '';
tech2SubSurfPsal = '';
tech2NbSbdRx = '';
tech2NbSbdTx = '';
tech2IrSession = '';
tech2IrSessionDuration = '';

switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      confLabelIc0 = 'CONFIG_IC00';
      confLabelIc4 = 'CONFIG_IC04';

      tech1TransStartHour = 39 + ID_OFFSET;
      tech1AscentStartHour = 38 + ID_OFFSET;
      tech1IrSession = 2 + ID_OFFSET;
      tech1PresOffset = 47 + ID_OFFSET;

      tech2IceDetectionFlagId = 59 + ID_OFFSET;
      tech2IrSession = 2 + ID_OFFSET;
      tech2IrSessionDuration = 41 + ID_OFFSET;
   case {216}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc4 = 'CONFIG_PG03';

      tech1TransStartHour = 36 + ID_OFFSET;
      tech1AscentStartHour = 35 + ID_OFFSET;
      tech1PresOffset = 44 + ID_OFFSET;

      tech2IceDetectionFlagId = 42 + ID_OFFSET;
      tech1IrSessionDuration = 70 + ID_OFFSET;
   case {218}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc4 = 'CONFIG_PG04';

      tech1TransStartHour = 36 + ID_OFFSET;
      tech1AscentStartHour = 35 + ID_OFFSET;
      tech1PresOffset = 44 + ID_OFFSET;

      tech2IceDetectionFlagId = 42 + ID_OFFSET;
      tech1IrSessionDuration = 70 + ID_OFFSET;
   case {221}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc4 = 'CONFIG_PG04';

      tech1TransStartHour = 36 + ID_OFFSET;
      tech1AscentStartHour = 35 + ID_OFFSET;
      tech1PresOffset = 44 + ID_OFFSET;

      tech2IceDetectionFlagId = 42 + ID_OFFSET;
      tech1IrSessionDuration = 70 + ID_OFFSET;
end

switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      tech2NbInAir = 14 + ID_OFFSET;
   case {221}
      tech2NbInAir = 44 + ID_OFFSET;
end

switch (a_decoderId)
   case {216, 218, 221}
      tech2SubSurfPres = 10 + ID_OFFSET;
      tech2SubSurfTemp = 11 + ID_OFFSET;
      tech2SubSurfPsal = 12 + ID_OFFSET;
   case {212, 214, 217, 222, 223, 225, 231, 232}
      tech2SubSurfPres = 15 + ID_OFFSET;
      tech2SubSurfTemp = 16 + ID_OFFSET;
      tech2SubSurfPsal = 17 + ID_OFFSET;
end

switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      tech1GpsValidFix = 61 + ID_OFFSET;
      tech1GpsSessionDuration = 62 + ID_OFFSET;
      tech1GpsSessionTimeout = 63 + ID_OFFSET;
      tech2NbSbdRx = 42 + ID_OFFSET;
      tech2NbSbdTx = 43 + ID_OFFSET;
   case {216, 218, 221}
      tech1GpsValidFix = 58 + ID_OFFSET;
      tech1GpsSessionDuration = 59 + ID_OFFSET;
      tech1GpsSessionTimeout = 60 + ID_OFFSET;
      tech1NbSbdRx = 71 + ID_OFFSET;
      tech1NbSbdTx = 72 + ID_OFFSET;
end

switch (a_decoderId)
   case {212, 222, 223, 225, 231, 232}
      confLabelPumpSwitchOff = 'CONFIG_PX02';
      % presCutOffProfOffset = 0;
   case {214, 217, 216, 218, 221}
      confLabelPumpSwitchOff = 'CONFIG_PX01';
      % presCutOffProfOffset = 0.5;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION

% retrieve IC0 configuration parameter values to check that the algorithm has
% been enabled
algoEnable = 0;
if (~isempty(confLabelIc0))
   configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
   configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;
   idIc0 = find(strncmp(confLabelIc0, configNames, length(confLabelIc0)), 1);
   ic0Values = [];
   if (~isempty(idIc0))
      ic0Values = configValues(idIc0, :);
   else
      % there is no configuration assigned yet
      % retrieve the last temporary one
      configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
      configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES;
      idIc0 = find(strncmp(confLabelIc0, configNames, length(confLabelIc0)), 1);
      if (~isempty(idIc0))
         ic0Values = configValues(idIc0, :);
      end
   end
   if (any(ic0Values > 0))
      algoEnable = 1;
   end
end

% retrieve configuration parameter values
if (any(g_decArgo_floatConfig.USE.CYCLE == g_decArgo_cycleNum))
   [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
else
   % there is no configuration assigned yet
   % retrieve the last temporary one
   configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
   configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
end

ic4Value = nan;
if (~isempty(confLabelIc4))
   ic4Value = get_config_value2(confLabelIc4, configNames, configValues);
end
presPumpSwitchOffConfig = nan;
if (~isempty(confLabelPumpSwitchOff))
   presPumpSwitchOffConfig = get_config_value2(confLabelPumpSwitchOff, configNames, configValues);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TECHNICAL

% technical message #2
idTech2 = '';
if (~isempty(a_tabTech2))
   idF2 = find(a_tabTech2(:, 1) == 4);
   if (length(idF2) == 1)
      idTech2 = idF2(1);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve pressure of the subsurface point

% get last pumped measurement
subsurfPres = nan;
if (~isempty(idTech2) && ...
      ~isempty(tech2SubSurfPres) && ~isempty(tech2SubSurfTemp) && ~isempty(tech2SubSurfPsal))
   switch (a_decoderId)
      case {216, 218, 221}
         pres = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(a_tabTech2(idTech2, tech2SubSurfPres));
         temp = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(a_tabTech2(idTech2, tech2SubSurfTemp));
         psal = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(a_tabTech2(idTech2, tech2SubSurfPsal));
      case {212, 214, 217, 222, 223, 225, 231, 232}
         pres = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(a_tabTech2(idTech2, tech2SubSurfPres));
         temp = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(a_tabTech2(idTech2, tech2SubSurfTemp));
         psal = a_tabTech2(idTech2, tech2SubSurfPsal)/1000;
   end
   if (any([pres temp psal] ~= 0))
      subsurfPres = pres;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find shallowest pressure measurement of the ascending profile

minPresMeas = nan;
minAscProfPres = nan;
if (~isempty(a_ascProfPres) || ~isempty(a_nearSurfPres) || ~isempty(a_inAirPres) || ~isnan(subsurfPres))
   if (~isempty(a_ascProfPres))
      minAscProfPres = min(a_ascProfPres(a_ascProfPres ~= g_decArgo_presDef));
   end
   minNearSurfPres = nan;
   if (~isempty(a_nearSurfPres))
      minNearSurfPres = min(a_nearSurfPres(a_nearSurfPres ~= g_decArgo_presDef));
   end
   minInAirPres = nan;
   if (~isempty(a_inAirPres))
      minInAirPres = min(a_inAirPres(a_inAirPres ~= g_decArgo_presDef));
   end
   minPresMeas = min([minAscProfPres minNearSurfPres minInAirPres, subsurfPres], [], 'omitnan');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% collect additional information for delayed (final) check

% get Iridium session number
irSessionNum = nan;
if (~isempty(idTech1) && ~isempty(tech1IrSession))
   irSessionNum = a_tabTech1(idTech1, tech1IrSession);
end
if (~isempty(idTech2) && ~isempty(tech2IrSession))
   irSessionNum = a_tabTech2(idTech2, tech2IrSession);
end

% compute AST and TST
ascentStartDate = nan;
transStartDate = nan;
if (~isempty(idTech1) && ~isnan(floatTime) && ...
      ~isempty(tech1TransStartHour) && ~isempty(tech1AscentStartHour))

   % the day of TST is around the current float time
   transStartHour = a_tabTech1(idTech1, tech1TransStartHour);
   transStartDate = fix(floatTime) +  transStartHour/1440;

   % if the float surfaced
   % with NS&IN_AIR measurements
   % ascentEndDate = transStartDate - 10/1440 - inAirAcqDurationMin*2/1440 - finalBuoyancyAcqSec/86400;
   % without NS&IN_AIR
   % ascentEndDate = transStartDate - 10/1440 - finalBuoyancyAcqSec/86400;
   % where
   % inAirAcqPeriod = get_config_value2('CONFIG_MC29_', configNames, configValues);
   % inAirAcqDurationMin = get_config_value2('CONFIG_MC31_', configNames, configValues);
   % finalBuoyancyAcqSec = get_config_value2('CONFIG_TC22_', configNames, configValues)/100;
   % if the float didn't surface
   % ascentEndDate = transStartDate;

   % we then assume that there is less than one day between AST and TST
   ascentStartHour = a_tabTech1(idTech1, tech1AscentStartHour);
   ascentStartDate = fix(transStartDate) +  ascentStartHour/1440;
   if (ascentStartDate > transStartDate)
      ascentStartDate = ascentStartDate - 1;
   end
end

% get Ice detected flag reported by the float
iceDetectionFlag = nan;
if (~isempty(idTech2) && ~isempty(tech2IceDetectionFlagId))
   iceDetectionFlag = a_tabTech2(idTech2, tech2IceDetectionFlagId);
end

% get number of In Air measurements
nbInAir = nan;
if (~isempty(idTech2) && ~isempty(tech2NbInAir))
   nbInAir = a_tabTech2(idTech2, tech2NbInAir);
end

% get GPS relative information
gpsValidFix = nan;
if (~isempty(idTech1) && ~isempty(tech1GpsValidFix))
   gpsValidFix = a_tabTech1(idTech1, tech1GpsValidFix);
end
gpsSessionDuration = nan;
if (~isempty(idTech1) && ~isempty(tech1GpsSessionDuration))
   gpsSessionDuration = a_tabTech1(idTech1, tech1GpsSessionDuration);
end
gpsSessionTimeout = nan;
if (~isempty(idTech1) && ~isempty(tech1GpsSessionTimeout))
   gpsSessionTimeout = a_tabTech1(idTech1, tech1GpsSessionTimeout);
end

% get Iridium transmission relative information
nbSbdRx = nan;
nbSbdTx = nan;
switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      if (~isempty(idTech2) && ~isempty(tech2NbSbdRx))
         nbSbdRx = a_tabTech2(idTech2, tech2NbSbdRx);
      end
      if (~isempty(idTech2) && ~isempty(tech2NbSbdTx))
         nbSbdTx = a_tabTech2(idTech2, tech2NbSbdTx);
      end
   case {216, 218, 221}
      if (~isempty(idTech1) && ~isempty(tech1NbSbdRx))
         nbSbdRx = a_tabTech1(idTech1, tech1NbSbdRx);
      end
      if (~isempty(idTech1) && ~isempty(tech1NbSbdTx))
         nbSbdTx = a_tabTech1(idTech1, tech1NbSbdTx);
      end
end

% get Iridium session duration (of the previous cycle)
irSessionDuration = nan;
if (~isempty(tech1IrSessionDuration))
   if (~isempty(idTech1))
      irSessionDuration = a_tabTech1(idTech1, tech1IrSessionDuration);
   end
end
if (~isempty(tech2IrSessionDuration))
   if (~isempty(idTech2))
      irSessionDuration = a_tabTech2(idTech2, tech2IrSessionDuration);
   end
end

% get surface offset
surfPresOffset = nan;
if (~isempty(idTech1))
   if (~isempty(tech1PresOffset))
      surfPresOffset = a_tabTech1(idTech1, tech1PresOffset);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set ascent aborded flag
if (algoEnable)
   if (~isnan(gpsValidFix))
      if (gpsValidFix == 255)
         o_ascentAbortedFlag = 1;
      else
         o_ascentAbortedFlag = 0;
      end
   else
      if (~isnan(minPresMeas))
         if (~isnan(ic4Value))
            if (abs(abs(minPresMeas) - ic4Value) < minPresMeas) % if minPresMeas is near ic4Value and not near 0, the ascent has been aborted
               if (transFlag ~= 1) % set ascent aborded flag consistent with transFlag
                  o_ascentAbortedFlag = 1;
               end
            end
         end
      else
         % no descent nor ascent
         o_ascentAbortedFlag = -1; % no data to process
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

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

g_decArgo_iceData = [g_decArgo_iceData; ...
   [g_decArgo_floatNum, g_decArgo_cycleNum, ...
   a_deepCycleFlag, irSessionNum, ...
   ascentStartDate, floatTime, iceDetectionFlag, transFlag, ...
   minPresMeas, nbInAir, subsurfPres, minAscProfPres, ...
   presPumpSwitchOffConfig, transStartDate, ...
   gpsValidFix, gpsSessionDuration, gpsSessionTimeout, nbSbdRx, nbSbdTx, ...
   irSessionDuration, surfPresOffset, ...
   o_ascentAbortedFlag]];

return
