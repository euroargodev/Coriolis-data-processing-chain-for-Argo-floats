
% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5 float in standard format.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd_standard(a_data, a_lastByteNum, a_decoderId)
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
%   02/15/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData] = decode_apmt_ctd_standard(a_data, a_lastByteNum, a_decoderId)

% output parameters initialization
o_ctdData = [];

switch (a_decoderId)
   case {126, 127}
      [o_ctdData] = decode_apmt_ctd_standard_126_127(a_data, a_lastByteNum);
   otherwise
      fprintf('ERROR: decode_apmt_ctd_standard not defined yet for deciId #%d\n', ...
         a_decoderId);
      return
end

return