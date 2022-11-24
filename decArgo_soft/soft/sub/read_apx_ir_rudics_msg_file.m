% ------------------------------------------------------------------------------
% Read Apex Iridium Rudics msg file.
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
%    o_nearSurfaceDataStr ...
%    ] = read_apx_ir_rudics_msg_file(a_msgFileName)
%
% INPUT PARAMETERS :
%   a_msgFileName : msg file name
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
%   o_nearSurfaceDataStr     : output ASCII surface data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
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
   o_nearSurfaceDataStr ...
   ] = read_apx_ir_rudics_msg_file(a_msgFileName)

% output parameters initialization
o_error = 0;
o_configDataStr = [];
o_driftMeasDataStr = [];
o_profInfoDataStr = [];
o_profLowResMeasDataStr = [];
o_profHighResMeasDataStr = [];
o_gpsFixDataStr = [];
o_engineeringDataStr = [];
o_nearSurfaceDataStr = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
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
NEAR_SURFACE_DATA = 'Near-surface measurements';
END = '<EOT>';

configData = 0;
driftMeasData = 0;
profInfo = 0;
lowResMeasData = 0;
highResMeasData = 0;
fixData = 0;
flushMultipleData = 0;
engineeringData = 0;
nearSurfaceData = 0;
endFlag = 0;

gpsFixDataStr = [];
engineeringDataStr = [];
nearSurfaceDataStr = [];

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
      if (configData ~= 0)
         fprintf('DEC_ERROR: %sAnomaly detected (line #%d) while parsing file: %s\n', errorHeader, lineNum, a_msgFileName);
         o_error = 1;
      end
      configData = 1;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif (any(strfind(line, DRIFT_MEAS)))
      if (configData ~= 0)
         fprintf('DEC_ERROR: %sAnomaly detected (line #%d) while parsing file: %s\n', errorHeader, lineNum, a_msgFileName);
         o_error = 1;
      end
      configData = 0;
      driftMeasData = 1;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif (any(strfind(line, PROF_START)))
      if (configData ~= 0)
         fprintf('DEC_ERROR: %sAnomaly detected (line #%d) while parsing file: %s\n', errorHeader, lineNum, a_msgFileName);
         o_error = 1;
      end
      configData = 0;
      driftMeasData = 0;
      profInfo = 1;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif (any(strfind(line, LOW_RES_MEAS_START_1)))
      if (profInfo ~= 1)
         fprintf('DEC_ERROR: %sAnomaly detected (line #%d) while parsing file: %s\n', errorHeader, lineNum, a_msgFileName);
         o_error = 1;
      end
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 1;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif (any(strfind(line, LOW_RES_MEAS_START_2)))
      profInfo = 0;
      lowResMeasData = 1;
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
      highResMeasData = 0;
      fixData = 1;
      if (any(strfind(line, GPS_FIX_DATA1)) || any(strfind(line, GPS_FIX_DATA3)))
         flushMultipleData = 1;
      end
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif (any(strfind(line, HIGH_RES_MEAS_START)))
      if (lowResMeasData ~= 1)
         if (strcmp(line, '# GPS fix obtaine'))
            fprintf('DEC_INFO: %sLine #%d : ''%s'' ignored in file: %s\n', errorHeader, lineNum, line, a_msgFileName);
            continue;
         else
            fprintf('DEC_ERROR: %sAnomaly detected (line #%d) while parsing file: %s\n', errorHeader, lineNum, a_msgFileName);
            o_error = 1;
         end
      end
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 1;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif ((fixData == 1) && any(strfind(line, EQUAL)))
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 1;
      nearSurfaceData = 0;
      endFlag = 0;
   elseif (any(strfind(line, NEAR_SURFACE_DATA)))
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 1;
      endFlag = 0;
   elseif (any(strfind(line, END)))
      
      if (~isempty(gpsFixDataStr) || ~isempty(engineeringDataStr) || ~isempty(nearSurfaceDataStr))
         o_gpsFixDataStr{end+1} = gpsFixDataStr;
         o_engineeringDataStr{end+1} = engineeringDataStr;
         o_nearSurfaceDataStr{end+1} = nearSurfaceDataStr;
      end
      
      configData = 0;
      driftMeasData = 0;
      profInfo = 0;
      lowResMeasData = 0;
      highResMeasData = 0;
      fixData = 0;
      engineeringData = 0;
      nearSurfaceData = 0;
      endFlag = 1;
      
      gpsFixDataStr = [];
      engineeringDataStr = [];
      nearSurfaceDataStr = [];
   end
   
   if (configData == 1)
      if (strcmp(line, CONFIG_DATA_END))
         configData = 0;
         continue;
      else
         if (strncmp(line, CONFIG_DATA_END, length(CONFIG_DATA_END)))
            o_configDataStr{end+1} = line;
            continue;
         end
      end
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
         if (~isempty(gpsFixDataStr) || ~isempty(engineeringDataStr) || ~isempty(nearSurfaceDataStr))
            o_gpsFixDataStr{end+1} = gpsFixDataStr;
            o_engineeringDataStr{end+1} = engineeringDataStr;
            o_nearSurfaceDataStr{end+1} = nearSurfaceDataStr;
            
            gpsFixDataStr = [];
            engineeringDataStr = [];
            nearSurfaceDataStr = [];
         end
         flushMultipleData = 0;
      end
      gpsFixDataStr{end+1} = line;
      continue;
   elseif (engineeringData == 1)
      engineeringDataStr{end+1} = line;
      continue;
   elseif (nearSurfaceData == 1)
      nearSurfaceDataStr{end+1} = line;
      continue;
   end
end

fclose(fId);

if (~isempty(gpsFixDataStr) || ~isempty(engineeringDataStr) || ~isempty(nearSurfaceDataStr))
   o_gpsFixDataStr{end+1} = gpsFixDataStr;
   o_engineeringDataStr{end+1} = engineeringDataStr;
   o_nearSurfaceDataStr{end+1} = nearSurfaceDataStr;
end

return;
