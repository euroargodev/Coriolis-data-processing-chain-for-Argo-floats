% ------------------------------------------------------------------------------
% Get the basic structure to store Apex Iridium Rudics cycle timming information.
%
% SYNTAX :
%  [o_timeStruct] = get_apx_ir_rudics_float_time_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_timeStruct : cycle timing structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeStruct] = get_apx_ir_rudics_float_time_init_struct

% FOR APEX IRIDIUM RUDICS
% parkEndDateBis is finally NOT USED (not reliable when compared with
% parkEndDate)
% see: 6900796 for cycles >= 36 (once DOWN_TIME has been reduced)
% see: 6902549 for cycles >= 22 (once DOWN_TIME has been reduced)

% FOR NAVIS
% no example of such inconsistencies => parkEndDateBis is used (as a second
% choice)

o_timeStruct = struct( ...
   'cycleNum', [], ... % from DescentInit() or ProfileInit() event information
   'cycleStartDate', [], ... % from DescentInit() event information
   'cycleStartAdjDate', [], ...
   'descentStartDate', [], ... % date of DescentInit() event
   'descentStartAdjDate', [], ...
   'descentStartSurfPres', [], ... % from DescentInit() event information
   'descentStartDateBis', [], ... % computed as PST - ParkDescentTime (PST = time of the first drift meas)
   'descentStartAdjDateBis', [], ...
   'descentEndDate', [], ... % computed as time of first drift sample within 3% of aimed drift pressure
   'descentEndAdjDate', [], ...
   'parkStartDate', [], ... % date of ParkInit() event
   'parkStartAdjDate', [], ...
   'parkEndDate', [], ... % date of ParkTerminate() event
   'parkEndAdjDate', [], ...
   'parkEndMeas', [], ... % from ParkTerminate() event information
   'parkEndDateBis', [], ... % computed as descentStartDateBis + DOWN_TIME - DeepProfileDescentTime (if PARK_PRES ~= PROF_PRES) and descentStartDateBis + DOWN_TIME otherwise
   'parkEndAdjDateBis', [], ...
   'ascentStartDate', [], ... % date of ProfileInit() event
   'ascentStartAdjDate', [], ...
   'ascentStartPres', [], ... % from ProfileInit() event information
   'ascentStartAdjPres', [], ...
   'ascentEndDate', [], ... % date of SurfaceDetect() event
   'ascentEndAdjDate', [], ...
   'ascentEndSurfPres', [], ... % from SurfaceDetect() event information
   'ascentEndPres', [], ... % from SurfaceDetect() event information
   'ascentEndAdjPres', [], ...
   'ascentEnd2Date', [], ... % date of ProfileTerminate() event
   'ascentEnd2AdjDate', [], ...
   'transStartDate', [], ... % of the previous cycle ! : date of login() event
   'transStartDateMTime', [], ... % of the previous cycle ! : date of login() event
   'transStartAdjDate', [], ... % of the previous cycle !
   'transEndDate', [], ... % of the previous cycle ! : date of logout() event
   'transEndDateMTime', [], ... % of the previous cycle ! : date of logout() event
   'transEndAdjDate', [] ... % of the previous cycle !
   );

return;
