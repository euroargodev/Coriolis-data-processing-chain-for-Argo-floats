% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatLoginName, o_floatMailFiles, o_rsyncLogName] = ...
%    parse_rsync_log_ir_sbd(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : rsync log name to parse
%
% OUTPUT PARAMETERS :
%   o_floatLoginName : float login name list
%   o_floatMailFiles : Iridium mail file name list
%   o_rsyncLogName   : rsync log file name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatLoginName, o_floatMailFiles, o_rsyncLogName] = ...
   parse_rsync_log_ir_sbd(a_rsyncLogName)

% output parameters initialization
o_floatLoginName = [];
o_floatMailFiles = [];
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
floatMailFiles = [];
rsyncLogName = [];
for idL = 1:length(logData)
   line = logData{idL};
   if (length(line) > 3)
      if (strcmp(line(end-3:end), '.txt') == 1)
         % we are looking for lines with the pattern:
         % floatImei/co_xxxxxxxxxxxxxxxx_floatImei_xxxxxx_xxxxxx_PID.txt
         filePathName = line;
         [path, fileName, ~] = fileparts(filePathName);
         idF = strfind(fileName, '_');
         if (isempty(strfind(path, '/')) && (length(idF) == 5))
            floatLogin = fileName(idF(2)+1:idF(3)-1);
            if (strcmp(path, floatLogin) == 1)
               floatLoginName{end+1} = floatLogin;
               floatMailFiles{end+1} = filePathName;
               rsyncLogName{end+1} = a_rsyncLogName;
            end
         end
      end
   end
end

% output data
o_floatLoginName = floatLoginName;
o_floatMailFiles = floatMailFiles;
o_rsyncLogName = rsyncLogName;

return;
