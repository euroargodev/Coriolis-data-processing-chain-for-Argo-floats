% ------------------------------------------------------------------------------
% Create and fill a basic structure to store N_MEASUREMENT trajectory
% information (time data).
%
% SYNTAX :
%  [o_measStruct] = create_one_meas_float_time( ...
%    a_measCode, a_time, a_timeStatus, a_clockDrift)
%
% INPUT PARAMETERS :
%   a_measCode   : measurement code associated to the trajectory information
%   a_time       : UTC time of the event
%   a_timeStatus : time status of the event
%   a_clockDrift : float clock drift
%
% OUTPUT PARAMETERS :
%   o_measStruct : N_MEASUREMENT trajectory initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measStruct] = create_one_meas_float_time( ...
   a_measCode, a_time, a_timeStatus, a_clockDrift)

% output parameters initialization
o_measStruct = get_traj_one_meas_init_struct();

% default values
global g_decArgo_dateDef;
global g_decArgo_ncDateDef;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrMissing;

% global time status
global g_JULD_STATUS_fill_value;


o_measStruct.measCode = a_measCode;
if (a_time ~= g_decArgo_dateDef)
   if (a_time ~= -1)
      if (~isempty(a_clockDrift))
         o_measStruct.juld = a_time + a_clockDrift;
         o_measStruct.juldStatus = a_timeStatus;
         o_measStruct.juldQc = g_decArgo_qcStrNoQc;
         o_measStruct.juldAdj = a_time;
         o_measStruct.juldAdjStatus = a_timeStatus;
         o_measStruct.juldAdjQc = g_decArgo_qcStrNoQc;
      else
         o_measStruct.juld = a_time;
         o_measStruct.juldStatus = a_timeStatus;
         o_measStruct.juldQc = g_decArgo_qcStrNoQc;
      end
   else
      if (~isempty(a_clockDrift))
         o_measStruct.juld = g_decArgo_ncDateDef;
         o_measStruct.juldStatus = a_timeStatus;
         o_measStruct.juldQc = g_decArgo_qcStrMissing;
         o_measStruct.juldAdj = g_decArgo_ncDateDef;
         o_measStruct.juldAdjStatus = a_timeStatus;
         o_measStruct.juldAdjQc = g_decArgo_qcStrMissing;
      else
         o_measStruct.juld = g_decArgo_ncDateDef;
         o_measStruct.juldStatus = a_timeStatus;
         o_measStruct.juldQc = g_decArgo_qcStrMissing;
         o_measStruct.juldAdj = g_decArgo_ncDateDef;
         o_measStruct.juldAdjStatus = g_JULD_STATUS_fill_value;
         o_measStruct.juldAdjQc = g_decArgo_qcStrDef;
      end
   end
end

return
