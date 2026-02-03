% ------------------------------------------------------------------------------
% Create and fill a basic structure to store N_MEASUREMENT trajectory
% information (time data).
%
% SYNTAX :
% [o_measStruct, o_nCycleTime] = create_one_meas_float_time_pfv2( ...
%   a_measCode, a_time, a_timeStatus, a_timeAdj)
%
% INPUT PARAMETERS :
%   a_measCode   : measurement code associated to the trajectory information
%   a_time       : time of the event
%   a_timeStatus : time status of the event
%   a_timeAdj    : adjusted time of the event
%
% OUTPUT PARAMETERS :
%   o_measStruct : N_MEASUREMENT trajectory initialized structure
%   o_nCycleTime : associated time to be stored in the corresponding N_CYCLE
%                  variable
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/01/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measStruct, o_nCycleTime] = create_one_meas_float_time_pfv2( ...
   a_measCode, a_time, a_timeStatus, a_timeAdj)

% output parameters initialization
o_measStruct = [];
o_nCycleTime = [];

% QC flag values (char)
global g_decArgo_qcStrNoQc;


o_measStruct = get_traj_one_meas_init_struct();

o_measStruct.measCode = a_measCode;
if (~isnan(a_time))
   o_measStruct.juld = a_time;
   o_measStruct.juldStatus = a_timeStatus;
   o_measStruct.juldQc = g_decArgo_qcStrNoQc;
end
if (~isnan(a_timeAdj))
   o_measStruct.juldAdj = a_timeAdj;
   o_measStruct.juldAdjStatus = a_timeStatus;
   o_measStruct.juldAdjQc = g_decArgo_qcStrNoQc;
end

if (~isnan(a_timeAdj))
   o_nCycleTime = a_timeAdj;
else
   o_nCycleTime = a_time;
end

return
