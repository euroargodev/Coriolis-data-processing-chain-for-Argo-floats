% ------------------------------------------------------------------------------
% Duplicate a list of files from a directory to another one.
%
% SYNTAX :
%  [o_ok] = duplicate_files_ir_cts4(a_listFileNames, a_inputDir, a_outputDir, a_floatDecId)
%
% INPUT PARAMETERS :
%   a_listFileNames : names of the files to duplicate
%   a_inputDir      : input directory
%   a_outputDir     : output directory
%   a_floatDecId    : float decoder Id
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
function [o_ok] = duplicate_files_ir_cts4(a_listFileNames, a_inputDir, a_outputDir, a_floatDecId)

% output parameters initialization
o_ok = 1;

switch (a_floatDecId)
   case {105, 106, 107, 108, 109, 110}
      % CTS4 floats (already in .sbd)
      
      % copy the files of the list
      for idFile = 1:length(a_listFileNames)
         fileName = a_listFileNames{idFile};
         fileNameIn = [a_inputDir '/' fileName];
         fileNamOut = [a_outputDir '/' fileName];
         if (copy_file(fileNameIn, fileNamOut) == 0)
            o_ok = 0;
            return;
         end
      end
      
   case {111}
      % CTS4 floats (in .bin)
      
      % copy the files of the list
      for idFile = 1:length(a_listFileNames)
         fileName = a_listFileNames{idFile};
         fileNameIn = [a_inputDir '/' fileName];
         fileNamOut = [a_outputDir '/' regexprep(fileName, '.bin', '.bin.sbd')];
         if (copy_file(fileNameIn, fileNamOut) == 0)
            o_ok = 0;
            return;
         end
      end
      
   otherwise
      fprintf('ERROR: don''t know how to duplicate files for decId #%d => exit\n', a_floatDecId);
      o_ok = 0;
      return;
end

return;
