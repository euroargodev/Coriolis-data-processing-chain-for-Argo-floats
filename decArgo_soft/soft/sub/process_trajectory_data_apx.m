% ------------------------------------------------------------------------------
% Process trajectory data (store all but times in the TRAJ structures).
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_apx( ...
%    a_cycleNum, ...
%    a_addLaunchData, a_floatSurfData, ...
%    a_trajData, a_parkData, a_astData, a_profData, a_surfData, ...
%    a_timeData, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cycleNum       : current cycle number
%   a_addLaunchData  : flag to add float launch time and position
%   a_floatSurfData  : float surface data structure
%   a_trajData       : trajectory data
%   a_parkData       : parking data
%   a_astData        : AST data
%   a_profData       : profile data
%   a_surfData       : surface data
%   a_timeData       : updated cycle time data structure
%   a_presOffsetData : updated pressure offset data structure
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_apx( ...
   a_cycleNum, ...
   a_addLaunchData, a_floatSurfData, ...
   a_trajData, a_parkData, a_astData, a_profData, a_surfData, ...
   a_timeData, a_presOffsetData, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global measurement codes
global g_MC_Launch;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkMean;
global g_MC_RPP;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_Surface;
global g_MC_InAirSeriesOfMeas;

% global time status
global g_JULD_STATUS_4;

% RPP status
global g_RPP_STATUS_2;
global g_RPP_STATUS_4;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT LAUNCH TIME AND POSITION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (a_addLaunchData == 1)
   
   % structure to store N_MEASUREMENT data
   trajNMeasStruct = get_traj_n_meas_init_struct(-1, -1);
      
   measStruct = create_one_meas_surface(g_MC_Launch, ...
      a_floatSurfData.launchDate, ...
      a_floatSurfData.launchLon, ...
      a_floatSurfData.launchLat, ...
      ' ', ' ', '0', 0);
   
   trajNMeasStruct.surfOnly = 1;
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
end

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);
trajNCycleStruct.grounded = 'U';

% surface data for the current cycle
cycleSurfData = a_floatSurfData.cycleData(end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POSITIONING SYSTEM TIMES AND LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Argos/Iridium locations
for idpos = 1:length(cycleSurfData.argosLocDate)
   measStruct = create_one_meas_surface(g_MC_Surface, ...
      cycleSurfData.argosLocDate(idpos), ...
      cycleSurfData.argosLocLon(idpos), ...
      cycleSurfData.argosLocLat(idpos), ...
      cycleSurfData.argosLocAcc(idpos), ...
      cycleSurfData.argosLocSat(idpos), ...
      cycleSurfData.argosLocQc(idpos), ...
      1);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

if (~isempty(cycleSurfData.argosLocDate))
   trajNCycleStruct.juldFirstLocation = cycleSurfData.argosLocDate(1);
   trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
   
   trajNCycleStruct.juldLastLocation = cycleSurfData.argosLocDate(end);
   trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEASUREMENTS SAMPLED DURING THE DRIFT AT PARKING DEPTH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_parkData))
   
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_DriftAtPark;
   measStruct.paramList = a_parkData.paramList;
   measStruct.paramData = a_parkData.data;
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REPRESENTATIVE PARKING MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (ismember(a_decoderId, [1013, 1015]))
   if (~isempty(a_parkData))
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_RPP;
      measStruct.paramList = a_parkData.paramList;
      measStruct.paramData = a_parkData.data;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      idPres = find(strcmp({measStruct.paramList.name}, 'PRES') == 1);
      if (~isempty(idPres))
         % add adjusted RPP to the N_CYCLE data
         paramDataAdj = measStruct.paramData(idPres);
         idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
         if (~isempty(idCycleStruct))
            paramDataAdj = compute_adjusted_pres(measStruct.paramData(idPres), a_presOffsetData.presOffset(idCycleStruct));
         end
         trajNCycleStruct.repParkPres = paramDataAdj;
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_4;
      end
   end
else
   if (~isempty(a_trajData))
      
      idRpMeas = find([a_trajData.measCode] == g_MC_DriftAtParkMean);
      if (~isempty(idRpMeas))
         
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_RPP;
         
         for id = 1:length(idRpMeas)
            % create the parameters
            paramName = a_trajData(idRpMeas(id)).paramName;
            paramStruct = get_netcdf_param_attributes(paramName);
            % convert decoder default values to netCDF fill values
            paramData = a_trajData(idRpMeas(id)).value;
            if (strcmp(paramName, 'PRES'))
               paramData(find(paramData == g_decArgo_presDef)) = paramStruct.fillValue;
               
               % add adjusted RPP to the N_CYCLE data
               paramDataAdj = paramData;
               idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
               if (~isempty(idCycleStruct))
                  paramDataAdj = compute_adjusted_pres(paramData, a_presOffsetData.presOffset(idCycleStruct));
               end
               
               trajNCycleStruct.repParkPres = paramDataAdj;
               trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_2;
               
            elseif (strcmp(paramName, 'TEMP'))
               paramData(find(paramData == g_decArgo_tempDef)) = paramStruct.fillValue;
            elseif (strcmp(paramName, 'PSAL'))
               paramData(find(paramData == g_decArgo_salDef)) = paramStruct.fillValue;
            else
               fprintf('ERROR: Float #%d Cycle #%d: Parameter ''%s'' not managed during storage of traj representative parking data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  paramName);
            end
            measStruct.paramList = [measStruct.paramList paramStruct];
            measStruct.paramData = [measStruct.paramData paramData];
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEASUREMENT SAMPLED AT START OF PROFILE PHASE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_astData))
   
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_AST;
   measStruct.paramList = a_astData.paramList;
   measStruct.paramData = a_astData.data;
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IN AIR MEASUREMENT SAMPLED AT THE SURFACE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_surfData))
   
   for idMeas = 1:size(a_surfData.data, 1)
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_InAirSeriesOfMeas;
      measStruct.paramList = a_surfData.paramList;
      measStruct.paramData = a_surfData.data(idMeas, :);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MISCELLANEOUS MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% deepest bin of the ascending profile
if (~isempty(a_profData))

   tabAscDeepestBin = [];
   tabAscDeepestBinPres = [];
   for idProf = 1:length(a_profData)
      profile = a_profData(idProf);
      
      % look for 'PRES' parameter index
      idPres = 1;
      while ~((idPres > length(profile.paramList)) || ...
            (strcmp(profile.paramList(idPres).name, 'PRES') == 1))
         idPres = idPres + 1;
      end
      
      if (idPres <= length(profile.paramList))
         
         profPresData = profile.data(:, idPres);
         presFillValue = profile.paramList(idPres).fillValue;
         
         idNotDef = find(profPresData ~= presFillValue);
         if (~isempty(idNotDef))
            
            idDeepest = idNotDef(1);
            
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_AscProfDeepestBin;
            
            % add parameter variables to the structure
            measStruct.paramList = profile.paramList;
            
            % add parameter data to the structure
            measStruct.paramData = profile.data(idDeepest, :);
            
            tabAscDeepestBin = [tabAscDeepestBin; measStruct];
            tabAscDeepestBinPres = [tabAscDeepestBinPres; profile.data(idDeepest, idPres)];
         end
      end
   end
   
   if (~isempty(tabAscDeepestBin))
      [~, idMax] = max(tabAscDeepestBinPres);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabAscDeepestBin(idMax)];
   end
end

% other miscellaneous measurements
if (~isempty(a_trajData))
   
   measCodeList = unique([a_trajData.measCode], 'stable');
   for idMC = 1:length(measCodeList)
      measCode = measCodeList(idMC);

      if (~ismember(measCode, [g_MC_MinPresInDriftAtPark g_MC_MaxPresInDriftAtPark]))
         
         % for these MC we should merge all the parameter measurements of a
         % given MC
         
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = measCode;
         
         idForMC = find([a_trajData.measCode] == measCode);
         for id = 1:length(idForMC)
            % create the parameters
            paramName = a_trajData(idForMC(id)).paramName;
            paramStruct = get_netcdf_param_attributes(paramName);
            % convert decoder default values to netCDF fill values
            paramData = a_trajData(idForMC(id)).value;
            if (strcmp(paramName, 'PRES'))
               paramData(find(paramData == g_decArgo_presDef)) = paramStruct.fillValue;
            elseif (strcmp(paramName, 'TEMP'))
               paramData(find(paramData == g_decArgo_tempDef)) = paramStruct.fillValue;
            elseif (strcmp(paramName, 'PSAL'))
               paramData(find(paramData == g_decArgo_salDef)) = paramStruct.fillValue;
            else
               fprintf('ERROR: Float #%d Cycle #%d: Parameter ''%s'' not managed during storage of traj miscellaneous measurements\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  paramName);
            end
            measStruct.paramList = [measStruct.paramList paramStruct];
            measStruct.paramData = [measStruct.paramData paramData];
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      else
                  
         % for these MC we should not merge all the parameter measurements of a
         % given MC

         idForMC = find([a_trajData.measCode] == measCode);
         for id = 1:length(idForMC)
            
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = measCode;
            
            % create the parameters
            paramName = a_trajData(idForMC(id)).paramName;
            paramStruct = get_netcdf_param_attributes(paramName);
            % convert decoder default values to netCDF fill values
            paramData = a_trajData(idForMC(id)).value;
            if (strcmp(paramName, 'PRES'))
               paramData(find(paramData == g_decArgo_presDef)) = paramStruct.fillValue;
            elseif (strcmp(paramName, 'TEMP'))
               paramData(find(paramData == g_decArgo_tempDef)) = paramStruct.fillValue;
            elseif (strcmp(paramName, 'PSAL'))
               paramData(find(paramData == g_decArgo_salDef)) = paramStruct.fillValue;
            else
               fprintf('ERROR: Float #%d Cycle #%d: Parameter ''%s'' not managed during storage of traj miscellaneous measurements\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  paramName);
            end
            measStruct.paramList = [measStruct.paramList paramStruct];
            measStruct.paramData = [measStruct.paramData paramData];
            
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
      end
   end
end

% add configuration mission number
if (a_cycleNum > 0) % we don't assign any configuration to cycle #0 data
   configMissionNumber = get_config_mission_number_argos( ...
      a_cycleNum, a_timeData, a_decoderId);
   if (~isempty(configMissionNumber))
      trajNCycleStruct.configMissionNumber = configMissionNumber;
   end
end

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return;
