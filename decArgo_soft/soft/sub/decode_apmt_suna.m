% ------------------------------------------------------------------------------
% Decode SUNA data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_sunaData] = decode_apmt_suna(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT SUNA file to decode
%
% OUTPUT PARAMETERS :
%   o_sunaData : SUNA decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sunaData] = decode_apmt_suna(a_inputFilePathName)

% output parameters initialization
o_sunaData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_suna: File not found: %s\n', a_inputFilePathName);
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
   case {12}
      o_sunaData = decode_apmt_suna_45_pixels(data, lastByteNum, a_inputFilePathName);
   case {13}
      o_sunaData = decode_apmt_suna_90_pixels(data, lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
