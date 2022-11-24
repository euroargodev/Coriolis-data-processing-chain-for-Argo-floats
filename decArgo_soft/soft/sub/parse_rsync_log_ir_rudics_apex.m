% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatFiles] = parse_rsync_log_ir_rudics_apex(a_rsyncLogName, a_floatRudicsId)
%
% INPUT PARAMETERS :
%   a_rsyncLogName  : rsync log name to parse
%   a_floatRudicsId : float Rudics Id
%
% OUTPUT PARAMETERS :
%   o_floatFiles : float data files name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/17/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatFiles] = parse_rsync_log_ir_rudics_apex(a_rsyncLogName, a_floatRudicsId)

% output parameters initialization
o_floatFiles = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return;
end
logData = textscan(fId, '%s');
logData = logData{:};
fclose(fId);

ptn = sprintf('%04d/%04d_', str2double(a_floatRudicsId), str2double(a_floatRudicsId));
for idL = 1:length(logData)
   line = logData{idL};
   % we are looking for lines with the pattern: floatRudicsId/floatRudicsId_*
   if (strncmp(line, ptn, length(ptn)))
      o_floatFiles{end+1} = line;
   end
end

return;
