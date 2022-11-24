% ------------------------------------------------------------------------------
% Parse one rsync log file and retrieve useful information.
%
% SYNTAX :
%  [o_floatFiles] = parse_rsync_log_ir_rudics_cts5(a_rsyncLogName, a_floatLoginName)
%
% INPUT PARAMETERS :
%   a_rsyncLogName   : rsync log name to parse
%   a_floatLoginName : float login name
%
% OUTPUT PARAMETERS :
%   o_floatFiles : RUDICS file name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatFiles] = parse_rsync_log_ir_rudics_cts5(a_rsyncLogName, a_floatLoginName)

% output parameters initialization
o_floatFiles = [];


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
ptnList = [ ...
   {'_apmt'} {'.ini'}; ...
   {'_autotest_'} {'.txt'}; ...
   {'_default_'} {'.txt'}; ...
   {'_technical'} {'.txt'}; ...
   {'_payload'} {'.bin'}; ...
   {'_payload_'} {'.txt'}; ...
   {'_payload'} {'.xml'}; ...
   {'_sbe41'} {'.hex'}; ...
   {'_system_'} {'.hex'}; ...
   ];
for idL = 1:length(logData)
   % we are looking for lines with the pattern:
   % f+++++++++ xxxxxx
   % with xxxxxx containing both information (pattern and extension) listed in ptnList
   %    if (~isempty(strfind(infoData{idL}, ptn1)) && ~isempty(strfind(logData{idL}, ptn2)))
   if (~isempty(strfind(infoData{idL}, ptn1)))
      
      fileName = logData{idL};
      for idPtn = 1:size(ptnList, 1)
         if (~isempty(strfind(fileName, ptnList{idPtn, 1})) && ...
               strcmp(fileExt, ptnList{idPtn, 2}))
            o_floatFiles{end+1} = [ptn2 fileName];
            break;
         end
      end
      
      %       filePathName = logData{idL};
      %       [filePath, fileName, fileExt] = fileparts(filePathName);
      %       if (isempty(strfind(filePath, '/')))
      %          for idPtn = 1:size(ptnList, 1)
      %             if (~isempty(strfind(fileName, ptnList{idPtn, 1})) && ...
      %                   strcmp(fileExt, ptnList{idPtn, 2}))
      %                o_floatFiles{end+1} = filePathName;
      %                break;
      %             end
      %          end
      %       end
   end
end

return;
