% ------------------------------------------------------------------------------
% Update the cycle number information of the Iridium mail data structure.
%
% SYNTAX :
%  update_mail_data_apx_ir_sbd(a_tabTrajNMeas)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas : trajectory N_MEASUREMENT data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function update_mail_data_apx_ir_sbd(a_tabTrajNMeas)

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% default values
global g_decArgo_ncDateDef;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_AET;
global g_MC_NearSurfaceSeriesOfMeas;
global g_MC_TST;
global g_MC_Surface;
global g_MC_TET;
global g_MC_InAirSeriesOfMeas;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDuration/24;


% set cycle number of mail files according to TRAJ N_MEASUREMENT data
surfMcList1 = [g_MC_CycleStart g_MC_DST];
surfMcList2 = [g_MC_AET g_MC_NearSurfaceSeriesOfMeas g_MC_TST g_MC_Surface g_MC_TET g_MC_InAirSeriesOfMeas];
trajCyNumList = unique([a_tabTrajNMeas.cycleNumber]);
for idCy = 1:length(trajCyNumList)
   cyNum = trajCyNumList(idCy);
   
   surfDates = [];
   idCyNextNMeas = find([a_tabTrajNMeas.cycleNumber] == cyNum+1);
   if (~isempty(idCyNextNMeas))
      if (~isempty(a_tabTrajNMeas(idCyNextNMeas).tabMeas))
         idDates = find(ismember([a_tabTrajNMeas(idCyNextNMeas).tabMeas.measCode], surfMcList1));
         if (~isempty(idDates))
            cySurfDates = [a_tabTrajNMeas(idCyNextNMeas).tabMeas(idDates).juldAdj];
            if (~any(cySurfDates ~= g_decArgo_ncDateDef))
               cySurfDates = [a_tabTrajNMeas(idCyNextNMeas).tabMeas(idDates).juld];
            end
            surfDates = [surfDates cySurfDates];
         end
      end
   end
   idCyNMeas = find([a_tabTrajNMeas.cycleNumber] == cyNum);
   if (~isempty(idCyNMeas))
      if (~isempty(a_tabTrajNMeas(idCyNMeas).tabMeas))
         idDates = find(ismember([a_tabTrajNMeas(idCyNMeas).tabMeas.measCode], surfMcList2));
         if (~isempty(idDates))
            cySurfDates = [a_tabTrajNMeas(idCyNMeas).tabMeas(idDates).juldAdj];
            if (~any(cySurfDates ~= g_decArgo_ncDateDef))
               cySurfDates = [a_tabTrajNMeas(idCyNMeas).tabMeas(idDates).juld];
            end
            surfDates = [surfDates cySurfDates];
         end
      end
   end
   surfDates(find(surfDates == g_decArgo_ncDateDef)) = [];
   
   % set cycle number associated to Iridium sessions
   if (~isempty(surfDates))
      firstSurfDate = min(surfDates);
      lastSurfDate = max(surfDates);
      
      idCyIrSession = find( ...
         ([g_decArgo_iridiumMailData.timeOfSessionJuld] >= firstSurfDate) & ...
         ([g_decArgo_iridiumMailData.timeOfSessionJuld] <= lastSurfDate) & ...
         ([g_decArgo_iridiumMailData.cycleNumber] == -1));
      [g_decArgo_iridiumMailData(idCyIrSession).cycleNumber] = deal(cyNum);
   end
end

% assign remaining mail files according to transmission session
idFCy = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
for id = 1:length(idFCy)
   idF = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] <= g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld + MIN_SUB_CYCLE_DURATION_IN_DAYS) & ...
      ([g_decArgo_iridiumMailData.timeOfSessionJuld] >= g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld - MIN_SUB_CYCLE_DURATION_IN_DAYS));
   cyNum = unique([g_decArgo_iridiumMailData(idF).cycleNumber]);
   cyNum(find(cyNum == -1)) = [];
   if (length(cyNum) == 1)
      g_decArgo_iridiumMailData(idFCy(id)).cycleNumber = cyNum;
   end
end

% assign remaining mail files according to assigned cycle numbers
idFCy = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
tabCyNum = ones(size(idFCy))*-1;
for id = 1:length(idFCy)
   idF1 = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] < g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld) & ...
      ([g_decArgo_iridiumMailData.cycleNumber] ~= -1));
   idF2 = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] > g_decArgo_iridiumMailData(idFCy(id)).timeOfSessionJuld) & ...
      ([g_decArgo_iridiumMailData.cycleNumber] ~= -1));
   if (~isempty(idF1) && ~isempty(idF2))
      cyNumPrev = g_decArgo_iridiumMailData(idF1(end)).cycleNumber;
      cyNumNext = g_decArgo_iridiumMailData(idF2(1)).cycleNumber;
      if ((cyNumPrev ~= -1) && (cyNumNext ~= -1) && (cyNumNext - cyNumPrev == 2))
         tabCyNum(id) = cyNumPrev + 1;
      end
   end
end
for id = 1:length(tabCyNum)
   g_decArgo_iridiumMailData(idFCy(id)).cycleNumber = tabCyNum(id);
end

return;
