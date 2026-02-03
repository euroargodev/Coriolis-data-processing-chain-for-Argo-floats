% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
% [o_tabProfiles] = process_profiles_3T_228( ...
%   a_descProfDate, a_descProfDateAdj, ...
%   a_descProfPresSbe41, a_descProfTempSbe41, a_descProfSalSbe41, ...
%   a_descProfPresSbe61, a_descProfTempSbe61, a_descProfSalSbe61, ...
%   a_descProfPresRbr, a_descProfTempRbr, a_descProfSalRbr, a_descProfTempCndcRbr, ...
%   a_ascProfDate, a_ascProfDateAdj, ...
%   a_ascProfPresSbe41, a_ascProfTempSbe41, a_ascProfSalSbe41, ...
%   a_ascProfPresSbe61, a_ascProfTempSbe61, a_ascProfSalSbe61, ...
%   a_ascProfPresRbr, a_ascProfTempRbr, a_ascProfSalRbr, a_ascProfTempCndcRbr, ...
%   a_gpsData, a_iridiumMailData, ...
%   a_cycleTimeData, a_tabTech2, a_tabTech3, a_decoderId)
%
% INPUT PARAMETERS :
%   a_descProfDate        : descending profile dates
%   a_descProfDateAdj     : descending profile adjusted dates
%   a_descProfPresSbe41   : descending profile PRES from SBE41 sensor
%   a_descProfTempSbe41   : descending profile TEMP from SBE41 sensor
%   a_descProfSalSbe41    : descending profile PSAL from SBE41 sensor
%   a_descProfPresSbe61   : descending profile PRES from SBE61 sensor
%   a_descProfTempSbe61   : descending profile TEMP from SBE61 sensor
%   a_descProfSalSbe61    : descending profile PSAL from SBE61 sensor
%   a_descProfPresRbr     : descending profile PRES from RBR sensor
%   a_descProfTempRbr     : descending profile TEMP from RBR sensor
%   a_descProfSalRbr      : descending profile PSAL from RBR sensor
%   a_descProfTempCndcRbr : descending profile TEMP_CNDC from RBR sensor
%   a_ascProfDate         : ascending profile dates
%   a_ascProfDateAdj      : ascending profile adjusted dates
%   a_ascProfPresSbe41    : ascending profile PRES from SBE41 sensor
%   a_ascProfTempSbe41    : ascending profile TEMP from SBE41 sensor
%   a_ascProfSalSbe41     : ascending profile PSAL from SBE41 sensor
%   a_ascProfPresSbe61    : ascending profile PRES from SBE61 sensor
%   a_ascProfTempSbe61    : ascending profile TEMP from SBE61 sensor
%   a_ascProfSalSbe61     : ascending profile PSAL from SBE61 sensor
%   a_ascProfPresRbr      : ascending profile PRES from RBR sensor
%   a_ascProfTempRbr      : ascending profile TEMP from RBR sensor
%   a_ascProfSalRbr       : ascending profile PSAL from RBR sensor
%   a_ascProfTempCndcRbr  : ascending profile TEMP_CNDC from RBR sensor
%   a_gpsData             : GPS data
%   a_iridiumMailData     : Iridium mail contents
%   a_cycleTimeData       : cycle timings structure
%   a_tabTech2            : decoded data of technical msg #2
%   a_tabTech3            : decoded data of technical msg #3
%   a_decoderId           : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_3T_228( ...
   a_descProfDate, a_descProfDateAdj, ...
   a_descProfPresSbe41, a_descProfTempSbe41, a_descProfSalSbe41, ...
   a_descProfPresSbe61, a_descProfTempSbe61, a_descProfSalSbe61, ...
   a_descProfPresRbr, a_descProfTempRbr, a_descProfSalRbr, a_descProfTempCndcRbr, ...
   a_ascProfDate, a_ascProfDateAdj, ...
   a_ascProfPresSbe41, a_ascProfTempSbe41, a_ascProfSalSbe41, ...
   a_ascProfPresSbe61, a_ascProfTempSbe61, a_ascProfSalSbe61, ...
   a_ascProfPresRbr, a_ascProfTempRbr, a_ascProfSalRbr, a_ascProfTempCndcRbr, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleTimeData, a_tabTech2, a_tabTech3, a_decoderId)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


% retrieve useful information from cycle timings structure
if (~isempty(a_cycleTimeData.descentToParkStartDateAdj))
   descentToParkStartDate = a_cycleTimeData.descentToParkStartDateAdj;
else
   descentToParkStartDate = a_cycleTimeData.descentToParkStartDate;
end
if (~isempty(a_cycleTimeData.ascentEndDateAdj))
   ascentEndDate = a_cycleTimeData.ascentEndDateAdj;
else
   ascentEndDate = a_cycleTimeData.ascentEndDate;
end
if (~isempty(a_cycleTimeData.transStartDateAdj))
   transStartDate = a_cycleTimeData.transStartDateAdj;
else
   transStartDate = a_cycleTimeData.transStartDate;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SBE41

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROFILE CTD CUT OFF PRESSURE DETERMINATION

% retrieve the pressure of the "subsurface point" (last pumped raw PTS meas)
subSurfacePres = '';
if (~isempty(a_tabTech2))

   % retrieve the last pumped PRES from the tech msg
   if (size(a_tabTech2, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #2 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech2, 1));
   end
   tabTech2 = a_tabTech2(end, :);
   pres = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(tabTech2(11));
   temp = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(tabTech2(12));
   psal = tabTech2(13)/1000;
   if (any([pres temp psal] ~= 0))
      % A specific bin is created after the pressure of the ‘subsurface point’
      % (PSubsurfacePoint).so that pumped and unpumped data are not mixed in the
      % bin-averaged output values.
      subSurfacePres = pres;
   end
end
if (isempty(subSurfacePres))
   % retrieve the CTD pump cut-off pressure from the configuration
   [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
   ctpPumpSwitchOffPres = get_config_value('CONFIG_PT20', configNames, configValues);
   if (~isempty(ctpPumpSwitchOffPres))
      % PT20 is CTD pump cut-off pressure we should add Poverlap = 0.5 dbar
      presCutOffProfConfig = ctpPumpSwitchOffPres + 0.5;
   else
      presCutOffProfConfig = 5 + 0.5;
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tabTech3 = [];
if (~isempty(a_tabTech3))
   if (size(a_tabTech3, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #3 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech3, 1));
   end
   tabTech3 = a_tabTech3(end, :);
end

% process the descending and ascending profiles
for idProf = 1:3

   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];

   if (idProf == 1)

      % descending profile
      tabDate = a_descProfDate;
      tabDateAdj = a_descProfDateAdj;
      tabPres = a_descProfPresSbe41;
      tabTemp = a_descProfTempSbe41;
      tabSal = a_descProfSalSbe41;

      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabDateAdj = flipud(tabDateAdj);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech3))
         profileCompleted = sum(tabTech3(11:15)) - length(a_descProfPresSbe41);
      end
   else

      % ascending profile
      if (idProf == 2)
         % primary profile
         if (~isempty(subSurfacePres))
            if (ismember(a_decoderId, [201:218, 221:223, 225, 228, 230]))
               idLev = find((a_ascProfPresSbe41 ~= g_decArgo_presDef) & (a_ascProfPresSbe41 > subSurfacePres)); % not compliant with Argo profile cookbook but historical implementation
            else
               idLev = find((a_ascProfPresSbe41 ~= g_decArgo_presDef) & (a_ascProfPresSbe41 >= subSurfacePres));
            end
         else
            idLev = find((a_ascProfPresSbe41 ~= g_decArgo_presDef) & (a_ascProfPresSbe41 > presCutOffProfConfig));
         end
         if (~isempty(idLev))
            tabDate = a_ascProfDate(1:idLev(end));
            tabDateAdj = a_ascProfDateAdj(1:idLev(end));
            tabPres = a_ascProfPresSbe41(1:idLev(end));
            tabTemp = a_ascProfTempSbe41(1:idLev(end));
            tabSal = a_ascProfSalSbe41(1:idLev(end));
         end
      else
         % unpumped profile
         if (~isempty(subSurfacePres))
            if (ismember(a_decoderId, [201:218, 221:223, 225, 228, 230]))
               idLev = find((a_ascProfPresSbe41 ~= g_decArgo_presDef) & (a_ascProfPresSbe41 <= subSurfacePres)); % not compliant with Argo profile cookbook but historical implementation
            else
               idLev = find((a_ascProfPresSbe41 ~= g_decArgo_presDef) & (a_ascProfPresSbe41 < subSurfacePres));
            end
         else
            idLev = find((a_ascProfPresSbe41 ~= g_decArgo_presDef) & (a_ascProfPresSbe41 <= presCutOffProfConfig));
         end
         if (~isempty(idLev))
            tabDate = a_ascProfDate(idLev(1):end);
            tabDateAdj = a_ascProfDateAdj(idLev(1):end);
            tabPres = a_ascProfPresSbe41(idLev(1):end);
            tabTemp = a_ascProfTempSbe41(idLev(1):end);
            tabSal = a_ascProfSalSbe41(idLev(1):end);
         end
      end

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech3))
         profileCompleted = sum(tabTech3(17:21)) - length(a_ascProfPresSbe41);
      end
   end

   if (~isempty(tabDate))

      % create the profile structure
      primarySamplingProfileFlag = 1;
      if (idProf == 3)
         primarySamplingProfileFlag = 2;
      end
      profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, primarySamplingProfileFlag);
      profStruct.sensorNumber = 0;
      profStruct.rbrFlag = 0;

      % profile direction
      if (idProf == 1)
         profStruct.direction = 'D';
      end

      % positioning system
      profStruct.posSystem = 'GPS';

      % CTD pump cut-off pressure
      if (~isempty(subSurfacePres))
         profStruct.presCutOffProf = subSurfacePres;
      else
         profStruct.presCutOffProf = presCutOffProfConfig;
      end

      % create the parameters
      paramJuld = get_netcdf_param_attributes('JULD');
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');

      % convert decoder default values to netCDF fill values
      tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabDateAdj(find(tabDateAdj == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
      tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;

      % add parameter variables to the profile structure
      profStruct.paramList = [paramPres paramTemp paramSal];
      profStruct.dateList = paramJuld;

      % add parameter data to the profile structure
      profStruct.data = [tabPres tabTemp tabSal];
      profStruct.dates = tabDate;
      profStruct.datesAdj = tabDateAdj;

      % measurement dates
      if (any(tabDateAdj ~= paramJuld.fillValue))
         dates = tabDateAdj;
      else
         dates = tabDate;
      end
      dates(dates == paramJuld.fillValue) = [];
      profStruct.minMeasDate = min(dates);
      profStruct.maxMeasDate = max(dates);

      % update the profile completed flag
      if (~isempty(nbMeaslist))
         profStruct.profileCompleted = profileCompleted;
      end

      % add profile date and location information
      [profStruct] = add_profile_date_and_location_201_to_230_40x_2001_to_2003( ...
         profStruct, a_gpsData, a_iridiumMailData, ...
         descentToParkStartDate, ascentEndDate, transStartDate);

      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         profStruct.configMissionNumber = configMissionNumber;
      end

      o_tabProfiles = [o_tabProfiles profStruct];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SBE61

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROFILE CTD CUT OFF PRESSURE DETERMINATION

% THE LAST PUMPED RAW MEASUREMENT PROVIDED IN TECH3 IS NOT USED BECAUSE IT SEEMS
% NOT RELIABLE

% retrieve the CTD pump cut-off pressure from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
ctpPumpSwitchOffPres = get_config_value('CONFIG_FR07', configNames, configValues);
if (~isempty(ctpPumpSwitchOffPres))
   % FR07 is CTD pump cut-off pressure we should add Poverlap = 0.5 dbar
   presCutOffProfConfig = ctpPumpSwitchOffPres + 0.5;
else
   presCutOffProfConfig = 5 + 0.5;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tabTech3 = [];
if (~isempty(a_tabTech3))
   if (size(a_tabTech3, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #3 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech3, 1));
   end
   tabTech3 = a_tabTech3(end, :);
end

% process the descending and ascending profiles
for idProf = 1:3

   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];

   if (idProf == 1)

      % descending profile
      tabDate = a_descProfDate;
      tabDateAdj = a_descProfDateAdj;
      tabPres = a_descProfPresSbe61;
      tabTemp = a_descProfTempSbe61;
      tabSal = a_descProfSalSbe61;

      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabDateAdj = flipud(tabDateAdj);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech3))
         profileCompleted = sum(tabTech3(22:26)) - length(a_descProfPresSbe61);
      end
   else

      % ascending profile
      if (idProf == 2)
         % primary profile
         idLev = find((a_ascProfPresSbe61 ~= g_decArgo_presDef) & (a_ascProfPresSbe61 > presCutOffProfConfig));
         if (~isempty(idLev))
            tabDate = a_ascProfDate(1:idLev(end));
            tabDateAdj = a_ascProfDateAdj(1:idLev(end));
            tabPres = a_ascProfPresSbe61(1:idLev(end));
            tabTemp = a_ascProfTempSbe61(1:idLev(end));
            tabSal = a_ascProfSalSbe61(1:idLev(end));
         end
      else
         % unpumped profile
         idLev = find((a_ascProfPresSbe61 ~= g_decArgo_presDef) & (a_ascProfPresSbe61 <= presCutOffProfConfig));
         if (~isempty(idLev))
            tabDate = a_ascProfDate(idLev(1):end);
            tabDateAdj = a_ascProfDateAdj(idLev(1):end);
            tabPres = a_ascProfPresSbe61(idLev(1):end);
            tabTemp = a_ascProfTempSbe61(idLev(1):end);
            tabSal = a_ascProfSalSbe61(idLev(1):end);
         end
      end

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech3))
         profileCompleted = sum(tabTech3(28:32)) - length(a_ascProfPresSbe61);
      end

   end

   if (~isempty(tabDate))

      % create the profile structure
      primarySamplingProfileFlag = 0;
      if (idProf == 3)
         primarySamplingProfileFlag = 2;
      end
      profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, primarySamplingProfileFlag);
      profStruct.sensorNumber = 0;
      profStruct.rbrFlag = 0;

      % profile direction
      if (idProf == 1)
         profStruct.direction = 'D';
      end

      % positioning system
      profStruct.posSystem = 'GPS';

      % CTD pump cut-off pressure
      profStruct.presCutOffProf = presCutOffProfConfig;

      % create the parameters
      paramJuld = get_netcdf_param_attributes('JULD');
      paramPres = get_netcdf_param_attributes('PRES_2');
      paramTemp = get_netcdf_param_attributes('TEMP_2');
      paramSal = get_netcdf_param_attributes('PSAL_2');

      % convert decoder default values to netCDF fill values
      tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabDateAdj(find(tabDateAdj == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
      tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;

      % add parameter variables to the profile structure
      profStruct.paramList = [paramPres paramTemp paramSal];
      profStruct.dateList = paramJuld;

      % add parameter data to the profile structure
      profStruct.data = [tabPres tabTemp tabSal];
      profStruct.dates = tabDate;
      profStruct.datesAdj = tabDateAdj;

      % measurement dates
      if (any(tabDateAdj ~= paramJuld.fillValue))
         dates = tabDateAdj;
      else
         dates = tabDate;
      end
      dates(dates == paramJuld.fillValue) = [];
      profStruct.minMeasDate = min(dates);
      profStruct.maxMeasDate = max(dates);

      % update the profile completed flag
      if (~isempty(nbMeaslist))
         profStruct.profileCompleted = profileCompleted;
      end

      % add profile date and location information
      [profStruct] = add_profile_date_and_location_201_to_230_40x_2001_to_2003( ...
         profStruct, a_gpsData, a_iridiumMailData, ...
         descentToParkStartDate, ascentEndDate, transStartDate);

      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         profStruct.configMissionNumber = configMissionNumber;
      end

      o_tabProfiles = [o_tabProfiles profStruct];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RBR

tabTech3 = [];
if (~isempty(a_tabTech3))
   if (size(a_tabTech3, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #3 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech3, 1));
   end
   tabTech3 = a_tabTech3(end, :);
end

% process the descending and ascending profiles
for idProf = 1:2

   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];
   tabTempCndc = [];

   if (idProf == 1)

      % descending profile
      tabDate = a_descProfDate;
      tabDateAdj = a_descProfDateAdj;
      tabPres = a_descProfPresRbr;
      tabTemp = a_descProfTempRbr;
      tabSal = a_descProfSalRbr;
      tabTempCndc = a_descProfTempCndcRbr;

      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabDateAdj = flipud(tabDateAdj);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);
      tabTempCndc = flipud(tabTempCndc);

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech3))
         profileCompleted = sum(tabTech3(34:38)) - length(a_descProfPresRbr);
      end
   else

      % ascending profile
      tabDate = a_ascProfDate;
      tabDateAdj = a_ascProfDateAdj;
      tabPres = a_ascProfPresRbr;
      tabTemp = a_ascProfTempRbr;
      tabSal = a_ascProfSalRbr;
      tabTempCndc = a_ascProfTempCndcRbr;

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech3))
         profileCompleted = sum(tabTech3(40:44)) - length(a_ascProfPresRbr);
      end

   end

   if (~isempty(tabDate))

      % create the profile structure
      primarySamplingProfileFlag = 0;
      profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, primarySamplingProfileFlag);
      profStruct.sensorNumber = 0;
      profStruct.rbrFlag = 1;

      % profile direction
      if (idProf == 1)
         profStruct.direction = 'D';
      end

      % positioning system
      profStruct.posSystem = 'GPS';

      % create parameters data structure
      paramJuld = get_netcdf_param_attributes('JULD');
      tabDate(tabDate == g_decArgo_dateDef) = paramJuld.fillValue;
      tabDateAdj(tabDateAdj == g_decArgo_dateDef) = paramJuld.fillValue;
      paramPres = get_netcdf_param_attributes('PRES_3');
      tabPres(tabPres == g_decArgo_presDef) = paramPres.fillValue;
      paramTemp = get_netcdf_param_attributes('TEMP_3');
      tabTemp(tabTemp == g_decArgo_tempDef) = paramTemp.fillValue;
      paramSal = get_netcdf_param_attributes('PSAL_3');
      tabSal(tabSal == g_decArgo_salDef) = paramSal.fillValue;
      paramTempCndc = get_netcdf_param_attributes('TEMP_CNDC');
      tabTempCndc(tabTempCndc == g_decArgo_tempDef) = paramTempCndc.fillValue;

      % add parameter variables to the profile structure
      profStruct.paramList = [paramPres paramTemp paramSal paramTempCndc];
      profStruct.dateList = paramJuld;

      % add parameter data to the profile structure
      profStruct.data = [tabPres tabTemp tabSal tabTempCndc];
      profStruct.dates = tabDate;
      profStruct.datesAdj = tabDateAdj;

      % measurement dates
      if (any(tabDateAdj ~= paramJuld.fillValue))
         dates = tabDateAdj;
      else
         dates = tabDate;
      end
      dates(find(dates == paramJuld.fillValue)) = [];
      profStruct.minMeasDate = min(dates);
      profStruct.maxMeasDate = max(dates);

      % update the profile completed flag
      if (~isempty(nbMeaslist))
         profStruct.profileCompleted = profileCompleted;
      end

      % add profile date and location information
      [profStruct] = add_profile_date_and_location_201_to_230_40x_2001_to_2003( ...
         profStruct, a_gpsData, a_iridiumMailData, ...
         descentToParkStartDate, ascentEndDate, transStartDate);

      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         profStruct.configMissionNumber = configMissionNumber;
      end

      o_tabProfiles = [o_tabProfiles profStruct];
   end
end

return
