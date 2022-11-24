% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatImei, o_floatSbdFiles, o_rsyncLogName] = ...
%    parse_rsync_log_ir_sbd2(a_rsyncLogName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName : rsync log name to parse
%
% OUTPUT PARAMETERS :
%   o_floatImei : float login name list
%   o_floatSbdFiles  : SBD file name list
%   o_rsyncLogName   : rsync log file name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/02/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatImei, o_floatSbdFiles, o_rsyncLogName] = ...
   parse_rsync_log_ir_sbd2(a_rsyncLogName)

% output parameters initialization
o_floatImei = [];
o_floatSbdFiles = [];
o_rsyncLogName = [];


% read the log file and store the useful information
fId = fopen(a_rsyncLogName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_rsyncLogName);
   return
end
logData = textscan(fId, '%s');
logData = logData{:};
fclose(fId);

floatImeiName = [];
floatSbdFiles = [];
rsyncLogName = [];
for idL = 1:length(logData)
   line = logData{idL};
   if (length(line) > 3)
      if (strncmp(line(end-3:end), '.txt', length('.txt')) == 1)
         % we are looking for lines with the pattern:
         % IMEI/co_YYYYmmddTHHMMSSZ_IMEI_MOMSN_MTMSN_PID.txt
         filePathName = line;
         [path, fileName, ~] = fileparts(filePathName);
         idF = strfind(fileName, '_');
         if (isempty(strfind(path, '/')) && (length(idF) == 5))
            floatImei = fileName(idF(2)+1:idF(3)-1);
            if (strcmp(path, floatImei) == 1)
               floatImeiName{end+1} = floatImei;
               floatSbdFiles{end+1} = filePathName;
               rsyncLogName{end+1} = a_rsyncLogName;
            end
         end
      end
   end
end

% output data
o_floatImei = floatImeiName;
o_floatSbdFiles = floatSbdFiles;
o_rsyncLogName = rsyncLogName;

return
