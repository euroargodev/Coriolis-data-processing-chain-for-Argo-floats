
% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5 float in extended format.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd_extended(a_data, a_lastByteNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_data        : input CTD data to decode
%   a_lastByteNum : number of the last useful byte of the data
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ctdData : CTD decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData] = decode_apmt_ctd_extended(a_data, a_lastByteNum, a_decoderId)

% output parameters initialization
o_ctdData = [];

switch (a_decoderId)
   case {121, 122, 123, 124, 125}
      [o_ctdData] = decode_apmt_ctd_extended_121_2_125(a_data, a_lastByteNum);
   case {126}
      [o_ctdData] = decode_apmt_ctd_extended_126(a_data, a_lastByteNum);
   otherwise
      fprintf('ERROR: decode_event_data not defined yet for deciId #%d\n', ...
         a_decoderId);
      return
end

return