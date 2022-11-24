% ------------------------------------------------------------------------------
% Decode OPUS data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_opusLightData, o_uvpBlackData] = decode_apmt_opus(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT OPUS file to decode
%
% OUTPUT PARAMETERS :
%   o_opusLightData : OPUS-LIGHT decoded data
%   o_uvpBlackData  : OPUS-BLACK decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/15/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_opusLightData, o_uvpBlackData] = decode_apmt_opus(a_inputFilePathName)

% output parameters initialization
o_opusLightData = [];
o_uvpBlackData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_opus: File not found: %s\n', a_inputFilePathName);
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
   case {24}
      o_opusLightData = decode_apmt_opus_light(data, lastByteNum, a_inputFilePathName);
   case {25}
      o_uvpBlackData = decode_apmt_opus_black(data, lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
