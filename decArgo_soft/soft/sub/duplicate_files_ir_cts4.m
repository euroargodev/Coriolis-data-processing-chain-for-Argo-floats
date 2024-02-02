% ------------------------------------------------------------------------------
% Duplicate a list of files from a directory to another one.
%
% SYNTAX :
%  [o_ok] = duplicate_files_ir_cts4(a_listFileNames, a_inputDir, a_outputDir)
%
% INPUT PARAMETERS :
%   a_listFileNames : names of the files to duplicate
%   a_inputDir      : input directory
%   a_outputDir     : output directory
%
% OUTPUT PARAMETERS :
%   o_ok : copy operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = duplicate_files_ir_cts4(a_listFileNames, a_inputDir, a_outputDir)

global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_unusedDirectory;


% output parameters initialization
o_ok = 1;

% copy the files of the list
for idFile = 1:length(a_listFileNames)
   fileName = a_listFileNames{idFile};
   fileNameIn = [a_inputDir '/' fileName];
   fileNamOut = [a_outputDir '/' fileName];
   if (copy_file(fileNameIn, fileNamOut) == 0)
      o_ok = 0;
      return
   end
end

% specific
switch(g_decArgo_floatNum)
   case 6902902
      % files transmitted in 2023 should be ignored (bad cycle number and
      % dates due to emergency ascent)
      delFile = dir([a_outputDir '/230113_*.b64']);
      for idF = 1:length(delFile)
         move_file([a_outputDir '/' delFile(idF).name], g_decArgo_unusedDirectory);
      end
end

return
