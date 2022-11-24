% ------------------------------------------------------------------------------
% Create the list of existing files from a directory and a file pattern name.
%
% SYNTAX :
%  [o_fileList] = manage_split_files(a_inputFilePath, a_inputFileName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_inputFilePath : directory of the files
%   a_inputFileName : file pattern name
%   a_decoderId     : float decoder Id
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
function [o_fileList] = manage_split_files(a_inputFilePath, a_inputFileName, a_decoderId)

% output parameters initialization
o_fileList = [];

% current float WMO number
global g_decArgo_floatNum;


% ANOMALY in V1.06.010 AMPT version concerning payload data file:
% sometimes the information '#01' is missing in the name of the first splitted file
% Ex: 003a_009_01_payload.bin, 003a_009_01_payload#02.bin
if (a_decoderId == 122)
   for idFilePtn = 1:length(a_inputFileName)
      if (any(strfind(a_inputFileName{idFilePtn}, '_payload*.bin')))
         files = dir([a_inputFilePath{idFilePtn} '/' a_inputFileName{idFilePtn}]);
         if (~isempty(files))
            fileList = {files(:).name}';
            idF = strfind(fileList, '#');
            if (~isempty(cell2mat(idF)))
               if (length(cell2mat(idF)) ~= length(fileList))
                  idExist = cellfun(@(x) strfind(fileList, x), {'_payload#02_'}, 'UniformOutput', 0);
                  idExist = find(~cellfun(@isempty, idExist{:}) == 1);
                  idToMove = cellfun(@(x) strfind(fileList, x), {'_payload_'}, 'UniformOutput', 0);
                  idToMove = find(~cellfun(@isempty, idToMove{:}) == 1);
                  if (~isempty(idExist) && ~isempty(idToMove))
                     fileNameNew = regexprep(fileList{idToMove}, '_payload_', '_payload#01_');
                     move_file([a_inputFilePath{idFilePtn} '/' fileList{idToMove}], ...
                        [a_inputFilePath{idFilePtn} '/' fileNameNew]);
                     fprintf('DEC_WARNING: Float #%d: File naming anomaly (%s renamed %s)\n', ...
                        g_decArgo_floatNum, ...
                        fileList{idToMove}, ...
                        fileNameNew);
                  end
               end
            end
         end
      end
   end
end

% collect files and associated information
for idFilePtn = 1:length(a_inputFileName)
   files = dir([a_inputFilePath{idFilePtn} '/' a_inputFileName{idFilePtn}]);
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
               fileList{idFirst, 3} = a_inputFilePath{idFilePtn};
               fileList(idDel, :) = [];
            else
               break;
            end
         end
      end
      
      for idL = 1:size(fileList, 1)
         if (isempty(fileList{idL, 2}))
            fileList{idL, 2} = fileList(idL, 1);
            fileList{idL, 3} = a_inputFilePath{idFilePtn};
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
