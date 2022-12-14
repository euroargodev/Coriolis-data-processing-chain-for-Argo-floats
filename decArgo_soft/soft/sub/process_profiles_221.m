% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_221( ...
%    a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy, ...
%    a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxy, a_ascProfDoxy, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_cycleTimeData, a_tabTech2, a_decoderId)
%
% INPUT PARAMETERS :
%   a_descProfDate        : descending profile dates
%   a_descProfDateAdj     : descending profile adjusted dates
%   a_descProfPres        : descending profile PRES
%   a_descProfTemp        : descending profile TEMP
%   a_descProfSal         : descending profile PSAL
%   a_descProfC1PhaseDoxy : descending profile C1PHASE_DOXY
%   a_descProfC2PhaseDoxy : descending profile C2PHASE_DOXY
%   a_descProfTempDoxy    : descending profile TEMP_DOXY
%   a_descProfDoxy        : descending profile DOXY
%   a_ascProfDate         : ascending profile dates
%   a_ascProfDateAdj      : ascending profile adjusted dates
%   a_ascProfPres         : ascending profile PRES
%   a_ascProfTemp         : ascending profile TEMP
%   a_ascProfSal          : ascending profile PSAL
%   a_ascProfC1PhaseDoxy  : ascending profile C1PHASE_DOXY
%   a_ascProfC2PhaseDoxy  : ascending profile C2PHASE_DOXY
%   a_ascProfTempDoxy     : ascending profile TEMP_DOXY
%   a_ascProfDoxy         : ascending profile DOXY
%   a_gpsData             : GPS data
%   a_iridiumMailData     : Iridium mail contents
%   a_cycleTimeData       : cycle timings structure
%   a_tabTech2            : decoded data of technical msg #2
%   a_decoderId           : float decoder Id
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
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_221( ...
   a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy, ...
   a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxy, a_ascProfDoxy, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleTimeData, a_tabTech2, a_decoderId)

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
iceDetected = a_cycleTimeData.iceDetected;

% look for the CTD pump cut-off pressure
presCutOffProf = [];
tabTech = [];
% if the float surfaced we use the last pumped PRES from the tech msg;
% otherwise, as the "subsurface point" is not the "last pumped PRES", we use the
% configuration parameter
if (~isempty(a_tabTech2) && (iceDetected == 0))
   
   % retrieve the last pumped PRES from the tech msg
   if (size(a_tabTech2, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech2, 1));
   end
   tabTech = a_tabTech2(end, :);
   pres = sensor_2_value_for_pressure_201_203_215_216_218_221(tabTech(11));
   temp = sensor_2_value_for_temperature_201_to_203_215_216_218_221(tabTech(12));
   psal = tabTech(13)/1000;
   if (any([pres temp psal] ~= 0))
      presCutOffProf = pres;
   end
end
if (isempty(presCutOffProf))
   
   % retrieve the CTD pump cut-off pressure from the configuration
   [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
   ctpPumpSwitchOffPres = get_config_value('CONFIG_PX01', configNames, configValues);
   if (~isempty(ctpPumpSwitchOffPres))
      presCutOffProf = ctpPumpSwitchOffPres + 0.5;
      
      if (iceDetected == 0)
         fprintf('DEC_WARNING: Float #%d Cycle #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data - value retrieved from the configuration\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   else
      presCutOffProf = 5 + 0.5;
      
      fprintf('DEC_WARNING: Float #%d Cycle #%d: PRES_CUT_OFF_PROF parameter is missing in the tech data and in the configuration - value set to 5 dbars\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end
end

% process the descending and ascending profiles
for idProf = 1:3
   
   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];
   tabC1PhaseDoxy = [];
   tabC2PhaseDoxy = [];
   tabTempDoxy = [];
   tabDoxy = [];
   bottomThreshold = [];
   
   if (idProf == 1)
      
      % descending profile
      tabDate = a_descProfDate;
      tabDateAdj = a_descProfDateAdj;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      tabSal = a_descProfSal;
      if (~isempty(a_descProfC1PhaseDoxy) && any(a_descProfC1PhaseDoxy ~= g_decArgo_c1C2PhaseDoxyDef))
         tabC1PhaseDoxy = a_descProfC1PhaseDoxy;
         tabC2PhaseDoxy = a_descProfC2PhaseDoxy;
         tabTempDoxy = a_descProfTempDoxy;
         tabDoxy = a_descProfDoxy;
      end
      
      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabDateAdj = flipud(tabDateAdj);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);
      if (~isempty(a_descProfC1PhaseDoxy) && any(a_descProfC1PhaseDoxy ~= g_decArgo_c1C2PhaseDoxyDef))
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
            tabDateAdj = a_ascProfDateAdj(1:idLev(end));
            tabPres = a_ascProfPres(1:idLev(end));
            tabTemp = a_ascProfTemp(1:idLev(end));
            tabSal = a_ascProfSal(1:idLev(end));
            if (~isempty(a_ascProfC1PhaseDoxy) && any(a_ascProfC1PhaseDoxy ~= g_decArgo_c1C2PhaseDoxyDef))
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
            tabDateAdj = a_ascProfDateAdj(idLev(1):end);
            tabPres = a_ascProfPres(idLev(1):end);
            tabTemp = a_ascProfTemp(idLev(1):end);
            tabSal = a_ascProfSal(idLev(1):end);
            if (~isempty(a_ascProfC1PhaseDoxy) && any(a_ascProfC1PhaseDoxy ~= g_decArgo_c1C2PhaseDoxyDef))
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
      
      % look for additionnal bottom depth zone
      if (a_decoderId == 221)
         bottomThreshold = check_bottom_zone(g_decArgo_cycleNum, tabPres, tabTech);
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
      tabDateAdj(find(tabDateAdj == g_decArgo_dateDef)) = paramJuld.fillValue;
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
      [profStruct] = add_profile_date_and_location_201_to_224_2001_to_2003( ...
         profStruct, a_gpsData, a_iridiumMailData, ...
         descentToParkStartDate, ascentEndDate, transStartDate);
      
      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         profStruct.configMissionNumber = configMissionNumber;
      end
      
      profStruct.additionnalBottomThreshold = bottomThreshold;
      
      o_tabProfiles = [o_tabProfiles profStruct];
   end
end

return

% ------------------------------------------------------------------------------
% Look for the additionnal deep zone created when the float grounded during
% the descent to profile depth phase.
%
% SYNTAX :
%  [o_bottomThreshold] = check_bottom_zone(a_cycleNum, a_tabPres, a_tabTech)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_tabPres  : cycle profiles
%   a_tabTech  : technical #2 data
%
% OUTPUT PARAMETERS :
%   o_bottomThreshold : threshold of the additionnal deep zone
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bottomThreshold] = check_bottom_zone(a_cycleNum, a_tabPres, a_tabTech)

% output parameters initialization
o_bottomThreshold = [];

% default values
global g_decArgo_presDef;


[configNames, configValues] = get_float_config_ir_sbd(a_cycleNum);
if (~isempty(configNames))
   parkPres = get_config_value('CONFIG_PM09', configNames, configValues);
   profilePres = get_config_value('CONFIG_PM09', configNames, configValues);
   threshold2 = get_config_value('CONFIG_PM11', configNames, configValues);
   thickBottom = get_config_value('CONFIG_PM14', configNames, configValues);
   newBottomThick = get_config_value('CONFIG_PM18', configNames, configValues);
   
   go = 1;
   if (~isempty(a_tabTech))
      if (a_tabTech(17) == 0)
         go = 0;
      elseif (a_tabTech(17) == 1)
         if (~isempty(parkPres) && ~isempty(profilePres))
            if ~(((parkPres == profilePres) && ((a_tabTech(21) == 3) || (a_tabTech(21) == 5))) || ...
                  ((parkPres ~= profilePres) && (a_tabTech(21) == 5)))
               go = 0;
            end
         end
      end
   end
   
   if (go == 1)
      
      % retrieve theoretical bottom threshold and check depth table
      if (~isempty(threshold2) && ~isempty(newBottomThick))
         maxPres = max(a_tabPres(find(a_tabPres ~= g_decArgo_presDef)));
         threshold3 = maxPres - newBottomThick;
         if (threshold2 < threshold3)
            presVal = flipud(a_tabPres(find(a_tabPres ~= g_decArgo_presDef)));
            idF = find(presVal > threshold3);
            if (~isempty(idF))
               if (length(idF) > 3)
                  idF([1 end]) = [];
               end
               tick4 = round(mean(round(diff(presVal(idF)))));
               if ((thickBottom ~= 1) && (abs(tick4-thickBottom) > abs(tick4-1)))
                  o_bottomThreshold = threshold3;
               end
            end
         end
      end
   end
end

return
