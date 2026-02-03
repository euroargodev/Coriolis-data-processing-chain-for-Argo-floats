% ------------------------------------------------------------------------------
% Split EasyOneArgo data set in 2 directories (so that the size of the archives
% is < 3 Gbytes).
%
% SYNTAX :
%  split_one_argo_data_set
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/18/2025 - RNU - creation
% ------------------------------------------------------------------------------
function split_one_argo_data_set

INPUT_DIR = 'C:\Users\jprannou\_DATA\ONE_ARGO\OUT_TMP\OneArgoCoreEov_20250119T103533Z';

newDirName = 'OneArgoCoreEov_20250119T103533Z_part1';
newDirPathName = [INPUT_DIR '/../' newDirName '/'];
mkdir(newDirPathName);

files = dir([INPUT_DIR '/*.csv']);
for id = 1:length(files)/2
   move_file([INPUT_DIR '/' files(id).name], newDirPathName);
end

return
