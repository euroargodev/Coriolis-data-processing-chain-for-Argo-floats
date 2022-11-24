% ------------------------------------------------------------------------------
% Get the park and profile specific value (that causes all profiles to start at
% park depth) for a given decoder.
%
% SYNTAX :
%  [o_specificValue] = get_park_and_prof_specific_value_apx(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_specificValue : PnP specific value for this decoder Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_specificValue] = get_park_and_prof_specific_value_apx(a_decoderId)

% output parameters initialization
o_specificValue = -1; % so that it is not used if specific value doesn't exist (APF11) or is unknown for a given firmware version

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1001, 1005, 1007, 1009, 1010, 1011, 1012, 1015, 1016}
      % Apex Argos
      % 071412, 061810, 082213, 032213, 110613&090413&102015, 121512, 110813, 020110,
      % 090810
      o_specificValue = 234;
      
   case {1002, 1003, 1004, 1006, 1008, 1013, 1014}
      % Apex Argos
      % 062608, 061609, 021009, 093008, 021208, 071807, 082807
      o_specificValue = 254;
      
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1201, 1314}
      % Apex Iridium & Navis
      o_specificValue = 254;

   case {1021, 1022, 1321, 1322}
      % APF11 Argos & iridium (no specific value)
      o_specificValue = -1;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_park_and_prof_specific_value_apx for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return
