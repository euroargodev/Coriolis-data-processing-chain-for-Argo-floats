% ------------------------------------------------------------------------------
% Read and decode SBD data file.
%
% SYNTAX :
%  [o_decodedData] = decode_sbd_file_cts4(a_sbdFileName, a_sbdFileDate, a_decoderId)
%
% INPUT PARAMETERS :
%   a_sbdFileName : SBD file name
%   a_sbdFileName : SBD file date
%   a_decoderId   : float decoder Id
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
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_sbd_file_cts4(a_sbdFileName, a_sbdFileDate, a_decoderId)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% SBD sub-directories
global g_decArgo_archiveDirectory;


% retrieve cycle number from SBD file name
g_decArgo_cycleNum = get_cycle_num_from_sbd_name_ir_rudics({a_sbdFileName});

% read SBD data
sbdFilePathName = [g_decArgo_archiveDirectory '/' a_sbdFileName];

fId = fopen(sbdFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
      g_decArgo_floatNum, ...
      sbdFilePathName);
end
sbdData = fread(fId);
fclose(fId);

if (strcmp(a_sbdFileName(end-3:end), '.b64'))
   idZ = find(sbdData == 0, 1, 'first');
   if (any(sbdData(idZ:end) ~= 0))
      fprintf('ERROR: Float #%d: Inconsistent data in file : %s\n', ...
         g_decArgo_floatNum, ...
         sbdFilePathName);
      return
   end
   sbdData = double(base64decode(sbdData(1:idZ-1), '', 'matlab'));
elseif (strcmp(a_sbdFileName(end-3:end), '.bin'))
   if (length(sbdData) == 1024)
      sbdData = sbdData(1:980);
   end
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
   fprintf('DEC_WARNING: Float #%d: input file ignored because of unexpected size (%d bytes)  : %s\n', ...
      g_decArgo_floatNum, ...
      length(sbdData), ...
      sbdFilePathName);
end

% decode SBD data
for idMsg = 1:size(sbdDataTab, 1)
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {111, 113, 114, 115} % Remocean V3.00 and higher
         
         % decode the collected data
         decodedData = decode_prv_data_ir_rudics_cts4_111_113_114_115(sbdDataTab(idMsg, :), ...
            a_sbdFileName, a_sbdFileDate, size(sbdDataTab, 1)*140);
         o_decodedData = cat(2, o_decodedData, decodedData);
            
      otherwise
         fprintf('WARNING: Float #%d: Nothing implemented yet in decode_sbd_file_cts4 for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
end

return
