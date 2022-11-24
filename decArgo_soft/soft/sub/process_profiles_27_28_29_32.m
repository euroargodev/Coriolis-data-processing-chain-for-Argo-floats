% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_27_28_29_32(...
%    a_floatSurfData, a_cycleNum, ...
%    a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfRawDoxy, a_descProfDoxy, ...
%    a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfRawDoxy, a_ascProfDoxy, ...
%    a_repRateMetaData, a_decoderId, a_tabTech)
%
% INPUT PARAMETERS :
%   a_floatSurfData   : float surface data structure
%   a_cycleNum        : current cycle number
%   a_descProfDate    : descending profile measurement dates
%   a_descProfPres    : descending profile pressure measurements
%   a_descProfTemp    : descending profile temperature measurements
%   a_descProfSal     : descending profile salinity measurements
%   a_descProfRawDoxy : descending profile oxygen raw measurements
%   a_descProfDoxy    : descending profile oxygen measurements
%   a_ascProfDate     : ascending profile measurement dates
%   a_ascProfPres     : ascending profile pressure measurements
%   a_ascProfTemp     : ascending profile temperature measurements
%   a_ascProfSal      : ascending profile salinity measurements
%   a_ascProfRawDoxy  : ascending profile oxygen raw measurements
%   a_ascProfDoxy     : ascending profile oxygen measurements
%   a_repRateMetaData : repetition rate information from json meta-data file
%   a_decoderId       : float decoder Id
%   a_tabTech         : technical data
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
%   04/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_27_28_29_32(...
   a_floatSurfData, a_cycleNum, ...
   a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfRawDoxy, a_descProfDoxy, ...
   a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfRawDoxy, a_ascProfDoxy, ...
   a_repRateMetaData, a_decoderId, a_tabTech)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tPhaseDoxyCountsDef;
global g_decArgo_doxyDef;


if (~isempty(g_decArgo_jsonMetaData) && isfield(g_decArgo_jsonMetaData, 'PRES_CUT_OFF_PROF'))
   presCutOffProf = g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF;
else
   fprintf('ERROR: Float #%d Cycle #%d: PRES_CUT_OFF_PROF parameter is missing => CTD profiles not split\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   presCutOffProf = g_decArgo_presDef*-1;
end

% process the descending and ascending profiles
for idProf = 1:3
   if (idProf == 1)
      % descending profile
      tabDate = a_descProfDate;
      tabPres = a_descProfPres;
      tabTemp = a_descProfTemp;
      tabSal = a_descProfSal;
      tabRawDoxy = a_descProfRawDoxy;
      tabDoxy = a_descProfDoxy;
      
      % profiles must be ordered chronologically (and finally from top to bottom
      % in the NetCDF files)
      tabDate = flipud(tabDate);
      tabPres = flipud(tabPres);
      tabTemp = flipud(tabTemp);
      tabSal = flipud(tabSal);
      tabRawDoxy = flipud(tabRawDoxy);
      tabDoxy = flipud(tabDoxy);
      
      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(a_tabTech))
         % number of expected profile bins in the descending profile
         nbMeaslist = get_nb_meas_list_from_tech(a_tabTech, a_decoderId);
         nbMeaslist(3:4) = [];
         profileCompleted = sum(nbMeaslist) - length(a_descProfPres);
      end
   else
      % ascending profile
      tabDate = [];
      tabPres = [];
      tabTemp = [];
      tabSal = [];
      tabRawDoxy = [];
      tabDoxy = [];
      
      if (idProf == 2)
         % primary profile
         idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres > presCutOffProf));
         if (~isempty(idLev))
            tabDate = a_ascProfDate(1:idLev(end));
            tabPres = a_ascProfPres(1:idLev(end));
            tabTemp = a_ascProfTemp(1:idLev(end));
            tabSal = a_ascProfSal(1:idLev(end));
            tabRawDoxy = a_ascProfRawDoxy(1:idLev(end));
            tabDoxy = a_ascProfDoxy(1:idLev(end));
         end
      else
         % unpumped profile
         idLev = find((a_ascProfPres ~= g_decArgo_presDef) & (a_ascProfPres <= presCutOffProf));
         if (~isempty(idLev))
            tabDate = a_ascProfDate(idLev(1):end);
            tabPres = a_ascProfPres(idLev(1):end);
            tabTemp = a_ascProfTemp(idLev(1):end);
            tabSal = a_ascProfSal(idLev(1):end);
            tabRawDoxy = a_ascProfRawDoxy(idLev(1):end);
            tabDoxy = a_ascProfDoxy(idLev(1):end);
         end
      end
      
      % update the profile completed flag
      nbMeaslist = [];
      if (~isempty(a_tabTech))
         % number of expected profile bins in the ascending profile
         nbMeaslist = get_nb_meas_list_from_tech(a_tabTech, a_decoderId);
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
      profStruct = get_profile_init_struct(a_cycleNum, -1, -1, primarySamplingProfileFlag);
      profStruct.sensorNumber = 0;

      % profile direction
      if (idProf == 1)
         profStruct.direction = 'D';
      end
      
      % positioning system
      profStruct.posSystem = 'ARGOS';
      
      % create the parameters
      paramJuld = get_netcdf_param_attributes('JULD');
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramRawDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');
      
      % convert decoder default values to netCDF fill values
      tabDate(find(tabDate == g_decArgo_dateDef)) = paramJuld.fillValue;
      tabPres(find(tabPres == g_decArgo_presDef)) = paramPres.fillValue;
      tabTemp(find(tabTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      tabSal(find(tabSal == g_decArgo_salDef)) = paramSal.fillValue;
      tabRawDoxy(find(tabRawDoxy == g_decArgo_tPhaseDoxyCountsDef)) = paramRawDoxy.fillValue;
      tabDoxy(find(tabDoxy == g_decArgo_doxyDef)) = paramDoxy.fillValue;
      
      % add parameter variables to the profile structure
      profStruct.paramList = [paramPres paramTemp paramSal paramRawDoxy paramDoxy];
      profStruct.dateList = paramJuld;
      
      % add parameter data to the profile structure
      profStruct.data = [tabPres tabTemp tabSal tabRawDoxy tabDoxy];
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
      
      % add configuration mission number
      configMissionNumber = get_config_mission_number_argos( ...
         a_cycleNum, a_repRateMetaData, a_decoderId);
      if (~isempty(configMissionNumber))
         profStruct.configMissionNumber = configMissionNumber;
      end

      % add profile date and location information
      [profStruct] = add_profile_date_and_location_argos( ...
         profStruct, a_floatSurfData, a_cycleNum, a_decoderId);
            
      o_tabProfiles = [o_tabProfiles profStruct];
   end
end

return;
