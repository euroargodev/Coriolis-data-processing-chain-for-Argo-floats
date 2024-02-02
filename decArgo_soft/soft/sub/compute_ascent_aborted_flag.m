% ------------------------------------------------------------------------------
% Use the float Ice algorithm to determine if the ascent is aborted.
%
% SYNTAX :
% compute_ascent_aborted_flag(a_tabTech1, a_tabTech2, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTech1  : decoded data of technical msg #1
%   a_tabTech2  : decoded data of technical msg #2
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ascentAborted  : 0 if the ascent is not aborted
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   21/12/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ascentAborted] = compute_ascent_aborted_flag(a_tabTech1, a_tabTech2, a_decoderId)

% output parameters initialization
o_ascentAborted = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;

% date of last ICE detection
global g_decArgo_lastDetectionDate;

% date of last surfacing
global g_decArgo_lastSurfacingDate;

% number of consecutive ISA detection
global g_decArgo_isaDetectionCounter;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;

% float configuration
global g_decArgo_floatConfig;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;

% name of the CSV file of ICE information
global g_decArgo_iceInfoFilePathName;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


ID_OFFSET = 1;

% CSV output only for decode_provor_2_csv decoder
csvOutput = 0;
if (~isempty(g_decArgo_outputCsvFileId))
   csvOutput = 1;
end

% decId concerned by ICE algorithm
% 212 5.45 : ARVOR ARN Ir Ice
% 217 5.46 : ARVOR-ARN-DO Ir Ice
% 222 5.47 : ARVOR-ARN Ir Ice
% 223 5.48 : ARVOR-ARN-DO Ir Ice
% 224 5.49 : ARVOR ARN Ir Ice with RBR
% 225 5.76 : ARVOR-ARN-DO Ir Ice
% 226 5.51 : ARVOR ARN Ir Ice with RBR 1 Hz
%
% 214 5.75 : PROVOR ARN DO Ir Ice
%
% 216 5.65 : ARVOR_DEEP 4000
% 218 5.66 : ARVOR_DEEP 4000
% 221 5.67 : ARVOR_DEEP 4000

if (~ismember(a_decoderId, [212 217 222:226 214 216 218 221]))
   return
end

tech1IrSessionId = -1;
tech1GpsValidFixId = -1;
tech1GPSSessionDurationId = -1;
tech2IrSessionId = -1;
tech2IceDetectionFlagId = -1;
switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226}
      confLabelIc0 = 'CONFIG_IC00_';
      confLabelIc1 = 'CONFIG_IC01_';
      confLabelIc2 = 'CONFIG_IC02_';

      tech1IrSessionId = 2 + ID_OFFSET;
      tech1GpsValidFixId = 61 + ID_OFFSET;
      tech1GPSSessionDurationId = 62 + ID_OFFSET;

      tech2IrSessionId = 2 + ID_OFFSET;
      tech2IceDetectionFlagId = 59 + ID_OFFSET;
   case {216}
      % ICE mode is supposed to be activated
      g_decArgo_7TypePacketReceivedCyNum = 0;

      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc1 = 'CONFIG_PG01';
      confLabelIc2 = '';

      tech1IrSessionId = -1;
      tech1GpsValidFixId = 58 + ID_OFFSET;
      tech1GPSSessionDurationId = 59 + ID_OFFSET;

      tech2IrSessionId = -1;
      tech2IceDetectionFlagId = 42 + ID_OFFSET;
   case {218, 221}
      confLabelIc0 = 'CONFIG_PG00';
      confLabelIc1 = 'CONFIG_PG01';
      confLabelIc2 = 'CONFIG_PG02';

      tech1IrSessionId = -1;
      tech1GpsValidFixId = 58 + ID_OFFSET;
      tech1GPSSessionDurationId = 59 + ID_OFFSET;

      tech2IrSessionId = -1;
      tech2IceDetectionFlagId = 42 + ID_OFFSET;
end

if (isempty(a_tabTech1) && isempty(a_tabTech2))
   return
end

% print CSV output only if ICE algorithm is enabled
if (csvOutput == 1)
   if (isempty(g_decArgo_7TypePacketReceivedCyNum))
      csvOutput = 0;
   else
      algoEnable = '';

      % retrieve IC0 configuration parameter values
      configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
      configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;
      idIc0 = find(strncmp(confLabelIc0, configNames, length(confLabelIc0)), 1);
      if (~isempty(idIc0))
         ic0Values = configValues(idIc0, :);
         if (any(ic0Values > 0))
            algoEnable = 1;
         else
            algoEnable = 0;
         end
      end
      if (isempty(algoEnable))
         % there is no configuration assigned yet
         % retrieve the last temporary one
         configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
         configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES;
         idIc0 = find(strncmp(confLabelIc0, configNames, length(confLabelIc0)), 1);
         if (~isempty(idIc0))
            ic0Values = configValues(idIc0, :);
            if (any(ic0Values > 0))
               algoEnable = 1;
            else
               algoEnable = 0;
            end
         end
      end
      if (isempty(algoEnable))
         csvOutput = 0;
      elseif (algoEnable == 0)
         csvOutput = 0;
      end
   end
end

if (csvOutput)
   if (isempty(g_decArgo_iceInfoFilePathName))
      % create output CSV file
      csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_ice_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end
      g_decArgo_iceInfoFilePathName = csvFilepathName;
      header = [ ...
         'WMO;Cycle #;Ice available;IC0;IC1;IC2;Ice activated;Tech1 received;Tech2 received;Ir session #;' ...
         'Float time;Ice detection flag;Ascent aborted;No transmission;ANOMALY;ISA detection counter;Breakup start;Breakup end;Last surfacing;Forced surfacing'];
      fprintf(fId, '%s\n', header);
   else
      fId = fopen(g_decArgo_iceInfoFilePathName, 'a');
      if (fId == -1)
         fprintf('ERROR: Unable to open file: %s\n', g_decArgo_iceInfoFilePathName);
         return
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICE detection determination

if (csvOutput)
   fprintf(fId, '%d;%d;', g_decArgo_floatNum, g_decArgo_cycleNum);
end

ascentAborted = 0;
if (~isempty(g_decArgo_7TypePacketReceivedCyNum) && ...
      (g_decArgo_cycleNum >= g_decArgo_7TypePacketReceivedCyNum)) % check that ICE capability is available

   if (csvOutput)
      fprintf(fId, 'Y;');
   end

   % retrieve IC0, IC1 and IC2 configuration parameter values
   cyNum = g_decArgo_cycleNum;
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
   ic0Value = get_config_value(confLabelIc0, configNames, configValues);
   ic1Value = get_config_value(confLabelIc1, configNames, configValues);
   if (~isempty(confLabelIc2))
      ic2Value = get_config_value(confLabelIc2, configNames, configValues);
   else
      ic2Value = 1;
   end

   if (csvOutput)
      fprintf(fId, '%d;%d;%d;', ic0Value, ic1Value, ic2Value);
   end

   if (ic0Value > 0) % check that ICE algorithm is enabled

      if (csvOutput)
         fprintf(fId, 'Y;');
      end

      % technical message #1
      idTech1 = [];
      if (~isempty(a_tabTech1))
         idF1 = find(a_tabTech1(:, 1) == 0);
         if (length(idF1) == 1)
            idTech1 = idF1(1);
         end
      end
      % technical message #2
      idTech2 = [];
      if (~isempty(a_tabTech2))
         idF2 = find(a_tabTech2(:, 1) == 4);
         if (length(idF2) == 1)
            idTech2 = idF2(1);
         end
      end
      if (~isempty(idTech1) && ~isempty(idTech2))

         if (csvOutput)
            fprintf(fId, '1;1;');
         end

         if (tech1IrSessionId ~= -1)
            tech1IrSession = a_tabTech1(idTech1, tech1IrSessionId);
         else
            tech1IrSession = 0;
         end
         if (tech2IrSessionId ~= -1)
            tech2IrSession = a_tabTech2(idTech2, tech2IrSessionId);
         else
            tech2IrSession = 0;
         end

         if ((tech1IrSession == 0) && (tech2IrSession == 0))

            floatTime = a_tabTech1(idTech1, end-3); % float time at the creation of the TECH packet
            iceDetectionFlag = a_tabTech2(idTech2, tech2IceDetectionFlagId);

            if (csvOutput)
               fprintf(fId, '1;%s;%d;', julian_2_gregorian_dec_argo(floatTime), iceDetectionFlag);
            end

            switch (iceDetectionFlag)
               case 0
                  ascentAborted = 0;
                  if (~isempty(g_decArgo_lastDetectionDate) && (floatTime < g_decArgo_lastDetectionDate + ic0Value))
                     ascentAborted = 5;
                  end
                  g_decArgo_isaDetectionCounter = 0;

               case 1
                  ascentAborted = 1;
                  g_decArgo_isaDetectionCounter = g_decArgo_isaDetectionCounter + 1;
                  if (g_decArgo_isaDetectionCounter >= ic2Value)
                     if (isempty(g_decArgo_lastDetectionDate) || (floatTime > g_decArgo_lastDetectionDate))
                        g_decArgo_lastDetectionDate = floatTime;
                     end
                  end

               case 2 % sat mask => ascent aborted for a IC0 days period
                  ascentAborted = 2;
                  if (isempty(g_decArgo_lastDetectionDate) || (floatTime > g_decArgo_lastDetectionDate))
                     g_decArgo_lastDetectionDate = floatTime;
                  end

               case 4 % ascent hanging => ascent aborted for a IC0 days period
                  ascentAborted = 4;
                  if (isempty(g_decArgo_lastDetectionDate) || (floatTime > g_decArgo_lastDetectionDate))
                     g_decArgo_lastDetectionDate = floatTime;
                  end

               otherwise
                  fprintf('ERROR: Float #%d cycle #%d: not expected ice detection flag value (%d)\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     iceDetectionFlag);
            end
            if (~ascentAborted)
               if (isempty(g_decArgo_lastSurfacingDate) || (floatTime > g_decArgo_lastSurfacingDate))
                  g_decArgo_lastSurfacingDate = floatTime;
               end
            else
               if (~isempty(g_decArgo_lastSurfacingDate) && (floatTime > g_decArgo_lastSurfacingDate + ic1Value))
                  ascentAborted = 0;
               end
            end

            if (csvOutput)

               if (any(abs([g_decArgo_iridiumMailData.timeOfSessionJuld] - floatTime) < 1/24))
                  noTransmission = 'N';
               else
                  noTransmission = 'Y';
               end

               ascentAbortedStr = 'Y';
               if (ascentAborted == 0)
                  ascentAbortedStr = 'N';
               end
               breakupPeriodStartDate = 'n/a';
               if (~isempty(g_decArgo_lastDetectionDate))
                  breakupPeriodStartDate = julian_2_gregorian_dec_argo(g_decArgo_lastDetectionDate);
               end
               breakupPeriodEndDate = 'n/a';
               if (~isempty(g_decArgo_lastDetectionDate))
                  breakupPeriodEndDate = julian_2_gregorian_dec_argo(g_decArgo_lastDetectionDate + ic0Value);
               end
               lastSurfacingDate = 'n/a';
               if (~isempty(g_decArgo_lastSurfacingDate))
                  lastSurfacingDate = julian_2_gregorian_dec_argo(g_decArgo_lastSurfacingDate);
               end
               forcedSurfacingDate = 'n/a';
               if (~isempty(g_decArgo_lastSurfacingDate))
                  forcedSurfacingDate = julian_2_gregorian_dec_argo(g_decArgo_lastSurfacingDate + ic1Value);
               end

               if (ascentAbortedStr ~= noTransmission)
                  anomaly = 'Y';
                  fprintf('ICE_ANOMALY: Float #%d cycle #%d: anomaly in ICE algorithm VS surfacing (ascentAborted ''%c'' noTransmission ''%c'')\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     ascentAbortedStr, noTransmission);
               else
                  anomaly = 'N';
               end

               fprintf(fId, '%c;%c;%c;%d;%s;%s;%s;%s\n', ...
                  ascentAbortedStr, ...
                  noTransmission, ...
                  anomaly, ...
                  g_decArgo_isaDetectionCounter, ...
                  breakupPeriodStartDate, ...
                  breakupPeriodEndDate, ...
                  lastSurfacingDate, ...
                  forcedSurfacingDate);
            end

            % check consitency with other information
            if (ascentAborted == 0)
               gpsValidFix = a_tabTech1(idTech1, tech1GpsValidFixId);
               gpsSessionDuration = a_tabTech1(idTech1, tech1GPSSessionDurationId);
               if ((gpsValidFix == 255) && (gpsSessionDuration == 0))
                  fprintf('WARNING: Float #%d cycle #%d: ice detection information not consistent with TECH information (Ice detection: %d, GPS valid fix: %d, GPS session duration: %d)\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     ascentAborted, gpsValidFix, gpsSessionDuration);
               end
            end
         else
            if (csvOutput)
               fprintf(fId, '2\n');
            end
         end

      elseif (~isempty(idTech1))

         if (csvOutput)
            fprintf(fId, '1;0\n');
         end

         floatTime = a_tabTech1(idTech1, end-3); % float time at the creation of the TECH packet
         if (~isempty(g_decArgo_lastDetectionDate) && (floatTime > g_decArgo_lastDetectionDate + ic0Value))
            ascentAborted = 5;
         end

         if (~ascentAborted)
            if (isempty(g_decArgo_lastSurfacingDate) || (floatTime > g_decArgo_lastSurfacingDate))
               g_decArgo_lastSurfacingDate = floatTime;
            end
         else
            if (~isempty(g_decArgo_lastSurfacingDate) && (floatTime > g_decArgo_lastSurfacingDate + ic1Value))
               ascentAborted = 0;
            end
         end

      elseif (~isempty(idTech2))

         if (csvOutput)
            fprintf(fId, '0;1\n');
         end

         iceDetectionFlag = a_tabTech2(idTech2, tech2IceDetectionFlagId);

         switch (iceDetectionFlag)
            case 0
               ascentAborted = 0;
               g_decArgo_isaDetectionCounter = 0;

            case 1
               ascentAborted = 1;
               g_decArgo_isaDetectionCounter = g_decArgo_isaDetectionCounter + 1;

            case 2 % sat mask => ascent aborted for a IC0 days period
               ascentAborted = 2;

            case 4 % ascent hanging => ascent aborted for a IC0 days period
               ascentAborted = 4;

            otherwise
               fprintf('ERROR: Float #%d cycle #%d: not expected ice detection flag value (%d)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  iceDetectionFlag);
         end

      else
         if (csvOutput)
            fprintf(fId, '0;0\n');
         end
      end

      % store information for compute_ice_detected_bit_value
      idFCy = find(g_decArgo_cycleNumListForIce == g_decArgo_cycleNum);
      if (isempty(idFCy))
         idFCy = length(g_decArgo_cycleNumListForIce) + 1;
      end
      g_decArgo_cycleNumListForIce(idFCy) = g_decArgo_cycleNum;
      g_decArgo_cycleNumListIceDetected(idFCy) = ~(ascentAborted == 0);

      % fprintf('INFO: Float #%d cycle #%d: IC0 IC1 IC2 (%d %d %d): iceDetectionFlag %d: ascentAborted %d\n', ...
      %    g_decArgo_floatNum, g_decArgo_cycleNum, ...
      %    ic0Value, ic1Value, ic2Value, iceDetectionFlag, ascentAborted);

   else
      if (csvOutput)
         fprintf(fId, 'N\n');
      end
   end
else
   if (csvOutput)
      fprintf(fId, 'N\n');
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (csvOutput)
   fclose(fId);
end

return
