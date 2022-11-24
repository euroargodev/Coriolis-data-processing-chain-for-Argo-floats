% ------------------------------------------------------------------------------
% Check for existing cycle Argos or Iridium data files within a given list of
% expected cycles.
%
% SYNTAX :
%  [o_cycleList, o_excludedCycleList] = get_float_cycle_list( ...
%    a_floatNum, a_floatArgosIridiumId, a_floatLaunchDate, )
%
% INPUT PARAMETERS :
%   a_floatNum            : float WMO number
%   a_floatArgosIridiumId : float PTT number
%   a_floatLaunchDate     : float launch data
%   a_decoderId           : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cycleList         : existing cycle Argos/Iridium data files
%   o_excludedCycleList : excluded cycle Argos/Iridium data files
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/13/2011 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList, o_excludedCycleList] = get_float_cycle_list( ...
   a_floatNum, a_floatArgosIridiumId, a_floatLaunchDate, a_decoderId)

% output parameters initialization
o_cycleList = [];
o_excludedCycleList = [];

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;


if (g_decArgo_floatTransType == 1)
   
   % Argos floats
   [o_cycleList, o_excludedCycleList] = get_float_cycle_list_argos(a_floatNum, str2num(char(a_floatArgosIridiumId)));
   
elseif (g_decArgo_floatTransType == 2)
   
   % Iridium RUDICS floats
   
   if ((a_decoderId > 1000) && (a_decoderId < 2000))
      % Apex Iridium RUDICS floats
      [o_cycleList, ~] = get_float_cycle_list_iridium_rudics_apx(a_floatNum, str2num(char(a_floatArgosIridiumId)));
   elseif (~ismember(a_decoderId, [121 122 123]))
      % PROVOR CTS4 Iridium RUDICS floats
      [o_cycleList] = get_float_cycle_list_iridium_rudics_cts4(a_floatNum, char(a_floatArgosIridiumId));
   else
      % PROVOR CTS5 Iridium RUDICS floats
      [o_cycleList] = get_float_cycle_list_iridium_rudics_cts5(a_floatNum, char(a_floatArgosIridiumId));
   end
      
elseif ((g_decArgo_floatTransType == 3) || (g_decArgo_floatTransType == 4))
   
   % Iridium SBD floats
   [o_cycleList] = get_float_cycle_list_iridium_sbd(a_floatNum, str2num(char(a_floatArgosIridiumId)), a_floatLaunchDate);
   
end

return;
