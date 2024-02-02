
% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5 float in standard format.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd_standard(a_data, a_lastByteNum, a_decoderId, a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_data              : input CTD data to decode
%   a_lastByteNum       : number of the last useful byte of the data
%   a_decoderId         : float decoder Id
%   a_inputFilePathName : APMT CTD file to decode
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
function [o_ctdData] = decode_apmt_ctd_standard(a_data, a_lastByteNum, a_decoderId, a_inputFilePathName)

% output parameters initialization
o_ctdData = [];

switch (a_decoderId)
   case {126, 127, 128, 129, 130, 131, 132, 133}
      [o_ctdData] = decode_apmt_ctd_standard_126_to_133(a_data, a_lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: decode_apmt_ctd_standard not defined yet for deciId #%d\n', ...
         a_decoderId);
      return
end

return