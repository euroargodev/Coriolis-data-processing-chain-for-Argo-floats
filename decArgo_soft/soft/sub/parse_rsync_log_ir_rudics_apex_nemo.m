% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatFiles] = parse_rsync_log_ir_rudics_apex_nemo(a_rsyncLogName, a_floatRudicsId)
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
function [o_floatFiles] = parse_rsync_log_ir_rudics_apex_nemo(a_rsyncLogName, a_floatRudicsId)

% output parameters initialization
o_floatFiles = [];

% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return
end
logData = textscan(fId, '%s %s');
% logData = logData{:};
infoData = logData{1};
logData = logData{2};
fclose(fId);

ptn1 = sprintf('%s/%s.', a_floatRudicsId, a_floatRudicsId);
ptn2 = '>f+++++++++';
ptn3 = sprintf('%s.', a_floatRudicsId);
% we are looking for lines with the pattern:
% floatRudicsId/floatRudicsId.* or >f+++++++++ floatRudicsId.*
for idL = 1:length(logData)
   col1 = infoData{idL};
   col2 = logData{idL};
   if (strncmp(col1, ptn1, length(ptn1)))
      o_floatFiles{end+1} = col1;
   elseif (strncmp(col1, ptn2, length(ptn2)) && any(strfind(col2, ptn3)))
      o_floatFiles{end+1} = sprintf('%s/%s', a_floatRudicsId, col2);
   end
end

return
