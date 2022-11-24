% ------------------------------------------------------------------------------
% Check report information structure for C-PROF VS B-PROF consistency.
%
% SYNTAX :
%  [o_cFileToCreate] = get_missing_c_prof_files
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_cFileToCreate : list and information on C-PROF files to generate
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cFileToCreate] = get_missing_c_prof_files

% output parameters initialization
o_cFileToCreate = [];

% report information structure
global g_decArgo_reportStruct;


% collect information on C-PROF and B-PROF files generated
cProfInfo = [];
bProfInfo = [];
for idFile = 1:length(g_decArgo_reportStruct.outputMonoProfFiles)
   filePathName = g_decArgo_reportStruct.outputMonoProfFiles{idFile};
   idF = strfind(filePathName, '/');
   fileName = filePathName(idF(end)+1:end);
   idF = strfind(fileName, '_');
   cyNum = str2double(fileName(idF+1:idF+3));
   if (fileName(end-3) == 'D')
      direction = 1;
   else
      direction = 2;
   end
   if (fileName(1) == 'R')
      cProfInfo = [cProfInfo; [cyNum direction str2double([num2str(cyNum) num2str(direction)])]];
   else
      bProfInfo = [bProfInfo; [cyNum direction str2double([num2str(cyNum) num2str(direction)])]];
   end
end

% compare two lists
if (~isempty(bProfInfo))
   [~, id] = setdiff(bProfInfo(:, 3), cProfInfo(:, 3));
   if (~isempty(id))
      o_cFileToCreate = bProfInfo(id, 1:2);
   end
end

return
