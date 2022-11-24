% ------------------------------------------------------------------------------
% Retrieve or compute message types from Argos data
%
% SYNTAX :
% [o_messageType] = get_message_type(a_data, a_decoderId)
%
% INPUT PARAMETERS :
%   a_data      : data of the Argos message
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_messageType : retrieved message types
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_messageType] = get_message_type(a_data, a_decoderId)

% output parameter initialization
o_messageType = [];

switch (a_decoderId)
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31, 32}
      o_messageType = bitshift(a_data(:, 1), -4);
   otherwise
      fprintf('WARNING: Nothing done yet in get_message_type for decoderId #%d\n', ...
         a_decoderId);
end

return
