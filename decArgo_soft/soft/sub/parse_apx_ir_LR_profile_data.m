% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data(a_profLowResMeasDataStr, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data(a_profLowResMeasDataStr, a_decoderId)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_profLowResMeasDataStr))
   return;
end

switch (a_decoderId)
   
   case {1101} % 030410
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_apx_ir_LR_profile_data_1(a_profLowResMeasDataStr);
      
   case {1102, 1103, 1106, 1108, 1109, 1314} % 120210 & 012811 & 060612 & 062813_2 & 062813_3 & 090215
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_apx_ir_LR_profile_data_2_3_6_8_9_14(a_profLowResMeasDataStr);
            
   case {1104} % 020212
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_apx_ir_LR_profile_data_4(a_profLowResMeasDataStr);
      
   case {1105} % 030512
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_apx_ir_LR_profile_data_5(a_profLowResMeasDataStr);
      
   case {1107, 1113} % 062813_1 & 110216
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_apx_ir_LR_profile_data_7_13(a_profLowResMeasDataStr);
      
   case {1110, 1111, 1112} % 092813 & 073014 & 102815
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_apx_ir_LR_profile_data_10_to_12(a_profLowResMeasDataStr);
                  
   case {1201} % 061113
      
      [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
         parse_nvs_ir_rudics_LR_profile_data_1(a_profLowResMeasDataStr);
      
   otherwise
      fprintf('DEC_WARNING: Float #%d Cycle #%d: Nothing done yet in parse_apx_ir_LR_profile_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
      return;
end

return;

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data_1(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data_1(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_frequencyDoxyDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkPres = [];
parkTemp = [];
parkSal = [];
parkFrequencyDoxy = [];
parkFluorescenceChla = [];
parkBetaBackscqttering700 = [];
parkTempCpuChla = [];
profLrPres = [];
profLrTemp  = [];
profLrSal  = [];
profLrFrequencyDoxy  = [];
profLrFluorescenceChla  = [];
profLrBetaBackscqttering700  = [];
profLrTempCpuChla  = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataPres = str2double(data{1});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataTemp = str2double(data{2});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataSal = str2double(data{3});
      else
         dataSal = g_decArgo_salDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataFrequencyDoxy = str2double(data{4});
         if (dataFrequencyDoxy == 0)
            dataFrequencyDoxy = g_decArgo_frequencyDoxyDef;
         end
      else
         dataFrequencyDoxy = g_decArgo_frequencyDoxyDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataFluorescenceChla = str2double(data{5});
      else
         dataFluorescenceChla = g_decArgo_fluorescenceChlaDef;
      end
      if ((length(data) > 5) && ~strcmp(data{6}, 'nan'))
         dataBetaBackscqttering700 = str2double(data{6});
      else
         dataBetaBackscqttering700 = g_decArgo_betaBackscattering700Def;
      end
      if ((length(data) > 6) && ~strcmp(data{7}, 'nan'))
         dataTempCpuChla = str2double(data{7});
      else
         dataTempCpuChla = g_decArgo_tempCpuChlaDef;
      end
      
      if (any(strfind(dataStr, PATTERN)))
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
         parkFrequencyDoxy = [parkFrequencyDoxy; dataFrequencyDoxy];
         parkFluorescenceChla = [parkFluorescenceChla; dataFluorescenceChla];
         parkBetaBackscqttering700 = [parkBetaBackscqttering700; dataBetaBackscqttering700];
         parkTempCpuChla = [parkTempCpuChla; dataTempCpuChla];
      else
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
         profLrFrequencyDoxy = [profLrFrequencyDoxy; dataFrequencyDoxy];
         profLrFluorescenceChla = [profLrFluorescenceChla; dataFluorescenceChla];
         profLrBetaBackscqttering700 = [profLrBetaBackscqttering700; dataBetaBackscqttering700];
         profLrTempCpuChla = [profLrTempCpuChla; dataTempCpuChla];
      end
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramFrequencyDoxy = get_netcdf_param_attributes('FREQUENCY_DOXY');
paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   parkFrequencyDoxy(find(parkFrequencyDoxy == g_decArgo_frequencyDoxyDef)) = paramFrequencyDoxy.fillValue;
   parkFluorescenceChla(find(parkFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
   parkBetaBackscqttering700(find(parkBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
   parkTempCpuChla(find(parkTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
   
   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.paramList = [paramPres paramTemp paramSal paramFrequencyDoxy ...
      paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
   
   % add parameter data to the data structure
   o_parkData.data = [parkPres parkTemp parkSal parkFrequencyDoxy ...
      parkFluorescenceChla parkBetaBackscqttering700 parkTempCpuChla];
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profLrFrequencyDoxy(find(profLrFrequencyDoxy == g_decArgo_frequencyDoxyDef)) = paramFrequencyDoxy.fillValue;
   profLrFluorescenceChla(find(profLrFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
   profLrBetaBackscqttering700(find(profLrBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
   profLrTempCpuChla(find(profLrTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.paramList = [paramPres paramTemp paramSal paramFrequencyDoxy ...
      paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
   
   % add parameter data to the data structure
   o_profLrData.data = [profLrPres profLrTemp profLrSal profLrFrequencyDoxy ...
      profLrFluorescenceChla profLrBetaBackscqttering700 profLrTempCpuChla];
end

return;

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data_2_3_6_8_9_14(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data_2_3_6_8_9_14(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkPres = [];
parkTemp = [];
parkSal = [];
profLrPres = [];
profLrTemp  = [];
profLrSal  = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataPres = str2double(data{1});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataTemp = str2double(data{2});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataSal = str2double(data{3});
      else
         dataSal = g_decArgo_salDef;
      end
      
      if (any(strfind(dataStr, PATTERN)))
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
      else
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
      end
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   
   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.paramList = [paramPres paramTemp paramSal];
   
   % add parameter data to the data structure
   o_parkData.data = [parkPres parkTemp parkSal];
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.paramList = [paramPres paramTemp paramSal];
   
   % add parameter data to the data structure
   o_profLrData.data = [profLrPres profLrTemp profLrSal];
end

return;

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data_4(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data_4(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_tempDoxyDef;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkPres = [];
parkTemp = [];
parkSal = [];
parkTPhaseDoxy = [];
parkTempDoxy = [];
profLrPres = [];
profLrTemp = [];
profLrSal = [];
profLrTPhaseDoxy = [];
profLrTempDoxy = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataPres = str2double(data{1});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataTemp = str2double(data{2});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataSal = str2double(data{3});
      else
         dataSal = g_decArgo_salDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataTPhaseDoxy = str2double(data{4});
      else
         dataTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataTempDoxy = str2double(data{5});
      else
         dataTempDoxy = g_decArgo_tempDoxyDef;
      end
      
      if (any(strfind(dataStr, PATTERN)))
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
         parkTPhaseDoxy = [parkTPhaseDoxy; dataTPhaseDoxy];
         parkTempDoxy = [parkTempDoxy; dataTempDoxy];
      else
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
         profLrTPhaseDoxy = [profLrTPhaseDoxy; dataTPhaseDoxy];
         profLrTempDoxy = [profLrTempDoxy; dataTempDoxy];
      end
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   parkTPhaseDoxy(find(parkTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   parkTempDoxy(find(parkTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   
   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.paramList = [paramPres paramTemp paramSal paramTPhaseDoxy paramTempDoxy];
   
   % add parameter data to the data structure
   o_parkData.data = [parkPres parkTemp parkSal parkTPhaseDoxy parkTempDoxy];
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profLrTPhaseDoxy(find(profLrTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   profLrTempDoxy(find(profLrTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.paramList = [paramPres paramTemp paramSal paramTPhaseDoxy paramTempDoxy];
   
   % add parameter data to the data structure
   o_profLrData.data = [profLrPres profLrTemp profLrSal profLrTPhaseDoxy profLrTempDoxy];
end

return;

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data_5(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data_5(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkPres = [];
parkTemp = [];
parkSal = [];
parkTPhaseDoxy = [];
parkTempDoxy = [];
parkFluorescenceChla = [];
parkBetaBackscqttering700 = [];
parkTempCpuChla = [];
profLrPres = [];
profLrTemp  = [];
profLrSal  = [];
profLrTPhaseDoxy = [];
profLrTempDoxy = [];
profLrFluorescenceChla  = [];
profLrBetaBackscqttering700  = [];
profLrTempCpuChla  = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataPres = str2double(data{1});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataTemp = str2double(data{2});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataSal = str2double(data{3});
      else
         dataSal = g_decArgo_salDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataTPhaseDoxy = str2double(data{4});
      else
         dataTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataTempDoxy = str2double(data{5});
      else
         dataTempDoxy = g_decArgo_tempDoxyDef;
      end
      if ((length(data) > 5) && ~strcmp(data{6}, 'nan'))
         dataFluorescenceChla = str2double(data{6});
      else
         dataFluorescenceChla = g_decArgo_fluorescenceChlaDef;
      end
      if ((length(data) > 6) && ~strcmp(data{7}, 'nan'))
         dataBetaBackscqttering700 = str2double(data{7});
      else
         dataBetaBackscqttering700 = g_decArgo_betaBackscattering700Def;
      end
      if ((length(data) > 7) && ~strcmp(data{8}, 'nan'))
         dataTempCpuChla = str2double(data{8});
      else
         dataTempCpuChla = g_decArgo_tempCpuChlaDef;
      end
      
      if (any(strfind(dataStr, PATTERN)))
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
         parkTPhaseDoxy = [parkTPhaseDoxy; dataTPhaseDoxy];
         parkTempDoxy = [parkTempDoxy; dataTempDoxy];
         parkFluorescenceChla = [parkFluorescenceChla; dataFluorescenceChla];
         parkBetaBackscqttering700 = [parkBetaBackscqttering700; dataBetaBackscqttering700];
         parkTempCpuChla = [parkTempCpuChla; dataTempCpuChla];
      else
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
         profLrTPhaseDoxy = [profLrTPhaseDoxy; dataTPhaseDoxy];
         profLrTempDoxy = [profLrTempDoxy; dataTempDoxy];
         profLrFluorescenceChla = [profLrFluorescenceChla; dataFluorescenceChla];
         profLrBetaBackscqttering700 = [profLrBetaBackscqttering700; dataBetaBackscqttering700];
         profLrTempCpuChla = [profLrTempCpuChla; dataTempCpuChla];
      end
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   parkTPhaseDoxy(find(parkTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   parkTempDoxy(find(parkTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   parkFluorescenceChla(find(parkFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
   parkBetaBackscqttering700(find(parkBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
   parkTempCpuChla(find(parkTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
   
   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.paramList = [paramPres paramTemp paramSal ...
      paramTPhaseDoxy paramTempDoxy ...
      paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
   
   % add parameter data to the data structure
   o_parkData.data = [parkPres parkTemp parkSal ...
      parkTPhaseDoxy parkTempDoxy ...
      parkFluorescenceChla parkBetaBackscqttering700 parkTempCpuChla];
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profLrTPhaseDoxy(find(profLrTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   profLrTempDoxy(find(profLrTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   profLrFluorescenceChla(find(profLrFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
   profLrBetaBackscqttering700(find(profLrBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
   profLrTempCpuChla(find(profLrTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.paramList = [paramPres paramTemp paramSal ...
      paramTPhaseDoxy paramTempDoxy ...
      paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
   
   % add parameter data to the data structure
   o_profLrData.data = [profLrPres profLrTemp profLrSal ...
      profLrTPhaseDoxy profLrTempDoxy ...
      profLrFluorescenceChla profLrBetaBackscqttering700 profLrTempCpuChla];
end

return;

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data_7_13(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data_7_13(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_rPhaseDoxyDef;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkPres = [];
parkTemp = [];
parkSal = [];
parkTempDoxy = [];
parkTPhaseDoxy = [];
parkRPhaseDoxy = [];
profLrPres = [];
profLrTemp = [];
profLrSal = [];
profLrTempDoxy = [];
profLrTPhaseDoxy = [];
profLrRPhaseDoxy = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataPres = str2double(data{1});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataTemp = str2double(data{2});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataSal = str2double(data{3});
      else
         dataSal = g_decArgo_salDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataTempDoxy = str2double(data{4});
      else
         dataTempDoxy = g_decArgo_tempDoxyDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataTPhaseDoxy = str2double(data{5});
      else
         dataTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if ((length(data) > 5) && ~strcmp(data{6}, 'nan'))
         dataRPhaseDoxy = str2double(data{6});
      else
         dataRPhaseDoxy = g_decArgo_rPhaseDoxyDef;
      end
      
      if (any(strfind(dataStr, PATTERN)))
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
         parkTempDoxy = [parkTempDoxy; dataTempDoxy];
         parkTPhaseDoxy = [parkTPhaseDoxy; dataTPhaseDoxy];
         parkRPhaseDoxy = [parkRPhaseDoxy; dataRPhaseDoxy];
      else
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
         profLrTempDoxy = [profLrTempDoxy; dataTempDoxy];
         profLrTPhaseDoxy = [profLrTPhaseDoxy; dataTPhaseDoxy];
         profLrRPhaseDoxy = [profLrRPhaseDoxy; dataRPhaseDoxy];
      end
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   parkTempDoxy(find(parkTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   parkTPhaseDoxy(find(parkTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   parkRPhaseDoxy(find(parkRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
   
   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.paramList = [paramPres paramTemp paramSal paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy];
   
   % add parameter data to the data structure
   o_parkData.data = [parkPres parkTemp parkSal parkTempDoxy parkTPhaseDoxy parkRPhaseDoxy];
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profLrTempDoxy(find(profLrTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   profLrTPhaseDoxy(find(profLrTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   profLrRPhaseDoxy(find(profLrRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.paramList = [paramPres paramTemp paramSal paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy];
   
   % add parameter data to the data structure
   o_profLrData.data = [profLrPres profLrTemp profLrSal profLrTempDoxy profLrTPhaseDoxy profLrRPhaseDoxy];
end

return;

% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_apx_ir_LR_profile_data_10_to_12(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_apx_ir_LR_profile_data_10_to_12(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_rPhaseDoxyDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkPres = [];
parkTemp = [];
parkSal = [];
parkTempDoxy = [];
parkTPhaseDoxy = [];
parkRPhaseDoxy = [];
parkFluorescenceChla = [];
parkBetaBackscqttering700 = [];
parkTempCpuChla = [];
profLrPres = [];
profLrTemp  = [];
profLrSal  = [];
profLrTempDoxy = [];
profLrTPhaseDoxy = [];
profLrRPhaseDoxy = [];
profLrFluorescenceChla  = [];
profLrBetaBackscqttering700  = [];
profLrTempCpuChla  = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataPres = str2double(data{1});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataTemp = str2double(data{2});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataSal = str2double(data{3});
      else
         dataSal = g_decArgo_salDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataTempDoxy = str2double(data{4});
      else
         dataTempDoxy = g_decArgo_tempDoxyDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataTPhaseDoxy = str2double(data{5});
      else
         dataTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if ((length(data) > 5) && ~strcmp(data{6}, 'nan'))
         dataRPhaseDoxy = str2double(data{6});
      else
         dataRPhaseDoxy = g_decArgo_rPhaseDoxyDef;
      end
      if ((length(data) > 6) && ~strcmp(data{7}, 'nan'))
         dataFluorescenceChla = str2double(data{7});
      else
         dataFluorescenceChla = g_decArgo_fluorescenceChlaDef;
      end
      if ((length(data) > 7) && ~strcmp(data{8}, 'nan'))
         dataBetaBackscqttering700 = str2double(data{8});
      else
         dataBetaBackscqttering700 = g_decArgo_betaBackscattering700Def;
      end
      if ((length(data) > 8) && ~strcmp(data{9}, 'nan'))
         dataTempCpuChla = str2double(data{9});
      else
         dataTempCpuChla = g_decArgo_tempCpuChlaDef;
      end
      
      if (any(strfind(dataStr, PATTERN)))
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
         parkTempDoxy = [parkTempDoxy; dataTempDoxy];
         parkTPhaseDoxy = [parkTPhaseDoxy; dataTPhaseDoxy];
         parkRPhaseDoxy = [parkRPhaseDoxy; dataRPhaseDoxy];
         parkFluorescenceChla = [parkFluorescenceChla; dataFluorescenceChla];
         parkBetaBackscqttering700 = [parkBetaBackscqttering700; dataBetaBackscqttering700];
         parkTempCpuChla = [parkTempCpuChla; dataTempCpuChla];
      else
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
         profLrTempDoxy = [profLrTempDoxy; dataTempDoxy];
         profLrTPhaseDoxy = [profLrTPhaseDoxy; dataTPhaseDoxy];
         profLrRPhaseDoxy = [profLrRPhaseDoxy; dataRPhaseDoxy];
         profLrFluorescenceChla = [profLrFluorescenceChla; dataFluorescenceChla];
         profLrBetaBackscqttering700 = [profLrBetaBackscqttering700; dataBetaBackscqttering700];
         profLrTempCpuChla = [profLrTempCpuChla; dataTempCpuChla];
      end
   end
end

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   parkTempDoxy(find(parkTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   parkTPhaseDoxy(find(parkTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   parkRPhaseDoxy(find(parkRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
   parkFluorescenceChla(find(parkFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
   parkBetaBackscqttering700(find(parkBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
   parkTempCpuChla(find(parkTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
   
   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.paramList = [paramPres paramTemp paramSal ...
      paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy ...
      paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
   
   % add parameter data to the data structure
   o_parkData.data = [parkPres parkTemp parkSal ...
      parkTempDoxy parkTPhaseDoxy parkRPhaseDoxy ...
      parkFluorescenceChla parkBetaBackscqttering700 parkTempCpuChla];
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profLrTempDoxy(find(profLrTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   profLrTPhaseDoxy(find(profLrTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   profLrRPhaseDoxy(find(profLrRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
   profLrFluorescenceChla(find(profLrFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
   profLrBetaBackscqttering700(find(profLrBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
   profLrTempCpuChla(find(profLrTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.paramList = [paramPres paramTemp paramSal ...
      paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy ...
      paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
   
   % add parameter data to the data structure
   o_profLrData.data = [profLrPres profLrTemp profLrSal ...
      profLrTempDoxy profLrTPhaseDoxy profLrRPhaseDoxy ...
      profLrFluorescenceChla profLrBetaBackscqttering700 profLrTempCpuChla];
end

return;

% ------------------------------------------------------------------------------
% Parse Navis LR profile data.
%
% SYNTAX :
%  [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
%    parse_nvs_ir_rudics_LR_profile_data_1(a_profLowResMeasDataStr)
%
% INPUT PARAMETERS :
%   a_profLowResMeasDataStr : input ASCII LR profile data
%
% OUTPUT PARAMETERS :
%   o_parkData                : park measurement data
%   o_profLrData              : LR profile data
%   o_expectedProfLrNbSamples : number of expected levels of LR profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData, o_profLrData, o_expectedProfLrNbSamples] = ...
   parse_nvs_ir_rudics_LR_profile_data_1(a_profLowResMeasDataStr)

% output parameters initialization
o_parkData = [];
o_profLrData = [];
o_expectedProfLrNbSamples = [];

% default values
global g_decArgo_epochDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_rPhaseDoxyDef;
global g_decArgo_phaseDelayDoxyDef;

% global time status
global g_JULD_STATUS_2;


HEADER = '$ Discrete samples:';
PATTERN = '(Park Sample)';

parkEpoch = [];
parkPres = [];
parkTemp = [];
parkSal = [];
parkTPhaseDoxy = [];
parkTempDoxy = [];
parkRPhaseDoxy = [];
parkPhaseDelayDoxy = [];
parkTempDoxy2 = [];
profLrEpoch = [];
profLrPres = [];
profLrTemp  = [];
profLrSal  = [];
profLrTPhaseDoxy = [];
profLrTempDoxy = [];
profLrRPhaseDoxy = [];
profLrPhaseDelayDoxy = [];
profLrTempDoxy2 = [];
for idL = 1:length(a_profLowResMeasDataStr)
   
   dataStr = a_profLowResMeasDataStr{idL};
   if (dataStr(1) == '$')
      if (any(strfind(dataStr, HEADER)))
         idF = strfind(dataStr, HEADER);
         profLrNbSamplesStr = strtrim(dataStr(idF+length(HEADER):end));
         [profLrNbSamples, status] = str2num(profLrNbSamplesStr);
         if (status)
            o_expectedProfLrNbSamples = profLrNbSamples;
         end
      end
   else
      if (any(strfind(dataStr, PATTERN)))
         idF = strfind(dataStr, PATTERN);
         dataStr2 = dataStr(1:idF-1);
      else
         dataStr2 = dataStr;
      end
      
      % extract data
      data = strsplit(dataStr2, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataEpoch = str2double(data{1});
      else
         dataEpoch = g_decArgo_epochDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataPres = str2double(data{2});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataTemp = str2double(data{3});
      else
         dataTemp = g_decArgo_tempDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataSal = str2double(data{4});
      else
         dataSal = g_decArgo_salDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataTPhaseDoxy = str2double(data{5});
      else
         dataTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if ((length(data) > 5) && ~strcmp(data{6}, 'nan'))
         dataTempDoxy = str2double(data{6});
      else
         dataTempDoxy = g_decArgo_tempDoxyDef;
      end
      if ((length(data) > 6) && ~strcmp(data{7}, 'nan'))
         dataRPhaseDoxy = str2double(data{7});
      else
         dataRPhaseDoxy = g_decArgo_rPhaseDoxyDef;
      end
      if ((length(data) > 7) && ~strcmp(data{8}, 'nan'))
         dataPhaseDelayDoxy = str2double(data{8});
      else
         dataPhaseDelayDoxy = g_decArgo_phaseDelayDoxyDef;
      end
      if ((length(data) > 8) && ~strcmp(data{9}, 'nan'))
         dataTempDoxy2 = str2double(data{9});
      else
         dataTempDoxy2 = g_decArgo_tempDoxyDef;
      end

      if (any(strfind(dataStr, PATTERN)))
         parkEpoch = [parkEpoch; dataEpoch];
         parkPres = [parkPres; dataPres];
         parkTemp = [parkTemp; dataTemp];
         parkSal = [parkSal; dataSal];
         parkTPhaseDoxy = [parkTPhaseDoxy; dataTPhaseDoxy];
         parkTempDoxy = [parkTempDoxy; dataTempDoxy];
         parkRPhaseDoxy = [parkRPhaseDoxy; dataRPhaseDoxy];
         parkPhaseDelayDoxy = [parkPhaseDelayDoxy; dataPhaseDelayDoxy];
         parkTempDoxy2 = [parkTempDoxy2; dataTempDoxy2];
      else
         profLrEpoch = [profLrEpoch; dataEpoch];
         profLrPres = [profLrPres; dataPres];
         profLrTemp = [profLrTemp; dataTemp];
         profLrSal = [profLrSal; dataSal];
         profLrTPhaseDoxy = [profLrTPhaseDoxy; dataTPhaseDoxy];
         profLrTempDoxy = [profLrTempDoxy; dataTempDoxy];
         profLrRPhaseDoxy = [profLrRPhaseDoxy; dataRPhaseDoxy];
         profLrPhaseDelayDoxy = [profLrPhaseDelayDoxy; dataPhaseDelayDoxy];
         profLrTempDoxy2 = [profLrTempDoxy2; dataTempDoxy2];
      end
   end
end

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

if (~isempty(parkPres))
   
   % convert decoder default values to netCDF fill values
   parkPres(find(parkPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
   parkTPhaseDoxy(find(parkTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   parkTempDoxy(find(parkTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   parkRPhaseDoxy(find(parkRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
   parkPhaseDelayDoxy(find(parkPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
   parkTempDoxy2(find(parkTempDoxy2 == g_decArgo_tempDoxyDef)) = paramTempDoxy2.fillValue;
   
   % compute JULD from EPOCH
   parkJuld = ones(size(parkEpoch))*paramJuld.fillValue;
   idNoDef = find(parkEpoch ~= g_decArgo_epochDef);
   parkJuld(idNoDef) = epoch_2_julian_dec_argo(parkEpoch(idNoDef));

   % store park data
   o_parkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_parkData.dateList = paramJuld;
   o_parkData.paramList = [paramPres paramTemp paramSal ...
      paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy ...
      paramPhaseDelayDoxy paramTempDoxy2];
   
   % add parameter data to the data structure
   o_parkData.dates = parkJuld;
   o_parkData.data = [parkPres parkTemp parkSal ...
      parkTPhaseDoxy parkTempDoxy parkRPhaseDoxy ...
      parkPhaseDelayDoxy parkTempDoxy2];
   
   % add date status to the data structure
   o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
   
   if (~isempty(o_expectedProfLrNbSamples))
      o_expectedProfLrNbSamples = o_expectedProfLrNbSamples - 1;
   end
end

if (~isempty(profLrPres))
   
   % convert decoder default values to netCDF fill values
   profLrPres(find(profLrPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
   profLrTemp(find(profLrTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profLrSal(find(profLrSal == g_decArgo_salDef)) = paramSal.fillValue;
   profLrTPhaseDoxy(find(profLrTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
   profLrTempDoxy(find(profLrTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
   profLrRPhaseDoxy(find(profLrRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
   profLrPhaseDelayDoxy(find(profLrPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
   profLrTempDoxy2(find(profLrTempDoxy2 == g_decArgo_tempDoxyDef)) = paramTempDoxy2.fillValue;
   
   % compute JULD from EPOCH
   profLrJuld = ones(size(profLrEpoch))*paramJuld.fillValue;
   idNoDef = find(profLrEpoch ~= g_decArgo_epochDef);
   profLrJuld(idNoDef) = epoch_2_julian_dec_argo(profLrEpoch(idNoDef));
   
   % store prof LR data
   o_profLrData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_profLrData.dateList = paramJuld;
   o_profLrData.paramList = [paramPres paramTemp paramSal ...
      paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy ...
      paramPhaseDelayDoxy paramTempDoxy2];
   
   % add parameter data to the data structure
   o_profLrData.dates = profLrJuld;
   o_profLrData.data = [profLrPres profLrTemp profLrSal ...
      profLrTPhaseDoxy profLrTempDoxy profLrRPhaseDoxy ...
      profLrPhaseDelayDoxy profLrTempDoxy2];
   
   % add date status to the data structure
   o_profLrData.datesStatus = repmat(g_JULD_STATUS_2, size(o_profLrData.dates));
end

return;
