% ------------------------------------------------------------------------------
% Retrieve information from files in a given directory.
%
% SYNTAX :
%  [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_dir_files_info_ir_sbd( ...
%    a_dirName, a_floatImei, a_fileExt, a_floatLaunchDate)
%
% INPUT PARAMETERS :
%   a_dirName         : concerned directory
%   a_floatImei       : float IMEI
%   a_fileExt         : file extension
%   a_floatLaunchDate : float launch date
%
% OUTPUT PARAMETERS :
%   o_fileName  : file names
%   o_fileCycle : file cycle numbers
%   o_fileDate  : file dates
%   o_fileSize  : file sizes
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_dir_files_info_ir_sbd( ...
   a_dirName, a_floatImei, a_fileExt, a_floatLaunchDate)

% output parameters initialization
o_fileName = [];
o_fileCycle = [];
o_fileDate = [];
o_fileSize = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;


% check the files of the directory
dirFiles = dir([a_dirName '/' sprintf('*_%d_*.%s', a_floatImei, a_fileExt)]);
for idFile = 1:length(dirFiles)
   
   dirFileName = dirFiles(idFile).name;
   dirFileDate = datenum([dirFileName(4:11) dirFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   o_fileName{end+1} = dirFileName;
   o_fileDate(end+1) = dirFileDate;
   o_fileSize(end+1) = dirFiles(idFile).bytes;
end

if (isempty(o_fileName))
   return;
end

% chronologically sort the files
[o_fileDate, idSort] = sort(o_fileDate);
o_fileName = o_fileName(idSort);
o_fileSize = o_fileSize(idSort);

% create what could be the cycle numbers
if (~isempty(a_floatLaunchDate))
   idSplit = find(diff(o_fileDate) > g_decArgo_minSubSurfaceCycleDuration/24);
   cyNum = 0;
   idStart = 1;
   for id = 1:length(idSplit)+1
      if (id <= length(idSplit))
         idStop = idSplit(id);
      else
         idStop = length(o_fileDate);
      end
      
      if (o_fileDate(idStop) < a_floatLaunchDate)
         o_fileCycle(idStart:idStop) = cyNum;
      else
         o_fileCycle(idStart:idStop) = cyNum;
         cyNum = cyNum + 1;
      end
      
      idStart = idStop + 1;
   end
end

return;
