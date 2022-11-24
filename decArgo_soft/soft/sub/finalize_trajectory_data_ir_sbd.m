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
      fprintf('INFO: Float #%d cycle #%d: %d surf N_MEASUREMENT records\n', ...
         g_decArgo_floatNum, cycleNum, ...
         length(idCySurf));
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
   
   idCy = find([a_tabTrajNMeas.cycleNumber] == cycleNum);
   idF1 = find([a_tabTrajNMeas(idCy).tabMeas.measCode] == g_MC_CycleStart);
   if (~isempty(idF1))
      idCyPrec = find([a_tabTrajNMeas.cycleNumber] == cycleNum-1);
      if (~isempty(idCyPrec))
         idF2 = find([a_tabTrajNMeas(idCyPrec).tabMeas.measCode] == g_MC_TET);
         if (~isempty(idF2))
            
            measStruct = create_one_meas_float_time(g_MC_TET, ...
               a_tabTrajNMeas(idCy).tabMeas(idF1).juld, g_JULD_STATUS_2, 0);
            a_tabTrajNMeas(idCyPrec).tabMeas(idF2) = measStruct;
         end
      end
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
tabCyNum = tabCyNum(find(tabCyNum > 0));
for idCy = 1:length(tabCyNum)
   cycleNum = tabCyNum(idCy);
   
   if (cycleNum == -1)
      % cycle number = -1 is used to store launch location and date only (no
      % need to add all the expected MCs)
      continue;
   end
   
   idCy = find([a_tabTrajNMeas.cycleNumber] == cycleNum);
   measCodeList = unique([a_tabTrajNMeas(idCy).tabMeas.measCode]);
   
   % add MCs so that all expected ones will be present
   mcList = setdiff(expMcList, measCodeList);
   measData = [];
   for idMc = 1:length(mcList)
      measStruct = create_one_meas_float_time(mcList(idMc), -1, g_JULD_STATUS_9, 0);
      measData = [measData; measStruct];
   end
   
   % store the data
   if (~isempty(measData))
      a_tabTrajNMeas(idCy(end)).tabMeas = [a_tabTrajNMeas(idCy(end)).tabMeas; measData];
      
      % sort the N_MEASUREMENT data structures according to the measurement codes
      tabMeas = a_tabTrajNMeas(idCy).tabMeas;
      [~, idSort] = sort([tabMeas.measCode]);
      a_tabTrajNMeas(idCy).tabMeas = tabMeas(idSort);
   end
end

% N_CYCLE DATA

if (~isempty(a_tabTrajNCycle))
   
   % clean the collected data from float anomaly
   % Ex: float 6901038 #272: the float transmitted twice the TECH and PARAM
   % messages
   idDel = [];
   tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
   for idCy = 1:length(tabCyNum)
      cycleNum = tabCyNum(idCy);
      
      idCyDeep = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] == 0));
      if (length(idCyDeep) > 1)
         fprintf('ERROR: Float #%d cycle #%d: %d deep N_CYCLE records => only the first one is considered\n', ...
            g_decArgo_floatNum, cycleNum, ...
            length(idCyDeep));
         idDel = [idDel idCyDeep(2:end)];
      end
      
      idCySurf = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] == 1));
      if (length(idCySurf) > 1)
         fprintf('INFO: Float #%d cycle #%d: %d surf N_CYCLE records\n', ...
            g_decArgo_floatNum, cycleNum, ...
            length(idCySurf));
         idDel = [idDel idCySurf(1:end-1)];
      end
   end
   
   % delete the corresponding records
   a_tabTrajNCycle(idDel) = [];
   
   if (~isempty(a_tabTrajNCycle))
      
      tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
      for idCy = 1:length(tabCyNum)
         cycleNum = tabCyNum(idCy);
         
         idCyDeep = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] == 0));
         idCySurf = find(([a_tabTrajNCycle.cycleNumber] == cycleNum) & ([a_tabTrajNCycle.surfOnly] == 1));
         
         if (length(idCyDeep) == 1)
            if (~isempty(idCySurf))
               
               % preserve only the juldFirstMessage, juldFirstLocation,
               % juldLastLocation and juldLastMessage of the last surface record
               a_tabTrajNCycle(idCyDeep).juldFirstMessage = a_tabTrajNCycle(idCySurf(end)).juldFirstMessage;
               a_tabTrajNCycle(idCyDeep).juldFirstLocation = a_tabTrajNCycle(idCySurf(end)).juldFirstLocation;
               a_tabTrajNCycle(idCyDeep).juldLastLocation = a_tabTrajNCycle(idCySurf(end)).juldLastLocation;
               a_tabTrajNCycle(idCyDeep).juldLastMessage = a_tabTrajNCycle(idCySurf(end)).juldLastMessage;
               
               a_tabTrajNCycle(idCySurf) = [];
            end
         end
      end
      
      % assign cycle start time of the current cycle to the TET of the previous cycle
      tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
      for idCy = 1:length(tabCyNum)
         cycleNum = tabCyNum(idCy);
         
         idCy = find([a_tabTrajNCycle.cycleNumber] == cycleNum);
         idCyPrec = find([a_tabTrajNCycle.cycleNumber] == cycleNum-1);
         if (~isempty(idCyPrec))
            a_tabTrajNCycle(idCyPrec).juldTransmissionEnd = a_tabTrajNCycle(idCy).juldCycleStart;
            a_tabTrajNCycle(idCyPrec).juldTransmissionEndStatus = a_tabTrajNCycle(idCy).juldCycleStartStatus;
         end
      end
      
      % clean the data
      idDel = find([a_tabTrajNCycle.surfOnly] == 1);
      a_tabTrajNCycle(idDel) = [];
   end
end

% output data
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

return;
