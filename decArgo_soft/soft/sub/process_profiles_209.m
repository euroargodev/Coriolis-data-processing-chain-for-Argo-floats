% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_209( ...
%    a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxyAa, a_descProfDoxyAa, ...
%    a_descProfPhaseDelayDoxy, a_descProfTempDoxySbe, a_descProfDoxySbe, ...
%    a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxyAa, a_ascProfDoxyAa, ...
%    a_ascProfPhaseDelayDoxy, a_ascProfTempDoxySbe, a_ascProfDoxySbe, ...
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
%   a_descProfTempDoxyAa     : descending profile TEMP_DOXY (Aanderaa sensor)
%   a_descProfDoxyAa         : descending profile DOXY (Aanderaa sensor)
%   a_descProfPhaseDelayDoxy : descending profile PHASE_DELAY_DOXY
%   a_descProfTempDoxySbe    : descending profile TEMP_DOXY2 (SBE sensor)
%   a_descProfDoxySbe        : descending profile DOXY2 (SBE sensor)
%   a_ascProfDate            : ascending profile dates
%   a_ascProfPres            : ascending profile PRES
%   a_ascProfTemp            : ascending profile TEMP
%   a_ascProfSal             : ascending profile PSAL
%   a_ascProfC1PhaseDoxy     : ascending profile C1PHASE_DOXY
%   a_ascProfC2PhaseDoxy     : ascending profile C2PHASE_DOXY
%   a_ascProfTempDoxyAa      : ascending profile TEMP_DOXY (Aanderaa sensor)
%   a_ascProfDoxySbe         : ascending profile DOXY (Aanderaa sensor)
%   a_ascProfPhaseDelayDoxy  : ascending profile PHASE_DELAY_DOXY
%   a_ascProfTempDoxySbe     : ascending profile TEMP_DOXY2 (SBE sensor)
%   a_ascProfDoxySbe         : ascending profile DOXY2 (SBE sensor)
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
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_209( ...
   a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxyAa, a_descProfDoxyAa, ...
   a_descProfPhaseDelayDoxy, a_descProfTempDoxySbe, a_descProfDoxySbe, ...
   a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxyAa, a_ascProfDoxyAa, ...
   a_ascProfPhaseDelayDoxy, a_ascProfTempDoxySbe, a_ascProfDoxySbe, ...
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
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;

% look for the CTD pump cut-off pressure
presCutOffProf = '';
tabTech = '';
if (~isempty(a_tabTech))
   
   % retrieve the last pumped PRES from the tech msg
   if (size(a_tabTech, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer => using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech, 1));
   end
   tabTech = a_tabTech(end, :);
   presCutOffProf = sensor_2_value_for_pressure_204_to_209(tabTech(41));
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
   tabTempDoxyAa = [];
   tabDoxyAa = [];
   tabPhaseDelayDoxy = [];
   tabTempDoxySbe = [];
   tabDoxySbe = [];

   if (idProf == 1)
      
      % descending profile
      tabDate = a_descProfDate;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      tabSal = a_descProfSal;
      tabC1PhaseDoxy = a_descProfC1PhaseDoxy;
      tabC2PhaseDoxy = a_descProfC2PhaseDoxy;
      tabTempDoxyAa = a_descProfTempDoxyAa;
      tabDoxyAa = a_descProfDoxyAa;
      tabPhaseDelayDoxy = a_descProfPhaseDelayDoxy;
      tabTempDoxySbe = a_descProfTempDoxySbe;
      tabDoxySbe = a_descProfDoxySbe;
      
      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);
      if (~isempty(tabC1PhaseDoxy))
         tabC1PhaseDoxy = flipud(tabC1PhaseDoxy);
         tabC2PhaseDoxy = flipud(tabC2PhaseDoxy);
         tabTempDoxyAa = flipud(tabTempDoxyAa);
         tabDoxyAa = flipud(tabDoxyAa);
      end
      if (~isempty(tabPhaseDelayDoxy))
         tabPhaseDelayDoxy = flipud(tabPhaseDelayDoxy);
         tabTempDoxySbe = flipud(tabTempDoxySbe);
         tabDoxySbe = flipud(tabDoxySbe);
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
      
      % ascending profiles
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
               tabTempDoxyAa = a_ascProfTempDoxyAa(1:idLev(end));
               tabDoxyAa = a_ascProfDoxyAa(1:idLev(end));
            end
            if (~isempty(a_ascProfPhaseDelayDoxy))
               tabPhaseDelayDoxy = a_ascProfPhaseDelayDoxy(1:idLev(end));
               tabTempDoxySbe = a_ascProfTempDoxySbe(1:idLev(end));
               tabDoxySbe = a_ascProfDoxySbe(1:idLev(end));
            end
         end
      elseif (idProf == 3)
         
         % unpumped profile
         % the last (shallower) measurement is sampled in the air (it will be
         % stored in the TRAJ file with MC = 1100)
         idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres <= presCutOffProf));
         if (length(idLev) > 1)
            tabDate = a_ascProfDate(idLev(1):end-1);
            tabPres = a_ascProfPres(idLev(1):end-1);
            tabTemp = a_ascProfTemp(idLev(1):end-1);
            tabSal = a_ascProfSal(idLev(1):end-1);
            if (~isempty(a_ascProfC1PhaseDoxy))
               tabC1PhaseDoxy = a_ascProfC1PhaseDoxy(idLev(1):end-1);
               tabC2PhaseDoxy = a_ascProfC2PhaseDoxy(idLev(1):end-1);
               tabTempDoxyAa = a_ascProfTempDoxyAa(idLev(1):end-1);
               tabDoxyAa = a_ascProfDoxyAa(idLev(1):end-1);
            end
            if (~isempty(a_ascProfPhaseDelayDoxy))
               tabPhaseDelayDoxy = a_ascProfPhaseDelayDoxy(idLev(1):end-1);
               tabTempDoxySbe = a_ascProfTempDoxySbe(idLev(1):end-1);
               tabDoxySbe = a_ascProfDoxySbe(idLev(1):end-1);
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
         paramTempDoxyAa = get_netcdf_param_attributes('TEMP_DOXY');
      end
      if (~isempty(tabPhaseDelayDoxy))
         paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY');
         paramTempDoxySbe = get_netcdf_param_attributes('TEMP_DOXY2');
      end
      paramDoxyAA = get_netcdf_param_attributes('DOXY');
      paramDoxySbe = get_netcdf_param_attributes('DOXY2');
      
      if (~isempty(tabDate))
         
         % convert decoder default values to netCDF fill values
         tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
         tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
         tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
         tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;
         if (~isempty(tabC1PhaseDoxy))
            tabC1PhaseDoxy(find(tabC1PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef)) = paramC1PhaseDoxy.fillValue;
            tabC2PhaseDoxy(find(tabC2PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef)) = paramC2PhaseDoxy.fillValue;
            tabTempDoxyAa(find(tabTempDoxyAa == g_decArgo_tempDoxyDef)) = paramTempDoxyAa.fillValue;
            tabDoxyAa(find(tabDoxyAa == g_decArgo_doxyDef)) = paramDoxyAA.fillValue;
         end
         if (~isempty(tabPhaseDelayDoxy))
            tabPhaseDelayDoxy(find(tabPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
            tabTempDoxySbe(find(tabTempDoxySbe == g_decArgo_tempDoxyDef)) = paramTempDoxySbe.fillValue;
            tabDoxySbe(find(tabDoxySbe == g_decArgo_doxyDef)) = paramDoxySbe.fillValue;
         end
         
         % add parameter variables to the profile structure
         if (~isempty(tabC1PhaseDoxy) && ~isempty(tabPhaseDelayDoxy))
            profStruct.paramList = [paramPres paramTemp paramSal ...
               paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxyAa paramDoxyAA ...
               paramPhaseDelayDoxy paramTempDoxySbe paramDoxySbe];
         elseif (~isempty(tabC1PhaseDoxy))
            profStruct.paramList = [paramPres paramTemp paramSal ...
               paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxyAa paramDoxyAA];
         elseif (~isempty(tabPhaseDelayDoxy))
            profStruct.paramList = [paramPres paramTemp paramSal ...
               paramPhaseDelayDoxy paramTempDoxySbe paramDoxySbe];
         else
            profStruct.paramList = [paramPres paramTemp paramSal];
         end
         profStruct.dateList = paramJuld;
         
         % add parameter data to the profile structure
         if (~isempty(tabC1PhaseDoxy) && ~isempty(tabPhaseDelayDoxy))
            profStruct.data = [tabPres tabTemp tabSal ...
               tabC1PhaseDoxy tabC2PhaseDoxy tabTempDoxyAa tabDoxyAa ...
               tabPhaseDelayDoxy tabTempDoxySbe tabDoxySbe];
         elseif (~isempty(tabC1PhaseDoxy))
            profStruct.data = [tabPres tabTemp tabSal ...
               tabC1PhaseDoxy tabC2PhaseDoxy tabTempDoxyAa tabDoxyAa];
         elseif (~isempty(tabPhaseDelayDoxy))
            profStruct.data = [tabPres tabTemp tabSal ...
               tabPhaseDelayDoxy tabTempDoxySbe tabDoxySbe];
         else
            profStruct.data = [tabPres tabTemp tabSal];
         end
         profStruct.dates = tabDate;
         
         % measurement dates
         dates = tabDate;
         dates(find(dates == paramJuld.fillValue)) = [];
         profStruct.minMeasDate = min(dates);
         profStruct.maxMeasDate = max(dates);
         
      end
      
      % update the profile completed flag
      if (~isempty(nbMeaslist))
         profStruct.profileCompleted = profileCompleted;
      end
      
      % add profile date and location information
      [profStruct] = add_profile_date_and_location_201_to_209_2001_2002( ...
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
