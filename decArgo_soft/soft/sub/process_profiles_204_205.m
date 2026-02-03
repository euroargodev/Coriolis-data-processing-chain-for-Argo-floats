% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_204_205( ...
%    a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_transStartDate, a_tabTech, a_decoderId)
%
% INPUT PARAMETERS :
%   a_descProfDate           : descending profile dates
%   a_descProfPres           : descending profile PRES
%   a_descProfTemp           : descending profile TEMP
%   a_descProfSal            : descending profile PSAL
%   a_ascProfDate            : ascending profile dates
%   a_ascProfPres            : ascending profile PRES
%   a_ascProfTemp            : ascending profile TEMP
%   a_ascProfSal             : ascending profile PSAL
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_204_205( ...
   a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROFILE CTD CUT OFF PRESSURE DETERMINATION

[subSurfacePres, presCutOffProfConfig, presCutOffProf, tabTech] = ...
   get_pres_cut_off_prof(a_tabTech, a_decoderId);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process the descending and ascending profiles
for idProf = 1:3

   tabDate = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];

   if (idProf == 1)

      % descending profile
      tabDate = a_descProfDate;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      tabSal = a_descProfSal;

      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);

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
         if (~isempty(subSurfacePres))
            if (ismember(a_decoderId, [201:218, 221:223, 225, 228, 230]))
               idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres > subSurfacePres)); % not compliant with Argo profile cookbook but historical implementation
            else
               idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres >= subSurfacePres));
            end
         else
            idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres > presCutOffProfConfig));
         end
         if (~isempty(idLev))
            tabDate = a_ascProfDate(1:idLev(end));
            tabPres = a_ascProfPres(1:idLev(end));
            tabTemp = a_ascProfTemp(1:idLev(end));
            tabSal = a_ascProfSal(1:idLev(end));
         end
      else
         % unpumped profile
         if (~isempty(subSurfacePres))
            if (ismember(a_decoderId, [201:218, 221:223, 225, 228, 230]))
               idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres <= subSurfacePres)); % not compliant with Argo profile cookbook but historical implementation
            else
               idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres < subSurfacePres));
            end
         else
            idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres <= presCutOffProfConfig));
         end
         if (~isempty(idLev))
            tabDate = a_ascProfDate(idLev(1):end);
            tabPres = a_ascProfPres(idLev(1):end);
            tabTemp = a_ascProfTemp(idLev(1):end);
            tabSal = a_ascProfSal(idLev(1):end);
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

      % convert decoder default values to netCDF fill values
      tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
      tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;

      % add parameter variables to the profile structure
      profStruct.paramList = [paramPres paramTemp paramSal];
      profStruct.dateList = paramJuld;

      % add parameter data to the profile structure
      profStruct.data = [tabPres tabTemp tabSal];
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
      [profStruct] = add_profile_date_and_location_201_to_230_40x_2001_to_2003( ...
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

return
