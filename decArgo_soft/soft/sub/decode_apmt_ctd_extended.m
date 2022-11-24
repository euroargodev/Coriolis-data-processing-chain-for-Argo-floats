
% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5 float in extended format.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd_extended(a_data, a_lastByteNum, a_decoderId, a_inputFilePathName)
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
%   09/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData] = decode_apmt_ctd_extended(a_data, a_lastByteNum, a_decoderId, a_inputFilePathName)

% output parameters initialization
o_ctdData = [];

switch (a_decoderId)
   case {121, 122, 123, 124, 125}
      [o_ctdData] = decode_apmt_ctd_extended_121_2_125(a_data, a_lastByteNum, a_inputFilePathName);
   case {126, 127}
      [o_ctdData] = decode_apmt_ctd_extended_126_127(a_data, a_lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: decode_apmt_ctd_extended not defined yet for deciId #%d\n', ...
         a_decoderId);
      return
end

return