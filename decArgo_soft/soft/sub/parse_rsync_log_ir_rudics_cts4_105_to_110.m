% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatSbdFiles] = parse_rsync_log_ir_rudics_cts4_105_to_110(a_rsyncLogName, a_floatLoginName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName   : rsync log file name to parse
%   a_floatLoginName : float login name to look for
%
% OUTPUT PARAMETERS :
%   o_floatSbdFiles  : SBD file name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatSbdFiles] = parse_rsync_log_ir_rudics_cts4_105_to_110(a_rsyncLogName, a_floatLoginName)

% output parameters initialization
o_floatSbdFiles = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return;
end
logData = textscan(fId, '%s %s');
fclose(fId);
infoData = logData{1};
logData = logData{2};

ptn1 = 'f+++++++++';
ptn2 = sprintf('%s/', a_floatLoginName);
for idL = 1:length(logData)
   % we are looking for lines with the pattern:
   % f+++++++++ floatLoginName/xxxxxx_xxxxxx_floatLoginName_xxxxx.b64.sbd
   % or
   % f+++++++++ floatLoginName/xxxxxx_xxxxxx_floatLoginName_xxxxx.bin.sbd
   if (~isempty(strfind(infoData{idL}, ptn1)) && ~isempty(strfind(logData{idL}, ptn2)))
      line = logData{idL};
      if (length(line) > 7)
         if ((strncmp(line(end-7:end), '.b64.sbd', length('.b64.sbd')) == 1) || ...
               (strncmp(line(end-7:end), '.bin.sbd', length('.bin.sbd')) == 1))
            
            filePathName = line;
            [path, fileName, ~] = fileparts(filePathName);
            idF = strfind(fileName, '_');
            if (isempty(strfind(path, '/')) && (length(idF) == 3))
               floatLogin = fileName(idF(2)+1:idF(3)-1);
               if (strcmp(floatLogin, a_floatLoginName))
                  o_floatSbdFiles{end+1} = filePathName;
               end
            end
         end
      end
   end
end

return;