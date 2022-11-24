% ------------------------------------------------------------------------------
% Get the basic structure to store all cycle time information.
%
% SYNTAX :
%  [o_dataStruct] = get_apx_float_time_init_struct(a_decoderId)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : all cycle time initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_apx_float_time_init_struct(a_decoderId)

% default values
global g_decArgo_dateDef;


% specific times provided by the float version
[downTimeEnd, ascentStartTime] = time_provided(a_decoderId);

% structure to store configuration (and miscellaneous parameters)
paramStruct = struct( ...
   'dpfFloatFlag', [], ...
   'downTimeEndProvidedFlag', downTimeEnd, ...
   'ascentStartTimeProvidedFlag', ascentStartTime, ...
   'cycleTime', [], ...
   'downTime', [], ...
   'upTime', [], ...
   'parkingPres', [], ...
   'profilePres', [], ...
   'parkAndProfileCycleLength', [], ...
   'deepProfileDescentPeriod', [], ...
   'transRepPeriod', [], ...
   'profileLength', [] ...
   );

% output parameter
o_dataStruct = struct( ...
   'clockOffsetAtLaunch', [], ...
   'clockOffsetAtLaunchRefDate', g_decArgo_dateDef, ...
   'clockDriftInSecPerYear', [], ... % from LMT dates
   'configParam', paramStruct, ...
   'cycleNum', [], ...
   'cycleTime', [], ...
   'cycleParkPres', [], ...
   'cycleProfPres', [] ...
   );

return;

% ------------------------------------------------------------------------------
% Retrieve information on cycle time provided by a float version.
%
% SYNTAX :
%  [o_downTimeEnd, o_ascentStartTime] = time_provided(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_downTimeEnd     : the float provides DOWN_TIME end time ?
%   o_ascentStartTime : the float provides AST ?
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_downTimeEnd, o_ascentStartTime] = time_provided(a_decoderId)

% output parameters initialization
o_downTimeEnd = 0;
o_ascentStartTime = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_decoderId)   
   case {1001} % 071412
      o_downTimeEnd = 1;
      o_ascentStartTime = 1;
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in down_time_provided for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;
