% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5 float.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd(a_fileNameInfo, a_decoderId)
%
% INPUT PARAMETERS :
%   a_fileNameInfo : information on APMT CTD file to decode
%   a_decoderId    : float decoder Id
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
function [o_ctdData] = decode_apmt_ctd(a_fileNameInfo, a_decoderId)

% output parameters initialization
o_ctdData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


% input data file
inputFilePathName = [a_fileNameInfo{4} a_fileNameInfo{1}];

if ~(exist(inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_ctd: File not found: %s\n', inputFilePathName);
   return
end

% open the file and read the data
fId = fopen(inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', inputFilePathName);
   return
end
data = fread(fId);
fclose(fId);

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

try

   % decode the data according to the first byte flag
   switch (data(1))
      case {1}
         o_ctdData = decode_apmt_ctd_extended(data, lastByteNum, a_decoderId, inputFilePathName);
      case {2}
         o_ctdData = decode_apmt_ctd_standard(data, lastByteNum, a_decoderId, inputFilePathName);
      otherwise
         fprintf('ERROR: Unexpected file type byte in file: %s\n', inputFilePathName);
   end

catch MException
   switch MException.identifier
      case 'MATLAB:badsubscript'

         fprintf('ERROR: Float #%d: (Cy,Ptn)=(%d,%d): File ''%s'' is inconsistent (shorter than expected) - file ignored\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            a_fileNameInfo{1});
         return
   end
   rethrow(MException)
end

return
