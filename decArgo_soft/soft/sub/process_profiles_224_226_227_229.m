% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_224_226_227_229( ...
%    a_descProfDate, a_descProfDateAdj, ...
%    a_descProfPres, a_descProfTemp, a_descProfSal, a_descProfSalCor, a_descProfTempCndc, ...
%    a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy, ...
%    a_ascProfDate, a_ascProfDateAdj, ...
%    a_ascProfPres, a_ascProfTemp, a_ascProfSal, a_ascProfSalCor, a_ascProfTempCndc, ...
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
%   a_descProfSalCor      : descending profile PSAL_DynamicCorrection
%   a_descProfTempCndc    : descending profile TEMP_CNDC
%   a_descProfC1PhaseDoxy : descending profile C1PHASE_DOXY
%   a_descProfC2PhaseDoxy : descending profile C2PHASE_DOXY
%   a_descProfTempDoxy    : descending profile TEMP_DOXY
%   a_descProfDoxy        : descending profile DOXY
%   a_ascProfDate         : ascending profile dates
%   a_ascProfDateAdj      : ascending profile adjusted dates
%   a_ascProfPres         : ascending profile PRES
%   a_ascProfTemp         : ascending profile TEMP
%   a_ascProfSal          : ascending profile PSAL
%   a_ascProfSalCor       : ascending profile PSAL_DynamicCorrection
%   a_ascProfTempCndc     : ascending profile TEMP_CNDC
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_224_226_227_229( ...
   a_descProfDate, a_descProfDateAdj, ...
   a_descProfPres, a_descProfTemp, a_descProfSal, a_descProfSalCor, a_descProfTempCndc, ...
   a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy, ...
   a_ascProfDate, a_ascProfDateAdj, ...
   a_ascProfPres, a_ascProfTemp, a_ascProfSal, a_ascProfSalCor, a_ascProfTempCndc, ...
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

tabTech = [];
if (~isempty(a_tabTech2))
   if (size(a_tabTech2, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #2 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech2, 1));
   end
   tabTech = a_tabTech2(end, :);
end

% process the descending and ascending profiles
for idProf = 1:2
   
   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];
   tabSalCor = [];
   tabTempCndc = [];
   tabC1PhaseDoxy = [];
   tabC2PhaseDoxy = [];
   tabTempDoxy = [];
   tabDoxy = [];
   
   if (idProf == 1)
      
      % descending profile
      tabDate = a_descProfDate;
      tabDateAdj = a_descProfDateAdj;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      if (~isempty(a_descProfSal) && any(a_descProfSal ~= g_decArgo_salDef))
         tabSal = a_descProfSal;
      end
      if (~isempty(a_descProfSalCor) && any(a_descProfSalCor ~= g_decArgo_salDef))
         tabSalCor = a_descProfSalCor;
      end
      if (~isempty(a_descProfTempCndc) && any(a_descProfTempCndc ~= g_decArgo_tempDef))
         tabTempCndc = a_descProfTempCndc;
      end
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
      tabSalCor = flipud(tabSalCor);
      tabTempCndc = flipud(tabTempCndc);
      tabC1PhaseDoxy = flipud(tabC1PhaseDoxy);
      tabC2PhaseDoxy = flipud(tabC2PhaseDoxy);
      tabTempDoxy = flipud(tabTempDoxy);
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
      if (~isempty(a_ascProfSal) && any(a_ascProfSal ~= g_decArgo_salDef))
         tabSal = a_ascProfSal;
      end
      if (~isempty(a_ascProfSalCor) && any(a_ascProfSalCor ~= g_decArgo_salDef))
         tabSalCor = a_ascProfSalCor;
      end
      if (~isempty(a_ascProfTempCndc) && any(a_ascProfTempCndc ~= g_decArgo_tempDef))
         tabTempCndc = a_ascProfTempCndc;
      end
      if (~isempty(a_ascProfC1PhaseDoxy) && any(a_ascProfC1PhaseDoxy ~= g_decArgo_c1C2PhaseDoxyDef))
         tabC1PhaseDoxy = a_ascProfC1PhaseDoxy;
         tabC2PhaseDoxy = a_ascProfC2PhaseDoxy;
         tabTempDoxy = a_ascProfTempDoxy;
         tabDoxy = a_ascProfDoxy;
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
      profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, primarySamplingProfileFlag);
      profStruct.sensorNumber = 0;

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
      paramPres = get_netcdf_param_attributes('PRES');
      tabPres(tabPres == g_decArgo_presDef) = paramPres.fillValue;
      paramTemp = get_netcdf_param_attributes('TEMP');
      tabTemp(tabTemp == g_decArgo_tempDef) = paramTemp.fillValue;
      profStruct.paramList = [paramPres paramTemp];
      profStruct.data = [tabPres tabTemp];
      if (~isempty(tabSal))
         paramSal = get_netcdf_param_attributes('PSAL');
         tabSal(tabSal == g_decArgo_salDef) = paramSal.fillValue;
         profStruct.paramList = [profStruct.paramList paramSal];
         profStruct.data = [profStruct.data tabSal];
      end
      if (~isempty(tabSalCor))
         paramSalCor = get_netcdf_param_attributes('PSAL_DynamicCorrection');
         tabSalCor(tabSalCor == g_decArgo_salDef) = paramSalCor.fillValue;
         profStruct.paramList = [profStruct.paramList paramSalCor];
         profStruct.data = [profStruct.data tabSalCor];
      end
      if (~isempty(tabTempCndc))
         paramTempCndc = get_netcdf_param_attributes('TEMP_CNDC');
         tabTempCndc(tabTempCndc == g_decArgo_tempDef) = paramTempCndc.fillValue;
         profStruct.paramList = [profStruct.paramList paramTempCndc];
         profStruct.data = [profStruct.data tabTempCndc];
      end
      if (~isempty(tabC1PhaseDoxy))
         paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
         tabC1PhaseDoxy(tabC1PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef) = paramC1PhaseDoxy.fillValue;
         paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
         tabC2PhaseDoxy(tabC2PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef) = paramC2PhaseDoxy.fillValue;
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         tabTempDoxy(tabTempDoxy == g_decArgo_tempDoxyDef) = paramTempDoxy.fillValue;
         paramDoxy = get_netcdf_param_attributes('DOXY');
         tabDoxy(tabDoxy == g_decArgo_doxyDef) = paramDoxy.fillValue;
         profStruct.paramList = [profStruct.paramList paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy paramDoxy];
         profStruct.data = [profStruct.data tabC1PhaseDoxy tabC2PhaseDoxy tabTempDoxy tabDoxy];
      end

      profStruct.dateList = paramJuld;
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
      
      % set 'PSAL_DynamicCorrection' in PROF_AUX file
      idPsalCor = find(strcmp({profStruct.paramList.name}, 'PSAL_DynamicCorrection'));
      profStructAux = '';
      if (~isempty(idPsalCor))
         profStructAux = profStruct;
         profStruct.data(:, idPsalCor) = [];
         profStruct.paramList(idPsalCor) = [];
         profStructAux.data = profStructAux.data(:, [1 idPsalCor]);
         profStructAux.paramList = profStructAux.paramList([1 idPsalCor]);
         profStructAux.sensorNumber = profStructAux.sensorNumber + 1000;
      end

      o_tabProfiles = [o_tabProfiles profStruct profStructAux];
   end
end

return
