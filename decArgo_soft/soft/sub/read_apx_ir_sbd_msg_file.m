% ------------------------------------------------------------------------------
% Read Apex Iridium Sbd msg file.
%
% SYNTAX :
%  [ ...
%    o_error, ...
%    o_configDataStr, ...
%    o_driftMeasDataStr, ...
%    o_profInfoDataStr, ...
%    o_profLowResMeasDataStr, ...
%    o_profHighResMeasDataStr, ...
%    o_gpsFixDataStr, ...
%    o_engineeringDataStr ...
%    ] = read_apx_ir_sbd_msg_file(a_msgFileName, a_decoderId, a_printCycleNum)
%
% INPUT PARAMETERS :
%   a_msgFileName   : msg file name
%   a_decoderId     : float decoder Id
%   a_printCycleNum : 'print cycle in log message' flag
%
% OUTPUT PARAMETERS :
%   o_error                  : parsing error flag
%   o_configDataStr          : output ASCII configuration data
%   o_driftMeasDataStr       : output ASCII drift data
%   o_profInfoDataStr        : output ASCII profile misc information
%   o_profLowResMeasDataStr  : output ASCII LR profile data
%   o_profHighResMeasDataStr : output ASCII HR profile data
%   o_gpsFixDataStr          : output ASCII GPS data
%   o_engineeringDataStr     : output ASCII engineering data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [ ...
   o_error, ...
   o_configDataStr, ...
   o_driftMeasDataStr, ...
   o_profInfoDataStr, ...
   o_profLowResMeasDataStr, ...
   o_profHighResMeasDataStr, ...
   o_gpsFixDataStr, ...
   o_engineeringDataStr ...
   ] = read_apx_ir_sbd_msg_file(a_msgFileName, a_decoderId, a_printCycleNum)

% output parameters initialization
o_error = 0;
o_configDataStr = [];
o_driftMeasDataStr = [];
o_profInfoDataStr = [];
o_profLowResMeasDataStr = [];
o_profHighResMeasDataStr = [];
o_gpsFixDataStr = [];
o_engineeringDataStr = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


VERBOSE = 0;

errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   if (a_printCycleNum)
      errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      errorHeader = sprintf('Float #%d: ', g_decArgo_floatNum);
   end
end

if ~(exist(a_msgFileName, 'file') == 2)
   fprintf('ERROR: %sFile not found: %s\n', errorHeader, a_msgFileName);
   return;
end

% open the file and read the data
fId = fopen(a_msgFileName, 'r');
if (fId == -1)
   fprintf('ERROR: %sUnable to open file: %s\n', errorHeader, a_msgFileName);
   return;
end

CONFIG_DATA_START = '$ Mission configuration for';
CONFIG_DATA = '$';
CONFIG_DATA_END = '$';
DRIFT_MEAS = 'ParkPt';
PROF_START = '$ Profile';
LOW_RES_MEAS_START_1 = '$ Discrete samples:';
LOW_RES_MEAS_START_2 = '$       p        t';
HIGH_RES_MEAS_START = '#';
GPS_FIX_DATA1 = '# GPS fix obtained in';
GPS_FIX_DATA2_1 = '#          lon      lat mm/dd/yyyy hhmmss nsat';
GPS_FIX_DATA2_2 = '#         lon     lat mm/dd/yyyy hhmmss nsat';
GPS_FIX_DATA3 = '# Attempt to get GPS fix failed after';
GPS_FIX_DATA4 = '# Ice evasion initiated at';
GPS_FIX_DATA5 = '# Ice-cap evasion initiated.';
GPS_FIX_DATA6 = '# Leads or break-up of surface ice detected.';
GPS_FIX_DATA7 ='Fix:';
EQUAL = '=';
END = '<EOT>';

configData = 0;
driftMeasData = 0;
profInfo = 0;
lowResMeasData = 0;
lowResMeasDataNbCol = get_low_resolution_data_nb_col(a_decoderId, a_printCycleNum);
highResMeasData = 0;
fixData = 0;
flushMultipleData = 0;
engineeringData = 0;
endFlag = 0;

gpsFixDataStr = [];
engineeringDataStr = [];

lineNum = 0;
while 1
   line = fgetl(fId);
   
   if (line == -1)
      if (endFlag ~= 1)
         %          fprintf('WARNING: End of file without ''<EOT>'' in file: %s\n', a_msgFileName);
      end
      break;
   end
   
   lineNum = lineNum + 1;
   line = strtrim(line);
   if (isempty(line))
      continue;
   end
   
   if (any(strfind(line, CONFIG_DATA_START)))
      configData = 1;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      endFlag = 0;
   elseif (strcmp(line, CONFIG_DATA_END))
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      endFlag = 0;
   elseif (strncmp(line, DRIFT_MEAS, length(DRIFT_MEAS)))
      configData = 0;
      driftMeasData = 1;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      endFlag = 0;
   elseif (any(strfind(line, PROF_START)))
      configData = 0;
      driftMeasData = 0;
      profInfo = 1;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      endFlag = 0;
   elseif (any(strfind(line, LOW_RES_MEAS_START_1)) || ...
         any(strfind(line, LOW_RES_MEAS_START_2)))
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 1;
      if (lowResMeasDataNbCol == 0)
         if (any(strfind(line, LOW_RES_MEAS_START_2)))
            line2 = strtrim(line(2:end));
            len2 = length(line2);
            len3 = 0;
            while (len2 ~= len3)
               len2 = length(line2);
               line3 = regexprep(line2, '  ', ' ');
               len3 = length(line3);
               line2 = line3;
            end
            idFB = strfind(line2, ' ');
            lowResMeasDataNbCol = length(idFB) + 1;
         end
      end
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      endFlag = 0;
   elseif (any(strfind(line, GPS_FIX_DATA1)) || ...
         any(strfind(line, GPS_FIX_DATA2_1)) || ...
         any(strfind(line, GPS_FIX_DATA2_2)) || ...
         any(strfind(line, GPS_FIX_DATA3)) || ...
         any(strfind(line, GPS_FIX_DATA4)) || ...
         any(strfind(line, GPS_FIX_DATA5)) || ...
         any(strfind(line, GPS_FIX_DATA6)) || ...
         any(strfind(line, GPS_FIX_DATA7)))
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      lowResMeasDataNbCol = 0;
      highResMeasData = 0;
      fixData = 1;
      if (any(strfind(line, GPS_FIX_DATA1)) || any(strfind(line, GPS_FIX_DATA3)))
         flushMultipleData = 1;
      end
      engineeringData = 0;
      endFlag = 0;
   elseif (any(strfind(line, HIGH_RES_MEAS_START)))
      if (fixData == 0)
         configData = 0;
         driftMeasData = 0;
         profInfo = 0;
         lowResMeasData = 0;
         lowResMeasDataNbCol = 0;
         highResMeasData = 1;
         fixData = 0;
         engineeringData = 0;
         endFlag = 0;
      else
         fixData = 0;
      end
   elseif (any(strfind(line, EQUAL)))
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      lowResMeasDataNbCol = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 1;
      endFlag = 0;
   elseif (any(strfind(line, END)))
      
      if (~isempty(gpsFixDataStr) || ~isempty(engineeringDataStr))
         o_gpsFixDataStr{end+1} = gpsFixDataStr;
         o_engineeringDataStr{end+1} = engineeringDataStr;
      end
      
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      lowResMeasDataNbCol = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      endFlag = 1;
      
      gpsFixDataStr = [];
      engineeringDataStr = [];
   else
      used = 0;
      if ((configData == 1) && (~strncmp(line, CONFIG_DATA, length(CONFIG_DATA))))
         configData = 0;
      end
      if ((driftMeasData == 1) && (~strncmp(line, DRIFT_MEAS, length(DRIFT_MEAS))))
         driftMeasData = 0;
      end
      if ((profInfo == 1) && ~any(strfind(line, PROF_START)))
         profInfo = 0;
      end
      if ((lowResMeasData == 1) && ...
            ~((any(strfind(line, LOW_RES_MEAS_START_1)) || ...
            any(strfind(line, LOW_RES_MEAS_START_2)))))
         if (lowResMeasDataNbCol > 0)
            [val, count, errmsg, nextIndex] = sscanf(line, repmat('%g ', 1, lowResMeasDataNbCol));
            if (isempty(errmsg) && (count == lowResMeasDataNbCol))
               lowResMeasData = 1;
               used = 1;
            else
               [val, count, errmsg, nextIndex] = sscanf(line, [repmat('%g ', 1, lowResMeasDataNbCol) ' (Park Sample)']);
               if (isempty(errmsg) && (count == lowResMeasDataNbCol))
                  lowResMeasData = 1;
                  used = 1;
               end
            end
         end
      end
      if ((highResMeasData == 1) && ~any(strfind(line, HIGH_RES_MEAS_START)))
         line2 = strtrim(line);
         if ~(((length(line2) == 14) || (length(line2) > 16) && (line2(end) == ']')) && ...
               (length(regexp(lower(line2(1:14)), '[0-9 a-f]')) == 14))
            highResMeasData = 0;
         end
      end
      if ((fixData == 1) && ~((any(strfind(line, GPS_FIX_DATA1)) || ...
            any(strfind(line, GPS_FIX_DATA2_1)) || ...
            any(strfind(line, GPS_FIX_DATA2_2)) || ...
            any(strfind(line, GPS_FIX_DATA3)) || ...
            any(strfind(line, GPS_FIX_DATA4)) || ...
            any(strfind(line, GPS_FIX_DATA5)) || ...
            any(strfind(line, GPS_FIX_DATA6)) || ...
            any(strfind(line, GPS_FIX_DATA7)))))
         fixData = 0;
      end
      
      if (used == 0)
         if (highResMeasData == 0)
            line2 = strtrim(line);
            if (((length(line2) == 14) || (length(line2) > 16) && (line2(end) == ']')) && ...
                  (length(regexp(lower(line2(1:14)), '[0-9a-f]')) == 14))
               configData = 0;
               driftMeasData = 0;
               profInfo = 0;
               lowResMeasData = 0;
               highResMeasData = 1;
               fixData = 0;
               engineeringData = 0;
               endFlag = 0;
               used = 1;
            end
         end
      end
      if (used == 0)
         if (lowResMeasData == 0)
            if (lowResMeasDataNbCol > 0)
               [val, count, errmsg, nextIndex] = sscanf(line, repmat('%g ', 1, lowResMeasDataNbCol));
               if (isempty(errmsg) && (count == lowResMeasDataNbCol))
                  configData = 0;
                  driftMeasData = 0;
                  profInfo = 0;
                  lowResMeasData = 1;
                  highResMeasData = 0;
                  fixData = 0;
                  engineeringData = 0;
                  endFlag = 0;
               else
                  [val, count, errmsg, nextIndex] = sscanf(line, [repmat('%g ', 1, lowResMeasDataNbCol) ' (Park Sample)']);
                  if (isempty(errmsg) && (count == lowResMeasDataNbCol))
                     configData = 0;
                     driftMeasData = 0;
                     profInfo = 0;
                     lowResMeasData = 1;
                     highResMeasData = 0;
                     fixData = 0;
                     engineeringData = 0;
                     endFlag = 0;
                  end
               end
            end
         end
      end
   end
   
   if (configData == 1)
      o_configDataStr{end+1} = line;
   elseif (driftMeasData == 1)
      o_driftMeasDataStr{end+1} = line;
      continue;
   elseif (profInfo == 1)
      o_profInfoDataStr{end+1} = line;
      continue;
   elseif (lowResMeasData == 1)
      o_profLowResMeasDataStr{end+1} = line;
      continue;
   elseif (highResMeasData == 1)
      o_profHighResMeasDataStr{end+1} = line;
      continue;
   elseif (fixData == 1)
      if (flushMultipleData == 1)
         if (~isempty(gpsFixDataStr) || ~isempty(engineeringDataStr))
            o_gpsFixDataStr{end+1} = gpsFixDataStr;
            o_engineeringDataStr{end+1} = engineeringDataStr;
            
            gpsFixDataStr = [];
            engineeringDataStr = [];
         end
         flushMultipleData = 0;
      end
      gpsFixDataStr{end+1} = line;
      continue;
   elseif (engineeringData == 1)
      engineeringDataStr{end+1} = line;
      continue;
   else
      if (~strcmp(line, CONFIG_DATA_END))
         if (VERBOSE == 1)
            fprintf('PARSE_INFO: %sLine #%d : ''%s'' ignored in file: %s\n', errorHeader, lineNum, line, a_msgFileName);
         end
         continue;
      end
   end
end

fclose(fId);

if (~isempty(gpsFixDataStr) || ~isempty(engineeringDataStr))
   o_gpsFixDataStr{end+1} = gpsFixDataStr;
   o_engineeringDataStr{end+1} = engineeringDataStr;
end

return;

% ------------------------------------------------------------------------------
% Get the number of columns of Apex Irdium Sbd Low Resolution data.
%
% SYNTAX :
%  [o_nbCol] = get_low_resolution_data_nb_col(a_decoderId, a_printCycleNum)
%
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_printCycleNum : 'print cycle in log message' flag
%
% OUTPUT PARAMETERS :
%   o_nbCol : number of columns
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbCol] = get_low_resolution_data_nb_col(a_decoderId, a_printCycleNum)

% output parameters initialization
o_nbCol = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   if (a_printCycleNum)
      errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      errorHeader = sprintf('Float #%d: ', g_decArgo_floatNum);
   end
end

switch (a_decoderId)
   
   case {1314}
      
      % Apex Iridium SBD

      o_nbCol = 3;

   otherwise
      fprintf('DEC_WARNING: %sNothing done yet in get_low_resolution_data_nb_col for decoderId #%d\n', ...
         errorHeader, a_decoderId);
      return;
end

return;
