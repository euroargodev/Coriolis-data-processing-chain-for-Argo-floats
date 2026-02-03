% ------------------------------------------------------------------------------
% Create the Argo profiles of decoded data.
%
% SYNTAX :
% [o_tabProfiles] = process_profiles_40x( ...
%   a_desc2ParkProf, a_ascProf, ...
%   a_cycleTimeData, a_tech2)
%
% INPUT PARAMETERS :
%   a_desc2ParkProf   : desc2park profile data
%   a_ascProf         : asc profile data
%   a_cycleTimeData   : cycle timings structure
%   a_tech2           : decoded data of technical msg #2
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
%   09/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_40x( ...
   a_desc2ParkProf, a_ascProf, ...
   a_cycleTimeData, a_tech2)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% sensor list
global g_decArgo_sensorMountedOnFloat;


if (isempty(a_desc2ParkProf) && isempty(a_ascProf))
   return
end

if (~ismember('CTD_RBR', g_decArgo_sensorMountedOnFloat))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROFILE CTD CUT OFF PRESSURE DETERMINATION

   % retrieve the pressure of the "subsurface point" (last pumped raw PTS meas)
   subSurfacePres = '';
   if (~isempty(a_tech2))
      tech2TrajData = a_tech2{3}; % tabTechTraj
      idSubsurface = find([tech2TrajData.techId] == 500000);
      if (~isempty(idSubsurface))
         % last pumped PRES measurement
         % A specific bin is created after the pressure of the ‘subsurface point’
         % (PSubsurfacePoint).so that pumped and unpumped data are not mixed in the
         % bin-averaged output values.
         subSurfacePres = tech2TrajData(idSubsurface).pres;
         presCutOffProf = subSurfacePres;
      end
   end
   if (isempty(subSurfacePres))
      % retrieve the CTD pump cut-off pressure from the configuration
      configName = 'SENSORS-SENSOR01-SPECIFIC.P0';
      ctpPumpSwitchOffPres = get_config_value_pfv2_2(configName, a_cycleTimeData.cycleNum);
      if (~isempty(ctpPumpSwitchOffPres))
         % SENSORS-SENSOR01-SPECIFIC_SBE41.P0 is CTD pump cut-off pressure we should add Poverlap = 0.5 dbar
         presCutOffProfConfig = ctpPumpSwitchOffPres + 0.5;
      else
         presCutOffProfConfig = 5 + 0.5;
      end
      presCutOffProf = presCutOffProfConfig;
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
   presCutOffProf = '';
end

if (~isempty(a_desc2ParkProf))
   for idProf = 1:length(a_desc2ParkProf)
      prof = a_desc2ParkProf(idProf);

      % primary sampling flag
      if (prof.payloadSensorNumber ~= 2)
         prof.primarySamplingProfileFlag = 1;
      else
         prof.primarySamplingProfileFlag = 0;
      end

      % positioning system
      prof.posSystem = 'GPS';

      % add profile date and location information
      % set in process_delayed_data_pfv2 once Iridium fixes are available

      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         prof.configMissionNumber = configMissionNumber;
      end

      o_tabProfiles = [o_tabProfiles prof];
   end
end

if (~isempty(a_ascProf))

   paramPres = get_netcdf_param_attributes('PRES');
   for idProf = 1:length(a_ascProf)
      prof = a_ascProf(idProf);

      % primary sampling flag
      if (prof.payloadSensorNumber ~= 2)
         prof.primarySamplingProfileFlag = 1;
      else
         prof.primarySamplingProfileFlag = 0;
      end

      % positioning system
      prof.posSystem = 'GPS';

      % CTD pump cut-off pressure
      if (~isempty(presCutOffProf))
         prof.presCutOffProf = presCutOffProf;
      end

      % add profile date and location information
      % set in process_delayed_data_pfv2 once Iridium fixes are available

      % add configuration mission number
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_cycleNum);
      if (~isempty(configMissionNumber))
         prof.configMissionNumber = configMissionNumber;
      end

      if (prof.payloadSensorNumber == 1)
         % primary profile
         if (~isempty(subSurfacePres))
            idLev = find((prof.data(:, 1) ~= paramPres.fillValue) & (prof.data(:, 1) >= subSurfacePres));
         else
            idLev = find((prof.data(:, 1) ~= paramPres.fillValue) & (prof.data(:, 1) > presCutOffProfConfig));
         end
         if (~isempty(idLev))
            idDel = setdiff(1:size(prof.data, 1), idLev);
            profPrimary = prof;
            profPrimary.data(idDel, :) = [];
            profPrimary.dates(idDel) = [];
            if (~isempty(profPrimary.datesAdj))
               profPrimary.datesAdj(idDel) = [];
            end
            o_tabProfiles = [o_tabProfiles profPrimary];
         end
         % unpumped profile
         if (~isempty(subSurfacePres))
            idLev = find((prof.data(:, 1) ~= paramPres.fillValue) & (prof.data(:, 1) < subSurfacePres));
         else
            idLev = find((prof.data(:, 1) ~= paramPres.fillValue) & (prof.data(:, 1) <= presCutOffProfConfig));
         end
         if (~isempty(idLev))
            idDel = setdiff(1:size(prof.data, 1), idLev);
            profUnpumped = prof;
            profUnpumped.primarySamplingProfileFlag = 0;
            profUnpumped.data(idDel, :) = [];
            profUnpumped.dates(idDel) = [];
            if (~isempty(profUnpumped.datesAdj))
               profUnpumped.datesAdj(idDel) = [];
            end
            o_tabProfiles = [o_tabProfiles profUnpumped];
         end
      else
         o_tabProfiles = [o_tabProfiles prof];
      end
   end
end

return
