% ------------------------------------------------------------------------------
% Convert float decoder Id to DAC format version
%
% SYNTAX :
% [o_dacFormatVersion] = get_dac_format_version(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_dacFormatVersion : DAC format version
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/25/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dacFormatVersion] = get_dac_format_version(a_decoderId)

% output parameter initialization
o_dacFormatVersion = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   case 1
      o_dacFormatVersion = '4.2';
   case 2
      o_dacFormatVersion = '4.1';
   case 3
      o_dacFormatVersion = '4.5';
   case 4
      o_dacFormatVersion = '4.4';
   case 5
      o_dacFormatVersion = '3.81';
   case 6
      o_dacFormatVersion = '1';
   case 7
      o_dacFormatVersion = ' ';
   case 8
      o_dacFormatVersion = '3.8';
   case 9
      o_dacFormatVersion = '3.61';
   case 10
      o_dacFormatVersion = '4.11';
   case 11
      o_dacFormatVersion = '4.21';
   case 12
      o_dacFormatVersion = '4.22';
   case 13
      o_dacFormatVersion = '2.6 & 2.7';
   case 14
      o_dacFormatVersion = '3.5';
   case 15
      o_dacFormatVersion = '2.2';
   case 16
      o_dacFormatVersion = '3.21';
   case 17
      o_dacFormatVersion = '4.51';
   case 18
      o_dacFormatVersion = ' ';
   case 19
      o_dacFormatVersion = '4.41';
   case 20
      o_dacFormatVersion = ' ';
   case 21
      o_dacFormatVersion = ' ';
   case 22
      o_dacFormatVersion = ' ';
   case 23
      o_dacFormatVersion = ' ';
   case 24
      o_dacFormatVersion = '4.23';
   case 101
      o_dacFormatVersion = '5.0';
   case 102
      o_dacFormatVersion = '5.1';
   case 103
      o_dacFormatVersion = '5.2';
   case 104
      o_dacFormatVersion = '5.4';
   case 105
      o_dacFormatVersion = '5.9';
   otherwise
      fprintf('WARNING: Float #%d: No DAC format version for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
