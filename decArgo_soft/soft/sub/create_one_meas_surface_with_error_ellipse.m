% ------------------------------------------------------------------------------
% Create and fill a basic structure to store N_MEASUREMENT trajectory
% information (surface data).
%
% SYNTAX :
%  [o_measStruct] = create_one_meas_surface_with_error_ellipse( ...
%    a_measCode, a_time, ...
%    a_posLon, a_posLat, a_posAcc, a_posQc, ...
%    a_posAxErrEllMajor, a_posAxErrEllMinor, a_posAxErrEllAngle, a_posSat, a_clockDriftKnown)
%
% INPUT PARAMETERS :
%   a_measCode         : measurement code associated to the trajectory information
%   a_time             : time of the surface event or location
%   a_posLon           : longitude of the surface location
%   a_posLat           : latitude of the surface location
%   a_posAcc           : accuracy of the surface location
%   a_posQc            : QC of the surface location
%   a_posAxErrEllMajor : major axis of location error ellipse
%   a_posAxErrEllMinor : minor axis of location error ellipse
%   a_posAxErrEllAngle : angle of location error ellipse
%   a_posSat           : satellite name associated to the surface location
%   a_clockDriftKnown  : 1 if float clock drift is known, 0 otherwise
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measStruct] = create_one_meas_surface_with_error_ellipse( ...
   a_measCode, a_time, ...
   a_posLon, a_posLat, a_posAcc, a_posQc, ...
   a_posAxErrEllMajor, a_posAxErrEllMinor, a_posAxErrEllAngle, a_posSat, a_clockDriftKnown)

% output parameters initialization
o_measStruct = get_traj_one_meas_init_struct();

% global time status
global g_JULD_STATUS_4;

% default values
global g_decArgo_argosLonDef;

% QC flag values (char)
global g_decArgo_qcStrNoQc;


o_measStruct.measCode = a_measCode;
o_measStruct.juld = a_time;
o_measStruct.juldStatus = g_JULD_STATUS_4;
o_measStruct.juldQc = g_decArgo_qcStrNoQc;
if (a_clockDriftKnown == 1)
   o_measStruct.juldAdj = a_time;
   o_measStruct.juldAdjStatus = g_JULD_STATUS_4;
   o_measStruct.juldAdjQc = g_decArgo_qcStrNoQc;
end

if (a_posLon ~= g_decArgo_argosLonDef)
   o_measStruct.longitude = a_posLon;
   o_measStruct.latitude = a_posLat;
   o_measStruct.posAccuracy = a_posAcc;
   o_measStruct.posQc = num2str(a_posQc);
   o_measStruct.posAxErrEllMajor = a_posAxErrEllMajor;
   o_measStruct.posAxErrEllMinor = a_posAxErrEllMinor;
   o_measStruct.posAxErrEllAngle = a_posAxErrEllAngle;
   o_measStruct.satelliteName = a_posSat;
end

return
