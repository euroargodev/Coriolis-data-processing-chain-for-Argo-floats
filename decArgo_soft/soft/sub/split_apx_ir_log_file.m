% ------------------------------------------------------------------------------
% Split file contents according to provided first and last lines.
%
% SYNTAX :
%  split_apx_ir_log_file(a_inputFilePathName, a_outputFilePathName, a_firstLine, a_lastLine)
%
% INPUT PARAMETERS :
%   a_inputFilePathName  : input file path name
%   a_outputFilePathName : output file path name
%   a_firstLine          : first line to consider
%   a_lastLine           : last line to consider
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function split_apx_ir_log_file(a_inputFilePathName, a_outputFilePathName, a_firstLine, a_lastLine)
   

if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_inputFilePathName);
   return;
end

% open the input file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return;
end

lineNum = 0;
lines = [];
while (1)
   line = fgetl(fId);
   
   if (line == -1)
      break;
   end
   
   lineNum = lineNum + 1;
   if (a_lastLine ~= -1)
      if ((lineNum >= a_firstLine) && (lineNum <= a_lastLine))
         lines{end+1} = line;
      end
      if (lineNum >= a_lastLine)
         break;
      end
   else
      if (lineNum >= a_firstLine)
         lines{end+1} = line;
      end
   end
end

fclose(fId);

% store the data in the output file
fIdOut = fopen(a_outputFilePathName, 'wt');
if (fIdOut == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_outputFilePathName);
   return;
end

fprintf(fIdOut, '%s\n', lines{:});

fclose(fIdOut);

return;
