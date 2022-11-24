% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatBinFiles] = parse_rsync_log_ir_rudics_cts4_111_113(a_rsyncLogName, a_floatLoginName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName   : rsync log file name to parse
%   a_floatLoginName : float login name to look for
%
% OUTPUT PARAMETERS :
%   o_floatBinFiles : binary file name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatBinFiles] = parse_rsync_log_ir_rudics_cts4_111_113(a_rsyncLogName, a_floatLoginName)

% output parameters initialization
o_floatBinFiles = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return;
end
logData = textscan(fId, '%s');
logData = logData{:};
fclose(fId);

for idL = 1:length(logData)
   line = logData{idL};
   % we are looking for lines with the pattern:
   % xxxxxx_xxxxxx_floatLoginName_xxxxx.bin
   if (length(line) > 3)
      if (strcmp(line(end-3:end), '.bin') == 1)
         
         fileName = line;
         idF = strfind(fileName, '_');
         if (length(idF) == 3)
            floatLogin = fileName(idF(2)+1:idF(3)-1);
            if (strcmp(floatLogin, a_floatLoginName) == 1)
               o_floatBinFiles{end+1} = fileName;
            end
         end
         
         %          if (strncmp(line, a_floatLoginName, length(a_floatLoginName)))
         %             filePathName = line;
         %             [path, fileName, ~] = fileparts(filePathName);
         %             idF = strfind(fileName, '_');
         %             if (isempty(strfind(path, '/')) && (length(idF) == 3))
         %                floatLogin = fileName(idF(2)+1:idF(3)-1);
         %                if (strcmp(path, floatLogin) == 1)
         %                   o_floatBinFiles{end+1} = filePathName;
         %                end
         %             end
         %          end
      end
   end
end

return;
