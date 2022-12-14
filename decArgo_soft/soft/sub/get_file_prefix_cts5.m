% ------------------------------------------------------------------------------
% Retrieve the prefix of the files transmitted by a given float.
%
% SYNTAX :
%  [o_filePrefix] = get_file_prefix_cts5(a_dirName)
%
% INPUT PARAMETERS :
%   a_dirName : transmitted files directory
%
% OUTPUT PARAMETERS :
%   o_filePrefix : prefix of the files transmitted
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_filePrefix] = get_file_prefix_cts5(a_dirName)

% output parameters initialization
o_filePrefix = [];

% list of CTS5 files
global g_decArgo_provorCts5UseaFileTypeList;


% type of files to consider
fileTypeList = g_decArgo_provorCts5UseaFileTypeList;

fileNamePrefix = [];
for idType = 1:length(fileTypeList)
   files = dir([a_dirName fileTypeList{idType}]);
   for idFile = 1:length(files)
      fileName = files(idFile).name;
      fileNamePrefix{end+1} = fileName(1:4);
   end
end

% get file prefix
if (length(unique(fileNamePrefix)) == 1)
   o_filePrefix = unique(fileNamePrefix);
   o_filePrefix = o_filePrefix{:};
else
   uFileNamePrefix = unique(fileNamePrefix);
   maxCount = 0;
   idCount = 0;
   for idP = 1:length(uFileNamePrefix)
      if (length(find(strcmp(fileNamePrefix, uFileNamePrefix{idP}))) > maxCount)
         maxCount = length(find(strcmp(fileNamePrefix, uFileNamePrefix{idP})));
         idCount = idP;
      end
   end
   o_filePrefix = uFileNamePrefix{idCount};
   fprintf('DEC_WARNING: Multiple prefix in input files: ''%s'' is used\n', o_filePrefix);
end

return
