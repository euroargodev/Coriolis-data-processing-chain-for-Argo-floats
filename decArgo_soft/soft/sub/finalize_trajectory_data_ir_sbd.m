% ------------------------------------------------------------------------------
% Merge FMT, LMT and GPS locations and set TET for a given cycle.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    finalize_trajectory_data_ir_sbd(a_tabTrajNMeas, a_tabTrajNCycle, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = ...
   finalize_trajectory_data_ir_sbd(a_tabTrajNMeas, a_tabTrajNCycle, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% current float WMO number
global g_decArgo_floatNum;

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
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_9;

% default values
global g_decArgo_ncDateDef;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% when the transmission failed, only one mail file without attachment can be
% received (Ex: 6903177 #3 and #11); these cycles have not been processed (since
% no data has been received) however the information FMT/LMT should be added to
% the trajectory (to report that the float was at the surface and tried a
% transmission)

if (~isempty(g_decArgo_iridiumMailData))
   
   tabTrajCyNum = sort(unique([a_tabTrajNMeas.cycleNumber]));
   tabMailCyNum = sort(unique([g_decArgo_iridiumMailData.cycleNumber]));
   unseenCycles = setdiff(tabMailCyNum, tabTrajCyNum);
   for idCy = 1:length(unseenCycles)
      cycleNum = unseenCycles(idCy);
      
      [firstMsgTime, lastMsgTime] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, cycleNum);
      
      % structure to store N_MEASUREMENT data
      trajNMeasStruct = get_traj_n_meas_init_struct(cycleNum, -1);
      trajNMeasStruct.outputCycleNumber = cycleNum;
      
      % structure to store N_CYCLE data
      trajNCycleStruct = get_traj_n_cycle_init_struct(cycleNum, -1);
      trajNCycleStruct.outputCycleNumber = cycleNum;
      trajNCycleStruct.grounded = ' ';
      
      % First Message Time
      measStruct = create_one_meas_surface(g_MC_FMT, ...
         firstMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], []);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldFirstMessage = firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
      
      % Last Message Time
      measStruct = create_one_meas_surface(g_MC_LMT, ...
         lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], []);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldLastMessage = lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
      
      a_tabTrajNMeas = [a_tabTrajNMeas trajNMeasStruct];
      a_tabTrajNCycle = [a_tabTrajNCycle trajNCycleStruct];
   end
end

% N_MEASUREMENT DATA

% clean the collected data from float anomaly
% Ex: float 6901038 #272: the float transmitted twice the TECH and PARAM
% messages
idDel = [];
tabCyNum = sort(unique([a_tabTrajNMeas.cycleNumber]));
for idCy = 1:length(tabCyNum)
   cycleNum = tabCyNum(idCy);
   
   idCyDeep = find(([a_tabTrajNMeas.cycleNumber] == cycleNum) & ([a_tabTrajNMeas.surfOnly] == 0));
   if (length(idCyDeep) > 1)
      fprintf('ERROR: Float #%d cycle #%d: %d deep N_MEASUREMENT records => only the first one is considered\n', ...
         g_decArgo_floatNum, cycleNum, ...
         length(idCyDeep));
      idDel = [idDel idCyDeep(2:end)];
   end
   
   idCySurf = find(([a_tabTrajNMeas.cycleNumber] == cycleNum) & ([a_tabTrajNMeas.surfOnly] == 1));
   if (length(idCySurf) > 1)
      if (cycleNum > 1)
         % new firmware (ARN) transmits 2 tech message for cycle #0
         fprintf('INFO: Float #%d cycle #%d: %d surf N_MEASUREMENT records\n', ...
            g_decArgo_floatNum, cycleNum, ...
            length(idCySurf));
      end
      idDel = [idDel idCySurf(1:end-1)];
   end
end

% delete the corresponding records
a_tabTrajNMeas(idDel) = [];

tabCyNum = sort(unique([a_tabTrajNMeas.cycleNumber]));
for idCy = 1:length(tabCyNum)
   cycleNum = tabCyNum(idCy);
   
   idCyDeep = find(([a_tabTrajNMeas.cycleNumber] == cycleNum) & ([a_tabTrajNMeas.surfOnly] == 0));
   idCySurf = find(([a_tabTrajNMeas.cycleNumber] == cycleNum) & ([a_tabTrajNMeas.surfOnly] == 1));
   
   if (length(idCyDeep) == 1)
      if (~isempty(idCySurf))
         
         % preserve only the FMT, LMT and GPS locations of the last surface
         % record
         idF1 = find([a_tabTrajNMeas(idCyDeep).tabMeas.measCode] == g_MC_FMT);
         idF2 = find([a_tabTrajNMeas(idCySurf(end)).tabMeas.measCode] == g_MC_FMT);
         a_tabTrajNMeas(idCyDeep).tabMeas(idF1) = a_tabTrajNMeas(idCySurf(end)).tabMeas(idF2);
         
         idF1 = find([a_tabTrajNMeas(idCyDeep).tabMeas.measCode] == g_MC_LMT);
         idF2 = find([a_tabTrajNMeas(idCySurf(end)).tabMeas.measCode] == g_MC_LMT);
         a_tabTrajNMeas(idCyDeep).tabMeas(idF1) = a_tabTrajNMeas(idCySurf(end)).tabMeas(idF2);
         
         idF1 = find([a_tabTrajNMeas(idCyDeep).tabMeas.measCode] == g_MC_Surface);
         idF2 = find([a_tabTrajNMeas(idCySurf(end)).tabMeas.measCode] == g_MC_Surface);
         a_tabTrajNMeas(idCyDeep).tabMeas(idF1) = [];
         a_tabTrajNMeas(idCyDeep).tabMeas = [a_tabTrajNMeas(idCyDeep).tabMeas; a_tabTrajNMeas(idCySurf(end)).tabMeas(idF2)];
         
         a_tabTrajNMeas(idCySurf) = [];
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [a_tabTrajNMeas(idCyDeep)] = sort_trajectory_data(a_tabTrajNMeas(idCyDeep), a_decoderId);
      end
   end
   
end

% assign cycle start time of the current cycle to the TET of the previous cycle
tabCyNum = sort(unique([a_tabTrajNMeas.cycleNumber]));
for idCy = 1:length(tabCyNum)
   cycleNum = tabCyNum(idCy);
   
   idC = find([a_tabTrajNMeas.cycleNumber] == cycleNum);
   idF1 = find([a_tabTrajNMeas(idC).tabMeas.measCode] == g_MC_CycleStart);
   if (~isempty(idF1))
      idCyPrec = find([a_tabTrajNMeas.cycleNumber] == cycleNum-1);
      if (~isempty(idCyPrec))
         idF2 = find([a_tabTrajNMeas(idCyPrec).tabMeas.measCode] == g_MC_TET);
         if (~isempty(idF2))
            
            measStruct = create_one_meas_float_time(g_MC_TET, ...
               a_tabTrajNMeas(idC).tabMeas(idF1).juld, g_JULD_STATUS_2, 0);
            a_tabTrajNMeas(idCyPrec).tabMeas(idF2) = measStruct;
         end
      end
   end
end

% N_CYCLE DATA

if (~isempty(a_tabTrajNCycle))
   
   % clean the collected data from float anomaly
   % Ex: float 6901038 #272: the float transmitted twice the TECH and PARAM
   % messages
   idDelFinal = [];
   tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
   for idCy = 1:length(tabCyNum)
      cycleNum = tabCyNum(idCy);
      
      idCyDeep = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] ~= 1));
      if (length(idCyDeep) > 1)
         if (cycleNum == 0)
            
            % some floats transmit 2 cycle #0
            
            % merge juldFirstMessage, juldFirstLocation, juldLastLocation and
            % juldLastMessage of the deep and surface records
            
            % juldFirstMessage cannot be empty
            tabDate = [a_tabTrajNCycle(idCyDeep).juldFirstMessage];
            tabDate(find(tabDate == g_decArgo_ncDateDef)) = [];
            a_tabTrajNCycle(idCyDeep(1)).juldFirstMessage = min(tabDate);
            
            % juldFirstLocation can be empty
            idF = find(~strcmp({a_tabTrajNCycle(idCyDeep).juldFirstLocation}, ''));
            tabDate = [a_tabTrajNCycle(idCyDeep(idF)).juldFirstLocation];
            tabDateStatus = [a_tabTrajNCycle(idCyDeep(idF)).juldFirstLocationStatus];
            idDel = find(tabDate == g_decArgo_ncDateDef);
            tabDate(idDel) = [];
            tabDateStatus(idDel) = [];
            if (~isempty(tabDate))
               [a_tabTrajNCycle(idCyDeep(1)).juldFirstLocation, idMin] = min(tabDate);
               a_tabTrajNCycle(idCyDeep(1)).juldFirstLocationStatus = tabDateStatus(idMin);
            end
            
            % juldLastLocation can be empty
            idF = find(~strcmp({a_tabTrajNCycle(idCyDeep).juldLastLocation}, ''));
            tabDate = [a_tabTrajNCycle(idCyDeep(idF)).juldLastLocation];
            tabDateStatus = [a_tabTrajNCycle(idCyDeep(idF)).juldLastLocationStatus];
            idDel = find(tabDate == g_decArgo_ncDateDef);
            tabDate(idDel) = [];
            tabDateStatus(idDel) = [];
            if (~isempty(tabDate))
               [a_tabTrajNCycle(idCyDeep(1)).juldLastLocation, idMax] = max(tabDate);
               a_tabTrajNCycle(idCyDeep(1)).juldLastLocationStatus = tabDateStatus(idMax);
            end
            
            % juldLastMessage cannot be empty
            tabDate = [a_tabTrajNCycle(idCyDeep).juldLastMessage];
            tabDate(find(tabDate == g_decArgo_ncDateDef)) = [];
            a_tabTrajNCycle(idCyDeep(1)).juldLastMessage = max(tabDate);
         else
            fprintf('ERROR: Float #%d cycle #%d: %d deep N_CYCLE records => only the first one is considered\n', ...
               g_decArgo_floatNum, cycleNum, ...
               length(idCyDeep));
         end
         idDelFinal = [idDelFinal idCyDeep(2:end)];
      end
      
      idCySurf = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] == 1));
      if (length(idCySurf) > 1)
         fprintf('INFO: Float #%d cycle #%d: %d surf N_CYCLE records\n', ...
            g_decArgo_floatNum, cycleNum, ...
            length(idCySurf));
         idDelFinal = [idDelFinal idCySurf(1:end-1)];
      end
   end
   
   % delete the corresponding records
   a_tabTrajNCycle(idDelFinal) = [];
   
   if (~isempty(a_tabTrajNCycle))
      
      tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
      for idCy = 1:length(tabCyNum)
         cycleNum = tabCyNum(idCy);

         idCyDeep = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] ~= 1));
         idCySurf = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] == 1));
         
         if (length(idCyDeep) == 1)
            if (~isempty(idCySurf))
               
               % merge juldFirstMessage, juldFirstLocation, juldLastLocation and
               % juldLastMessage of the deep and surface records
               
               % juldFirstMessage cannot be empty
               tabDate = [a_tabTrajNCycle(idCyDeep).juldFirstMessage a_tabTrajNCycle(idCySurf).juldFirstMessage];
               tabDate(find(tabDate == g_decArgo_ncDateDef)) = [];
               a_tabTrajNCycle(idCyDeep).juldFirstMessage = min(tabDate);
               
               % juldFirstLocation can be empty
               tabDate = [];
               tabDateStatus = [];
               if (~isempty(a_tabTrajNCycle(idCyDeep).juldFirstLocation))
                  tabDate = [tabDate a_tabTrajNCycle(idCyDeep).juldFirstLocation];
                  tabDateStatus = [tabDateStatus a_tabTrajNCycle(idCyDeep).juldFirstLocationStatus];
               end
               idF = find(~strcmp({a_tabTrajNCycle(idCySurf).juldFirstLocation}, ''));
               tabDate = [tabDate a_tabTrajNCycle(idCySurf(idF)).juldFirstLocation];
               tabDateStatus = [tabDateStatus a_tabTrajNCycle(idCySurf(idF)).juldFirstLocationStatus];
               idDel = find(tabDate == g_decArgo_ncDateDef);
               tabDate(idDel) = [];
               tabDateStatus(idDel) = [];
               if (~isempty(tabDate))
                  [a_tabTrajNCycle(idCyDeep).juldFirstLocation, idMin] = min(tabDate);
                  a_tabTrajNCycle(idCyDeep).juldFirstLocationStatus = tabDateStatus(idMin);
               end
               
               % juldLastLocation can be empty
               tabDate = [];
               tabDateStatus = [];
               if (~isempty(a_tabTrajNCycle(idCyDeep).juldLastLocation))
                  tabDate = [tabDate a_tabTrajNCycle(idCyDeep).juldLastLocation];
                  tabDateStatus = [tabDateStatus a_tabTrajNCycle(idCyDeep).juldLastLocationStatus];
               end
               idF = find(~strcmp({a_tabTrajNCycle(idCySurf).juldLastLocation}, ''));
               tabDate = [tabDate a_tabTrajNCycle(idCySurf(idF)).juldLastLocation];
               tabDateStatus = [tabDateStatus a_tabTrajNCycle(idCySurf(idF)).juldLastLocationStatus];
               idDel = find(tabDate == g_decArgo_ncDateDef);
               tabDate(idDel) = [];
               tabDateStatus(idDel) = [];
               if (~isempty(tabDate))
                  [a_tabTrajNCycle(idCyDeep).juldLastLocation, idMax] = max(tabDate);
                  a_tabTrajNCycle(idCyDeep).juldLastLocationStatus = tabDateStatus(idMax);
               end
               
               % juldLastMessage cannot be empty
               tabDate = [a_tabTrajNCycle(idCyDeep).juldLastMessage a_tabTrajNCycle(idCySurf).juldLastMessage];
               tabDate(find(tabDate == g_decArgo_ncDateDef)) = [];
               a_tabTrajNCycle(idCyDeep).juldLastMessage = max(tabDate);
               
               a_tabTrajNCycle(idCySurf) = [];
            end
         end
      end
      
      % assign cycle start time of the current cycle to the TET of the previous cycle
      tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
      for idCy = 1:length(tabCyNum)
         cycleNum = tabCyNum(idCy);
         
         idC = find([a_tabTrajNCycle.cycleNumber] == cycleNum);
         idCPrec = find([a_tabTrajNCycle.cycleNumber] == cycleNum-1);
         if (~isempty(idCPrec) && ...
               ~isempty(a_tabTrajNCycle(idC).juldCycleStart) && ...
               (a_tabTrajNCycle(idC).juldCycleStart ~= g_decArgo_ncDateDef))
            
            a_tabTrajNCycle(idCPrec).juldTransmissionEnd = a_tabTrajNCycle(idC).juldCycleStart;
            a_tabTrajNCycle(idCPrec).juldTransmissionEndStatus = a_tabTrajNCycle(idC).juldCycleStartStatus;
         end
      end
      
      % clean the data
      idDel = find([a_tabTrajNCycle.surfOnly] == 1);
      a_tabTrajNCycle(idDel) = [];
   end
end

% check that all expected MC are present

% measurement codes expected to be in each cycle for these floats (primary and
% secondary MC experienced by Arvor deep floats)
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

tabCyNum = sort(unique([a_tabTrajNMeas.cycleNumber]));
tabCyNum = tabCyNum(find(tabCyNum >= 0));
for idCy = 1:length(tabCyNum)
   cycleNum = tabCyNum(idCy);
   
   if (cycleNum == -1)
      % cycle number = -1 is used to store launch location and date only (no
      % need to add all the expected MCs)
      continue;
   end
   
   if (cycleNum == 0)
      expMcList = [ ...
         g_MC_TST ...
         g_MC_TET ...
         ];
   end
   
   idC = find([a_tabTrajNMeas.cycleNumber] == cycleNum);
   measCodeList = unique([a_tabTrajNMeas(idC).tabMeas.measCode]);
   
   % add MCs so that all expected ones will be present
   mcList = setdiff(expMcList, measCodeList);
   measData = [];
   for idMc = 1:length(mcList)
      measStruct = create_one_meas_float_time(mcList(idMc), -1, g_JULD_STATUS_9, 0);
      measData = [measData; measStruct];
      
      if (~isempty(a_tabTrajNCycle))
         idF = find([a_tabTrajNCycle.cycleNumber] == cycleNum);
         if (~isempty(idF))
            [a_tabTrajNCycle(idF)] = set_status_of_n_cycle_juld(a_tabTrajNCycle(idF), mcList(idMc), g_JULD_STATUS_9);
         end
      end
   end
   
   % store the data
   if (~isempty(measData))
      a_tabTrajNMeas(idC(end)).tabMeas = [a_tabTrajNMeas(idC(end)).tabMeas; measData];
      
      % sort trajectory data structures according to the predefined
      % measurement code order
      a_tabTrajNMeas(idC) = sort_trajectory_data(a_tabTrajNMeas(idC), a_decoderId);
   end
end

% output data
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

return;
