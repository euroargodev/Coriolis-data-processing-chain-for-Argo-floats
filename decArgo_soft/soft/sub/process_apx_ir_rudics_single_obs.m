% ------------------------------------------------------------------------------
% Process Apex Iridium Rudics measurement data from engineering data.
%
% SYNTAX :
%  [o_singleData] = process_apx_ir_rudics_single_obs(a_engData, a_decoderId, a_surfDataFlag)
%
% INPUT PARAMETERS :
%   a_engData      : measurement data (from engineering data)
%   a_decoderId    : float decoder Id
%   a_surfDataFlag : surface measurement flag
%
% OUTPUT PARAMETERS :
%   o_singleData : measurement data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_singleData] = process_apx_ir_rudics_single_obs(a_engData, a_decoderId, a_surfDataFlag)

% output parameters initialization
o_singleData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_frequencyDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_rPhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;


if (isempty(a_engData))
   return
end

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1101} % 030410
      
      if (length(a_engData) ~= 7)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      % extract data
      if (~strcmp(a_engData{1}, 'nan'))
         measPres = a_engData{1};
         measPres = str2double(measPres(1:end-4));
      else
         measPres = g_decArgo_presDef;
      end
      if (~strcmp(a_engData{2}, 'nan'))
         measTemp = a_engData{2};
         measTemp = str2double(measTemp(1:end-1));
      else
         measTemp = g_decArgo_tempDef;
      end
      if (~strcmp(a_engData{3}, 'nan'))
         measSal = a_engData{3};
         measSal = str2double(measSal(1:end-3));
      else
         measSal = g_decArgo_salDef;
      end
      if (~strcmp(a_engData{4}, 'nan'))
         measFrequencyDoxy = str2double(a_engData{4});
      else
         measFrequencyDoxy = g_decArgo_frequencyDoxyDef;
      end
      if (~strcmp(a_engData{5}, 'nan'))
         measFluorescenceChla = str2double(a_engData{5});
      else
         measFluorescenceChla = g_decArgo_fluorescenceChlaDef;
      end
      if (~strcmp(a_engData{6}, 'nan'))
         measBetaBackscqttering700 = str2double(a_engData{6});
      else
         measBetaBackscqttering700 = g_decArgo_betaBackscattering700Def;
      end
      if (~strcmp(a_engData{7}, 'nan'))
         measTempCpuChla = str2double(a_engData{7});
      else
         measTempCpuChla = g_decArgo_tempCpuChlaDef;
      end
      
      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramFrequencyDoxy = get_netcdf_param_attributes('FREQUENCY_DOXY');
      paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
      paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
      paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
      
      % convert decoder default values to netCDF fill values
      measPres(find(measPres == g_decArgo_presDef)) = paramPres.fillValue;
      measTemp(find(measTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      measSal(find(measSal == g_decArgo_salDef)) = paramSal.fillValue;
      measFrequencyDoxy(find(measFrequencyDoxy == g_decArgo_frequencyDoxyDef)) = paramFrequencyDoxy.fillValue;
      measFluorescenceChla(find(measFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
      measBetaBackscqttering700(find(measBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
      measTempCpuChla(find(measTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
      
      % store single data
      o_singleData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_singleData.paramList = [paramPres paramTemp paramSal paramFrequencyDoxy ...
         paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
      
      % add parameter data to the data structure
      o_singleData.data = [measPres measTemp measSal measFrequencyDoxy ...
         measFluorescenceChla measBetaBackscqttering700 measTempCpuChla];
      
      if (a_surfDataFlag)
         o_singleData.paramList(2:4) = [];
         o_singleData.data(2:4) = [];
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1102, 1103, 1104, 1106, 1107, 1108, 1109, 1113, 1314}
      % 120210 & 012811 & 020212 & 060612 & 062813_1 & 062813_2 & 062813_3 &
      % 110216 & 090215

      if (length(a_engData) ~= 3)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      % extract data
      if (~strcmp(a_engData{1}, 'nan'))
         measPres = a_engData{1};
         measPres = str2double(measPres(1:end-4));
      else
         measPres = g_decArgo_presDef;
      end
      if (~strcmp(a_engData{2}, 'nan'))
         measTemp = a_engData{2};
         measTemp = str2double(measTemp(1:end-1));
      else
         measTemp = g_decArgo_tempDef;
      end
      if (~strcmp(a_engData{3}, 'nan'))
         measSal = a_engData{3};
         measSal = str2double(measSal(1:end-3));
      else
         measSal = g_decArgo_salDef;
      end
      
      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      
      % convert decoder default values to netCDF fill values
      measPres(find(measPres == g_decArgo_presDef)) = paramPres.fillValue;
      measTemp(find(measTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      measSal(find(measSal == g_decArgo_salDef)) = paramSal.fillValue;
      
      % store single data
      o_singleData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_singleData.paramList = [paramPres paramTemp paramSal];
      
      % add parameter data to the data structure
      o_singleData.data = [measPres measTemp measSal];

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1105} % 030512
      
      if (length(a_engData) ~= 5)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      if (any(strfind(a_engData{3}, '/')))
         newData = strtrim(strsplit(a_engData{3}, ' '));
         if ((newData{2} == '/') && (newData{5} == '/'))
            tmpData(1) = a_engData(1);
            tmpData(2) = a_engData(2);
            tmpData(3) = newData(1);
            tmpData(4) = newData(3);
            tmpData(5) = newData(4);
            tmpData(6) = newData(6);
            tmpData(7) = a_engData(4);
            tmpData(8) = a_engData(5);
            a_engData = tmpData;
         end
      end
      
      if (length(a_engData) ~= 8)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      % extract data
      if (~strcmp(a_engData{1}, 'nan'))
         measPres = a_engData{1};
         measPres = str2double(measPres(1:end-4));
      else
         measPres = g_decArgo_presDef;
      end
      if (~strcmp(a_engData{2}, 'nan'))
         measTemp = a_engData{2};
         measTemp = str2double(measTemp(1:end-1));
      else
         measTemp = g_decArgo_tempDef;
      end
      if (~strcmp(a_engData{3}, 'nan'))
         measSal = a_engData{3};
         measSal = str2double(measSal(1:end-3));
      else
         measSal = g_decArgo_salDef;
      end
      if (~strcmp(a_engData{4}, 'nan'))
         measTPhaseDoxy = str2double(a_engData{4});
      else
         measTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if (~strcmp(a_engData{5}, 'nan'))
         measTempDoxy = a_engData{5};
         measTempDoxy = str2double(measTempDoxy(1:end-1));
      else
         measTempDoxy = g_decArgo_tempDoxyDef;
      end
      if (~strcmp(a_engData{6}, 'nan'))
         measFluorescenceChla = str2double(a_engData{6});
      else
         measFluorescenceChla = g_decArgo_fluorescenceChlaDef;
      end
      if (~strcmp(a_engData{7}, 'nan'))
         measBetaBackscqttering700 = str2double(a_engData{7});
      else
         measBetaBackscqttering700 = g_decArgo_betaBackscattering700Def;
      end
      if (~strcmp(a_engData{8}, 'nan'))
         measTempCpuChla = str2double(a_engData{8});
      else
         measTempCpuChla = g_decArgo_tempCpuChlaDef;
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
      
      % convert decoder default values to netCDF fill values
      measPres(find(measPres == g_decArgo_presDef)) = paramPres.fillValue;
      measTemp(find(measTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      measSal(find(measSal == g_decArgo_salDef)) = paramSal.fillValue;
      measTPhaseDoxy(find(measTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
      measTempDoxy(find(measTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
      measFluorescenceChla(find(measFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
      measBetaBackscqttering700(find(measBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
      measTempCpuChla(find(measTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
      
      % store single data
      o_singleData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_singleData.paramList = [paramPres paramTemp paramSal ...
         paramTPhaseDoxy paramTempDoxy ...
         paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
      
      % add parameter data to the data structure
      o_singleData.data = [measPres measTemp measSal ...
         measTPhaseDoxy measTempDoxy ...
         measFluorescenceChla measBetaBackscqttering700 measTempCpuChla];
      
      if (a_surfDataFlag)
         o_singleData.paramList(2:3) = [];
         o_singleData.data(2:3) = [];
         if (~any(o_singleData.data ~= 0))
            o_singleData = [];
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1110, 1111, 1112} % 092813 & 073014 & 102815

      if (length(a_engData) ~= 5)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      if (any(strfind(a_engData{3}, '/')))
         newData = strtrim(strsplit(a_engData{3}, ' '));
         if ((newData{2} == '/') && (newData{6} == '/'))
            tmpData(1) = a_engData(1);
            tmpData(2) = a_engData(2);
            tmpData(3) = newData(1);
            tmpData(4) = newData(3);
            tmpData(5) = newData(4);
            tmpData(6) = newData(5);
            tmpData(7) = newData(7);
            tmpData(8) = a_engData(4);
            tmpData(9) = a_engData(5);
            a_engData = tmpData;
         end
      end
      
      if (length(a_engData) ~= 9)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      % extract data
      if (~strcmp(a_engData{1}, 'nan'))
         measPres = a_engData{1};
         measPres = str2double(measPres(1:end-4));
      else
         measPres = g_decArgo_presDef;
      end
      if (~strcmp(a_engData{2}, 'nan'))
         measTemp = a_engData{2};
         measTemp = str2double(measTemp(1:end-1));
      else
         measTemp = g_decArgo_tempDef;
      end
      if (~strcmp(a_engData{3}, 'nan'))
         measSal = a_engData{3};
         measSal = str2double(measSal(1:end-3));
      else
         measSal = g_decArgo_salDef;
      end
      if (~strcmp(a_engData{4}, 'nan'))
         measTempDoxy = str2double(a_engData{4});
      else
         measTempDoxy = g_decArgo_tempDoxyDef;
      end
      if (~strcmp(a_engData{5}, 'nan'))
         measTPhaseDoxy = a_engData{5};
         measTPhaseDoxy = str2double(measTPhaseDoxy(1:end-1));
      else
         measTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if (~strcmp(a_engData{6}, 'nan'))
         measRPhaseDoxy = str2double(a_engData{6});
      else
         measRPhaseDoxy = g_decArgo_rPhaseDoxyDef;
      end
      if (~strcmp(a_engData{7}, 'nan'))
         measFluorescenceChla = str2double(a_engData{7});
      else
         measFluorescenceChla = g_decArgo_fluorescenceChlaDef;
      end
      if (~strcmp(a_engData{8}, 'nan'))
         measBetaBackscqttering700 = str2double(a_engData{8});
      else
         measBetaBackscqttering700 = g_decArgo_betaBackscattering700Def;
      end
      if (~strcmp(a_engData{9}, 'nan'))
         measTempCpuChla = str2double(a_engData{9});
      else
         measTempCpuChla = g_decArgo_tempCpuChlaDef;
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
      
      % convert decoder default values to netCDF fill values
      measPres(find(measPres == g_decArgo_presDef)) = paramPres.fillValue;
      measTemp(find(measTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      measSal(find(measSal == g_decArgo_salDef)) = paramSal.fillValue;
      measTempDoxy(find(measTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
      measTPhaseDoxy(find(measTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
      measRPhaseDoxy(find(measRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
      measFluorescenceChla(find(measFluorescenceChla == g_decArgo_fluorescenceChlaDef)) = paramFluorescenceChla.fillValue;
      measBetaBackscqttering700(find(measBetaBackscqttering700 == g_decArgo_betaBackscattering700Def)) = paramBetaBackscattering700.fillValue;
      measTempCpuChla(find(measTempCpuChla == g_decArgo_tempCpuChlaDef)) = paramTempCpuChla.fillValue;
      
      % store single data
      o_singleData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_singleData.paramList = [paramPres paramTemp paramSal ...
         paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy ...
         paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
      
      % add parameter data to the data structure
      o_singleData.data = [measPres measTemp measSal ...
         measTempDoxy measTPhaseDoxy measRPhaseDoxy ...
         measFluorescenceChla measBetaBackscqttering700 measTempCpuChla];
      
      if (a_surfDataFlag)
         o_singleData.paramList(2:3) = [];
         o_singleData.data(2:3) = [];
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1201} % 061113
      
      if (length(a_engData) ~= 6)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      if (any(strfind(a_engData{3}, '/')) && any(strfind(a_engData{4}, '/')))
         newData1 = strtrim(strsplit(a_engData{3}, ' '));
         if (newData1{2} == '/')
            newData2 = strtrim(strsplit(a_engData{4}, ' '));
            if (newData2{2} == '/')
               tmpData(1) = a_engData(1);
               tmpData(2) = a_engData(2);
               tmpData(3) = newData1(1);
               tmpData(4) = newData1(3);
               tmpData(5) = newData2(1);
               tmpData(6) = newData2(3);
               tmpData(7) = a_engData(5);
               tmpData(8) = a_engData(6);
               a_engData = tmpData;
            end
         end
      end
      
      if (length(a_engData) ~= 8)
         fprintf('WARNING: Float #%d Cycle #%d: Not consistent single data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         return
      end
      
      % extract data
      if (~strcmp(a_engData{1}, 'nan'))
         measPres = a_engData{1};
         measPres = str2double(measPres(1:end-4));
      else
         measPres = g_decArgo_presDef;
      end
      if (~strcmp(a_engData{2}, 'nan'))
         measTemp = a_engData{2};
         measTemp = str2double(measTemp(1:end-1));
      else
         measTemp = g_decArgo_tempDef;
      end
      if (~strcmp(a_engData{3}, 'nan'))
         measSal = a_engData{3};
         measSal = str2double(measSal(1:end-3));
      else
         measSal = g_decArgo_salDef;
      end
      if (~strcmp(a_engData{4}, 'nan'))
         measPhaseDelayDoxy = a_engData{4};
         measPhaseDelayDoxy = str2double(measPhaseDelayDoxy(1:end-2));
      else
         measPhaseDelayDoxy = g_decArgo_phaseDelayDoxyDef;
      end
      if (~strcmp(a_engData{5}, 'nan'))
         measTempDoxy2 = a_engData{5};
         measTempDoxy2 = str2double(measTempDoxy2(1:end-1));
      else
         measTempDoxy2 = g_decArgo_tempDoxyDef;
      end
      if (~strcmp(a_engData{6}, 'nan'))
         measTPhaseDoxy = str2double(a_engData{6});
      else
         measTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if (~strcmp(a_engData{7}, 'nan'))
         measRPhaseDoxy = str2double(a_engData{7});
      else
         measRPhaseDoxy = g_decArgo_rPhaseDoxyDef;
      end
      if (~strcmp(a_engData{8}, 'nan'))
         measTempDoxy = a_engData{8};
         measTempDoxy = str2double(measTempDoxy(1:end-1));
      else
         measTempDoxy = g_decArgo_tempDoxyDef;
      end
      
      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
      paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY2');
      paramTempDoxy2 = get_netcdf_param_attributes('TEMP_DOXY2');
      
      % convert decoder default values to netCDF fill values
      measPres(find(measPres == g_decArgo_presDef)) = paramPres.fillValue;
      measTemp(find(measTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      measSal(find(measSal == g_decArgo_salDef)) = paramSal.fillValue;
      measTPhaseDoxy(find(measTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
      measTempDoxy(find(measTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
      measRPhaseDoxy(find(measRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
      measPhaseDelayDoxy(find(measPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
      measTempDoxy2(find(measTempDoxy2 == g_decArgo_tempDoxyDef)) = paramTempDoxy2.fillValue;
      
      % store single data
      o_singleData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_singleData.paramList = [paramPres paramTemp paramSal ...
         paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy ...
         paramPhaseDelayDoxy paramTempDoxy2];
      
      % add parameter data to the data structure
      o_singleData.data = [measPres measTemp measSal ...
         measTPhaseDoxy measTempDoxy measRPhaseDoxy ...
         measPhaseDelayDoxy measTempDoxy2];
      
      if (a_surfDataFlag)
         o_singleData.paramList(2:3) = [];
         o_singleData.data(2:3) = [];
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in process_apx_ir_rudics_single_obs for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return
