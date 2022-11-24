% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
%    process_trajectory_data_ir_rudics_sbd2( ...
%    a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList : information (cycle #, prof #, phase #) on each received
%                       packet
%   a_tabTrajIndex    : trajectory index information
%   a_tabTrajData     : trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : N_CYCLE trajectory data
%   o_tabTechNMeas  : technical N_MEASUREMENT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
   process_trajectory_data_ir_rudics_sbd2( ...
   a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];

if (~isempty(a_tabTrajIndex))
   % process data for N_MEASUREMENT arrays
   [o_tabTrajNMeas, o_tabTrajNMeasRpp, o_tabTechNMeas] = ...
      process_n_meas_for_trajectory_data( ...
      a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData);
   
   % process data for N_CYCLE arrays
   [o_tabTrajNCycle] = process_n_cycle_for_trajectory_data( ...
      a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData, o_tabTrajNMeasRpp);
end

return

% ------------------------------------------------------------------------------
% Process N_MEASUREMENT trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNMeasRpp, o_tabTechNMeas] = ...
%    process_n_meas_for_trajectory_data( ...
%    a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList : information (cycle #, prof #, phase #) on each received
%                       packet
%   a_tabTrajIndex    : trajectory index information
%   a_tabTrajData     : trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas    : trajectory N_MEASUREMENT data
%   o_tabTrajNMeasRpp : trajectory N_MEASUREMENT data associated to RPP
%   o_tabTechNMeas    : technical N_MEASUREMENT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNMeasRpp, o_tabTechNMeas] = ...
   process_n_meas_for_trajectory_data( ...
   a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNMeasRpp = [];
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseInitNewCy;
global g_decArgo_phaseInitNewProf;
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseAscEmerg;
global g_decArgo_phaseDataProc;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfProf;
global g_decArgo_phaseEndOfLife;
global g_decArgo_phaseEmergencyAsc;
global g_decArgo_phaseUserDialog;

% global default values
global g_decArgo_argosLonDef;

% global measurement codes
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
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
global g_MC_TST;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

% global time status
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;


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
      techNMeasStruct = get_traj_n_meas_init_struct(cycleNum, profNum);
      
      measData = [];
      
      %%%%%%%%%%%%%%%%%%%%%%
      % data before the dive
      
      % collect the SBD dates of the packets (unfortunately msg types 254 and
      % 255 have no phase information and cannot be used, because they can be
      % received during a second Iridium session or during an usual
      % transmission)
      idPack = find( ...
         (a_cyProfPhaseList(:, 3) == cycleNum) & ...
         (a_cyProfPhaseList(:, 4) == profNum) & ...
         ((a_cyProfPhaseList(:, 5) == g_decArgo_phasePreMission) | ...
         (a_cyProfPhaseList(:, 5) == g_decArgo_phaseSurfWait)));
      packTimes = a_cyProfPhaseList(idPack, 6);
      
      if (~isempty(packTimes))
         
         if (any(a_cyProfPhaseList(idPack, 5) == g_decArgo_phaseSurfWait) && ...
               (cycleNum == 0) && (profNum == 0))
            % transmission start time
            measStruct = create_one_meas_float_time(g_MC_TST, -1, g_JULD_STATUS_9, 0);
            measStruct.cyclePhase = g_decArgo_phaseSurfWait;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
         
         % first message time
         [firstMsgTime, idMin] = min(packTimes);
         measStruct = create_one_meas_surface(g_MC_FMT, ...
            firstMsgTime, ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         measStruct.cyclePhase = a_cyProfPhaseList(idPack(idMin), 5);
         measData = [measData; measStruct];
         
         % collect the float tech msg of the prelude or/and the second iridium
         % session
         idPackTech  = find( ...
            (a_tabTrajIndex(:, 1) == 253) & ...
            (a_tabTrajIndex(:, 2) == cycleNum) & ...
            (a_tabTrajIndex(:, 3) == profNum) & ...
            ((a_tabTrajIndex(:, 4) == g_decArgo_phasePreMission) | ...
            (a_tabTrajIndex(:, 4) == g_decArgo_phaseSurfWait)));
         
         if (~isempty(idPackTech))
            
            % GPS locations
            for idP = 1:length(idPackTech)
               id = idPackTech(idP);
               
               if (a_tabTrajData{id}.gpsLon ~= g_decArgo_argosLonDef)
                  measStruct = create_one_meas_surface(g_MC_Surface, ...
                     a_tabTrajData{id}.gpsDate, ...
                     a_tabTrajData{id}.gpsLon, ...
                     a_tabTrajData{id}.gpsLat, ...
                     a_tabTrajData{id}.gpsAccuracy, ...
                     '', ...
                     a_tabTrajData{id}.gpsQc, ...
                     1);
                  measStruct.cyclePhase = a_tabTrajIndex(id, 4);
                  measData = [measData; measStruct];
               end
            end
         end
         
         % last message time
         [lastMsgTime, idMax] = max(packTimes);
         measStruct = create_one_meas_surface(g_MC_LMT, ...
            lastMsgTime, ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         measStruct.cyclePhase = a_cyProfPhaseList(idPack(idMax), 5);
         measData = [measData; measStruct];
         
         % sort the data by date
         measDates = [measData.juld];
         [measDates, idSort] = sort(measDates);
         measData = measData(idSort);
         
         % store the data
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
         measData = [];
         
         % transmission end time
         if (any(a_cyProfPhaseList(idPack, 5) == g_decArgo_phaseSurfWait) && ...
               (cycleNum == 0) && (profNum == 0))
            measStruct = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, 0);
            measStruct.cyclePhase = g_decArgo_phaseSurfWait;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%
      % data during the dive
      
      % check that deep data have been received
      idPackDeepData = find( ...
         ((a_cyProfPhaseList(:, 1) == 0) | ...
         (a_cyProfPhaseList(:, 1) == 250) | ...
         (a_cyProfPhaseList(:, 1) == 252)) & ...
         (a_cyProfPhaseList(:, 3) == cycleNum) & ...
         (a_cyProfPhaseList(:, 4) == profNum));
      
      if (~isempty(idPackDeepData))
         
         % technical information
         idPackTech  = find( ...
            (a_tabTrajIndex(:, 1) == 253) & ...
            (a_tabTrajIndex(:, 2) == cycleNum) & ...
            (a_tabTrajIndex(:, 3) == profNum) & ...
            (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
         
         if (~isempty(idPackTech))
            
            % the float technical message has been received
            if (length(idPackTech) > 1)
               fprintf('WARNING: Float #%d Cycle #%d Prof #%d: %d float tech messages received after the dive (only the last one is considered)\n', ...
                  g_decArgo_floatNum, cycleNum, profNum, length(idPackTech));
               idPackTech = idPackTech(end);
            end
            
            % buoyancy reduction start date
            measStruct = create_one_meas_float_time(g_MC_CycleStart, a_tabTrajData{idPackTech}.buoyancyRedStartDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % descent to park start time
            measStruct = create_one_meas_float_time(g_MC_DST, a_tabTrajData{idPackTech}.descentToParkStartDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % first stab time and pres
            if (~isempty(a_tabTrajData{idPackTech}.firstStabDate))
               measStruct = create_one_meas_float_time(g_MC_FST, a_tabTrajData{idPackTech}.firstStabDate, g_JULD_STATUS_2, 0);
               paramPres = get_netcdf_param_attributes('PRES');
               paramPres.resolution = single(10);
               measStruct.paramList = paramPres;
               measStruct.paramData = a_tabTrajData{idPackTech}.firstStabPres;
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            % spy pressure measurements during descent to park
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyInDescToPark, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyInDescToPark, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
               end
            end
            
            % dated measurements during descent to park
            
            % dated measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_DescProf, dates(idM), g_JULD_STATUS_2, 0);
                  measStruct.paramList = a_tabTrajData{id}.paramList;
                  measStruct.paramNumberWithSubLevels = a_tabTrajData{id}.paramNumberWithSubLevels;
                  measStruct.paramNumberOfSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels;
                  measStruct.paramData = data(idM, :);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measStruct.sensorNumber = a_tabTrajData{id}.sensorNumber;
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
            
            % deepest bin measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 1) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
            
            if (~isempty(idPackData))
               dateFillValue = a_tabTrajData{idPackData}.dateList.fillValue;
               if (a_tabTrajData{idPackData}.dates ~= dateFillValue)
                  measStruct = create_one_meas_float_time(g_MC_DescProfDeepestBin, a_tabTrajData{idPackData}.dates, g_JULD_STATUS_2, 0);
               else
                  measStruct = get_traj_one_meas_init_struct();
                  measStruct.measCode = g_MC_DescProfDeepestBin;
               end
               measStruct.paramList = a_tabTrajData{idPackData}.paramList;
               measStruct.paramNumberWithSubLevels = a_tabTrajData{idPackData}.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = a_tabTrajData{idPackData}.paramNumberOfSubLevels;
               measStruct.paramData = a_tabTrajData{idPackData}.data;
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               measStruct.sensorNumber = a_tabTrajData{idPackData}.sensorNumber;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            % park start time
            measStruct = create_one_meas_float_time(g_MC_PST, a_tabTrajData{idPackTech}.descentToParkEndDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % max P during descent to park
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MaxPresInDescToPark;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_tabTrajData{idPackTech}.maxPDuringDescentToPark;
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % spy pressure measurements during drift at park
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseParkDrift));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyAtPark, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyAtPark, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
               end
            end
            
            % dated measurements during drift at park
            
            % dated measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseParkDrift));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_DriftAtPark, dates(idM), g_JULD_STATUS_2, 0);
                  measStruct.paramList = a_tabTrajData{id}.paramList;
                  measStruct.paramNumberWithSubLevels = a_tabTrajData{id}.paramNumberWithSubLevels;
                  measStruct.paramNumberOfSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels;
                  measStruct.paramData = data(idM, :);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measStruct.sensorNumber = a_tabTrajData{id}.sensorNumber;
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
            
            % RPP (mean value of each parameter during drift at park)
            
            % collect the drift measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
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
               listParam = a_tabTrajData{id}.paramList;
               for idParam = 1:length(listParam)
                  paramName = listParam(idParam).name;
                  
                  if (~isempty(paramList))
                     
                     idF1 = find(strcmp(paramName, {paramList.name}) == 1);
                     if (isempty(idF1))
                        
                        paramList = [paramList a_tabTrajData{id}.paramList(idParam)];
                        
                        nbSubLevels = 1;
                        idF2 = find(a_tabTrajData{id}.paramNumberWithSubLevels == idParam);
                        if (~isempty(idF2))
                           paramNumberWithSubLevels = [paramNumberWithSubLevels length(paramList)];
                           nbSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels(idF2);
                           paramNumberOfSubLevels = [paramNumberOfSubLevels nbSubLevels];
                        end
                        
                        paramData = [paramData {a_tabTrajData{id}.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1))}];
                        offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
                     else
                        
                        nbSubLevels = 1;
                        idF2 = find(a_tabTrajData{id}.paramNumberWithSubLevels == idParam);
                        if (~isempty(idF2))
                           nbSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels(idF2);
                        end
                        
                        data = a_tabTrajData{id}.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        
                        paramData{idF1} = [paramData{idF1}; data];
                        offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
                     end
                  else
                     
                     paramList = [paramList a_tabTrajData{id}.paramList(idParam)];
                     
                     nbSubLevels = 1;
                     idF2 = find(a_tabTrajData{id}.paramNumberWithSubLevels == idParam);
                     if (~isempty(idF2))
                        paramNumberWithSubLevels = [paramNumberWithSubLevels length(paramList)];
                        nbSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels(idF2);
                        paramNumberOfSubLevels = [paramNumberOfSubLevels nbSubLevels];
                     end
                     
                     paramData = [paramData {a_tabTrajData{id}.data(:, ...
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
                  nbSubLevels = paramNumberWithSubLevels(idF);
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
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               % we cannot assign only one sensor number to this measurement
               % => we cannot report the QC = '4' for ko sensors for some of the
               % measuremenst
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
               
               trajNMeasStructRpp.tabMeas = [trajNMeasStructRpp.tabMeas; measStruct];
            end
            
            % min P during drift at park
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MinPresInDriftAtPark;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_tabTrajData{idPackTech}.minPDuringDriftAtPark;
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % max P during drift at park
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MaxPresInDriftAtPark;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_tabTrajData{idPackTech}.maxPDuringDriftAtPark;
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % park end time
            measStruct = create_one_meas_float_time(g_MC_PET, a_tabTrajData{idPackTech}.descentToProfStartDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % spy pressure measurements during descent to prof
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prof));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyInDescToProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyInDescToProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
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
            
            % deep park start time
            measStruct = create_one_meas_float_time(g_MC_DPST, a_tabTrajData{idPackTech}.descentToProfEndDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % spy pressure measurements during drift at prof
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseProfDrift));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyAtProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyAtProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
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
            
            % max P during descent to prof
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MaxPresInDescToProf;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_tabTrajData{idPackTech}.maxPDuringDescentToProf;
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % min P during drift at prof
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MinPresInDriftAtProf;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_tabTrajData{idPackTech}.minPDuringDriftAtProf;
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % max P during drift at prof
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_MaxPresInDriftAtProf;
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_tabTrajData{idPackTech}.maxPDuringDriftAtProf;
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % ascent start time
            measStruct = create_one_meas_float_time(g_MC_AST, a_tabTrajData{idPackTech}.ascentStartDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % deepest bin measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 1) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
            
            if (~isempty(idPackData))
               dateFillValue = a_tabTrajData{idPackData}.dateList.fillValue;
               if (a_tabTrajData{idPackData}.dates ~= dateFillValue)
                  measStruct = create_one_meas_float_time(g_MC_AscProfDeepestBin, a_tabTrajData{idPackData}.dates, g_JULD_STATUS_2, 0);
               else
                  measStruct = get_traj_one_meas_init_struct();
                  measStruct.measCode = g_MC_AscProfDeepestBin;
               end
               measStruct.paramList = a_tabTrajData{idPackData}.paramList;
               measStruct.paramNumberWithSubLevels = a_tabTrajData{idPackData}.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = a_tabTrajData{idPackData}.paramNumberOfSubLevels;
               measStruct.paramData = a_tabTrajData{idPackData}.data;
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               measStruct.sensorNumber = a_tabTrajData{idPackData}.sensorNumber;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            % spy pressure measurements during ascent to surface
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               ((a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf) | ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscEmerg) | ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseEmergencyAsc)));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyInAscProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyInAscProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
               end
            end
            
            % dated measurements during ascent
            
            % dated measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_AscProf, dates(idM), g_JULD_STATUS_2, 0);
                  measStruct.paramList = a_tabTrajData{id}.paramList;
                  measStruct.paramNumberWithSubLevels = a_tabTrajData{id}.paramNumberWithSubLevels;
                  measStruct.paramNumberOfSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels;
                  measStruct.paramData = data(idM, :);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measStruct.sensorNumber = a_tabTrajData{id}.sensorNumber;
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
            
            % last pumped CTD measurement
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 250) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = g_MC_LastAscPumpedCtd;
               paramPres = get_netcdf_param_attributes('PRES');
               paramTemp = get_netcdf_param_attributes('TEMP');
               paramPsal = get_netcdf_param_attributes('PSAL');
               measStruct.paramList = [paramPres paramTemp paramPsal];
               measStruct.paramData = [a_tabTrajData{id}.subsurface_pres ...
                  a_tabTrajData{id}.subsurface_temp ...
                  a_tabTrajData{id}.subsurface_psal];
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            % ascent end time
            measStruct = create_one_meas_float_time(g_MC_AET, a_tabTrajData{idPackTech}.ascentEndDate, g_JULD_STATUS_2, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % transmission start time
            if (~isempty(a_tabTrajData{idPackTech}.transStartDate))
               measStruct = create_one_meas_float_time(g_MC_TST, a_tabTrajData{idPackTech}.transStartDate, g_JULD_STATUS_3, 0);
            else
               measStruct = create_one_meas_float_time(g_MC_TST, -1, g_JULD_STATUS_9, 0);
            end
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % transmission end time
            measStruct = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            % grounding information
            if (~isempty(a_tabTrajData{idPackTech}.groundingDate))
               measStruct = create_one_meas_float_time(g_MC_Grounded, a_tabTrajData{idPackTech}.groundingDate, g_JULD_STATUS_2, 0);
               paramPres = get_netcdf_param_attributes('PRES');
               paramPres.resolution = single(10);
               measStruct.paramList = paramPres;
               measStruct.paramData = a_tabTrajData{idPackTech}.groundingPres;
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            %%%%%%%%%%%%%%%%%%%%%
            % data after the dive
            
            if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum))
               
               % collect the SBD dates of the packets (unfortunately msg types 254 and
               % 255 have no phase information and cannot be used, because they can be
               % received during a second Iridium session or during an usual
               % transmission)
               idPack = find( ...
                  ((a_cyProfPhaseList(:, 1) == 253) & ...
                  (a_cyProfPhaseList(:, 3) == cycleNum) & ...
                  (a_cyProfPhaseList(:, 4) == profNum) & ...
                  (a_cyProfPhaseList(:, 5) == g_decArgo_phaseSatTrans)) | ...
                  (((a_cyProfPhaseList(:, 1) == 0) | ...
                  (a_cyProfPhaseList(:, 1) == 250) | ...
                  (a_cyProfPhaseList(:, 1) == 252)) & ...
                  (a_cyProfPhaseList(:, 3) == cycleNum) & ...
                  (a_cyProfPhaseList(:, 4) == profNum)));
               packTimes = a_cyProfPhaseList(idPack, 6);
               
               if (~isempty(packTimes))
                  
                  % first message time
                  measStruct = create_one_meas_surface(g_MC_FMT, ...
                     min(packTimes), ...
                     g_decArgo_argosLonDef, [], [], [], [], 1);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  % GPS locations
                  gpsDate = [];
                  gpsLon = [];
                  gpsLat = [];
                  gpsValid = [];
                  
                  idPackTech2  = find( ...
                     (a_tabTrajIndex(:, 1) == 253) & ...
                     (a_tabTrajIndex(:, 2) == cycleNum) & ...
                     (a_tabTrajIndex(:, 3) == profNum) & ...
                     (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
                  
                  for idP = 1:length(idPackTech2)
                     id = idPackTech2(idP);
                     
                     if (a_tabTrajData{id}.gpsLon ~= g_decArgo_argosLonDef)
                        measStruct = create_one_meas_surface(g_MC_Surface, ...
                           a_tabTrajData{id}.gpsDate, ...
                           a_tabTrajData{id}.gpsLon, ...
                           a_tabTrajData{id}.gpsLat, ...
                           a_tabTrajData{id}.gpsAccuracy, ...
                           '', ...
                           a_tabTrajData{id}.gpsQc, ...
                           1);
                        measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                        measData = [measData; measStruct];
                     end
                  end
                  
                  % last message time
                  measStruct = create_one_meas_surface(g_MC_LMT, ...
                     max(packTimes), ...
                     g_decArgo_argosLonDef, [], [], [], [], 1);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  % sort the data by date
                  measDates = [measData.juld];
                  [measDates, idSort] = sort(measDates);
                  measData = measData(idSort);
                  
                  % store the data
                  trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
                  measData = [];
               end
            end
         else
            
            % the float technical message has not been received
            
            % dated measurements during descent to park
            
            % dated measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_DescProf, dates(idM), g_JULD_STATUS_2, 0);
                  measStruct.paramList = a_tabTrajData{id}.paramList;
                  measStruct.paramNumberWithSubLevels = a_tabTrajData{id}.paramNumberWithSubLevels;
                  measStruct.paramNumberOfSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels;
                  measStruct.paramData = data(idM, :);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measStruct.sensorNumber = a_tabTrajData{id}.sensorNumber;
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
            
            % deepest bin measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 1) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prk));
            
            if (~isempty(idPackData))
               dateFillValue = a_tabTrajData{idPackData}.dateList.fillValue;
               if (a_tabTrajData{idPackData}.dates ~= dateFillValue)
                  measStruct = create_one_meas_float_time(g_MC_DescProfDeepestBin, a_tabTrajData{idPackData}.dates, g_JULD_STATUS_2, 0);
               else
                  measStruct = get_traj_one_meas_init_struct();
                  measStruct.measCode = g_MC_DescProfDeepestBin;
               end
               measStruct.paramList = a_tabTrajData{idPackData}.paramList;
               measStruct.paramNumberWithSubLevels = a_tabTrajData{idPackData}.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = a_tabTrajData{idPackData}.paramNumberOfSubLevels;
               measStruct.paramData = a_tabTrajData{idPackData}.data;
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               measStruct.sensorNumber = a_tabTrajData{idPackData}.sensorNumber;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            % spy pressure measurements during drift at park
            idPackData  = find((a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseParkDrift));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyAtPark, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyAtPark, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
               end
            end
            
            % dated measurements during drift at park
            
            % dated measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseParkDrift));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_DriftAtPark, dates(idM), g_JULD_STATUS_2, 0);
                  measStruct.paramList = a_tabTrajData{id}.paramList;
                  measStruct.paramNumberWithSubLevels = a_tabTrajData{id}.paramNumberWithSubLevels;
                  measStruct.paramNumberOfSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels;
                  measStruct.paramData = data(idM, :);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measStruct.sensorNumber = a_tabTrajData{id}.sensorNumber;
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
            
            % RPP (mean value of each parameter during drift at park)
            
            % collect the drift measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
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
               listParam = a_tabTrajData{id}.paramList;
               for idParam = 1:length(listParam)
                  paramName = listParam(idParam).name;
                  
                  if (~isempty(paramList))
                     
                     idF1 = find(strcmp(paramName, {paramList.name}) == 1);
                     if (isempty(idF1))
                        
                        paramList = [paramList a_tabTrajData{id}.paramList(idParam)];
                        
                        nbSubLevels = 1;
                        idF2 = find(a_tabTrajData{id}.paramNumberWithSubLevels == idParam);
                        if (~isempty(idF2))
                           paramNumberWithSubLevels = [paramNumberWithSubLevels length(paramList)];
                           nbSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels(idF2);
                           paramNumberOfSubLevels = [paramNumberOfSubLevels nbSubLevels];
                        end
                        
                        paramData = [paramData {a_tabTrajData{id}.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1))}];
                        offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
                     else
                        
                        nbSubLevels = 1;
                        idF2 = find(a_tabTrajData{id}.paramNumberWithSubLevels == idParam);
                        if (~isempty(idF2))
                           nbSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels(idF2);
                        end
                        
                        data = a_tabTrajData{id}.data(:, ...
                           (idParam+offsetInDataArray):(idParam+offsetInDataArray)+(nbSubLevels-1));
                        
                        paramData{idF1} = [paramData{idF1}; data];
                        offsetInDataArray = offsetInDataArray + (nbSubLevels-1);
                     end
                  else
                     
                     paramList = [paramList a_tabTrajData{id}.paramList(idParam)];
                     
                     nbSubLevels = 1;
                     idF2 = find(a_tabTrajData{id}.paramNumberWithSubLevels == idParam);
                     if (~isempty(idF2))
                        paramNumberWithSubLevels = [paramNumberWithSubLevels length(paramList)];
                        nbSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels(idF2);
                        paramNumberOfSubLevels = [paramNumberOfSubLevels nbSubLevels];
                     end
                     
                     paramData = [paramData {a_tabTrajData{id}.data(:, ...
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
                  nbSubLevels = paramNumberWithSubLevels(idF);
               end
               
               data = paramData{idParam};
               meanData = [];
               for idSL = 1:nbSubLevels
                  dataCol = data(:, idSL);
                  dataCol(find(dataCol == paramList(idParam).fillValue)) = [];
                  meanData = [meanData mean(dataCol)];
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
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
               
               trajNMeasStructRpp.tabMeas = [trajNMeasStructRpp.tabMeas; measStruct];
            end
            
            % spy pressure measurements during descent to prof
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseDsc2Prof));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyInDescToProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyInDescToProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
               end
            end
            
            % spy pressure measurements during drift at prof
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseProfDrift));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyAtProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyAtProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
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
            
            % deepest bin measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 1) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
            
            if (~isempty(idPackData))
               dateFillValue = a_tabTrajData{idPackData}.dateList.fillValue;
               if (a_tabTrajData{idPackData}.dates ~= dateFillValue)
                  measStruct = create_one_meas_float_time(g_MC_AscProfDeepestBin, a_tabTrajData{idPackData}.dates, g_JULD_STATUS_2, 0);
               else
                  measStruct = get_traj_one_meas_init_struct();
                  measStruct.measCode = g_MC_AscProfDeepestBin;
               end
               measStruct.paramList = a_tabTrajData{idPackData}.paramList;
               measStruct.paramNumberWithSubLevels = a_tabTrajData{idPackData}.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = a_tabTrajData{idPackData}.paramNumberOfSubLevels;
               measStruct.paramData = a_tabTrajData{idPackData}.data;
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               measStruct.sensorNumber = a_tabTrajData{idPackData}.sensorNumber;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            % spy pressure measurements during ascent to surface
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 252) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
            
            for idspyMeas = 1:length(idPackData)
               id = idPackData(idspyMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_SpyInAscProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = find(strcmp('PRES', {a_tabTrajData{id}.paramList.name}));
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  measStruct = create_one_meas_float_time(g_MC_SpyInAscProf, dates(idM), g_JULD_STATUS_2, 0);
                  idF = setdiff(1:length(a_tabTrajData{id}.paramList), idF);
                  measStruct.paramList = a_tabTrajData{id}.paramList(idF);
                  measStruct.paramData = data(idM, idF);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStruct];
               end
            end
            
            % dated measurements during ascent
            
            % dated measurements
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 0) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum) & ...
               (a_tabTrajIndex(:, 4) == g_decArgo_phaseAscProf));
            
            for idMeas = 1:length(idPackData)
               id = idPackData(idMeas);
               dates = a_tabTrajData{id}.dates;
               data = a_tabTrajData{id}.data;
               
               for idM = 1:length(dates)
                  measStruct = create_one_meas_float_time(g_MC_AscProf, dates(idM), g_JULD_STATUS_2, 0);
                  measStruct.paramList = a_tabTrajData{id}.paramList;
                  measStruct.paramNumberWithSubLevels = a_tabTrajData{id}.paramNumberWithSubLevels;
                  measStruct.paramNumberOfSubLevels = a_tabTrajData{id}.paramNumberOfSubLevels;
                  measStruct.paramData = data(idM, :);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measStruct.sensorNumber = a_tabTrajData{id}.sensorNumber;
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
            
            % last pumped CTD measurement
            idPackData  = find( ...
               (a_tabTrajIndex(:, 1) == 250) & ...
               (a_tabTrajIndex(:, 2) == cycleNum) & ...
               (a_tabTrajIndex(:, 3) == profNum));
            
            if (~isempty(idPackData))
               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = g_MC_LastAscPumpedCtd;
               paramPres = get_netcdf_param_attributes('PRES');
               paramTemp = get_netcdf_param_attributes('TEMP');
               paramPsal = get_netcdf_param_attributes('PSAL');
               measStruct.paramList = [paramPres paramTemp paramPsal];
               measStruct.paramData = [a_tabTrajData{idPackData}.subsurface_pres ...
                  a_tabTrajData{idPackData}.subsurface_temp ...
                  a_tabTrajData{idPackData}.subsurface_psal];
               measStruct.cyclePhase = g_decArgo_phaseSatTrans;
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
            
            %%%%%%%%%%%%%%%%%%%%%
            % data after the dive
            
            if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum))
               
               % collect the SBD dates of the packets (unfortunately msg types 254 and
               % 255 have no phase information and cannot be used, because they can be
               % received during a second Iridium session or during an usual
               % transmission)
               idPack = find( ...
                  ((a_cyProfPhaseList(:, 1) == 253) & ...
                  (a_cyProfPhaseList(:, 3) == cycleNum) & ...
                  (a_cyProfPhaseList(:, 4) == profNum) & ...
                  (a_cyProfPhaseList(:, 5) == g_decArgo_phaseSatTrans)) | ...
                  (((a_cyProfPhaseList(:, 1) == 0) | ...
                  (a_cyProfPhaseList(:, 1) == 250) | ...
                  (a_cyProfPhaseList(:, 1) == 252)) & ...
                  (a_cyProfPhaseList(:, 3) == cycleNum) & ...
                  (a_cyProfPhaseList(:, 4) == profNum)));
               packTimes = a_cyProfPhaseList(idPack, 6);
               
               if (~isempty(packTimes))
                  
                  % first message time
                  measStruct = create_one_meas_surface(g_MC_FMT, ...
                     min(packTimes), ...
                     g_decArgo_argosLonDef, [], [], [], [], 1);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  % last message time
                  measStruct = create_one_meas_surface(g_MC_LMT, ...
                     max(packTimes), ...
                     g_decArgo_argosLonDef, [], [], [], [], 1);
                  measStruct.cyclePhase = g_decArgo_phaseSatTrans;
                  measData = [measData; measStruct];
                  
                  % sort the data by date
                  measDates = [measData.juld];
                  [measDates, idSort] = sort(measDates);
                  measData = measData(idSort);
                  
                  % store the data
                  trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
                  measData = [];
               end
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%
      % End Of Life data
      
      % collect the SBD dates of the packets (unfortunately msg types 254 and
      % 255 have no phase information and cannot be used, because they can be
      % received during a second Iridium session or during an usual
      % transmission)
      idPack = find( ...
         (a_cyProfPhaseList(:, 3) == cycleNum) & ...
         (a_cyProfPhaseList(:, 4) == profNum) & ...
         (a_cyProfPhaseList(:, 5) == g_decArgo_phaseEndOfLife));
      packTimes = a_cyProfPhaseList(idPack, 6);
      
      if (~isempty(packTimes))
         
         % first message time
         measStruct = create_one_meas_surface(g_MC_FMT, ...
            min(packTimes), ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         measStruct.cyclePhase = g_decArgo_phaseEndOfLife;
         measData = [measData; measStruct];
         
         idPackTech  = find( ...
            (a_tabTrajIndex(:, 1) == 253) & ...
            (a_tabTrajIndex(:, 2) == cycleNum) & ...
            (a_tabTrajIndex(:, 3) == profNum) & ...
            (a_tabTrajIndex(:, 4) == g_decArgo_phaseEndOfLife));
         
         if (~isempty(idPackTech))
            
            % GPS locations
            for idP = 1:length(idPackTech)
               id = idPackTech(idP);
               
               if (a_tabTrajData{id}.gpsLon ~= g_decArgo_argosLonDef)
                  measStruct = create_one_meas_surface(g_MC_Surface, ...
                     a_tabTrajData{id}.gpsDate, ...
                     a_tabTrajData{id}.gpsLon, ...
                     a_tabTrajData{id}.gpsLat, ...
                     a_tabTrajData{id}.gpsAccuracy, ...
                     '', ...
                     a_tabTrajData{id}.gpsQc, ...
                     1);
                  measStruct.cyclePhase = g_decArgo_phaseEndOfLife;
                  measData = [measData; measStruct];
               end
            end
         end
         
         % last message time
         measStruct = create_one_meas_surface(g_MC_LMT, ...
            max(packTimes), ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         measStruct.cyclePhase = g_decArgo_phaseEndOfLife;
         measData = [measData; measStruct];
         
         % sort the data by date
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
      if (~isempty(techNMeasStruct.tabMeas))
         o_tabTechNMeas = [o_tabTechNMeas techNMeasStruct];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Process N_CYCLE trajectory data.
%
% SYNTAX :
%  [o_tabTrajNCycle] = process_n_cycle_for_trajectory_data( ...
%    a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData, a_tabTrajNMeasRpp)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList : information (cycle #, prof #, phase #) on each received
%                       packet
%   a_tabTrajIndex    : trajectory index information
%   a_tabTrajData     : trajectory data
%   a_tabTrajNMeasRpp : trajectory N_MEASUREMENT data associated to RPP
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNCycle] = process_n_cycle_for_trajectory_data( ...
   a_cyProfPhaseList, a_tabTrajIndex, a_tabTrajData, a_tabTrajNMeasRpp)

% output parameters initialization
o_tabTrajNCycle = [];

% current float WMO number
global g_decArgo_floatNum;

% cycle phases
% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% RPP status
global g_RPP_STATUS_1;

% float configuration
global g_decArgo_floatConfig;

% global default values
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_ncDateDef;


% process each cycle and each profile
cycleProfList = unique(a_tabTrajIndex(:, 2:3), 'rows');
for idCyPr = 1:size(cycleProfList, 1)
   cycleNum = cycleProfList(idCyPr, 1);
   profNum = cycleProfList(idCyPr, 2);
   
   % collect the SBD dates of the packets (unfortunately msg types 254 and
   % 255 have no phase information and cannot be used, because they can be
   % received during a second Iridium session or during an usual
   % transmission)
   idPack = find( ...
      ((a_cyProfPhaseList(:, 1) == 253) & ...
      (a_cyProfPhaseList(:, 3) == cycleNum) & ...
      (a_cyProfPhaseList(:, 4) == profNum) & ...
      (a_cyProfPhaseList(:, 5) == g_decArgo_phaseSatTrans)) | ...
      (((a_cyProfPhaseList(:, 1) == 0) | ...
      (a_cyProfPhaseList(:, 1) == 250) | ...
      (a_cyProfPhaseList(:, 1) == 252)) & ...
      (a_cyProfPhaseList(:, 3) == cycleNum) & ...
      (a_cyProfPhaseList(:, 4) == profNum)));
   packTimes = a_cyProfPhaseList(idPack, 6);
   
   if (~isempty(packTimes))
      
      % structure to store N_CYCLE data
      trajNCycleStruct = get_traj_n_cycle_init_struct(cycleNum, profNum);
      
      % technical information
      idPackTech  = find( ...
         (a_tabTrajIndex(:, 1) == 253) & ...
         (a_tabTrajIndex(:, 2) == cycleNum) & ...
         (a_tabTrajIndex(:, 3) == profNum) & ...
         (a_tabTrajIndex(:, 4) == g_decArgo_phaseSatTrans));
      
      if (~isempty(idPackTech))
         
         % the float technical message has been received
         if (length(idPackTech) > 1)
            fprintf('WARNING: Float #%d Cycle #%d Prof #%d: %d float tech messages received after the dive (only the last one is considered)\n', ...
               g_decArgo_floatNum, cycleNum, profNum, length(idPackTech));
            idPackTech = idPackTech(end);
         end
         
         % descent to park start date
         trajNCycleStruct.juldDescentStart = a_tabTrajData{idPackTech}.descentToParkStartDate;
         trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
         
         % first stab date and pres
         if (~isempty(a_tabTrajData{idPackTech}.firstStabDate))
            trajNCycleStruct.juldFirstStab = a_tabTrajData{idPackTech}.firstStabDate;
            trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;
         end
         
         % descent to park end date
         trajNCycleStruct.juldParkStart = a_tabTrajData{idPackTech}.descentToParkEndDate;
         trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
         
         % descent to prof start date
         trajNCycleStruct.juldParkEnd = a_tabTrajData{idPackTech}.descentToProfStartDate;
         trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
         
         % descent to prof end date
         trajNCycleStruct.juldDeepParkStart = a_tabTrajData{idPackTech}.descentToProfEndDate;
         trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;
         
         % ascent start date
         trajNCycleStruct.juldAscentStart = a_tabTrajData{idPackTech}.ascentStartDate;
         trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
         
         % ascent end date
         trajNCycleStruct.juldAscentEnd = a_tabTrajData{idPackTech}.ascentEndDate;
         trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
         
         if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum))
            if (~isempty(a_tabTrajData{idPackTech}.transStartDate))
               
               % transmission start date
               trajNCycleStruct.juldTransmissionStart = a_tabTrajData{idPackTech}.transStartDate;
               trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_3;
               
               % GPS locations
               gpsDate = [a_tabTrajData{idPackTech}.gpsDate];
               
               % first message date
               trajNCycleStruct.juldFirstMessage = min(packTimes);
               trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
               
               % first location date
               trajNCycleStruct.juldFirstLocation = min(gpsDate);
               trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
               
               % last location date
               trajNCycleStruct.juldLastLocation = max(gpsDate);
               trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
               
               % last message date
               trajNCycleStruct.juldLastMessage = max(packTimes);
               trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
               
               % transmission end date
               trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;
            else
               
               % transmission start date
               trajNCycleStruct.juldTransmissionStart = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_9;
               
               % transmission end date
               trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;
            end
         end
         
         % clock offset
         trajNCycleStruct.clockOffset = 0;
         
         % data mode
         trajNCycleStruct.dataMode = 'A'; % corrected from clock drift
         
         % grounded
         if (~isempty(a_tabTrajData{idPackTech}.groundingDate))
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
      else
         
         % the float technical message has not been received
         if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum))
            
            % first message date
            trajNCycleStruct.juldFirstMessage = min(packTimes);
            trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
            
            % last message date
            trajNCycleStruct.juldLastMessage = max(packTimes);
            trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
            
            % transmission end date
            trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;
         end
         
         % clock offset
         trajNCycleStruct.clockOffset = 0;
         
         % data mode
         trajNCycleStruct.dataMode = 'A'; % corrected from clock drift
         
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
      end
      
      % phase of the float tech message
      trajNCycleStruct.cyclePhase = g_decArgo_phaseSatTrans;
      
      o_tabTrajNCycle = [o_tabTrajNCycle trajNCycleStruct];
   end
   
   % surface information
   
   if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum))
      
      for idPhase = [g_decArgo_phasePreMission g_decArgo_phaseSurfWait g_decArgo_phaseEndOfLife]
         
         idPack = find( ...
            (a_cyProfPhaseList(:, 3) == cycleNum) & ...
            (a_cyProfPhaseList(:, 4) == profNum) & ...
            (a_cyProfPhaseList(:, 5) == idPhase));
         packTimes = a_cyProfPhaseList(idPack, 6);
         
         idPackTech  = find( ...
            (a_tabTrajIndex(:, 1) == 253) & ...
            (a_tabTrajIndex(:, 2) == cycleNum) & ...
            (a_tabTrajIndex(:, 3) == profNum) & ...
            (a_tabTrajIndex(:, 4) == idPhase));
         idPackLocDate = [];
         for id = idPackTech'
            if (a_tabTrajData{id}.gpsLon ~= g_decArgo_argosLonDef)
               idPackLocDate = [idPackLocDate; id];
            end
         end
         
         if (~isempty(packTimes))
            
            % structure to store N_CYCLE data
            trajNCycleStruct = get_traj_n_cycle_init_struct(cycleNum, profNum);
            
            % first message date
            trajNCycleStruct.juldFirstMessage = min(packTimes);
            trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
            
            if (~isempty(idPackLocDate))
               
               % first location date
               trajData = [a_tabTrajData{idPackLocDate}];
               trajNCycleStruct.juldFirstLocation = min([trajData.gpsDate]);
               trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
               
               % last location date
               trajNCycleStruct.juldLastLocation = max([trajData.gpsDate]);
               trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
            end
            
            % last message date
            trajNCycleStruct.juldLastMessage = max(packTimes);
            trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
            
            % phase of the float tech message
            trajNCycleStruct.cyclePhase = idPhase;
            trajNCycleStruct.surfOnly = 1;
            if ((cycleNum == 0) && (profNum == 0))
               % to keep N_CYCLE arrays for the prelude
               trajNCycleStruct.surfOnly = 2;
               
               trajNCycleStruct.clockOffset = 0;
               trajNCycleStruct.dataMode = 'A'; % corrected from clock drift
               trajNCycleStruct.grounded = 'U';
               
               % transmission start date
               trajNCycleStruct.juldTransmissionStart = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_9;
               
               % transmission end date
               trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;
            end
            
            if (isempty(trajNCycleStruct.juldTransmissionStart))
               % set the correct status for transmission start date
               trajNCycleStruct.juldTransmissionStart = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_9;
            end
            
            if (isempty(trajNCycleStruct.juldTransmissionEnd))
               % set the correct status for  transmission end date
               trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
               trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;
            end
            
            o_tabTrajNCycle = [o_tabTrajNCycle trajNCycleStruct];
         end
      end
   end
end

return
