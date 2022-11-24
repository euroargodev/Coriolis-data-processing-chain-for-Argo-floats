% ------------------------------------------------------------------------------
% Decode RAMSES data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_ramsesData, o_ramses2Data] = decode_apmt_ramses(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT RAMSES file to decode
%
% OUTPUT PARAMETERS :
%   o_ramsesData  : RAMSES decoded data
%   o_ramses2Data : RAMSES V2 decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ramsesData, o_ramses2Data] = decode_apmt_ramses(a_inputFilePathName)

% output parameters initialization
o_ramsesData = [];
o_ramses2Data = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_ramses: File not found: %s\n', a_inputFilePathName);
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
   case {23}
      o_ramsesData = decode_apmt_ramses_data(data, lastByteNum, a_inputFilePathName);
   case {32}
      o_ramses2Data = decode_apmt_ramses_data(data, lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
