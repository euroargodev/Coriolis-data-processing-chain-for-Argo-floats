% ------------------------------------------------------------------------------
% Concatenate the content of N files.
%
% SYNTAX :
%  [o_ok] = concat_files(a_inputDirName, a_inputFiles, a_outputDirName, a_outputFile)
%
% INPUT PARAMETERS :
%   a_inputDirName  : input files dir name
%   a_inputFiles    : input files names
%   a_outputDirName : output file dir name
%   a_outputFile    : output file name
%
% OUTPUT PARAMETERS :
%   o_ok : concatenation operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = concat_files(a_inputDirName, a_inputFiles, a_outputDirName, a_outputFile)

% output parameters initialization
o_ok = 1;

% concatenate files in the provided order
for idF = 1:length(a_inputFiles)
   if (~isempty(a_inputFiles{idF}))
      inputFilePathName = [a_inputDirName a_inputFiles{idF}];
      outputFilePathName = [a_outputDirName a_outputFile];
      if (idF == 1)
         if (copy_file(inputFilePathName, outputFilePathName) == 0)
            o_ok = 0;
            return
         end
      else

         % concatenate input file content in the output file
         fidOutput = fopen(outputFilePathName, 'a');
         if (fidOutput == -1)
            fprintf('ERROR: Unable to open file: %s\n', outputFilePathName);
            o_ok = 0;
            return
         end

         fidInput = fopen(inputFilePathName, 'r');
         if (fidInput == -1)
            fprintf('ERROR: Unable to open file: %s\n', inputFilePathName);
            o_ok = 0;
            return
         end

         fwrite(fidOutput, fread(fidInput));

         fclose(fidInput);
         fclose(fidOutput);
      end
   end
end

return
