% ------------------------------------------------------------------------------
% Finalize CTS5 trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_rudics_cts5( ...
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_rudics_cts5( ...
   a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% current float WMO number
global g_decArgo_floatNum;

% cycle phases
global g_decArgo_phaseSatTrans;

% global measurement codes
global g_MC_DST;
global g_MC_FST;
global g_MC_PST;
global g_MC_PET;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AET;
global g_MC_TST;
global g_MC_TET;

% global time status
global g_JULD_STATUS_9;


% merge N_MEAS records to keep only one per output cycle number
idDel = [];
cycleNumList = [a_tabTrajNMeas.outputCycleNumber];
uCycleNum = sort(unique(cycleNumList));
for idCyc = 1:length(uCycleNum)
   cycleNum = uCycleNum(idCyc);
   
   if (cycleNum < 0)
      continue
   end
   
   idData = find(cycleNumList == cycleNum);
   
   if (length(idData) > 1)
      
      idCyDeep = find([a_tabTrajNMeas(idData).profileNumber] ~= 0);
      if (isempty(idCyDeep))
         % only surface cycles: we use the first surface cycle as the base
         % record
         idBase = idData(1);
         idToMerge = setdiff(idData, idBase);
         idDel = [idDel idToMerge];
         [a_tabTrajNMeas] = merge_N_MEAS_records_cts5(a_tabTrajNMeas, idBase, idToMerge);
      elseif (length(idCyDeep) == 1)
         % one deep cycle: we use it as the base record
         idBase = idData(idCyDeep);
         idToMerge = setdiff(idData, idBase);
         idDel = [idDel idToMerge];
         [a_tabTrajNMeas] = merge_N_MEAS_records_cts5(a_tabTrajNMeas, idBase, idToMerge);
      else
         fprintf('ERROR: Float #%d cycle #%d: %d deep N_MEASUREMENT records => only the first one is considered\n', ...
            g_decArgo_floatNum, cycleNum, ...
            length(idCyDeep));
         idBase = idData(idCyDeep(1));
         idToMerge = setdiff(idData, idBase);
         idDel = [idDel idToMerge];
      end
   end
end
a_tabTrajNMeas(idDel) = [];

% merge N_CYCLE records to keep only one per output cycle number
idDel = [];
cycleNumList = [a_tabTrajNCycle.outputCycleNumber];
uCycleNum = sort(unique(cycleNumList));
for idCyc = 1:length(uCycleNum)
   cycleNum = uCycleNum(idCyc);
   
   if (cycleNum < 0)
      continue
   end
   
   idData = find(cycleNumList == cycleNum);
   
   if (length(idData) > 1)
      
      idCyDeep = find([a_tabTrajNCycle(idData).profileNumber] ~= 0);
      if (isempty(idCyDeep))
         % only surface cycles: we use the first surface cycle as the base
         % record
         idBase = idData(1);
         idToMerge = setdiff(idData, idBase);
         idDel = [idDel idToMerge];
         [a_tabTrajNCycle] = merge_N_CYCLE_records_cts5(a_tabTrajNCycle, idBase, idToMerge);
      elseif (length(idCyDeep) == 1)
         % one deep cycle: we use it as the base record
         idBase = idData(idCyDeep);
         idToMerge = setdiff(idData, idBase);
         idDel = [idDel idToMerge];
         [a_tabTrajNCycle] = merge_N_CYCLE_records_cts5(a_tabTrajNCycle, idBase, idToMerge);
      else
         fprintf('ERROR: Float #%d cycle #%d: %d deep N_MEASUREMENT records => only the first one is considered\n', ...
            g_decArgo_floatNum, cycleNum, ...
            length(idCyDeep));
         idBase = idData(idCyDeep(1));
         idToMerge = setdiff(idData, idBase);
         idDel = [idDel idToMerge];
      end
   end
end
a_tabTrajNCycle(idDel) = [];

% check that all expected MCs are present

% measurement codes expected to be in each cycle for these floats (primary and
% secondary MC experienced by CTS5 floats)
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

cycleNumList = [a_tabTrajNMeas.outputCycleNumber];
uCycleNum = sort(unique(cycleNumList));
for idCyc = 1:length(uCycleNum)
   cycleNum = uCycleNum(idCyc);
   if (cycleNum < 0)
      continue
   end
   
   idData = find(cycleNumList == cycleNum);
   
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
            idF = find([a_tabTrajNCycle.outputCycleNumber] == cycleNum);
            if (~isempty(idF))
               [a_tabTrajNCycle(idF)] = set_status_of_n_cycle_juld(a_tabTrajNCycle(idF), mcList(idMc), g_JULD_STATUS_9);
            end
         end
      end
      
      % store the data
      if (~isempty(measData))
         a_tabTrajNMeas(idData(end)).tabMeas = [a_tabTrajNMeas(idData(end)).tabMeas; measData];
      end
   end
end

% store output data
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

return

% ------------------------------------------------------------------------------
% Merge CTS5 N_MEASUREMENT records.
%
% SYNTAX :
%  [o_tabTrajNMeas] = merge_N_MEAS_records_cts5( ...
%    a_tabTrajNMeas, a_idBase, a_idToMerge)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas : input N_MEASUREMENT trajectory data
%   a_idBase       : base record
%   a_idToMerge    : records to merge
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = merge_N_MEAS_records_cts5( ...
   a_tabTrajNMeas, a_idBase, a_idToMerge)

% output parameters initialization
o_tabTrajNMeas = [];


for idD1 = 1:length(a_idToMerge)
   tabMeas = a_tabTrajNMeas(a_idToMerge(idD1)).tabMeas;
   a_tabTrajNMeas(a_idBase).tabMeas = [a_tabTrajNMeas(a_idBase).tabMeas; ...
      tabMeas];
end

% PREVIOUS VERSION START - (surface TEMP of cycle #0 is missing in TRAJ file)
% % global measurement codes
% global g_MC_Surface;
%
%
% % according to CTS5 measurement codes, only the GPS MC of the surface records
% % have to be added to the one of the deep record
% for idD1 = 1:length(a_idToMerge)
%    tabMeas = a_tabTrajNMeas(a_idToMerge(idD1)).tabMeas;
%    if (~isempty(tabMeas))
%       idSurface = find([tabMeas.measCode] == g_MC_Surface);
%       for idD2 = 1:length(idSurface)
%          a_tabTrajNMeas(a_idBase).tabMeas = [ ...
%             a_tabTrajNMeas(a_idBase).tabMeas; ...
%             tabMeas(idD2)];
%       end
%    end
% end
% PREVIOUS VERSION END - (surface TEMP of cycle #0 is missing in TRAJ file)

% store output data
o_tabTrajNMeas = a_tabTrajNMeas;

return

% ------------------------------------------------------------------------------
% Merge CTS5 N_CYCLE records.
%
% SYNTAX :
%  [o_tabTrajNCycle] = merge_N_CYCLE_records_cts5( ...
%    a_tabTrajNCycle, a_idBase, a_idToMerge)
%
% INPUT PARAMETERS :
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%   a_idBase        : base record
%   a_idToMerge     : records to merge
%
% OUTPUT PARAMETERS :
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNCycle] = merge_N_CYCLE_records_cts5( ...
   a_tabTrajNCycle, a_idBase, a_idToMerge)

% output parameters initialization
o_tabTrajNCycle = [];


% according to CTS5 measurement codes, only the first and last location times
% should be updated when we merge a deep N_CYCLE record with surface N_CYCLE
% records
juldFirstLocationList = [ ...
   a_tabTrajNCycle(a_idBase).juldFirstLocation ...
   [a_tabTrajNCycle(a_idToMerge).juldFirstLocation] ...
   ];
juldFirstLocationStatusList = [ ...
   a_tabTrajNCycle(a_idBase).juldFirstLocationStatus ...
   [a_tabTrajNCycle(a_idToMerge).juldFirstLocationStatus] ...
   ];
juldLastLocationList = [ ...
   a_tabTrajNCycle(a_idBase).juldLastLocation ...
   [a_tabTrajNCycle(a_idToMerge).juldLastLocation] ...
   ];
juldLastLocationStatusList = [ ...
   a_tabTrajNCycle(a_idBase).juldLastLocationStatus ...
   [a_tabTrajNCycle(a_idToMerge).juldLastLocationStatus] ...
   ];
if (~isempty(juldFirstLocationList))
   [minDate, idMin] = min(juldFirstLocationList);
   a_tabTrajNCycle(a_idBase).juldFirstLocation = minDate;
   a_tabTrajNCycle(a_idBase).juldFirstLocationStatus = juldFirstLocationStatusList(idMin);
   [maxDate, idMax] = max(juldLastLocationList);
   a_tabTrajNCycle(a_idBase).juldLastLocation = maxDate;
   a_tabTrajNCycle(a_idBase).juldlastLocationStatus = juldLastLocationStatusList(idMax);
end

% store output data
o_tabTrajNCycle = a_tabTrajNCycle;

return
