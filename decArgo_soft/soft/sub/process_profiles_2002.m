% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_2002( ...
%    a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfTempDoxy, a_descProfPhaseDelayDoxy, a_descProfDoxy, ...
%    a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfTempDoxy, a_ascProfPhaseDelayDoxy, a_ascProfDoxy, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_transStartDate, a_tabTech, a_decoderId)
%
% INPUT PARAMETERS :
%   a_descProfDate           : descending profile dates
%   a_descProfDateAdj        : descending profile adjusted dates
%   a_descProfPres           : descending profile PRES
%   a_descProfTemp           : descending profile TEMP
%   a_descProfSal            : descending profile PSAL
%   a_descProfTempDoxy       : descending profile TEMP_DOXY
%   a_descProfPhaseDelayDoxy : descending profile PHASE_DELAY_DOXY
%   a_descProfDoxy           : descending profile DOXY
%   a_ascProfDate            : ascending profile dates
%   a_ascProfDateAdj         : ascending profile adjusted dates
%   a_ascProfPres            : ascending profile PRES
%   a_ascProfTemp            : ascending profile TEMP
%   a_ascProfSal             : ascending profile PSAL
%   a_ascProfTempDoxy        : ascending profile TEMP_DOXY
%   a_ascProfPhaseDelayDoxy  : ascending profile PHASE_DELAY_DOXY
%   a_ascProfDoxy            : ascending profile DOXY
%   a_gpsData                : GPS data
%   a_iridiumMailData        : Iridium mail contents
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%   a_tabTech                : technical data
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_2002( ...
   a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfTempDoxy, a_descProfPhaseDelayDoxy, a_descProfDoxy, ...
   a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfTempDoxy, a_ascProfPhaseDelayDoxy, a_ascProfDoxy, ...
   a_gpsData, a_iridiumMailData, ...
   a_descentToParkStartDate, a_ascentEndDate, a_transStartDate, a_tabTech, a_decoderId)

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
global g_decArgo_tempDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_doxyDef;


if (isempty(a_tabTech))
   return;
end

if (size(a_tabTech, 1) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer => using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(a_tabTech, 1));
end
tabTech = a_tabTech(end, :);
presCutOffProf = 2;

% process the descending and ascending profiles
for idProf = 1:2
   
   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];
   tabTempDoxy = [];
   tabPhaseDelayDoxy = [];
   tabDoxy = [];
   
   if (idProf == 1)
      
      % descending profile
      tabDate = a_descProfDate;
      tabDateAdj = a_descProfDateAdj;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      tabSal = a_descProfSal;
      tabTempDoxy = a_descProfTempDoxy;
      tabPhaseDelayDoxy = a_descProfPhaseDelayDoxy;
      tabDoxy = a_descProfDoxy;
      
      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabDateAdj = flipud(tabDateAdj);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);
      tabTempDoxy = flipud(tabTempDoxy);
      tabPhaseDelayDoxy = flipud(tabPhaseDelayDoxy);
      tabDoxy = flipud(tabDoxy);
      
      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech))
         % number of expected profile bins in the descending profile
         nbMeaslist = get_nb_meas_list_from_tech(tabTech, a_decoderId);
         nbMeaslist(3:4) = [];
         profileCompleted = sum(nbMeaslist) - length(a_descProfPres);
      end
   else
      
      % ascending profile
      tabDate = a_ascProfDate;
      tabDateAdj = a_ascProfDateAdj;
      tabPres = a_ascProfPres;
      tabTemp = a_ascProfTemp;
      tabSal = a_ascProfSal;
      tabTempDoxy = a_ascProfTempDoxy;
      tabPhaseDelayDoxy = a_ascProfPhaseDelayDoxy;
      tabDoxy = a_ascProfDoxy;

      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(tabTech))
         % number of expected profile bins in the ascending profile
         nbMeaslist = get_nb_meas_list_from_tech(tabTech, a_decoderId);
         nbMeaslist(1:2) = [];
         profileCompleted = sum(nbMeaslist) - length(a_ascProfPres);
      end
   end
   
   if (~isempty(tabDate))
      
      % create the profile structure
      primarySamplingProfileFlag = 1;
      profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, primarySamplingProfileFlag);
      profStruct.sensorNumber = 0;

      % profile direction
      if (idProf == 1)
         profStruct.direction = 'D';
      end
      
      % positioning system
      profStruct.posSystem = 'GPS';
      
      % CTD pump cut-off pressure
      profStruct.presCutOffProf = presCutOffProf;
      
      % create the parameters
      paramJuld = get_netcdf_param_attributes('JULD');
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');

      % convert decoder default values to netCDF fill values
      tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabDateAdj(find(tabDateAdj == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
      tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;
      tabTempDoxy(find(tabTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
      tabPhaseDelayDoxy(find(tabPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
      tabDoxy(find(tabDoxy == g_decArgo_doxyDef)) = paramDoxy.fillValue;
      
      % add parameter variables to the profile structure
      profStruct.paramList = [paramPres paramTemp paramSal ...
         paramTempDoxy paramPhaseDelayDoxy paramDoxy];
      profStruct.dateList = paramJuld;
      
      % add parameter data to the profile structure
      profStruct.data = [tabPres tabTemp tabSal tabTempDoxy tabPhaseDelayDoxy tabDoxy];
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
      [profStruct] = add_profile_date_and_location_201_to_215_2001_2002( ...
         profStruct, a_gpsData, a_iridiumMailData, ...
         a_descentToParkStartDate, a_ascentEndDate, a_transStartDate);
      
      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         profStruct.configMissionNumber = configMissionNumber;
      end
      
      o_tabProfiles = [o_tabProfiles profStruct];
   end
end

return;
