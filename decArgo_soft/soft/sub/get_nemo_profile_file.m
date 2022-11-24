% ------------------------------------------------------------------------------
% Retrieve the name of existing .profile file for given float and cycle.
%
% SYNTAX :
%  [o_profileFile] = get_nemo_profile_file(a_floatNum, a_floatRudicsId, a_cycleNum, a_dirName)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_floatRudicsId : float Rudics Id
%   a_cycleNum      : concerned cycle number
%   a_dirName       : directory containing the files
%
% OUTPUT PARAMETERS :
%   o_profileFile : .profile file name
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profileFile] = get_nemo_profile_file(a_floatNum, a_floatRudicsId, a_cycleNum, a_dirName)

% output parameters initialization
o_profileFile = [];


% search for profile file
floatIriDirName = a_dirName;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return
end

% profile file
fileNames = dir([floatIriDirName sprintf('%04d', a_floatRudicsId) '_' num2str(a_floatNum) '*' sprintf('%04d', a_cycleNum) '.profile']);
for idFile = 1:length(fileNames)
   o_profileFile{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

if (length(o_profileFile) > 1)
   fprintf('ERROR: Float #%d Cycle #%d: %d .profile files (only one is expected) => only the last one is considered\n', ...
      a_floatNum, a_cycleNum, length(o_profileFile));
   o_profileFile = o_profileFile(end);
end

o_profileFile = o_profileFile{:};

return
