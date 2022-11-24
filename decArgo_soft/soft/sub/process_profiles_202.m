% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_202( ...
%    a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy, ...
%    a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxy, a_ascProfDoxy, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_transStartDate, a_tabTech, a_decoderId)
%
% INPUT PARAMETERS :
%   a_descProfDate           : descending profile dates
%   a_descProfPres           : descending profile PRES
%   a_descProfTemp           : descending profile TEMP
%   a_descProfSal            : descending profile PSAL
%   a_descProfC1PhaseDoxy    : descending profile C1PHASE_DOXY
%   a_descProfC2PhaseDoxy    : descending profile C2PHASE_DOXY
%   a_descProfTempDoxy       : descending profile TEMP_DOXY
%   a_descProfDoxy           : descending profile DOXY
%   a_ascProfDate            : ascending profile dates
%   a_ascProfPres            : ascending profile PRES
%   a_ascProfTemp            : ascending profile TEMP
%   a_ascProfSal             : ascending profile PSAL
%   a_ascProfC1PhaseDoxy     : ascending profile C1PHASE_DOXY
%   a_ascProfC2PhaseDoxy     : ascending profile C2PHASE_DOXY
%   a_ascProfTempDoxy        : ascending profile TEMP_DOXY
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
%   12/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_202( ...
   a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy, ...
   a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxy, a_ascProfDoxy, ...
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
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;

% look for the CTD pump cut-off pressure
presCutOffProf = '';
tabTech = '';
if (~isempty(a_tabTech))
   
   % retrieve the last pumped PRES from the tech msg #2
   idF2 = find(a_tabTech(:, 1) == 4);
   if (~isempty(idF2))
      if (length(idF2) > 1)
         fprintf('ERROR: Float #%d cycle #%d: %d decoded tech message #2  => using the last one\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(idF2));
      end
      
      tabTech = a_tabTech(idF2(end), :);
      presCutOffProf = sensor_2_value_for_pressure_202_210_211(tabTech(10));
   end
end
if (isempty(presCutOffProf))
   
   % retrieve the CTD pump cut-off pressure from the configuration
   presCutOffProf = [];
   [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
   ctpPumpSwitchOffPres = get_config_value('CONFIG_PT20', configNames, configValues);
   if (~isnan(ctpPumpSwitchOffPres))
      presCutOffProf = ctpPumpSwitchOffPres + 0.5;
      
      fprintf('DEC_WARNING: Float #%d Cycle #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data => value retrieved from the configuration\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      presCutOffProf = 5 + 0.5;
      
      fprintf('DEC_WARNING: Float #%d Cycle #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data and in the configuration => value set to 5 dbars\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end
end

% process the descending and ascending profiles
for idProf = 1:3
   
   tabDate = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];
   tabC1PhaseDoxy = [];
   tabC2PhaseDoxy = [];
   tabTempDoxy = [];
   tabDoxy = [];
   
   if (idProf == 1)
      
      % descending profile
      tabDate = a_descProfDate;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      tabSal = a_descProfSal;
      if (~isempty(a_descProfC1PhaseDoxy))
         tabC1PhaseDoxy = a_descProfC1PhaseDoxy;
         tabC2PhaseDoxy = a_descProfC2PhaseDoxy;
         tabTempDoxy = a_descProfTempDoxy;
         tabDoxy = a_descProfDoxy;
      end
      
      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);
      if (~isempty(a_descProfC1PhaseDoxy))
         tabC1PhaseDoxy = flipud(tabC1PhaseDoxy);
         tabC2PhaseDoxy = flipud(tabC2PhaseDoxy);
         tabTempDoxy = flipud(tabTempDoxy);
         tabDoxy = flipud(tabDoxy);
      end
      
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
      if (idProf == 2)
         % primary profile
         idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres > presCutOffProf));
         if (~isempty(idLev))
            tabDate = a_ascProfDate(1:idLev(end));
            tabPres = a_ascProfPres(1:idLev(end));
            tabTemp = a_ascProfTemp(1:idLev(end));
            tabSal = a_ascProfSal(1:idLev(end));
            if (~isempty(a_ascProfC1PhaseDoxy))
               tabC1PhaseDoxy = a_ascProfC1PhaseDoxy(1:idLev(end));
               tabC2PhaseDoxy = a_ascProfC2PhaseDoxy(1:idLev(end));
               tabTempDoxy = a_ascProfTempDoxy(1:idLev(end));
               tabDoxy = a_ascProfDoxy(1:idLev(end));
            end
         end
      else
         % unpumped profile
         idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres <= presCutOffProf));
         if (~isempty(idLev))
            tabDate = a_ascProfDate(idLev(1):end);
            tabPres = a_ascProfPres(idLev(1):end);
            tabTemp = a_ascProfTemp(idLev(1):end);
            tabSal = a_ascProfSal(idLev(1):end);
            if (~isempty(a_ascProfC1PhaseDoxy))
               tabC1PhaseDoxy = a_ascProfC1PhaseDoxy(idLev(1):end);
               tabC2PhaseDoxy = a_ascProfC2PhaseDoxy(idLev(1):end);
               tabTempDoxy = a_ascProfTempDoxy(idLev(1):end);
               tabDoxy = a_ascProfDoxy(idLev(1):end);
            end
         end
      end
      
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
      if (idProf == 3)
         primarySamplingProfileFlag = 2;
      end
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
      if (~isempty(tabC1PhaseDoxy))
         paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
         paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramDoxy = get_netcdf_param_attributes('DOXY');
      end
      
      % convert decoder default values to netCDF fill values
      tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
      tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;
      if (~isempty(tabC1PhaseDoxy))
         tabC1PhaseDoxy(find(tabC1PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef)) = paramC1PhaseDoxy.fillValue;
         tabC2PhaseDoxy(find(tabC2PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef)) = paramC2PhaseDoxy.fillValue;
         tabTempDoxy(find(tabTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
         tabDoxy(find(tabDoxy == g_decArgo_doxyDef)) = paramDoxy.fillValue;
      end
      
      % add parameter variables to the profile structure
      if (~isempty(tabC1PhaseDoxy))
         profStruct.paramList = [paramPres paramTemp paramSal paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy paramDoxy];
      else
         profStruct.paramList = [paramPres paramTemp paramSal];
      end
      profStruct.dateList = paramJuld;
      
      % add parameter data to the profile structure
      if (~isempty(tabC1PhaseDoxy))
         profStruct.data = [tabPres tabTemp tabSal tabC1PhaseDoxy tabC2PhaseDoxy tabTempDoxy tabDoxy];
      else
         profStruct.data = [tabPres tabTemp tabSal];
      end
      profStruct.dates = tabDate;
      
      % measurement dates
      dates = tabDate;
      dates(find(dates == paramJuld.fillValue)) = [];
      profStruct.minMeasDate = min(dates);
      profStruct.maxMeasDate = max(dates);
      
      % update the profile completed flag
      if (~isempty(nbMeaslist))
         profStruct.profileCompleted = profileCompleted;
      end
      
      % add profile date and location information
      [profStruct] = add_profile_date_and_location_201_to_211_2001_2002( ...
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
