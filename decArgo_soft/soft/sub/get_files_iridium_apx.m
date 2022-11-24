% ------------------------------------------------------------------------------
% Retrieve the list of existing .log and .msg files for a float and a given
% cycle.
%
% SYNTAX :
%  [o_msgFileList, o_logFileList] = get_files_iridium_apx( ...
%    a_floatNum, a_floatRudicsId, a_cycleNum, a_dirName)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_floatRudicsId : float Rudics Id
%   a_cycleNum      : concerned cycle number
%   a_dirName       : directory containing the files
%
% OUTPUT PARAMETERS :
%   o_msgFileList : .msg file name
%   o_logFileList : .log file names list
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_msgFileList, o_logFileList] = get_files_iridium_apx( ...
   a_floatNum, a_floatRudicsId, a_cycleNum, a_dirName)

% output parameters initialization
o_msgFileList = [];
o_logFileList = [];


% search for Iridium msg and log files
floatIriDirName = a_dirName;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return
end

% msg files
fileNames = dir([floatIriDirName sprintf('%04d', a_floatRudicsId) '_*_' num2str(a_floatNum) '_' sprintf('%03d', a_cycleNum) '_*.msg']);
for idFile = 1:length(fileNames)
   o_msgFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

% log files
fileNames = dir([floatIriDirName sprintf('%04d', a_floatRudicsId) '_*_' num2str(a_floatNum) '_' sprintf('%03d', a_cycleNum) '_*.log']);
for idFile = 1:length(fileNames)
   o_logFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

return
