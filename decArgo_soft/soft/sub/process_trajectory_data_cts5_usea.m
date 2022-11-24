% ------------------------------------------------------------------------------
% Process trajectory data for CTS5-USEA floats.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_cts5_usea( ...
%    a_tabTrajIndex, a_tabTrajData, a_firstCycleNum)
%
% INPUT PARAMETERS :
%   a_tabTrajIndex  : trajectory index information
%   a_tabTrajData   : trajectory data
%   a_firstCycleNum : firts cycle to consider
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_cts5_usea( ...
   a_tabTrajIndex, a_tabTrajData, a_firstCycleNum)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

if (~isempty(a_tabTrajIndex))
   % process data for N_MEASUREMENT arrays
   [o_tabTrajNMeas, o_tabTrajNMeasRpp] = process_n_meas_for_trajectory_data( ...
      a_tabTrajIndex, a_tabTrajData);
   
   % process data for N_CYCLE arrays
   [o_tabTrajNCycle] = process_n_cycle_for_trajectory_data( ...
      a_tabTrajIndex, a_tabTrajData, o_tabTrajNMeasRpp, a_firstCycleNum);
end

return

% ------------------------------------------------------------------------------
% Process N_MEASUREMENT trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNMeasRpp] = process_n_meas_for_trajectory_data( ...
%    a_tabTrajIndex, a_tabTrajData)
%
% INPUT PARAMETERS :
%   a_tabTrajIndex : trajectory index information
%   a_tabTrajData  : trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas    : trajectory N_MEASUREMENT data
%   o_tabTrajNMeasRpp : trajectory N_MEASUREMENT data associated to RPP
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNMeasRpp] = process_n_meas_for_trajectory_data( ...
   a_tabTrajIndex, a_tabTrajData)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNMeasRpp = [];

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_SpyAtSurface;
global g_MC_TST;
global g_MC_Surface;
global g_MC_InAirSingleMeasRelativeToTET;
global g_MC_TET;
global g_MC_Grounded;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% global time status
global g_JULD_STATUS_2;


% fill value for JULD parameter
paramJuld = get_netcdf_param_attributes('JULD');

% process each cycle and each profile
cycleNumList = sort(unique(a_tabTrajIndex(:, 2)));
profNumList = sort(unique(a_tabTrajIndex(:, 3)));
for idCyc = 1:length(cycleNumList)
   cycleNum = cycleNumList(idCyc);
   for idPrf = 1:length(profNumList)
      profNum = profNumList(idPrf);
      
      % structure to store N_MEASUREMENT data
      trajNMeasStruct = get_traj_n_meas_init_struct(cycleNum, profNum);
      trajNMeasStructRpp = get_traj_n_meas_init_struct(cycleNum, profNum);
      
      measData = [];
      
      %%%%%%%%%%%%%%%%%%%%%%
      % data before the dive
      
      % GPS Locations
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_Surface) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phasePreMission));
      if (~isempty(idPackTech))
         for idP = 1:length(idPackTech)
            dataGps = a_tabTrajData{idPackTech(idP)};
            paramName = cell2mat(dataGps);
            paramName = {paramName.paramName};
            measStruct = create_one_meas_surface(g_MC_Surface, ...
               dataGps{find(strcmp(paramName, 'JULD'), 1)}.value, ...
               dataGps{find(strcmp(paramName, 'LONGITUDE'), 1)}.value, ...
               dataGps{find(strcmp(paramName, 'LATITUDE'), 1)}.value, ...
               'G', ...
               '', ...
               0, ...
               1);
            measStruct.cyclePhase = g_decArgo_phasePreMission;
            measData = [measData; measStruct];
         end
      end
      
      % sort the data by date
      if (~isempty(measData))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
      end
      
      %%%%%%%%%%%%%%%%%%%%%%
      % data during the dive
      
      % cycle start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_CycleStart) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_CycleStart, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % descent to park start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_DST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_DST, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % spy pressure measurements during descent to park
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_SpyInDescToPark) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      measDataTab = repmat(get_traj_one_meas_init_struct, length(idPackData), 1);
      for idspyMeas = 1:length(idPackData)
         id = idPackData(idspyMeas);
         data = a_tabTrajData{id};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_SpyInDescToPark, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
            g_JULD_STATUS_2);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measDataTab(idspyMeas) = measStruct;
      end
      measData = [measData; measDataTab];
      
      % first stabilization time and pressure
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_FST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         data = a_tabTrajData{idPackTech};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         % time should be missing (information reported in Events only)
         if (any(strcmp(paramName, 'JULD')))
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_FST, ...
               data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
               data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
               g_JULD_STATUS_2);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MinPresInDriftAtPark;
         end
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % dated measurements during descent to park
      
      % dated measurements
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_DescProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
      for idMeas = 1:length(idPackData)
         id = idPackData(idMeas);
         dates = a_tabTrajData{id}{:}.dates;
         datesAdj = a_tabTrajData{id}{:}.datesAdj;
         data = a_tabTrajData{id}{:}.data;
         
         measDataTab = repmat(get_traj_one_meas_init_struct, length(dates), 1);
         for idM = 1:length(dates)
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_DescProf, ...
               dates(idM), datesAdj(idM), g_JULD_STATUS_2);
            measStruct.paramList = a_tabTrajData{id}{:}.paramList;
            measStruct.paramNumberWithSubLevels = a_tabTrajData{id}{:}.paramNumberWithSubLevels;
            measStruct.paramNumberOfSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels;
            measStruct.paramData = data(idM, :);
            if (~isempty(a_tabTrajData{id}{:}.ptsForDoxy))
               measStruct.ptsForDoxy = a_tabTrajData{id}{:}.ptsForDoxy(idM, :);
            end
            measStruct.cyclePhase = g_decArgo_phaseDsc2Prk;
            measStruct.sensorNumber = a_tabTrajData{id}{:}.sensorNumber;
            measDataTab(idM) = measStruct;
         end
         measData = [measData; measDataTab];
      end
      
      % sort the data by date
      if (~isempty(measData))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
      end
      
      % deepest bin measurements
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_DescProfDeepestBin) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
      if (~isempty(idPackData))
         dateFillValue = a_tabTrajData{idPackData}{:}.dateList.fillValue;
         if (a_tabTrajData{idPackData}{:}.dates ~= dateFillValue)
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_DescProfDeepestBin, ...
               a_tabTrajData{idPackData}{:}.dates, ...
               a_tabTrajData{idPackData}{:}.datesAdj, ...
               g_JULD_STATUS_2);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_DescProfDeepestBin;
         end
         measStruct.paramList = a_tabTrajData{idPackData}{:}.paramList;
         measStruct.paramNumberWithSubLevels = a_tabTrajData{idPackData}{:}.paramNumberWithSubLevels;
         measStruct.paramNumberOfSubLevels = a_tabTrajData{idPackData}{:}.paramNumberOfSubLevels;
         measStruct.paramData = a_tabTrajData{idPackData}{:}.data;
         measStruct.ptsForDoxy = a_tabTrajData{idPackData}{:}.ptsForDoxy;
         measStruct.cyclePhase = g_decArgo_phaseDsc2Prk;
         measStruct.sensorNumber = a_tabTrajData{idPackData}{:}.sensorNumber;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % drift park start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_PST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_PST, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % spy pressure measurements during drift at park
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_SpyAtPark) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      measDataTab = repmat(get_traj_one_meas_init_struct, length(idPackData), 1);
      for idspyMeas = 1:length(idPackData)
         id = idPackData(idspyMeas);
         data = a_tabTrajData{id};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_SpyAtPark, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
            g_JULD_STATUS_2);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measDataTab(idspyMeas) = measStruct;
      end
      measData = [measData; measDataTab];
      
      % measurements during drift at park
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_DriftAtPark) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseParkDrift));
      
      measData2 = [];
      for idMeas = 1:length(idPackData)
         id = idPackData(idMeas);
         dates = a_tabTrajData{id}{:}.dates;
         datesAdj = a_tabTrajData{id}{:}.datesAdj;
         data = a_tabTrajData{id}{:}.data;
         
         for idM = 1:length(dates)
            if (dates(idM) == paramJuld.fillValue)
               measStruct = get_traj_one_meas_init_struct();
               measStruct.paramList = a_tabTrajData{id}{:}.paramList;
               measStruct.paramNumberWithSubLevels = a_tabTrajData{id}{:}.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels;
               measStruct.paramData = data(idM, :);
               if (~isempty(a_tabTrajData{id}{:}.ptsForDoxy))
                  measStruct.ptsForDoxy = a_tabTrajData{id}{:}.ptsForDoxy(idM, :);
               end
               measStruct.cyclePhase = g_decArgo_phaseParkDrift;
               measStruct.sensorNumber = a_tabTrajData{id}{:}.sensorNumber;
               measData2 = [measData2; measStruct];
            else
               [measStruct, ~] = create_one_meas_float_time_bis(g_MC_DriftAtPark, ...
                  dates(idM), datesAdj(idM), g_JULD_STATUS_2);
               measStruct.paramList = a_tabTrajData{id}{:}.paramList;
               measStruct.paramNumberWithSubLevels = a_tabTrajData{id}{:}.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels;
               measStruct.paramData = data(idM, :);
               if (~isempty(a_tabTrajData{id}{:}.ptsForDoxy))
                  measStruct.ptsForDoxy = a_tabTrajData{id}{:}.ptsForDoxy(idM, :);
               end
               measStruct.cyclePhase = g_decArgo_phaseParkDrift;
               measStruct.sensorNumber = a_tabTrajData{id}{:}.sensorNumber;
               measData = [measData; measStruct];
            end
         end
      end
      
      % sort the data by date
      if (~isempty(measData) || ~isempty(measData2))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData; measData2];
         measData = [];
      end
      
      % drift park end time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_PET) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_PET, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
      end
            
      % min pressure during drift at park
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_MinPresInDriftAtPark) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MinPresInDriftAtPark;
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(a_tabTrajData{idPackTech}{:}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % max pressure during drift at park
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_MaxPresInDriftAtPark) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDriftAtPark;
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(a_tabTrajData{idPackTech}{:}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % RPP (mean value of each parameter during drift at park)
      
      % collect the drift measurements
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_DriftAtPark) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseParkDrift));
      
      paramList = [];
      paramNumberWithSubLevels = [];
      paramNumberOfSubLevels = [];
      paramData = [];
      for idMeas = 1:length(idPackData)
         id = idPackData(idMeas);
         
         offsetInDataArray = 0;
         
         % measurements from AUX sensor should be excluded because the RPP has
         % no 'sensorNumber' information (and then AUX data cannot be excluded
         % from 'b' TRAJ file
         if (a_tabTrajData{id}{:}.sensorNumber > 100)
            continue
         end
         
         listParam = a_tabTrajData{id}{:}.paramList;
         for idParam = 1:length(listParam)
            paramName = listParam(idParam).name;
            
            if (~isempty(paramList))
               
               idF1 = find(strcmp(paramName, {paramList.name}) == 1);
               if (isempty(idF1))
                  
                  paramList = [paramList a_tabTrajData{id}{:}.paramList(idParam)];
                  
                  nbSubLevels = 1;
                  idF2 = find(a_tabTrajData{id}{:}.paramNumberWithSubLevels == idParam);
                  if (~isempty(idF2))
                     paramNumberWithSubLevels = [paramNumberWithSubLevels length(paramList)];
                     nbSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels(idF2);
                     paramNumberOfSubLevels = [paramNumberOfSubLevels nbSubLevels];
                  end
                  
                  paramData = [paramData {a_tabTrajData{id}{:}.data(:, ...
                     (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1))}];
                  offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
               else
                  
                  nbSubLevels = 1;
                  idF2 = find(a_tabTrajData{id}{:}.paramNumberWithSubLevels == idParam);
                  if (~isempty(idF2))
                     nbSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels(idF2);
                  end
                  
                  data = a_tabTrajData{id}{:}.data(:, ...
                     (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                  
                  paramData{idF1} = [paramData{idF1}; data];
                  offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
               end
            else
               
               paramList = [paramList a_tabTrajData{id}{:}.paramList(idParam)];
               
               nbSubLevels = 1;
               idF2 = find(a_tabTrajData{id}{:}.paramNumberWithSubLevels == idParam);
               if (~isempty(idF2))
                  paramNumberWithSubLevels = [paramNumberWithSubLevels length(paramList)];
                  nbSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels(idF2);
                  paramNumberOfSubLevels = [paramNumberOfSubLevels nbSubLevels];
               end
               
               paramData = [paramData {a_tabTrajData{id}{:}.data(:, ...
                  (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1))}];
               offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
               
            end
         end
      end
      
      % compute the averaged values
      nbParamRpp = 0;
      paramListRpp = [];
      paramNumberWithSubLevelsRpp = [];
      paramNumberOfSubLevelsRpp = [];
      paramDataRpp = [];
      for idParam = 1:length(paramList)
         
         nbSubLevels = 1;
         idF = find(paramNumberWithSubLevels == idParam, 1);
         if (~isempty(idF))
            nbSubLevels = paramNumberOfSubLevels(idF);
         end
         
         data = paramData{idParam};
         meanData = [];
         for idSL = 1:nbSubLevels
            dataCol = data(:, idSL);
            dataCol(find(dataCol == paramList(idParam).fillValue)) = [];
            if (~isempty(dataCol))
               meanData = [meanData mean(dataCol)];
            else
               meanData = [meanData paramList(idParam).fillValue];
            end
         end
         
         if (~isempty(meanData))
            nbParamRpp = nbParamRpp + 1;
            paramListRpp = [paramListRpp paramList(idParam)];
            if (nbSubLevels > 1)
               paramNumberWithSubLevelsRpp = [paramNumberWithSubLevelsRpp nbParamRpp];
               paramNumberOfSubLevelsRpp = [paramNumberOfSubLevelsRpp nbSubLevels];
            end
            paramDataRpp = [paramDataRpp meanData];
         end
         
      end
      
      if (~isempty(paramDataRpp))
         
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_RPP;
         measStruct.paramList = paramListRpp;
         measStruct.paramNumberWithSubLevels = paramNumberWithSubLevelsRpp;
         measStruct.paramNumberOfSubLevels = paramNumberOfSubLevelsRpp;
         measStruct.paramData = paramDataRpp;
         measStruct.cyclePhase = g_decArgo_phaseParkDrift;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNMeasStructRpp.tabMeas = [trajNMeasStructRpp.tabMeas; measStruct];
      end
      
      % spy pressure measurements during descent to prof
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_SpyInDescToProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      for idspyMeas = 1:length(idPackData)
         id = idPackData(idspyMeas);
         data = a_tabTrajData{id};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_SpyInDescToProf, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
            g_JULD_STATUS_2);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % sort the data by date
      if (~isempty(measData))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
      end
      
      % max pressure during descent to prof
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_MaxPresInDescToProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDescToProf;
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(a_tabTrajData{idPackTech}{:}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % deep park start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_DPST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_DPST, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % spy pressure measurements during drift at prof
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_SpyAtProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      measDataTab = repmat(get_traj_one_meas_init_struct, length(idPackData), 1);
      for idspyMeas = 1:length(idPackData)
         id = idPackData(idspyMeas);
         data = a_tabTrajData{id};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_SpyAtProf, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
            g_JULD_STATUS_2);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measDataTab(idspyMeas) = measStruct;
      end
      measData = [measData; measDataTab];
      
      % min pressure during drift at prof
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_MinPresInDriftAtProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MinPresInDriftAtProf;
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(a_tabTrajData{idPackTech}{:}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % max pressure during drift at park
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_MaxPresInDriftAtProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDriftAtProf;
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(a_tabTrajData{idPackTech}{:}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % ascent start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_AST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_AST, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % sort the data by date
      if (~isempty(measData))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
      end
      
      % deepest bin measurements
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_AscProfDeepestBin) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
      if (~isempty(idPackData))
         dateFillValue = a_tabTrajData{idPackData}{:}.dateList.fillValue;
         if (a_tabTrajData{idPackData}{:}.dates ~= dateFillValue)
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_AscProfDeepestBin, ...
               a_tabTrajData{idPackData}{:}.dates, ...
               a_tabTrajData{idPackData}{:}.datesAdj, ...
               g_JULD_STATUS_2);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_AscProfDeepestBin;
         end
         measStruct.paramList = a_tabTrajData{idPackData}{:}.paramList;
         measStruct.paramNumberWithSubLevels = a_tabTrajData{idPackData}{:}.paramNumberWithSubLevels;
         measStruct.paramNumberOfSubLevels = a_tabTrajData{idPackData}{:}.paramNumberOfSubLevels;
         measStruct.paramData = a_tabTrajData{idPackData}{:}.data;
         measStruct.ptsForDoxy = a_tabTrajData{idPackData}{:}.ptsForDoxy;
         measStruct.cyclePhase = g_decArgo_phaseAscProf;
         measStruct.sensorNumber = a_tabTrajData{idPackData}{:}.sensorNumber;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % spy pressure measurements during ascent to surface
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_SpyInAscProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      measDataTab = repmat(get_traj_one_meas_init_struct, length(idPackData), 1);
      for idspyMeas = 1:length(idPackData)
         id = idPackData(idspyMeas);
         data = a_tabTrajData{id};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_SpyInAscProf, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
            data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
            g_JULD_STATUS_2);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measDataTab(idspyMeas) = measStruct;
      end
      measData = [measData; measDataTab];
      
      % dated measurements during ascent to surface
      
      % dated measurements
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_AscProf) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
      for idMeas = 1:length(idPackData)
         id = idPackData(idMeas);
         dates = a_tabTrajData{id}{:}.dates;
         datesAdj = a_tabTrajData{id}{:}.datesAdj;
         data = a_tabTrajData{id}{:}.data;
         
         measDataTab = repmat(get_traj_one_meas_init_struct, length(dates), 1);
         for idM = 1:length(dates)
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_AscProf, ...
               dates(idM), datesAdj(idM), g_JULD_STATUS_2);
            measStruct.paramList = a_tabTrajData{id}{:}.paramList;
            measStruct.paramNumberWithSubLevels = a_tabTrajData{id}{:}.paramNumberWithSubLevels;
            measStruct.paramNumberOfSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels;
            measStruct.paramData = data(idM, :);
            if (~isempty(a_tabTrajData{id}{:}.ptsForDoxy))
               measStruct.ptsForDoxy = a_tabTrajData{id}{:}.ptsForDoxy(idM, :);
            end
            measStruct.cyclePhase = g_decArgo_phaseAscProf;
            measStruct.sensorNumber = a_tabTrajData{id}{:}.sensorNumber;
            measDataTab(idM) = measStruct;
         end
         measData = [measData; measDataTab];
      end
      
      % last pumped CTD measurement
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_LastAscPumpedCtd) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum));
      if (~isempty(idPackData))
         data = a_tabTrajData{idPackData}{:};
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_LastAscPumpedCtd, ...
            data.juld, data.juldAdj, g_JULD_STATUS_2);
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramPsal = get_netcdf_param_attributes('PSAL');
         measStruct.paramList = [paramPres paramTemp paramPsal];
         measStruct.paramData = single([data.pres data.temp data.psal]);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measStruct.sensorNumber = 0;
         measData = [measData; measStruct];
      end
      
      % ascent end time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_AET) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_AET, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % final pump action start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_SpyAtSurface) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_SpyAtSurface, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % IN AIR measurements
      idPackData  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      for idMeas = 1:length(idPackData)
         id = idPackData(idMeas);
         dates = a_tabTrajData{id}{:}.dates;
         datesAdj = a_tabTrajData{id}{:}.datesAdj;
         data = a_tabTrajData{id}{:}.data;
         
         measDataTab = repmat(get_traj_one_meas_init_struct, length(dates), 1);
         for idM = 1:length(dates)
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST, ...
               dates(idM), datesAdj(idM), g_JULD_STATUS_2);
            measStruct.paramList = a_tabTrajData{id}{:}.paramList;
            measStruct.paramNumberWithSubLevels = a_tabTrajData{id}{:}.paramNumberWithSubLevels;
            measStruct.paramNumberOfSubLevels = a_tabTrajData{id}{:}.paramNumberOfSubLevels;
            measStruct.paramData = data(idM, :);
            if (~isempty(a_tabTrajData{id}{:}.ptsForDoxy))
               measStruct.ptsForDoxy = a_tabTrajData{id}{:}.ptsForDoxy(idM, :);
            end
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            measStruct.sensorNumber = a_tabTrajData{id}{:}.sensorNumber;
            measDataTab(idM) = measStruct;
         end
         measData = [measData; measDataTab];
      end
      
      % transmission start time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_TST) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_TST, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         measData = [measData; measStruct];
      end
      
      % GPS Locations
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_Surface) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         for idP = 1:length(idPackTech)
            dataGps = a_tabTrajData{idPackTech(idP)};
            paramName = cell2mat(dataGps);
            paramName = {paramName.paramName};
            measStruct = create_one_meas_surface(g_MC_Surface, ...
               dataGps{find(strcmp(paramName, 'JULD'), 1)}.value, ...
               dataGps{find(strcmp(paramName, 'LONGITUDE'), 1)}.value, ...
               dataGps{find(strcmp(paramName, 'LATITUDE'), 1)}.value, ...
               'G', ...
               '', ...
               0, ...
               1);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            measData = [measData; measStruct];
         end
      end
      
      % sort the data by date
      if (~isempty(measData))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
      end
      
      % surface temperature
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_InAirSingleMeasRelativeToTET) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_InAirSingleMeasRelativeToTET;
         for idP = 1:length(idPackTech)
            measStruct.paramList = [measStruct.paramList ...
               get_netcdf_param_attributes(a_tabTrajData{idPackTech(idP)}{:}.paramName)];
            measStruct.paramData = [measStruct.paramData ...
               a_tabTrajData{idPackTech(idP)}{:}.value];
         end
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % transmission end time
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_TET) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         [measStruct, ~] = create_one_meas_float_time_bis(g_MC_TET, ...
            a_tabTrajData{idPackTech}{:}.value, ...
            a_tabTrajData{idPackTech}{:}.valueAdj, ...
            g_JULD_STATUS_2);
         measStruct.cyclePhase = g_decArgo_phaseSatTrans;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % grounding time and pressure
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_Grounded) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      if (~isempty(idPackTech))
         data = a_tabTrajData{idPackTech};
         paramName = cell2mat(data);
         paramName = {paramName.paramName};
         if (any(strcmp(paramName, 'JULD')))
            [measStruct, ~] = create_one_meas_float_time_bis(g_MC_Grounded, ...
               data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
               data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
               g_JULD_STATUS_2);
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(1);
            measStruct.paramList = paramPres;
            if (any(strcmp(paramName, 'PRES'))) % to cope with anomaly of 6902670 #112,01
               measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
         else
            % this case means that grounding information comes from Alarm
            % in TECH file (PRES only) (i.e. there is something wrong in system
            % file that prevents retrieving information from events data
            % (JULD+PRES)).
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_Grounded;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(1);
            measStruct.paramList = paramPres;
            if (any(strcmp(paramName, 'PRES'))) % to cope with anomaly of 6902670 #112,01
               measStruct.paramData = single(data{find(strcmp(paramName, 'PRES'), 1)}.value);
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%
      % End Of Life data
      
      % GPS Locations
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == g_MC_Surface) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseEndOfLife));
      if (~isempty(idPackTech))
         for idP = 1:length(idPackTech)
            dataGps = a_tabTrajData{idPackTech(idP)};
            paramName = cell2mat(dataGps);
            paramName = {paramName.paramName};
            measStruct = create_one_meas_surface(g_MC_Surface, ...
               dataGps{find(strcmp(paramName, 'JULD'), 1)}.value, ...
               dataGps{find(strcmp(paramName, 'LONGITUDE'), 1)}.value, ...
               dataGps{find(strcmp(paramName, 'LATITUDE'), 1)}.value, ...
               'G', ...
               '', ...
               0, ...
               1);
            measStruct.cyclePhase = g_decArgo_phaseEndOfLife;
            measData = [measData; measStruct];
         end
      end
      
      % sort the data by date
      if (~isempty(measData))
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
      end
      
      o_tabTrajNMeas = [o_tabTrajNMeas trajNMeasStruct];
      if (~isempty(trajNMeasStructRpp.tabMeas))
         o_tabTrajNMeasRpp = [o_tabTrajNMeasRpp trajNMeasStructRpp];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Process N_CYCLE trajectory data.
%
% SYNTAX :
%  [o_tabTrajNCycle] = process_n_cycle_for_trajectory_data( ...
%    a_tabTrajIndex, a_tabTrajData, a_tabTrajNMeasRpp, a_firstCycleNum)
%
% INPUT PARAMETERS :
%   a_tabTrajIndex    : trajectory index information
%   a_tabTrajData     : trajectory data
%   a_tabTrajNMeasRpp : trajectory N_MEASUREMENT data associated to RPP
%   a_firstCycleNum   : first cycle to consider
%
% OUTPUT PARAMETERS :
%   o_tabTrajNCycle : N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNCycle] = process_n_cycle_for_trajectory_data( ...
   a_tabTrajIndex, a_tabTrajData, a_tabTrajNMeasRpp, a_firstCycleNum)

% output parameters initialization
o_tabTrajNCycle = [];

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% clock offset management
global g_decArgo_clockOffset;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_PST;
global g_MC_PET;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AET;
global g_MC_TST;
global g_MC_Surface;
global g_MC_TET;
global g_MC_Grounded;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_4;

% RPP status
global g_RPP_STATUS_1;


% process each cycle and each profile
cycleProfList = unique(a_tabTrajIndex(:, 2:3), 'rows');
for idCyPr = 1:size(cycleProfList, 1)
   cycleNum = cycleProfList(idCyPr, 1);
   profNum = cycleProfList(idCyPr, 2);
   
   if (profNum == -1)
      continue
   end
   
   % structure to store N_CYCLE data
   trajNCycleStruct = get_traj_n_cycle_init_struct(cycleNum, profNum);
   
   % cycle start time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_CycleStart) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldCycleStart = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldCycleStart = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;
   end
   
   % descent to park start time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_DST) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldDescentStart = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldDescentStart = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
   end
   
   % first stabilization time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_FST) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      data = a_tabTrajData{idPackTech};
      paramName = cell2mat(data);
      paramName = {paramName.paramName};
      % time should be missing (information reported in Events only)
      if (any(strcmp(paramName, 'JULD')))
         if (~isempty(data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj))
            trajNCycleStruct.juldFirstStab = data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj;
         else
            trajNCycleStruct.juldFirstStab = data{find(strcmp(paramName, 'JULD'), 1)}.value;
         end
         trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;
      end
   end
   
   % drift park start time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_PST) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldParkStart = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldParkStart = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
   end
   
   % drift park end time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_PET) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldParkEnd = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldParkEnd = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
   end
   
   % deep park start time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_DPST) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldDeepParkStart = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldDeepParkStart = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;
   end
   
   % ascent start time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_AST) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldAscentStart = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldAscentStart = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
   end
   
   % ascent end time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_AET) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldAscentEnd = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldAscentEnd = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
   end
   
   % transmission start time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_TST) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldTransmissionStart = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldTransmissionStart = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_2;
   end
   
   % GPS Locations
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_Surface) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      ((a_tabTrajIndex(:, 4) == g_decArgo_phasePreMission) | ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans) | ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseEndOfLife)));
   if (~isempty(idPackTech))
      gpsDate = [];
      for idP = 1:length(idPackTech)
         dataGps = a_tabTrajData{idPackTech(idP)};
         paramName = cell2mat(dataGps);
         paramName = {paramName.paramName};
         gpsDate = [gpsDate  dataGps{find(strcmp(paramName, 'JULD'), 1)}.value];
      end
      
      % first location date
      trajNCycleStruct.juldFirstLocation = min(gpsDate);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      % last location date
      trajNCycleStruct.juldLastLocation = max(gpsDate);
      trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
   end
   
   % transmission end time
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_TET) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(idPackTech))
      if (~isempty(a_tabTrajData{idPackTech}{:}.valueAdj))
         trajNCycleStruct.juldTransmissionEnd = a_tabTrajData{idPackTech}{:}.valueAdj;
      else
         trajNCycleStruct.juldTransmissionEnd = a_tabTrajData{idPackTech}{:}.value;
      end
      trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_2;
   end
   
   % clock offset
   idClockOffset  = find( ...
      (g_decArgo_clockOffset.cycleNum == cycleNum) & ...
      (g_decArgo_clockOffset.patternNum == profNum));
   if (~isempty(idClockOffset))
      if (length(idClockOffset) > 1)
         trajNCycleStruct.clockOffset = mean(g_decArgo_clockOffset.clockOffset(idClockOffset));
      else
         trajNCycleStruct.clockOffset = g_decArgo_clockOffset.clockOffset(idClockOffset);
      end
   else
      refDate = [];
      if (~isempty(trajNCycleStruct.juldTransmissionStart))
         idPackTech  = find( ...
            (a_tabTrajIndex(:, 1) == g_MC_TST) & ...
            (a_tabTrajIndex(:, 2) == cycleNum) & ...
            (a_tabTrajIndex(:, 3) == profNum) & ...
            (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
         refDate = a_tabTrajData{idPackTech}{:}.value; % to use not adjusted value
      elseif (~isempty(trajNCycleStruct.juldAscentEnd))
         idPackTech  = find( ...
            (a_tabTrajIndex(:, 1) == g_MC_AET) & ...
            (a_tabTrajIndex(:, 2) == cycleNum) & ...
            (a_tabTrajIndex(:, 3) == profNum) & ...
            (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
         refDate = a_tabTrajData{idPackTech}{:}.value; % to use not adjusted value
      end
      
      if (~isempty(refDate))
         refDateAdj = adjust_time_cts5(refDate);
         trajNCycleStruct.clockOffset = refDate - refDateAdj;
      end
   end
   
   % data mode
   if (~isempty(trajNCycleStruct.clockOffset))
      trajNCycleStruct.dataMode = 'A'; % corrected from clock drift
   else
      trajNCycleStruct.dataMode = 'R';
   end
   
   % grounded
   idPackTech  = find( ...
      (a_tabTrajIndex(:, 1) == g_MC_Grounded) & ...
      (a_tabTrajIndex(:, 2) == cycleNum) & ...
      (a_tabTrajIndex(:, 3) == profNum) & ...
      (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
   if (~isempty(  idPackTech))
      trajNCycleStruct.grounded = 'Y';
   end
   
   % RPP
   if (~isempty(a_tabTrajNMeasRpp))
      idNMeasRpp  = find( ...
         ([a_tabTrajNMeasRpp.cycleNumber] == cycleNum) & ...
         ([a_tabTrajNMeasRpp.profileNumber] == profNum));
      
      if (~isempty(idNMeasRpp))
         tabMeas = a_tabTrajNMeasRpp(idNMeasRpp).tabMeas;
         
         idF1 = find(strcmp('PRES', {tabMeas.paramList.name}) == 1, 1);
         if (~isempty(idF1))
            presCol = idF1;
            idF2 = find(tabMeas.paramNumberWithSubLevels < idF1);
            if (~isempty(idF2))
               presCol = presCol + sum(tabMeas.paramNumberOfSubLevels(idF2)) - length(idF2);
            end
            
            trajNCycleStruct.repParkPres = tabMeas.paramData(presCol);
            trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
         end
      end
   end
   
   % phase of the float tech message
   trajNCycleStruct.cyclePhase = g_decArgo_phaseSatTrans;
   
   % set surfOnly flag
   if ((cycleNum == a_firstCycleNum) && (profNum == 0))
      % to keep N_CYCLE arrays for the prelude
      trajNCycleStruct.surfOnly = 2;
   elseif (profNum == 0)
      trajNCycleStruct.surfOnly = 1;
   else
      trajNCycleStruct.surfOnly = 0;
   end
   
   o_tabTrajNCycle = [o_tabTrajNCycle trajNCycleStruct];
end

return
