% ------------------------------------------------------------------------------
% Process decoded data into Argo dedicated structures.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
%    process_decoded_data_pfv2( ...
%    a_decodedDataTab, a_refDay, a_decoderId, ...
%    a_tabProfiles, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, a_tabTechAuxNMeas)
%
% INPUT PARAMETERS :
%   a_decodedDataTab  : decoded data
%   a_refDay          : reference day
%   a_decoderId       : float decoder Id
%   a_tabProfiles     : input decoded profiles
%   a_tabTrajNMeas    : input decoded trajectory N_MEASUREMENT data
%   a_tabTrajNCycle   : input decoded trajectory N_CYCLE data
%   a_tabNcTechIndex  : input decoded technical index information
%   a_tabNcTechVal    : input decoded technical data
%   a_tabTechNMeas    : input decoded technical N_MEASUREMENT data
%   a_tabTechAuxNMeas : input decoded technical N_MEASUREMENT AUX data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles     : output decoded profiles
%   o_tabTrajNMeas    : output decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle   : output decoded trajectory N_CYCLE data
%   o_tabNcTechIndex  : output decoded technical index information
%   o_tabNcTechVal    : output decoded technical data
%   o_tabTechNMeas    : output decoded technical N_MEASUREMENT data
%   o_tabTechAuxNMeas : output decoded technical N_MEASUREMENT AUX data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
   process_decoded_data_pfv2( ...
   a_decodedDataTab, a_cycleNum, a_deepCycleFlag, a_decoderId, ...
   a_tabProfiles, ...
   a_tabTrajNMeas, a_tabTrajNCycle, ...
   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, a_tabTechAuxNMeas)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;
o_tabTechNMeas = a_tabTechNMeas;
o_tabTechAuxNMeas = a_tabTechAuxNMeas;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% generate nc flag
global g_decArgo_generateNcFlag;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;
g_decArgo_firstDeepCycleNumber = 1;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% clock offset management
global g_decArgo_clockOffset;


% no data to process
if (isempty(a_decodedDataTab))
   return
end

g_decArgo_generateNcFlag = 1;

g_decArgo_cycleNum = a_cycleNum;

if (g_decArgo_realtimeFlag == 1)
   % update the reports structure cycle list
   g_decArgo_reportStruct = add_cycle_number_in_report_struct(g_decArgo_reportStruct, g_decArgo_cycleNum);
end

fprintf('DEC_INFO: Float #%d Cycle #%d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

% process decoded data

switch (a_decoderId)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {401, 402}
      % Arvor PFV2 8.01
      % Arvor PFV2 8.02

      % get decoded data
      [tabSelfTest, tabTech1, tabTech2, tabEol, ...
         dataDesc2Park, dataParkDrift, dataDesc2Prof, dataProfDrift, dataAsc, dataInAir, ...
         tabConfig] = ...
         get_decoded_data_pfv2(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current cycle
      if (g_decArgo_cycleNum > 0)
         set_float_config_pfv2(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if (~isempty(tabConfig))
         update_float_config_pfv2(tabConfig, g_decArgo_cycleNum);
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_pfv2(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_pfv2(tabSelfTest, tabTech1, tabTech2, tabEol, g_decArgo_cycleNum);

      % create profiles of sampled measurements
      [desc2ParkProf, parkDriftProf, desc2ProfProf, profDriftProf, ascProf, inAirProf] = ...
         create_prv_profile_40x(dataDesc2Park, dataParkDrift, dataDesc2Prof, dataProfDrift, dataAsc, dataInAir);

      if (ismember('OPTODE', g_decArgo_sensorMountedOnFloat))
         % compute DOXY and PPOX_DOXY
         [desc2ParkProf, parkDriftProf, desc2ProfProf, profDriftProf, ascProf, inAirProf] = ...
            compute_DOXY_and_PPOX_DOXY_pfv2(desc2ParkProf, parkDriftProf, desc2ProfProf, profDriftProf, ascProf, inAirProf);
      end

      % compute the main dates of the cycle
      cycleTimeData = compute_prv_dates_40x(tabSelfTest, tabTech1, tabTech2, tabEol, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [desc2ParkProf, parkDriftProf, desc2ProfProf, profDriftProf, ascProf, inAirProf, ...
         tabSelfTest, tabTech1, tabTech2, tabEol, ...
         cycleTimeData] = adjust_clock_offset_pfv2( ...
         desc2ParkProf, parkDriftProf, desc2ProfProf, profDriftProf, ascProf, inAirProf, ...
         tabSelfTest, tabTech1, tabTech2, tabEol, ...
         cycleTimeData, g_decArgo_clockOffset);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % PROF NetCDF file

      % process profile data for PROF NetCDF file
      tabProfiles = [];
      if ~(isempty(desc2ParkProf) && isempty(ascProf))

         tabProfiles = process_profiles_40x( ...
            desc2ParkProf, ascProf, ...
            cycleTimeData, tabTech2);

         % add the vertical sampling scheme from configuration information
         tabProfiles = add_vertical_sampling_scheme_pfv2(tabProfiles);

         % print = 0;
         % if (print == 1)
         %    if (~isempty(tabProfiles))
         %       fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
         %          g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
         %       for idP = 1:length(tabProfiles)
         %          prof = tabProfiles(idP);
         %          paramList = prof.paramList;
         %          paramList = sprintf('%s ', paramList.name);
         %          profLength = size(prof.data, 1);
         %          fprintf('   ->%2d: dir=%c length=%d param=(%s)\n', ...
         %             idP, prof.direction, ...
         %             profLength, paramList(1:end-1));
         %          fprintf('   ->%2d: VSS: ''%s''\n', ...
         %             idP, prof.vertSamplingScheme);
         %       end
         %    else
         %       fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
         %          g_decArgo_floatNum, g_decArgo_cycleNum);
         %    end
         % end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TRAJ NetCDF file

      % process trajectory data for TRAJ NetCDF file
      [tabTrajNMeas, tabTrajNCycle, tabTechNMeas, tabTechAuxNMeas] = process_trajectory_data_40x( ...
         g_decArgo_cycleNum, a_deepCycleFlag, ...
         g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
         cycleTimeData, ...
         tabSelfTest, tabTech1, tabTech2, tabEol, ...
         tabProfiles, parkDriftProf, desc2ProfProf, profDriftProf, inAirProf);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TECH NetCDF file

      % store NetCDF technical data
      [tabNcTechIndex, tabNcTechVal, tabTechNMeas, tabTechAuxNMeas] = store_tech_data_for_nc_pfv2( ...
         tabSelfTest, tabTech1, tabTech2, tabEol, g_decArgo_cycleNum, tabTechNMeas, tabTechAuxNMeas);

      % store information on received file types
      [tabNcTechIndex, tabNcTechVal] = store_received_file_type_info_for_nc_pfv2( ...
         a_deepCycleFlag, tabNcTechIndex, tabNcTechVal);

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in process_decoded_data_pfv2 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% output parameters
if (~isempty(tabProfiles))
   o_tabProfiles = [o_tabProfiles tabProfiles];
end
if (~isempty(tabTrajNMeas))
   o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
end
if (~isempty(tabTrajNCycle))
   o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
end
if (~isempty(tabNcTechIndex))
   o_tabNcTechIndex = [o_tabNcTechIndex; tabNcTechIndex];
end
if (~isempty(tabNcTechVal))
   o_tabNcTechVal = [o_tabNcTechVal; tabNcTechVal];
end
if (~isempty(tabTechNMeas))
   o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
end
if (~isempty(tabTechAuxNMeas))
   o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
end

return
