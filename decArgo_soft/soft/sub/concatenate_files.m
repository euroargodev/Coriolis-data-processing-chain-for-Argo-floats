% ------------------------------------------------------------------------------
% Concatenate the content of 2 files.
%
% SYNTAX :
% [o_ok] = concatenate_files(a_baseFile, a_newFile)
%
% INPUT PARAMETERS :
%   a_baseFile : base file path name
%   a_newFile  : new file path name
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
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = concatenate_files(a_baseFile, a_newFile)

% output parameters initialization
o_ok = 1;


if ~(exist(a_baseFile, 'file') == 2)
   % if the base file does not exist copy the new file
   if (copy_file(a_newFile, a_baseFile) == 0)
      o_ok = 0;
      return;
   end
else
   
   % before concatenating the files, check their contents
   fidBase = fopen(a_baseFile, 'r');
   if (fidBase == -1)
      fprintf('ERROR: Unable to open file: %s\n', a_baseFile);
      o_ok = 0;
      return;
   end
   baseFileContents = textscan(fidBase, '%s');
   fclose(fidBase);
   
   fidNew = fopen(a_newFile, 'r');
   if (fidNew == -1)
      fprintf('ERROR: Unable to open file: %s\n', a_newFile);
      o_ok = 0;
      return;
   end
   newFileContents = textscan(fidNew, '%s');
   fclose(fidNew);
   
   compRes = 1;
   baseFileContents = baseFileContents{:};
   newFileContents = newFileContents{:};
   for idL = 1:min([length(baseFileContents) length(newFileContents)])
      if ((length(baseFileContents) >= idL) && (length(newFileContents) >= idL))
         if (strcmp(baseFileContents{idL}, newFileContents{idL}) == 0)
            compRes = 2;
            break;
         end
      elseif (length(baseFileContents) >= idL)
         compRes = 3;
         break;
      elseif (length(newFileContents) >= idL)
         compRes = 4;
         break;
      end
   end

   if (compRes == 1)
      
      % files are identical
      fprintf('DEC_INFO: Files %s and %s are identical => not concatenated\n', a_baseFile, a_newFile);
      
   elseif (compRes == 3)
      
      % new file contents is included in base file
      fprintf('DEC_INFO: File %s includes file %s contents => not concatenated\n', a_baseFile, a_newFile);
      
   elseif (compRes == 4)
      
      % base file contents is included in new file
      fprintf('DEC_INFO: File %s includes file %s contents => replace %s by %s\n', a_newFile, a_baseFile, a_baseFile, a_newFile);
      
      if (copy_file(a_newFile, a_baseFile) == 0)
         o_ok = 0;
         return;
      end
   
   elseif (compRes == 2)
      % the 2 files contents differ, concatenate them

      % concatenate new file content in the base file
      fidBase = fopen(a_baseFile, 'a');
      if (fidBase == -1)
         fprintf('ERROR: Unable to open file: %s\n', a_baseFile);
         o_ok = 0;
         return;
      end
      
      fidNew = fopen(a_newFile, 'r');
      if (fidNew == -1)
         fprintf('ERROR: Unable to open file: %s\n', a_newFile);
         o_ok = 0;
         return;
      end
      
      while (1)
         line = fgetl(fidNew);
         if (line == -1)
            break;
         end
         
         fprintf(fidBase, '%s\n', line);
      end
      
      fclose(fidNew);
      fclose(fidBase);
   end
end

return;
