% ------------------------------------------------------------------------------
% Read and decode SBD data file.
%
% SYNTAX :
%  [o_decodedData] = decode_sbd_file_cts4(a_sbdFileName, a_sbdFilePathName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_sbdFileName     : SBD file name
%   a_sbdFilePathName : SBD file path name
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_decodedData : decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_sbd_file_cts4(a_sbdFileName, a_sbdFilePathName, a_sbdFileDate)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;
g_decArgo_floatNum = 0;

% current cycle number
global g_decArgo_cycleNum;
g_decArgo_cycleNum = 0;


fId = fopen(a_sbdFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', ...
      a_sbdFilePathName);
   return
end
sbdData = fread(fId);
fclose(fId);

if (length(sbdData) == 1024)
   sbdData = sbdData(1:980);
end

sbdDataTab = [];
if (rem(length(sbdData), 140) == 0)
   sbdData = reshape(sbdData, 140, length(sbdData)/140)';
   for idMsg = 1:size(sbdData, 1)
      data = sbdData(idMsg, :);
      if ~((isempty(find(data ~= 0, 1)) || isempty(find(data ~= 26, 1))))
         sbdDataTab = cat(1, sbdDataTab, data);
      end
   end
else
   fprintf('DEC_WARNING: input file ignored because of unexpected size (%d bytes)  : %s\n', ...
      length(sbdData), ...
      sbdFilePathName);
end

% decode SBD data
for idMsg = 1:size(sbdDataTab, 1)
   
   % decode the collected data
   decodedData = decode_prv_data_ir_rudics_cts4_111_113_114_115(sbdDataTab(idMsg, :), ...
      a_sbdFileName, a_sbdFileDate, size(sbdDataTab, 1)*140);
   o_decodedData = cat(2, o_decodedData, decodedData);
end

return
