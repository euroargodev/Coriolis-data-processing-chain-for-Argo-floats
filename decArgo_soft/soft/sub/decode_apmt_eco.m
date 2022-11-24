% ------------------------------------------------------------------------------
% Decode ECO data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_ecoData] = decode_apmt_eco(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT ECO file to decode
%
% OUTPUT PARAMETERS :
%   o_ecoData : ECO decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ecoData] = decode_apmt_eco(a_inputFilePathName)

% output parameters initialization
o_ecoData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_eco: File not found: %s\n', a_inputFilePathName);
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
   case {7}
      fprintf('WARNING: decode_apmt_eco1 not implemented yet\n');
   case {8}
      o_ecoData = decode_apmt_eco2(data, lastByteNum, a_inputFilePathName);
   case {9}
      o_ecoData = decode_apmt_eco3(data, lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
