% ------------------------------------------------------------------------------
% Assign the second Iridium session to the end of previous cycle and then merge
% the first/last msg and location times.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_111( ...
%    a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : N_CYCLE trajectory data
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
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_111( ...
   a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% global measurement codes
global g_MC_DST;
global g_MC_FST;
global g_MC_PST;
global g_MC_PET;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AET;
global g_MC_TST;
global g_MC_FMT;
global g_MC_LMT;
global g_MC_TET;

% global time status
global g_JULD_STATUS_9;


% N_MEASUREMENT DATA

% change the output cycle number of the PRELUDE information
cycleNumList = [a_tabTrajNMeas.cycleNumber];
profNumList = [a_tabTrajNMeas.profileNumber];

idData = find( ...
   ((cycleNumList == 0) & (profNumList == 0)) | ...
   ((cycleNumList == 1) & (profNumList == 0)));

trajNMeasStruct = get_traj_n_meas_init_struct(-1, -1);
trajNMeasStruct.outputCycleNumber = 0;
idDel = [];
for idD = 1:length(idData)
   tabMeas = a_tabTrajNMeas(idData(idD)).tabMeas;
   if (~isempty(tabMeas))
      idPreMission = find([tabMeas.cyclePhase] == g_decArgo_phasePreMission);
      if (~isempty(idPreMission))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabMeas(idPreMission)];
         a_tabTrajNMeas(idData(idD)).tabMeas(idPreMission) = [];
         if (isempty(a_tabTrajNMeas(idData(idD)).tabMeas))
            idDel = [idDel; idData(idD)];
         end
         
         tabMeas = a_tabTrajNMeas(idData(idD)).tabMeas;
      end
      
      idSurfWait = find([tabMeas.cyclePhase] == g_decArgo_phaseSurfWait);
      if (~isempty(idSurfWait))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabMeas(idSurfWait)];
         a_tabTrajNMeas(idData(idD)).tabMeas(idSurfWait) = [];
         if (isempty(a_tabTrajNMeas(idData(idD)).tabMeas))
            idDel = [idDel; idData(idD)];
         end
      end
   end
end
a_tabTrajNMeas(idDel) = [];
if (~isempty(trajNMeasStruct.tabMeas))
   trajNMeasStruct = [a_tabTrajNMeas(1) trajNMeasStruct];
   if (length(a_tabTrajNMeas) > 1)
      trajNMeasStruct = [trajNMeasStruct a_tabTrajNMeas(2:end)];
   end
   a_tabTrajNMeas = trajNMeasStruct;
end

% assign the data of the second Iridium session to the end of the previous cycle
cycleNumList = [a_tabTrajNMeas.cycleNumber];
profNumList = [a_tabTrajNMeas.profileNumber];
uCycleNum = sort(unique(cycleNumList));
idDel = [];
for idCyc = 1:length(uCycleNum)
   cycleNum = uCycleNum(idCyc);
   if (cycleNum > 0)
      
      idData = find( ...
         (cycleNumList == cycleNum) & ...
         (profNumList == 0));
      
      for idD = 1:length(idData)
         tabMeas = a_tabTrajNMeas(idData(idD)).tabMeas;
         if (~isempty(tabMeas))
            idSurfWait = find([tabMeas.cyclePhase] == g_decArgo_phaseSurfWait);
            if (~isempty(idSurfWait))
               lastProfPrevCy = max(profNumList(find(cycleNumList == cycleNum-1)));
               if (~isempty(lastProfPrevCy))
                  idLastProfPrevCy = find( ...
                     (cycleNumList == cycleNum-1) & ...
                     (profNumList == lastProfPrevCy));
                  idLastProfPrevCy = idLastProfPrevCy(end);
                  [tabMeas(idSurfWait).cyclePhase] = deal(g_decArgo_phaseSatTrans);
                  a_tabTrajNMeas(idLastProfPrevCy).tabMeas = [ ...
                     a_tabTrajNMeas(idLastProfPrevCy).tabMeas; tabMeas(idSurfWait)];
                  a_tabTrajNMeas(idData(idD)).tabMeas(idSurfWait) = [];
                  if (isempty(a_tabTrajNMeas(idData(idD)).tabMeas))
                     idDel = [idDel; idData(idD)];
                  end
               end
            end
         end
      end
   end
end
a_tabTrajNMeas(idDel) = [];

% merge first/last msg times
cycleNumList = [a_tabTrajNMeas.cycleNumber];
profNumList = [a_tabTrajNMeas.profileNumber];
uCycleNum = sort(unique(cycleNumList));
uProfNum = sort(unique(profNumList));
for idCyc = 1:length(uCycleNum)
   cycleNum = uCycleNum(idCyc);
   for idPrf = 1:length(uProfNum)
      profNum = uProfNum(idPrf);
      
      idData = find( ...
         (cycleNumList == cycleNum) & ...
         (profNumList == profNum));
      
      if (~isempty(idData))
         
         % process first msg time
         [a_tabTrajNMeas] = merge_one_first_last_msg_time( ...
            1, a_tabTrajNMeas, idData, ...
            g_MC_FMT, g_decArgo_phaseSatTrans, g_decArgo_phaseEndOfLife);
         
         % process last msg time
         [a_tabTrajNMeas] = merge_one_first_last_msg_time( ...
            0, a_tabTrajNMeas, idData, ...
            g_MC_LMT, g_decArgo_phaseSatTrans, g_decArgo_phaseEndOfLife);
         
         if ((cycleNum == -1) && (profNum == -1))
            
            % process first msg time
            [a_tabTrajNMeas] = merge_one_first_last_msg_time( ...
               1, a_tabTrajNMeas, idData, ...
               g_MC_FMT, g_decArgo_phasePreMission, g_decArgo_phaseSurfWait);
            
            % process last msg time
            [a_tabTrajNMeas] = merge_one_first_last_msg_time( ...
               0, a_tabTrajNMeas, idData, ...
               g_MC_LMT, g_decArgo_phasePreMission, g_decArgo_phaseSurfWait);
         end
      end
   end
end

% N_CYCLE DATA

if (~isempty(a_tabTrajNCycle))
   
   % assign the data of the second Iridium session to the end of the previous cycle
   cycleNumList = [a_tabTrajNCycle.cycleNumber];
   profNumList = [a_tabTrajNCycle.profileNumber];
   uCycleNum = sort(unique(cycleNumList));
   for idCyc = 1:length(uCycleNum)
      cycleNum = uCycleNum(idCyc);
      if (cycleNum > 0)

         idData = find( ...
            (cycleNumList == cycleNum) & ...
            (profNumList == 0));
         
         if (~isempty(idData))
            idSurfWait = find([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phaseSurfWait);
            if (~isempty(idSurfWait))
               lastProfPrevCy = max(profNumList(find(cycleNumList == cycleNum-1)));
               if (~isempty(lastProfPrevCy))
                  [a_tabTrajNCycle(idData(idSurfWait)).cycleNumber] = deal(cycleNum-1);
                  [a_tabTrajNCycle(idData(idSurfWait)).profileNumber] = deal(lastProfPrevCy);
                  [a_tabTrajNCycle(idData(idSurfWait)).cyclePhase] = deal(g_decArgo_phaseSatTrans);
               end
            end
         end
      end
   end
   
   % merge first/last msg and location times
   cycleNumList = [a_tabTrajNCycle.cycleNumber];
   profNumList = [a_tabTrajNCycle.profileNumber];
   uCycleNum = sort(unique(cycleNumList));
   uProfNum = sort(unique(profNumList));
   for idCyc = 1:length(uCycleNum)
      cycleNum = uCycleNum(idCyc);
      for idPrf = 1:length(uProfNum)
         profNum = uProfNum(idPrf);
         
         idData = find( ...
            (cycleNumList == cycleNum) & ...
            (profNumList == profNum));

         if (~isempty(idData))
            
            % prelude data
            idPreMisAndSurfWait = find( ...
               ([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phasePreMission) | ...
               ([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phaseSurfWait));
            if (~isempty(idPreMisAndSurfWait))
               
               idFinal = find( ...
                  ([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phaseSurfWait) & ...
                  ([a_tabTrajNCycle(idData).surfOnly] == 2));
               if (~isempty(idFinal))
                  
                  idFinal = idFinal(end);
                  idList = idData(idPreMisAndSurfWait);
                  
                  dates = [];
                  status = [];
                  for id = idList
                     if (~isempty(a_tabTrajNCycle(id).juldFirstMessage))
                        dates = [dates; a_tabTrajNCycle(id).juldFirstMessage];
                        status = [status; a_tabTrajNCycle(id).juldFirstMessageStatus];
                     end
                  end
                  if (~isempty(dates))
                     [minDate, idMin] = min(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldFirstMessage = minDate;
                     a_tabTrajNCycle(idData(idFinal)).juldFirstMessageStatus = status(idMin);
                  end
                                    
                  dates = [];
                  status = [];
                  for id = idList
                     if (~isempty(a_tabTrajNCycle(id).juldFirstLocation))
                        dates = [dates; a_tabTrajNCycle(id).juldFirstLocation];
                        status = [status; a_tabTrajNCycle(id).juldFirstLocationStatus];
                     end
                  end
                  if (~isempty(dates))
                     [minDate, idMin] = min(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldFirstLocation = minDate;
                     a_tabTrajNCycle(idData(idFinal)).juldFirstLocationStatus = status(idMin);
                  end
                  
                  dates = [];
                  status = [];
                  for id = idData(idPreMisAndSurfWait)
                     if (~isempty(a_tabTrajNCycle(id).juldLastLocation))
                        dates = [dates; a_tabTrajNCycle(id).juldLastLocation];
                        status = [status; a_tabTrajNCycle(id).juldLastLocationStatus];
                     end
                  end
                  if (~isempty(dates))
                     [maxDate, idMax] = max(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldLastLocation = maxDate;
                     a_tabTrajNCycle(idData(idFinal)).juldLastLocationStatus = status(idMax);
                  end
                  
                  dates = [];
                  status = [];
                  for id = idList
                     if (~isempty(a_tabTrajNCycle(id).juldLastMessage))
                        dates = [dates; a_tabTrajNCycle(id).juldLastMessage];
                        status = [status; a_tabTrajNCycle(id).juldLastMessageStatus];
                     end
                  end
                  if (~isempty(dates))
                     [maxDate, idMax] = max(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldLastMessage = maxDate;
                     a_tabTrajNCycle(idData(idFinal)).juldLastMessageStatus = status(idMax);
                  end
               end
            end            
            
            % after first dive data
            idSatTransAndEol = find( ...
               ([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phaseSatTrans) | ...
               ([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phaseEndOfLife));
            if (~isempty(idSatTransAndEol))
               
               idFinal = find( ...
                  ([a_tabTrajNCycle(idData).cyclePhase] == g_decArgo_phaseSatTrans) & ...
                  ([a_tabTrajNCycle(idData).surfOnly] == 0));
               if (~isempty(idFinal))
                  
                  idFinal = idFinal(end);
                  idList = idData(idSatTransAndEol);
                  
                  dates = [];
                  status = [];
                  for id = idList
                     if (~isempty(a_tabTrajNCycle(id).juldFirstMessage))
                        dates = [dates; a_tabTrajNCycle(id).juldFirstMessage];
                        status = [status; a_tabTrajNCycle(id).juldFirstMessageStatus];
                     end
                  end
                  if (~isempty(dates))
                     [minDate, idMin] = min(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldFirstMessage = minDate;
                     a_tabTrajNCycle(idData(idFinal)).juldFirstMessageStatus = status(idMin);
                  end
                                    
                  dates = [];
                  status = [];
                  for id = idList
                     if (~isempty(a_tabTrajNCycle(id).juldFirstLocation))
                        dates = [dates; a_tabTrajNCycle(id).juldFirstLocation];
                        status = [status; a_tabTrajNCycle(id).juldFirstLocationStatus];
                     end
                  end
                  if (~isempty(dates))
                     [minDate, idMin] = min(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldFirstLocation = minDate;
                     a_tabTrajNCycle(idData(idFinal)).juldFirstLocationStatus = status(idMin);
                  end
                  
                  dates = [];
                  status = [];
                  for id = idData(idSatTransAndEol)
                     if (~isempty(a_tabTrajNCycle(id).juldLastLocation))
                        dates = [dates; a_tabTrajNCycle(id).juldLastLocation];
                        status = [status; a_tabTrajNCycle(id).juldLastLocationStatus];
                     end
                  end
                  if (~isempty(dates))
                     [maxDate, idMax] = max(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldLastLocation = maxDate;
                     a_tabTrajNCycle(idData(idFinal)).juldLastLocationStatus = status(idMax);
                  end
                  
                  dates = [];
                  status = [];
                  for id = idList
                     if (~isempty(a_tabTrajNCycle(id).juldLastMessage))
                        dates = [dates; a_tabTrajNCycle(id).juldLastMessage];
                        status = [status; a_tabTrajNCycle(id).juldLastMessageStatus];
                     end
                  end
                  if (~isempty(dates))
                     [maxDate, idMax] = max(dates);
                     a_tabTrajNCycle(idData(idFinal)).juldLastMessage = maxDate;
                     a_tabTrajNCycle(idData(idFinal)).juldLastMessageStatus = status(idMax);
                  end
               end
            end
         end
      end
   end
   
   % clean the data
   idDel = find( ...
      ([a_tabTrajNCycle.cyclePhase] == g_decArgo_phasePreMission) | ...
      (([a_tabTrajNCycle.cyclePhase] == g_decArgo_phaseSatTrans) & ([a_tabTrajNCycle.surfOnly] == 1)) | ...
      (([a_tabTrajNCycle.cyclePhase] == g_decArgo_phaseSurfWait) & ([a_tabTrajNCycle.surfOnly] ~= 2)) | ...
      ([a_tabTrajNCycle.cyclePhase] == g_decArgo_phaseEndOfLife));
   a_tabTrajNCycle(idDel) = [];
end

% check that all expected MC are present

% measurement codes expected to be in each cycle for these floats (primary and
% secondary MC experienced by Remocean floats)
expMcList = [ ...
   g_MC_DST ...
   g_MC_FST ...
   g_MC_PST ...
   g_MC_PET ...
   g_MC_DPST ...
   g_MC_AST ...
   g_MC_AET ...
   g_MC_TST ...
   g_MC_TET ...
   ];

cycleNumList = [a_tabTrajNMeas.cycleNumber];
profNumList = [a_tabTrajNMeas.profileNumber];
uCycleNum = sort(unique(cycleNumList));
uProfNum = sort(unique(profNumList));
for idCyc = 1:length(uCycleNum)
   cycleNum = uCycleNum(idCyc);
   if (cycleNum == -1)
      % cycle number = -1 is used to store launch location and date only (no
      % need to add all the expected MCs)
      continue;
   end
   for idPrf = 1:length(uProfNum)
      profNum = uProfNum(idPrf);
      
      idData = find( ...
         (cycleNumList == cycleNum) & ...
         (profNumList == profNum));
      
      if (~isempty(idData))
         
         measCodeList = [];
         for idD = 1:length(idData)
            tabMeas = a_tabTrajNMeas(idData(idD)).tabMeas;
            if (~isempty(tabMeas))
               measCodeList = [measCodeList [tabMeas.measCode]];
            end
         end
         measCodeList = unique(measCodeList);
         
         % add MCs so that all expected ones will be present
         mcList = setdiff(expMcList, measCodeList);
         measData = [];
         for idMc = 1:length(mcList)
            measStruct = create_one_meas_float_time(mcList(idMc), -1, g_JULD_STATUS_9, 0);
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            measData = [measData; measStruct];
            
            if (~isempty(a_tabTrajNCycle))
               idF = find( ...
                  ([a_tabTrajNCycle.cycleNumber] == cycleNum) & ...
                  ([a_tabTrajNCycle.profileNumber] == profNum) & ...
                  ([a_tabTrajNCycle.surfOnly] ~= 2));
               for id = 1:length(idF)
                  [a_tabTrajNCycle(idF(id))] = set_status_of_n_cycle_juld(a_tabTrajNCycle(idF(id)), mcList(idMc), g_JULD_STATUS_9);
               end
            end
         end
         
         % store the data
         if (~isempty(measData))
            a_tabTrajNMeas(idData(end)).tabMeas = [a_tabTrajNMeas(idData(end)).tabMeas; measData];
         end
      end
   end
end

% store output data
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

return;

% ------------------------------------------------------------------------------
% Merge one set of first or last msg times
%
% SYNTAX :
%  [o_tabTrajNMeas] = merge_one_first_last_msg_time( ...
%    a_first, a_tabTrajNMeas, a_idData, a_firstLastCode, a_phase1, a_phase2)
%
% INPUT PARAMETERS :
%   a_first         : first or last flag (1: first, 0: last)
%   a_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   a_idData        : data id for the current cycle and profile
%   a_firstLastCode : concerned MC code
%   a_phase1        : concerned phase #1
%   a_phase2        : concerned phase #2
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/10/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = merge_one_first_last_msg_time( ...
   a_first, a_tabTrajNMeas, a_idData, a_firstLastCode, a_phase1, a_phase2)

% output parameters initialization
o_tabTrajNMeas = [];

% process first/last msg time
firstLastJuld = [];
firstLastJuldId1 = [];
firstLastJuldId2 = [];
listFirstLastJuldId1 = [];
listFirstLastJuldId2 = [];
for idD1 = 1:length(a_idData)
   tabMeas = a_tabTrajNMeas(a_idData(idD1)).tabMeas;
   if (~isempty(tabMeas))
      idFirstLast = find(([tabMeas.measCode] == a_firstLastCode) & ...
         (([tabMeas.cyclePhase] == a_phase1) | ...
         ([tabMeas.cyclePhase] == a_phase2)));
      for idD2 = 1:length(idFirstLast)
         if (~isempty(firstLastJuld))
            if (a_first == 1)
               if (tabMeas(idFirstLast(idD2)).juld < firstLastJuld)
                  firstLastJuld = tabMeas(idFirstLast(idD2)).juld;
                  firstLastJuldId1 = a_idData(idD1);
                  firstLastJuldId2 = idFirstLast(idD2);
               end
            else
               if (tabMeas(idFirstLast(idD2)).juld > firstLastJuld)
                  firstLastJuld = tabMeas(idFirstLast(idD2)).juld;
                  firstLastJuldId1 = a_idData(idD1);
                  firstLastJuldId2 = idFirstLast(idD2);
               end
            end
         else
            firstLastJuld = tabMeas(idFirstLast(idD2)).juld;
            firstLastJuldId1 = a_idData(idD1);
            firstLastJuldId2 = idFirstLast(idD2);
         end
         
         listFirstLastJuldId1 = [listFirstLastJuldId1 a_idData(idD1)];
         listFirstLastJuldId2 = [listFirstLastJuldId2 idFirstLast(idD2)];
      end
   end
end

% sort the lists before deleting inconsistent first/last times
[listFirstLastJuldId1, idSort] = sort(listFirstLastJuldId1);
listFirstLastJuldId2 = listFirstLastJuldId2(idSort);
ulistFirstLastJuldId1 = unique(listFirstLastJuldId1);
for id = 1:length(ulistFirstLastJuldId1)
   idEq = find(listFirstLastJuldId1 == ulistFirstLastJuldId1(id));
   listFirstLastJuldId2(idEq) = sort(listFirstLastJuldId2(idEq), 'descend');
end

% delete inconsistent first/last times
for idD = 1:length(listFirstLastJuldId1)
   if ~((listFirstLastJuldId1(idD) == firstLastJuldId1) && ...
         (listFirstLastJuldId2(idD) == firstLastJuldId2))
      a_tabTrajNMeas(listFirstLastJuldId1(idD)).tabMeas(listFirstLastJuldId2(idD)) = [];
   end
end

% store output data
o_tabTrajNMeas = a_tabTrajNMeas;

return;
