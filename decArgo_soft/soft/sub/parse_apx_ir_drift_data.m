% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics drift data.
%
% SYNTAX :
%  [o_driftData] = parse_apx_ir_drift_data(a_driftMeasDataStr, a_decoderId)
%
% INPUT PARAMETERS :
%   a_driftMeasDataStr : input ASCII drift data
%   a_decoderId        : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_driftData : drift data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftData] = parse_apx_ir_drift_data(a_driftMeasDataStr, a_decoderId)

% output parameters initialization
o_driftData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

if (isempty(a_driftMeasDataStr))
   return
end

switch (a_decoderId)
   
   case {1101, 1104, 1105, 1107, 1110, 1111, 1112, 1113} % 030410 & 020212 & 030512 & 062813_1 & 092813 & 073014 & 102815 & 110216
      
      [o_driftData] = parse_apx_ir_drift_data_1_4_5_7_10_to_13(a_driftMeasDataStr);
      
   case {1314} % 090215
      
      [o_driftData] = parse_apx_ir_drift_data_14(a_driftMeasDataStr);
      
   case {1102, 1103, 1106, 1108, 1109} % 120210 & 012811 & 060612 & 062813_2 & 051216 & 062813_3
      
      [o_driftData] = parse_apx_ir_drift_data_2_3_6_8_9(a_driftMeasDataStr);
            
   case {1201} % 061113
      
      [o_driftData] = parse_nvs_ir_rudics_drift_data_1(a_driftMeasDataStr);
      
   otherwise
      fprintf('DEC_WARNING: %sNothing done yet in parse_apx_nvs_ir_rudics_drift_data for decoderId #%d\n', ...
         errorHeader, a_decoderId);
      return
end

return

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics drift data.
%
% SYNTAX :
%  [o_driftData] = parse_apx_ir_drift_data_1_4_5_7_10_to_13(a_driftMeasDataStr)
%
% INPUT PARAMETERS :
%   a_driftMeasDataStr : input ASCII drift data
%
% OUTPUT PARAMETERS :
%   o_driftData : drift data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftData] = parse_apx_ir_drift_data_1_4_5_7_10_to_13(a_driftMeasDataStr)

% output parameters initialization
o_driftData = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% global time status
global g_JULD_STATUS_2;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PREFIX = 'ParkPt:';

data = nan(length(a_driftMeasDataStr), 5);
for idL = 1:length(a_driftMeasDataStr)
   dataStr = a_driftMeasDataStr{idL};
   if (any(strfind(dataStr, PREFIX)))
      if (length(dataStr) == 67)
         measDate = datenum(dataStr(12:31), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(32:end), '%d %d %f %f');
         if (~isempty(errmsg) || (count ~= 4))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, :) = [measDate val'];
      elseif (length(dataStr) >= 59)
         measDate = datenum(dataStr(12:31), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(32:59), '%d %d %f');
         if (~isempty(errmsg) || (count ~= 3))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 51)
         measDate = datenum(dataStr(12:31), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(32:51), '%d %d');
         if (~isempty(errmsg) || (count ~= 2))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 43)
         measDate = datenum(dataStr(12:31), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(32:43), '%d');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 31)
         measDate = datenum(dataStr(12:31), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         data(idL, 1) = measDate;
         %          fprintf('INFO: Park measurement truncated\n');
      else
         %          fprintf('INFO: Park measurement truncated ''%s'' - ignored\n', errorHeader, dataStr);
      end
   else
      fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
   end
end
idDel = find(sum(isnan(data), 2) == size(data, 2));
data(idDel, :) = [];

% create the parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');

% store drift data
o_driftData = get_apx_profile_data_init_struct;

% add parameter variables to the data structure
o_driftData.dateList = paramJuld;
o_driftData.paramList = [paramPres paramTemp];

% add parameter data to the data structure
o_driftData.dates = data(:, 1);
o_driftData.data = data(:, 4:5);

% add date status to the data structure
o_driftData.datesStatus = repmat(g_JULD_STATUS_2, size(o_driftData.dates));

return

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics drift data.
%
% SYNTAX :
%  [o_driftData] = parse_apx_ir_drift_data_14(a_driftMeasDataStr)
%
% INPUT PARAMETERS :
%   a_driftMeasDataStr : input ASCII drift data
%
% OUTPUT PARAMETERS :
%   o_driftData : drift data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftData] = parse_apx_ir_drift_data_14(a_driftMeasDataStr)

% output parameters initialization
o_driftData = [];

% global time status
global g_JULD_STATUS_2;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PREFIX = 'ParkPt:';

data = nan(length(a_driftMeasDataStr), 4);
for idL = 1:length(a_driftMeasDataStr)
   dataStr = a_driftMeasDataStr{idL};
   if (any(strfind(dataStr, PREFIX)))
      % we should use the UnixEpoch since the 'month' string is not reliable
      % with the SBD transmission
      idF = strfind(dataStr, ':');
      if (length(idF) == 3)
         dataStr = strtrim(dataStr(idF(3)+3:end));
         if (length(dataStr) == 34)
            [val, count, errmsg, nextIndex] = sscanf(dataStr, '%d %d %f %f');
            if (~isempty(errmsg) || (count ~= 4))
               fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, a_driftMeasDataStr{idL});
               continue
            end
            data(idL, :) = val';
         elseif (length(dataStr) >= 26)
            [val, count, errmsg, nextIndex] = sscanf(dataStr(1:26), '%d %d %f');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, a_driftMeasDataStr{idL});
               continue
            end
            data(idL, 1:length(val')) = val';
            fprintf('INFO: Park measurement truncated\n');
         else
            fprintf('INFO: Park measurement truncated ''%s'' - ignored\n', errorHeader, a_driftMeasDataStr{idL});
         end
      end
   else
      fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, a_driftMeasDataStr{idL});
   end
end
idDel = find(sum(isnan(data), 2) == size(data, 2));
data(idDel, :) = [];

% create the parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');

% store drift data
o_driftData = get_apx_profile_data_init_struct;

% add parameter variables to the data structure
o_driftData.dateList = paramJuld;
o_driftData.paramList = [paramPres paramTemp];

% add parameter data to the data structure
o_driftData.dates = epoch_2_julian_dec_argo(data(:, 1));
o_driftData.data = data(:, 3:4);

% add date status to the data structure
o_driftData.datesStatus = repmat(g_JULD_STATUS_2, size(o_driftData.dates));

return

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics drift data.
%
% SYNTAX :
%  [o_driftData] = parse_apx_ir_drift_data_2_3_6_8_9(a_driftMeasDataStr)
%
% INPUT PARAMETERS :
%   a_driftMeasDataStr : input ASCII drift data
%
% OUTPUT PARAMETERS :
%   o_driftData : drift data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftData] = parse_apx_ir_drift_data_2_3_6_8_9(a_driftMeasDataStr)

% output parameters initialization
o_driftData = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% global time status
global g_JULD_STATUS_2;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PREFIX = 'ParkPts:';

data = nan(length(a_driftMeasDataStr), 6);
for idL = 1:length(a_driftMeasDataStr)
   dataStr = a_driftMeasDataStr{idL};
   if (any(strfind(dataStr, PREFIX)))
      if (length(dataStr) == 76)
         measDate = datenum(dataStr(13:32), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(33:end), '%d %d %f %f %f');
         if (~isempty(errmsg) || (count ~= 5))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, :) = [measDate val'];
      elseif (length(dataStr) >= 68)
         measDate = datenum(dataStr(13:32), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(33:68), '%d %d %f %f');
         if (~isempty(errmsg) || (count ~= 4))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 60)
         measDate = datenum(dataStr(13:32), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(33:60), '%d %d %f');
         if (~isempty(errmsg) || (count ~= 3))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 52)
         measDate = datenum(dataStr(13:32), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(33:52), '%d %d');
         if (~isempty(errmsg) || (count ~= 2))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 44)
         measDate = datenum(dataStr(13:32), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         [val, count, errmsg, nextIndex] = sscanf(dataStr(33:44), '%d');
         if (~isempty(errmsg) || (count ~= 1))
            fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
            continue
         end
         data(idL, 1:length([measDate val'])) = [measDate val'];
         %          fprintf('INFO: Park measurement truncated\n');
      elseif (length(dataStr) >= 32)
         measDate = datenum(dataStr(12:32), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         data(idL, 1) = measDate;
         %          fprintf('INFO: Park measurement truncated\n');
      else
         %          fprintf('INFO: Park measurement truncated ''%s'' - ignored\n', errorHeader, dataStr);
      end
   else
      fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
   end
end
idDel = find(sum(isnan(data), 2) == size(data, 2));
data(idDel, :) = [];

% create the parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');

% store drift data
o_driftData = get_apx_profile_data_init_struct;

% add parameter variables to the data structure
o_driftData.dateList = paramJuld;
o_driftData.paramList = [paramPres paramTemp paramSal];

% add parameter data to the data structure
o_driftData.dates = data(:, 1);
o_driftData.data = data(:, 4:6);

% add date status to the data structure
o_driftData.datesStatus = repmat(g_JULD_STATUS_2, size(o_driftData.dates));
      
return

% ------------------------------------------------------------------------------
% Parse Navis drift data.
%
% SYNTAX :
%  [o_driftData] = parse_nvs_ir_rudics_drift_data_1(a_driftMeasDataStr)
%
% INPUT PARAMETERS :
%   a_driftMeasDataStr : input ASCII drift data
%
% OUTPUT PARAMETERS :
%   o_driftData : drift data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftData] = parse_nvs_ir_rudics_drift_data_1(a_driftMeasDataStr)

% output parameters initialization
o_driftData = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% global time status
global g_JULD_STATUS_2;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

HEADER = '$ ParkPtsOpt63: Date       P       T       S Ph4330  T4330 RP4330  TPh63    T63';

data = nan(length(a_driftMeasDataStr)-1, 9);
for idL = 1:length(a_driftMeasDataStr)
   dataStr = a_driftMeasDataStr{idL};
   if (any(strfind(dataStr, HEADER)))
   elseif (length(dataStr) >= 79)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:end), '%f %f %f %f %f %f %f %f');
      if (~isempty(errmsg) || (count ~= 8))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, :) = [measDate val'];
   elseif (length(dataStr) >= 72)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:72), '%f %f %f %f %f %f %f');
      if (~isempty(errmsg) || (count ~= 7))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 65)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:65), '%f %f %f %f %f %f');
      if (~isempty(errmsg) || (count ~= 6))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 58)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:58), '%f %f %f %f %f');
      if (~isempty(errmsg) || (count ~= 5))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 51)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:51), '%f %f %f %f');
      if (~isempty(errmsg) || (count ~= 4))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 44)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:44), '%f %f %f');
      if (~isempty(errmsg) || (count ~= 3))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 36)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:36), '%f %f');
      if (~isempty(errmsg) || (count ~= 2))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 28)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      [val, count, errmsg, nextIndex] = sscanf(dataStr(21:28), '%f');
      if (~isempty(errmsg) || (count ~= 1))
         fprintf('DEC_INFO: %sAnomaly detected while parsing drift measurements ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      data(idL-1, 1:length([measDate val'])) = [measDate val'];
      %       fprintf('INFO: Park measurement truncated\n');
   elseif (length(dataStr) >= 20)
      measDate = datenum(dataStr(1:20), 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      data(idL-1, 1) = measDate;
      %       fprintf('INFO: Park measurement truncated\n');
   else
      %       fprintf('INFO: Park measurement truncated ''%s'' - ignored\n', errorHeader, dataStr);
   end
end
idDel = find(sum(isnan(data), 2) == size(data, 2));
data(idDel, :) = [];

% create the parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY2');
paramTempDoxy2 = get_netcdf_param_attributes('TEMP_DOXY2');

% store drift data
o_driftData = get_apx_profile_data_init_struct;

% add parameter variables to the data structure
o_driftData.dateList = paramJuld;
o_driftData.paramList = [paramPres paramTemp paramSal ...
   paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy ...
   paramPhaseDelayDoxy paramTempDoxy2];

% add parameter data to the data structure
o_driftData.dates = data(:, 1);
o_driftData.data = data(:, 2:9);

o_driftData.data(find(o_driftData.data(:, 4) == 3.409469756*1e38), 4) = paramTPhaseDoxy.fillValue;
o_driftData.data(find(o_driftData.data(:, 5) == 3.409469756*1e38), 5) = paramTempDoxy.fillValue;
o_driftData.data(find(o_driftData.data(:, 6) == 3.409469756*1e38), 6) = paramRPhaseDoxy.fillValue;
o_driftData.data(find(o_driftData.data(:, 7) == 3.409469756*1e38), 7) = paramPhaseDelayDoxy.fillValue;
o_driftData.data(find(o_driftData.data(:, 8) == 3.409469756*1e38), 8) = paramTempDoxy2.fillValue;

% add date status to the data structure
o_driftData.datesStatus = repmat(g_JULD_STATUS_2, size(o_driftData.dates));

return
