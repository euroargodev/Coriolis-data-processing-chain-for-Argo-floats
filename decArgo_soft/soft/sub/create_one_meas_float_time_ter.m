% ------------------------------------------------------------------------------
% Create and fill a basic structure to store N_MEASUREMENT trajectory
% information (time data).
%
% SYNTAX :
%  [o_measStruct, o_nCycleTime] = create_one_meas_float_time_ter( ...
%    a_measCode, a_time, a_timeStatus, a_clockDrift)
%
% INPUT PARAMETERS :
%   a_measCode   : measurement code associated to the trajectory information
%   a_time       : float time of the event
%   a_timeStatus : time status of the event
%   a_clockDrift : float clock drift
%
% OUTPUT PARAMETERS :
%   o_measStruct : N_MEASUREMENT trajectory initialized structure
%   o_nCycleTime : associated time to be stored in the corresponding N_CYCLE
%                  variable
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measStruct, o_nCycleTime] = create_one_meas_float_time_ter( ...
   a_measCode, a_time, a_timeStatus, a_clockDrift)

% output parameters initialization
o_measStruct = get_traj_one_meas_init_struct();
o_nCycleTime = [];

% default values
global g_decArgo_dateDef;

% QC flag values (char)
global g_decArgo_qcStrNoQc;

% global time status
global g_JULD_STATUS_3;

o_measStruct.measCode = a_measCode;
if (a_time ~= g_decArgo_dateDef)
   if (~isempty(a_clockDrift))
      o_measStruct.juld = a_time;
      o_measStruct.juldStatus = a_timeStatus;
      o_measStruct.juldQc = g_decArgo_qcStrNoQc;
      o_measStruct.juldAdj = a_time - a_clockDrift;
      o_measStruct.juldAdjStatus = g_JULD_STATUS_3;
      o_measStruct.juldAdjQc = g_decArgo_qcStrNoQc;
      
      o_nCycleTime = o_measStruct.juldAdj;
   else
      o_measStruct.juld = a_time;
      o_measStruct.juldStatus = a_timeStatus;
      o_measStruct.juldQc = g_decArgo_qcStrNoQc;
      
      o_nCycleTime = o_measStruct.juld;
   end
end

return
