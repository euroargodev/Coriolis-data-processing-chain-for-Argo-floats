% ------------------------------------------------------------------------------
% Decode UVP data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_uvpLpmData, o_uvpBlackData] = decode_apmt_uvp(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT UVP file to decode
%
% OUTPUT PARAMETERS :
%   o_uvpLpmData   : UVP_LPM decoded data
%   o_uvpBlackData : UVP-BLK decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_uvpLpmData, o_uvpBlackData] = decode_apmt_uvp(a_inputFilePathName)

% output parameters initialization
o_uvpLpmData = [];
o_uvpBlackData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_uvp: File not found: %s\n', a_inputFilePathName);
   return
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return
end
data = fread(fId);
fclose(fId);

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

% decode the data according to the first byte flag
switch (data(1))
   case {14}
      o_uvpLpmData = decode_apmt_uvp_lpm(data, lastByteNum);
   case {15}
      fprintf('WARNING: decode_apmt_uvp_taxo_1 not implemented yet\n');
   case {16}
      fprintf('WARNING: decode_apmt_uvp_taxo_2 not implemented yet\n');
   case {17}
      o_uvpBlackData = decode_apmt_uvp_black(data, lastByteNum);
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
