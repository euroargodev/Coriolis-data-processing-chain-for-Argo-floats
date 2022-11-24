% ------------------------------------------------------------------------------
% Decode HR profile of APEX Iridium Rudics data.
%
% SYNTAX :
%  [o_profHrData, o_profHrInfo] = ...
%    decode_apx_ir_HR_profile_data(a_profHighResMeasDataStr, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profHighResMeasDataStr : input ASCII HR profile data
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profHrData : HR profile data
%   o_profHrInfo : HR profile misc information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profHrData, o_profHrInfo] = ...
   decode_apx_ir_HR_profile_data(a_profHighResMeasDataStr, a_decoderId)

% output parameters initialization
o_profHrData = [];
o_profHrInfo = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_profHighResMeasDataStr))
   return
end

switch (a_decoderId)
   
   case {1101} % 030410
      
      [o_profHrData, o_profHrInfo] = ...
         decode_apx_ir_HR_profile_data_1(a_profHighResMeasDataStr);
      
   case {1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1314}
      % 120210 & 012811 & 020212 & 030512 & 060612 & 062813_1 & 062813_2 &
      % 062813_3 & 092813 & 073014 & 102815 & 110216 & 090215
      
      [o_profHrData, o_profHrInfo] = ...
         decode_apx_ir_HR_profile_data_2_to_14(a_profHighResMeasDataStr);
            
   case {1201} % 061113
      
      [o_profHrData, o_profHrInfo] = ...
         decode_nvs_ir_rudics_HR_profile_data_1(a_profHighResMeasDataStr);
      
   otherwise
      fprintf('DEC_WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apx_ir_HR_profile_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
      return
end

return

% ------------------------------------------------------------------------------
% Decode HR profile of APEX Iridium Rudics data.
%
% SYNTAX :
%  [o_profHrData, o_profHrInfo] = ...
%    decode_apx_ir_HR_profile_data_1(a_profHighResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profHighResMeasDataStr : input ASCII HR profile data
%
% OUTPUT PARAMETERS :
%   o_profHrData : HR profile data
%   o_profHrInfo : HR profile misc information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profHrData, o_profHrInfo] = ...
   decode_apx_ir_HR_profile_data_1(a_profHighResMeasDataStr)

% output parameters initialization
o_profHrData = [];
o_profHrInfo = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_frequencyDoxyDef;
global g_decArgo_nbSampleDef;
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamNbSampleCtd;


PATTERN1 = 'Sbe41cpSerNo';
PATTERN2_START = '[';
PATTERN2_END = ']';
binNum = 1;
profHrPres = [];
profHrTemp  = [];
profHrSal  = [];
profHrFrequencyDoxy  = [];
profHrNbSample  = [];
for idL = 1:length(a_profHighResMeasDataStr)
   
   dataStr = a_profHighResMeasDataStr{idL};
   if (dataStr(1) == '#')
      if (any(strfind(dataStr, PATTERN1)))
         idF = strfind(dataStr, PATTERN1);
         dateStr = strtrim(dataStr(2:idF-1));
         o_profHrInfo.ProfTime = datenum(dateStr, 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr(idF:end), 'Sbe41cpSerNo[%d] NSample[%d] NBin[%d]');
         if (~isempty(errmsg) || (count ~= 3))
            fprintf('DEC_INFO: Float #%d Cycle #%d: Anomaly detected while parsing HR profile header ''%s'' - ignored\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               dataStr);
            continue
         end
         o_profHrInfo.Sbe41cpSN = val(1);
         o_profHrInfo.ProfNbSample = val(2);
         o_profHrInfo.ProfNbBin = val(3);
      else
         fprintf('DEC_INFO: Float #%d Cycle #%d: Inconsistent HR profile header ''%s'' - ignored\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            dataStr);
         continue
      end
   else
      nbReplic = 1;
      if (any(strfind(dataStr, PATTERN2_START)))
         idF1 = strfind(dataStr, PATTERN2_START);
         idF2 = strfind(dataStr, PATTERN2_END);
         nbReplic = str2num(dataStr(idF1+length(PATTERN2_START):idF2-1));
         dataStr = dataStr(1:idF1-1);
      end
      
      if (length(dataStr) ~= 18)
         fprintf('DEC_INFO: Float #%d Cycle #%d: Anomaly detected while decoding HR profile data - some measurements are missing\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
      end
      
      if (length(dataStr) > 3)
         sensorValue = hex2dec(dataStr(1:4));
         if (sensorValue ~= 0)
            profHrPres(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_pressure(sensorValue, g_decArgo_presDef);
         else
            profHrPres(binNum:binNum+nbReplic-1, 1) = g_decArgo_presDef;
         end
      else
         profHrPres(binNum:binNum+nbReplic-1, 1) = g_decArgo_presDef;
      end
      
      if (length(dataStr) > 7)
         sensorValue = hex2dec(dataStr(5:8));
         if (sensorValue ~= 0)
            profHrTemp(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_temperature(sensorValue, g_decArgo_tempDef);
         else
            profHrTemp(binNum:binNum+nbReplic-1, 1) = g_decArgo_tempDef;
         end
      else
         profHrTemp(binNum:binNum+nbReplic-1, 1) = g_decArgo_tempDef;
      end
      
      if (length(dataStr) > 11)
         sensorValue = hex2dec(dataStr(9:12));
         if (sensorValue ~= 0)
            profHrSal(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_salinity(sensorValue, g_decArgo_salDef);
         else
            profHrSal(binNum:binNum+nbReplic-1, 1) = g_decArgo_salDef;
         end
      else
         profHrSal(binNum:binNum+nbReplic-1, 1) = g_decArgo_salDef;
      end
      
      if (length(dataStr) > 15)
         sensorValue = hex2dec(dataStr(13:16));
         if (sensorValue ~= 0)
            profHrFrequencyDoxy(binNum:binNum+nbReplic-1, 1) = sensorValue;
         else
            profHrFrequencyDoxy(binNum:binNum+nbReplic-1, 1) = g_decArgo_frequencyDoxyDef;
         end
      else
         profHrFrequencyDoxy(binNum:binNum+nbReplic-1, 1) = g_decArgo_frequencyDoxyDef;
      end
      
      if (length(dataStr) == 18)
         profHrNbSample(binNum:binNum+nbReplic-1, 1) = hex2dec(dataStr(17:18));
      else
         profHrNbSample(binNum:binNum+nbReplic-1, 1) = g_decArgo_nbSampleDef;
      end
      
      binNum = binNum + nbReplic;
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramFrequencyDoxy = get_netcdf_param_attributes('FREQUENCY_DOXY');
paramNbSampleCtd = get_netcdf_param_attributes('NB_SAMPLE_CTD');

if (~isempty(profHrPres))
   
   % convert decoder default values to netCDF fill values
   profHrPres(find(profHrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profHrTemp(find(profHrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profHrSal(find(profHrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profHrFrequencyDoxy(find(profHrFrequencyDoxy == g_decArgo_frequencyDoxyDef)) = paramFrequencyDoxy.fillValue;
   profHrNbSample(find(profHrNbSample == g_decArgo_nbSampleDef)) = paramNbSampleCtd.fillValue;
   profHrNbSample(find(profHrNbSample == 0)) = paramNbSampleCtd.fillValue;
   
   % store prof HR data
   o_profHrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profHrData.paramList = [paramPres paramTemp paramSal paramFrequencyDoxy paramNbSampleCtd];
   
   % add parameter data to the data structure
   o_profHrData.data = [profHrPres profHrTemp profHrSal profHrFrequencyDoxy profHrNbSample];
   o_profHrData.data = flipud(o_profHrData.data);
   
   g_decArgo_addParamNbSampleCtd = 1;
end

return

% ------------------------------------------------------------------------------
% Decode HR profile of APEX Iridium Rudics data.
%
% SYNTAX :
%  [o_profHrData, o_profHrInfo] = ...
%    decode_apx_ir_HR_profile_data_2_to_14(a_profHighResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profHighResMeasDataStr : input ASCII HR profile data
%
% OUTPUT PARAMETERS :
%   o_profHrData : HR profile data
%   o_profHrInfo : HR profile misc information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profHrData, o_profHrInfo] = ...
   decode_apx_ir_HR_profile_data_2_to_14(a_profHighResMeasDataStr)

% output parameters initialization
o_profHrData = [];
o_profHrInfo = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_nbSampleDef;
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamNbSampleCtd;


PATTERN1 = 'Sbe41cpSerNo';
PATTERN2_START = '[';
PATTERN2_END = ']';
binNum = 1;
profHrPres = [];
profHrTemp  = [];
profHrSal  = [];
profHrNbSample  = [];
for idL = 1:length(a_profHighResMeasDataStr)
   
   dataStr = a_profHighResMeasDataStr{idL};
   if (dataStr(1) == '#')
      if (any(strfind(dataStr, PATTERN1)))
         idF = strfind(dataStr, PATTERN1);
         dateStr = strtrim(dataStr(2:idF-1));
         o_profHrInfo.ProfTime = datenum(dateStr, 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr(idF:end), 'Sbe41cpSerNo[%d] NSample[%d] NBin[%d]');
         if (~isempty(errmsg) || (count ~= 3))
            fprintf('DEC_INFO: Float #%d Cycle #%d: Anomaly detected while parsing HR profile header ''%s'' - ignored\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               dataStr);
            continue
         end
         o_profHrInfo.Sbe41cpSN = val(1);
         o_profHrInfo.ProfNbSample = val(2);
         o_profHrInfo.ProfNbBin = val(3);
      else
         fprintf('DEC_INFO: Float #%d Cycle #%d: Inconsistent HR profile header ''%s'' - ignored\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            dataStr);
         continue
      end
   else
      nbReplic = 1;
      if (any(strfind(dataStr, PATTERN2_START)))
         idF1 = strfind(dataStr, PATTERN2_START);
         idF2 = strfind(dataStr, PATTERN2_END);
         nbReplic = str2num(dataStr(idF1+length(PATTERN2_START):idF2-1));
         dataStr = dataStr(1:idF1-1);
      end
      
      if (length(dataStr) ~= 14)
         fprintf('DEC_INFO: Float #%d Cycle #%d: Anomaly detected while decoding HR profile data - some measurements are missing\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
      end
      
      if (length(dataStr) > 3)
         sensorValue = hex2dec(dataStr(1:4));
         if (sensorValue ~= 0)
            profHrPres(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_pressure(sensorValue, g_decArgo_presDef);
         else
            profHrPres(binNum:binNum+nbReplic-1, 1) = g_decArgo_presDef;
         end
      else
         profHrPres(binNum:binNum+nbReplic-1, 1) = g_decArgo_presDef;
      end
      
      if (length(dataStr) > 7)
         sensorValue = hex2dec(dataStr(5:8));
         if (sensorValue ~= 0)
            profHrTemp(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_temperature(sensorValue, g_decArgo_tempDef);
         else
            profHrTemp(binNum:binNum+nbReplic-1, 1) = g_decArgo_tempDef;
         end
      else
         profHrTemp(binNum:binNum+nbReplic-1, 1) = g_decArgo_tempDef;
      end
      
      if (length(dataStr) > 11)
         sensorValue = hex2dec(dataStr(9:12));
         if (sensorValue ~= 0)
            profHrSal(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_salinity(sensorValue, g_decArgo_salDef);
         else
            profHrSal(binNum:binNum+nbReplic-1, 1) = g_decArgo_salDef;
         end
      else
         profHrSal(binNum:binNum+nbReplic-1, 1) = g_decArgo_salDef;
      end
      
      if (length(dataStr) == 14)
         profHrNbSample(binNum:binNum+nbReplic-1, 1) = hex2dec(dataStr(13:14));
      else
         profHrNbSample(binNum:binNum+nbReplic-1, 1) = g_decArgo_nbSampleDef;
      end
      
      binNum = binNum + nbReplic;
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramNbSampleCtd = get_netcdf_param_attributes('NB_SAMPLE_CTD');

if (~isempty(profHrPres))
   
   % convert decoder default values to netCDF fill values
   profHrPres(find(profHrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profHrTemp(find(profHrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profHrSal(find(profHrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profHrNbSample(find(profHrNbSample == g_decArgo_nbSampleDef)) = paramNbSampleCtd.fillValue;
   profHrNbSample(find(profHrNbSample == 0)) = paramNbSampleCtd.fillValue;
   
   % store prof HR data
   o_profHrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profHrData.paramList = [paramPres paramTemp paramSal paramNbSampleCtd];
   
   % add parameter data to the data structure
   o_profHrData.data = [profHrPres profHrTemp profHrSal profHrNbSample];
   o_profHrData.data = flipud(o_profHrData.data);
   
   g_decArgo_addParamNbSampleCtd = 1;
end

return

% ------------------------------------------------------------------------------
% Decode HR profile of Navis data.
%
% SYNTAX :
%  [o_profHrData, o_profHrInfo] = ...
%    decode_nvs_ir_rudics_HR_profile_data_1(a_profHighResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profHighResMeasDataStr : input ASCII HR profile data
%
% OUTPUT PARAMETERS :
%   o_profHrData : HR profile data
%   o_profHrInfo : HR profile misc information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profHrData, o_profHrInfo] = ...
   decode_nvs_ir_rudics_HR_profile_data_1(a_profHighResMeasDataStr)

% output parameters initialization
o_profHrData = [];
o_profHrInfo = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_nbSampleDef;
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamNbSampleCtd;


PATTERN1 = 'Sbe41cpSerNo';
PATTERN2_START = '[';
PATTERN2_END = ']';
binNum = 1;
profHrPres = [];
profHrTemp  = [];
profHrSal  = [];
profHrNbSample  = [];
for idL = 1:length(a_profHighResMeasDataStr)
   
   dataStr = a_profHighResMeasDataStr{idL};
   if (dataStr(1) == '#')
      if (any(strfind(dataStr, PATTERN1)))
         idF = strfind(dataStr, PATTERN1);
         dateStr = strtrim(dataStr(2:idF-1));
         o_profHrInfo.ProfTime = datenum(dateStr, 'mmm dd yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr(idF:end), 'Sbe41cpSerNo[%d] NSample[%d] NBin[%d]');
         if (~isempty(errmsg) || (count ~= 3))
            fprintf('DEC_INFO: Float #%d Cycle #%d: Anomaly detected while parsing HR profile header ''%s'' - ignored\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               dataStr);
            continue
         end
         o_profHrInfo.Sbe41cpSN = val(1);
         o_profHrInfo.ProfNbSample = val(2);
         o_profHrInfo.ProfNbBin = val(3);
      else
         fprintf('DEC_INFO: Float #%d Cycle #%d: Inconsistent HR profile header ''%s'' - ignored\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            dataStr);
         continue
      end
   else
      nbReplic = 1;
      if (any(strfind(dataStr, PATTERN2_START)))
         idF1 = strfind(dataStr, PATTERN2_START);
         idF2 = strfind(dataStr, PATTERN2_END);
         nbReplic = str2num(dataStr(idF1+length(PATTERN2_START):idF2-1));
         dataStr = dataStr(1:idF1-1);
      end
      
      if (length(dataStr) ~= 14)
         fprintf('DEC_INFO: Float #%d Cycle #%d: Anomaly detected while decoding HR profile data - some measurements are missing\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
      end
      
      if (length(dataStr) > 3)
         sensorValue = hex2dec(dataStr(1:4));
         if (sensorValue ~= 0)
            profHrPres(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_pressure(sensorValue, g_decArgo_presDef);
         else
            profHrPres(binNum:binNum+nbReplic-1, 1) = g_decArgo_presDef;
         end
      else
         profHrPres(binNum:binNum+nbReplic-1, 1) = g_decArgo_presDef;
      end
      
      if (length(dataStr) > 7)
         sensorValue = hex2dec(dataStr(5:8));
         if (sensorValue ~= 0)
            profHrTemp(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_temperature(sensorValue, g_decArgo_tempDef);
         else
            profHrTemp(binNum:binNum+nbReplic-1, 1) = g_decArgo_tempDef;
         end
      else
         profHrTemp(binNum:binNum+nbReplic-1, 1) = g_decArgo_tempDef;
      end
      
      if (length(dataStr) > 11)
         sensorValue = hex2dec(dataStr(9:12));
         if (sensorValue ~= 0)
            profHrSal(binNum:binNum+nbReplic-1, 1) = sensor_2_value_for_apex_apf9_salinity(sensorValue, g_decArgo_salDef);
         else
            profHrSal(binNum:binNum+nbReplic-1, 1) = g_decArgo_salDef;
         end
      else
         profHrSal(binNum:binNum+nbReplic-1, 1) = g_decArgo_salDef;
      end
      
      if (length(dataStr) == 14)
         profHrNbSample(binNum:binNum+nbReplic-1, 1) = hex2dec(dataStr(13:14));
      else
         profHrNbSample(binNum:binNum+nbReplic-1, 1) = g_decArgo_nbSampleDef;
      end
      
      binNum = binNum + nbReplic;
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramNbSampleCtd = get_netcdf_param_attributes('NB_SAMPLE_CTD');

if (~isempty(profHrPres))
   
   % convert decoder default values to netCDF fill values
   profHrPres(find(profHrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profHrTemp(find(profHrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profHrSal(find(profHrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profHrNbSample(find(profHrNbSample == g_decArgo_nbSampleDef)) = paramNbSampleCtd.fillValue;
   profHrNbSample(find(profHrNbSample == 0)) = paramNbSampleCtd.fillValue;
   
   % store prof HR data
   o_profHrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profHrData.paramList = [paramPres paramTemp paramSal paramNbSampleCtd];
   
   % add parameter data to the data structure
   o_profHrData.data = [profHrPres profHrTemp profHrSal profHrNbSample];
   o_profHrData.data = flipud(o_profHrData.data);
   
   g_decArgo_addParamNbSampleCtd = 1;
end

return
