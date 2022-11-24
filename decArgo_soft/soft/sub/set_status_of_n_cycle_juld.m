% ------------------------------------------------------------------------------
% Set the JULD_*_STATUS of a cycle timing provided by its associated MC.
%
% SYNTAX :
%  [o_nCycleStruct] = set_status_of_n_cycle_juld(a_nCycleStruct, a_measCode, a_timeStatus)
%
% INPUT PARAMETERS :
%   a_nCycleStruct : input N_CYCLE data
%   a_measCode     : associated MC
%   a_timeStatus   : time status value to set
%
% OUTPUT PARAMETERS :
%   o_nCycleStruct : output N_CYCLE data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nCycleStruct] = set_status_of_n_cycle_juld(a_nCycleStruct, a_measCode, a_timeStatus)

% output parameters initialization
o_nCycleStruct = a_nCycleStruct;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_DET;
global g_MC_PST;
global g_MC_PET;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AET;
global g_MC_TST;
global g_MC_FMT;
global g_MC_LMT;
global g_MC_TET;

% default values
global g_decArgo_ncDateDef;


% update the associated field of the N_CYCLE structure
switch (a_measCode)
   
   case g_MC_CycleStart
      o_nCycleStruct.juldCycleStart = g_decArgo_ncDateDef;
      o_nCycleStruct.juldCycleStartStatus = a_timeStatus;
      
   case g_MC_DST
      o_nCycleStruct.juldDescentStart = g_decArgo_ncDateDef;
      o_nCycleStruct.juldDescentStartStatus = a_timeStatus;
      
   case g_MC_FST
      o_nCycleStruct.juldFirstStab = g_decArgo_ncDateDef;
      o_nCycleStruct.juldFirstStabStatus = a_timeStatus;
      
   case g_MC_DET
      o_nCycleStruct.juldDescentEnd = g_decArgo_ncDateDef;
      o_nCycleStruct.juldDescentEndStatus = a_timeStatus;
      
   case g_MC_PST
      o_nCycleStruct.juldParkStart = g_decArgo_ncDateDef;
      o_nCycleStruct.juldParkStartStatus = a_timeStatus;
      
   case g_MC_PET
      o_nCycleStruct.juldParkEnd = g_decArgo_ncDateDef;
      o_nCycleStruct.juldParkEndStatus = a_timeStatus;
      
   case g_MC_DDET
      o_nCycleStruct.juldDeepDescentEnd = g_decArgo_ncDateDef;
      o_nCycleStruct.juldDeepDescentEndStatus = a_timeStatus;
      
   case g_MC_DPST
      o_nCycleStruct.juldDeepParkStart = g_decArgo_ncDateDef;
      o_nCycleStruct.juldDeepParkStartStatus = a_timeStatus;
      
   case g_MC_AST
      o_nCycleStruct.juldAscentStart = g_decArgo_ncDateDef;
      o_nCycleStruct.juldAscentStartStatus = a_timeStatus;
      
   case g_MC_AET
      o_nCycleStruct.juldAscentEnd = g_decArgo_ncDateDef;
      o_nCycleStruct.juldAscentEndStatus = a_timeStatus;
      
   case g_MC_TST
      o_nCycleStruct.juldTransmissionStart = g_decArgo_ncDateDef;
      o_nCycleStruct.juldTransmissionStartStatus = a_timeStatus;
      
   case g_MC_FMT
      o_nCycleStruct.juldFirstMessage = g_decArgo_ncDateDef;
      o_nCycleStruct.juldFirstMessageStatus = a_timeStatus;
      
   case g_MC_LMT
      o_nCycleStruct.juldLastMessage = g_decArgo_ncDateDef;
      o_nCycleStruct.juldLastMessageStatus = a_timeStatus;
      
   case g_MC_TET
      o_nCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
      o_nCycleStruct.juldTransmissionEndStatus = a_timeStatus;
end

return;
