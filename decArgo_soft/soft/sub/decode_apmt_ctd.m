% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5 float.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd(a_inputFilePathName)
%
% INPUT PARAMETERS :
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData] = decode_apmt_ctd(a_inputFilePathName)

% output parameters initialization
o_ctdData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_ctd: File not found: %s\n', a_inputFilePathName);
   return;
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return;
end
data = fread(fId);
fclose(fId);

% for id = 1:length(data)
%    fprintf('%4d: ''%c''\n', id, data(id));
% end

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

% decode the data according to the first byte flag
if (data(1) == 1)
   o_ctdData = decode_apmt_ctd_extended(data, lastByteNum);
elseif (data(1) == 2)
   fprintf('WARNING: decode_apmt_ctd_standard not implemented yet\n');
   return;
else
   fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
   return;
end

return;
