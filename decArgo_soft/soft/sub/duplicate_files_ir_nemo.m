% ------------------------------------------------------------------------------
% Duplicate a list of files from a directory to another one.
%
% SYNTAX :
%  [o_ok] = duplicate_files_ir_nemo(a_listFileNames, a_inputDir, a_outputDir)
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
%   02/14/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = duplicate_files_ir_nemo(a_floatNum, a_listFileNames, a_inputDir, a_outputDir)

% output parameters initialization
o_ok = 1;

% copy the files of the list
for idFile = 1:length(a_listFileNames)
   fileNameIn = a_listFileNames{idFile};
   filePathNameIn = [a_inputDir '/' fileNameIn];
   [~, fileNameOut, fileExt] = fileparts(filePathNameIn);
   fileNameOut = [fileNameOut(1:4) '_' num2str(a_floatNum) fileNameOut(5:end) fileExt];
   filePathNameOut = [a_outputDir '/archive/' fileNameOut];
   if (copy_file(filePathNameIn, filePathNameOut) == 0)
      o_ok = 0;
      return
   end
end

return
