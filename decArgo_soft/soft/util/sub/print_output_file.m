% ------------------------------------------------------------------------------
% Create Argos cycle file.
%
% SYNTAX :
%  print_output_file(a_dirName, a_fileName, ...
%    a_satLine, a_floatMsgLines, a_floatMsgDuplicatedLines, a_lineId)
%
% INPUT PARAMETERS :
%   a_dirName                 : file directory
%   a_fileName                : file name
%   a_satLine                 : line of the satellite header
%   a_floatMsgLines           : lines of each Argos message
%   a_floatMsgDuplicatedLines : flag for duplicated message
%   a_lineId                  : lines to print
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/15/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_output_file(a_dirName, a_fileName, ...
   a_satLine, a_floatMsgLines, a_floatMsgDuplicatedLines, a_lineId)


% create the output file
outputFileName = [a_dirName '/' a_fileName];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', outputFileName);
   return;
end

nbLines = 1;
for idL = 1:length(a_lineId)
   if (a_floatMsgDuplicatedLines(a_lineId(idL)) == 0)
      lines = a_floatMsgLines{a_lineId(idL)};
      nbLines = nbLines + length(lines);
   end
end
idFB = strfind(a_satLine, ' ');
fprintf(fidOut, '%s\n', [a_satLine(1:idFB(2)) num2str(nbLines) a_satLine(idFB(3):end)]);
for idL = 1:length(a_lineId)
   if (a_floatMsgDuplicatedLines(a_lineId(idL)) == 0)
      lines = a_floatMsgLines{a_lineId(idL)};
      for id = 1:length(lines)
         fprintf(fidOut, '%s\n', lines{id});
      end
   end
end

fclose(fidOut);

return;
