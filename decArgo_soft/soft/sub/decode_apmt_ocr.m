% ------------------------------------------------------------------------------
% Decode OCR data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_ocrData] = decode_apmt_ocr(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT OCR file to decode
%
% OUTPUT PARAMETERS :
%   o_ocrData : OCR decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ocrData] = decode_apmt_ocr(a_inputFilePathName)

% output parameters initialization
o_ocrData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_ocr: File not found: %s\n', a_inputFilePathName);
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
   case {4}
      o_ocrData = decode_apmt_ocr4(data, lastByteNum);
   case {5}
      fprintf('WARNING: decode_apmt_ocr7 not implemented yet\n');
   case {6}
      fprintf('WARNING: decode_apmt_ocr14 not implemented yet\n');
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
