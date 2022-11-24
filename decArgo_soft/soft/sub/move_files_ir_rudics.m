% ------------------------------------------------------------------------------
% Move a list of files from a directory to another one.
%
% SYNTAX :
%  [o_ok] = move_files_ir_rudics(a_listFileNames, a_inputDir, a_outputDir, ...
%    a_updateXmlReportFlag)
%
% INPUT PARAMETERS :
%   a_listFileNames       : names of the files to move
%   a_inputDir            : input directory
%   a_outputDir           : output directory
%   a_updateXmlReportFlag : flag for adding or not the moved file path name in
%                           the XML report (in the "input file" section)
%
% OUTPUT PARAMETERS :
%   o_ok : move operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = move_files_ir_rudics(a_listFileNames, a_inputDir, a_outputDir, ...
   a_updateXmlReportFlag)

% output parameters initialization
o_ok = 1;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;


% move the files of the list
for idFile = 1:length(a_listFileNames)
   fileName = a_listFileNames{idFile};
   fileNameIn = [a_inputDir '/' fileName];
   fileNameOut = [a_outputDir '/' fileName];
   
   if (move_file(fileNameIn, fileNameOut) == 0)
      o_ok = 0;
      continue
   end
   
   if (a_updateXmlReportFlag == 1)
      if (g_decArgo_realtimeFlag == 1)
         % store information for the XML report
         g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
            {fileNameOut}];
      end
   end
end

return
