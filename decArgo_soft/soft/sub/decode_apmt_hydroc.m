% ------------------------------------------------------------------------------
% Decode HYDROC data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_hydrocMData, o_hydrocCData] = decode_apmt_hydroc(a_fileNameInfo)
%
% INPUT PARAMETERS :
%   a_fileNameInfo : information on APMT OPUS file to decode
%
% OUTPUT PARAMETERS :
%   o_hydrocMData : HYDROC-M decoded data
%   o_hydrocCData : HYDROC-C decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_hydrocMData, o_hydrocCData] = decode_apmt_hydroc(a_fileNameInfo)

% output parameters initialization
o_hydrocMData = [];
o_hydrocCData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


% input data file
inputFilePathName = [a_fileNameInfo{4} a_fileNameInfo{1}];

if ~(exist(inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_hydroc: File not found: %s\n', inputFilePathName);
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
      case {30}
         o_hydrocMData = decode_apmt_hydroc_m_or_c(data, lastByteNum, inputFilePathName);
      case {31}
         o_hydrocCData = decode_apmt_hydroc_m_or_c(data, lastByteNum, inputFilePathName);
      otherwise
         fprintf('ERROR: Unexpected file type byte (%d) in file: %s\n', data(1), inputFilePathName);
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
