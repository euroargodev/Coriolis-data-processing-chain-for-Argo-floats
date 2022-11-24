% ------------------------------------------------------------------------------
% Get the basic structure to store Apex APF11 Iridium Rudics cycle timming
% information.
%
% SYNTAX :
%  [o_timeStruct] = get_apx_apf11_ir_float_time_init_struct
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeStruct] = get_apx_apf11_ir_float_time_init_struct(a_cycleNum)

o_timeStruct = struct( ...
   'cycleNum', a_cycleNum, ...
   'preludeStartDateSci', [], ... % from 'Prelude/Self Test' of science_log file
   'preludeStartAdjDateSci', [], ...
   'preludeStartDateSys', [], ... % from 'Mission state IDLE -> PRELUDE' of system_log file
   'preludeStartAdjDateSys', [], ...
   'descentStartDateSci', [], ... % from 'Park Descent Mission' of science_log file
   'descentStartAdjDateSci', [], ...
   'descentStartPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'descentStartAdjPresSci', [], ...
   'descentStartDateSys', [], ... % from 'Mission state PRELUDE -> PARKDESCENT' or 'Mission state SURFACE -> PARKDESCENT' or 'Mission state RECOVERY -> PARKDESCENT' of system_log file
   'descentStartAdjDateSys', [], ...
   'descentEndDate', [], ... % computed, from CTD_P data, as the first time the float enters in the [PARK_PRES-3%;PARK_PRES+3%] interval
   'descentEndAdjDate', [], ...
   'descentEndPres', [], ... % first CTD_P of [PARK_PRES-3%;PARK_PRES+3%] interval
   'descentEndAdjPres', [], ...
   'parkStartDateSci', [], ... % from 'Park Mission' of science_log file
   'parkStartAdjDateSci', [], ...
   'parkStartPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'parkStartAdjPresSci', [], ...
   'parkStartDateSys', [], ... % from 'Mission state PARKDESCENT -> PARK' of system_log file
   'parkStartAdjDateSys', [], ...
   'parkEndDateSci', [], ... % from 'Deep Descent Mission' of science_log file (or from 'Profiling Mission' of science_log file if 'Park Mission' is not present in science_log file, i.e. when PARK_PRES = PROF_PRES)
   'parkEndAdjDateSci', [], ...
   'parkEndPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'parkEndAdjPresSci', [], ...
   'parkEndDateSys', [], ... % from 'Mission state PARK -> DEEPDESCENT' of system_log file
   'parkEndAdjDateSys', [], ...
   'deepDescentEndDate', [], ... % computed, from CTD_P data, as the first time the float enters in the [PROFILE_PRES-3%;PROFILE_PRES+3%] interval
   'deepDescentEndAdjDate', [], ...
   'deepDescentEndPres', [], ... % first CTD_P of [PROFILE_PRES-3%;PROFILE_PRES+3%] interval
   'deepDescentEndAdjPres', [], ...
   'ascentStartDateSci', [], ... % from 'Profiling Mission' of science_log file
   'ascentStartAdjDateSci', [], ...
   'ascentStartPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'ascentStartAdjPresSci', [], ...
   'ascentStartDateSys', [], ... % from 'Mission state DEEPDESCENT -> ASCENT' or 'Mission state PARK -> ASCENT' of system_log file
   'ascentStartAdjDateSys', [], ...
   'continuousProfileStartDateSci', [], ... % from 'CP Started' of science_log file
   'continuousProfileStartAdjDateSci', [], ...
   'continuousProfileStartPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'continuousProfileStartAdjPresSci', [], ...
   'continuousProfileEndDateSci', [], ... % from 'CP Stopped' of science_log file
   'continuousProfileEndAdjDateSci', [], ...
   'continuousProfileEndPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'continuousProfileEndAdjPresSci', [], ...
   'ascentAbortDate', [], ... % from Ice information
   'ascentAbortAdjDate', [], ...
   'ascentAbortPres', [], ... % from Ice information
   'ascentAbortAdjPres', [], ...
   'ascentEndDateSci', [], ... % from 'Surface Mission' of science_log file
   'ascentEndAdjDateSci', [], ...
   'ascentEndPresSci', [], ... % CTD_P of same timestamp or average of 2 surrounding values
   'ascentEndAdjPresSci', [], ...
   'ascentEndDateSys', [], ... % from 'Mission state ASCENT -> SURFACE' of system_log file
   'ascentEndAdjDateSys', [], ...
   'ascentEndDate', [], ... % AED: duplicate of ascentEndDateSci if available ascentEndDateSys otherwise (remember that ascentEndDateSci is not provided when Ice is detected)
   'ascentEndAdjDate', [], ...
   'bladderInflationStartDateSys', [], ... % from 'Inflating air bladder' of system_log file
   'transStartDate', [], ... % from first occurence of 'Found sky.' in system_log file
   'transStartAdjDate', [], ...
   'transEndDate', [], ... % OF THE PREVIOUS CYCLE! from last occurence of 'Upload Complete:' in system_log file
   'transEndAdjDate', [] ...
   );

return
