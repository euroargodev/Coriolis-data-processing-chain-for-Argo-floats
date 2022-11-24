% ------------------------------------------------------------------------------
% Create the list of existing files from a directory and a file pattern name.
%
% SYNTAX :
%  [o_fileList] = manage_split_files(a_inputFilePath, a_inputFileName)
%
% INPUT PARAMETERS :
%   a_inputFilePath : directory of the files
%   a_inputFileName : file pattern name
%
% OUTPUT PARAMETERS :
%   o_fileList : list of existing files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileList] = manage_split_files(a_inputFilePath, a_inputFileName)

% output parameters initialization
o_fileList = [];


% collect files
for idFile = 1:length(a_inputFileName)
   files = dir([a_inputFilePath{idFile} '/' a_inputFileName{idFile}]);
   if (~isempty(files))
      fileList = {files(:).name}';
      fileList = cat(2, fileList, cell(size(fileList)), cell(size(fileList)));
      if (~isempty(fileList))
         while (1)
            idF = strfind(fileList(:, 1), '#');
            if (~isempty(cell2mat(idF)))
               for idL = 1:size(fileList, 1)
                  if (~isempty(idF{idL}))
                     break;
                  end
               end
               fileName = fileList{idL, 1};
               fileNameBase = fileName(1:idF{idL});
               fileNameNew = fileName([1:idF{idL}-1  idF{idL}+3:end]);
               idF2 = strfind(fileList(:, 1), fileNameBase);
               fileSubList = [];
               idDel = [];
               for idL2 = 1:size(fileList, 1)
                  if (~isempty(idF2{idL2}))
                     if (isempty(fileSubList))
                        idFirst = idL2;
                     else
                        idDel = [idDel idL2];
                     end
                     fileSubList{end+1} = fileList{idL2, 1};
                  end
               end
               fileList{idFirst, 1} = fileNameNew;
               fileList{idFirst, 2} = fileSubList;
               fileList{idFirst, 3} = a_inputFilePath{idFile};
               fileList(idDel, :) = [];
            else
               break;
            end
         end
      end
      
      for idL = 1:size(fileList, 1)
         if (isempty(fileList{idL, 2}))
            fileList{idL, 2} = fileList(idL, 1);
            fileList{idL, 3} = a_inputFilePath{idFile};
         end
      end
      
      o_fileList = cat(1, o_fileList, fileList);
   end
end

% concat files
o_fileList = cat(2, o_fileList, cell(size(o_fileList, 1), 1));
for idFile = 1:size(o_fileList, 1)
   nbFiles = length(o_fileList{idFile, 2});
   if (nbFiles > 1)
      o_fileList{idFile, 4} = [fileList{idFile, 3} '/tmp/'];
      concat_files(fileList{idFile, 3}, fileList{idFile, 2}, ...
         o_fileList{idFile, 4}, fileList{idFile, 1});
   else
      o_fileList{idFile, 4} = fileList{idFile, 3};
   end
end

return;
