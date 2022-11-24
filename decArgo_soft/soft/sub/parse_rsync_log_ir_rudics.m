% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatLoginName, o_floatSbdFiles, o_rsyncLogName] = ...
%    parse_rsync_log_ir_rudics(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : rsync log name to parse
%
% OUTPUT PARAMETERS :
%   o_floatLoginName : float login name list
%   o_floatSbdFiles  : SBD file name list
%   o_rsyncLogName   : rsync log file name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatLoginName, o_floatSbdFiles, o_rsyncLogName] = ...
   parse_rsync_log_ir_rudics(a_rsyncLogName)

% output parameters initialization
o_floatLoginName = [];
o_floatSbdFiles = [];
o_rsyncLogName = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return;
end
logData = textscan(fId, '%s');
logData = logData{:};
fclose(fId);

floatLoginName = [];
floatSbdFiles = [];
rsyncLogName = [];
for idL = 1:length(logData)
   line = logData{idL};
   if (length(line) > 7)
      if ((strncmp(line(end-7:end), '.b64.sbd', length('.b64.sbd')) == 1) || ...
            (strncmp(line(end-7:end), '.bin.sbd', length('.bin.sbd')) == 1))
         % we are looking for lines with the pattern:
         % floatLoginName/xxxxxx_xxxxxx_floatLoginName_xxxxx.b64.sbd
         % or
         % floatLoginName/xxxxxx_xxxxxx_floatLoginName_xxxxx.bin.sbd
         filePathName = line;
         [path, fileName, ~] = fileparts(filePathName);
         idF = strfind(fileName, '_');
         if (isempty(strfind(path, '/')) && (length(idF) == 3))
            floatLogin = fileName(idF(2)+1:idF(3)-1);
            if (strcmp(path, floatLogin) == 1)
               floatLoginName{end+1} = floatLogin;
               floatSbdFiles{end+1} = filePathName;
               rsyncLogName{end+1} = a_rsyncLogName;
            end
         end
      end
   end
end

% output data
o_floatLoginName = floatLoginName;
o_floatSbdFiles = floatSbdFiles;
o_rsyncLogName = rsyncLogName;

return;
