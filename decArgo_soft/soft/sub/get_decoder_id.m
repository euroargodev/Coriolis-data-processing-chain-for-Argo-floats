% ------------------------------------------------------------------------------
% Retrieve float decoder Id from DAC format version
%
% SYNTAX :
%  [o_decoderId] = get_decoder_id(a_dacFormatVersion)
%
% INPUT PARAMETERS :
%   a_dacFormatVersion : DAC format version
%
% OUTPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/17/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decoderId] = get_decoder_id(a_dacFormatVersion)

% output parameter initialization
o_decoderId = [];

switch (a_dacFormatVersion)
   case '4.2'
      o_decoderId = 1;
      
   case '4.21'
      o_decoderId = 11;
      
   case '4.22'
      o_decoderId = 12;
      
   case '4.23'
      o_decoderId = 24;
      
   case '4.4'
      o_decoderId = 4;
      
   case '4.41'
      o_decoderId = 19;
      
   case '4.42'
      o_decoderId = 27;
      
   case '4.43'
      o_decoderId = 25;
      
   case '4.44'
      o_decoderId = 28;
      
   case '4.45'
      o_decoderId = 29;
      
   case '4.5'
      o_decoderId = 3;
      
   case '4.51'
      o_decoderId = 17;
            
   case '5.9'
      o_decoderId = 105;
      
   otherwise
      fprintf('No decoderId for DAC format version %s\n', a_dacFormatVersion);
end

return;
