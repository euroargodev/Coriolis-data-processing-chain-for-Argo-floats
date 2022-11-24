% ------------------------------------------------------------------------------
% Retrieve information on a given item of a given virtual buffer list.
%
% SYNTAX :
%  [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_list_files_info_ir_sbd( ...
%    a_listName, a_fileName)
%
% INPUT PARAMETERS :
%   a_listName : name of the virtual buffer list
%   a_fileName : name of the file we need information
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
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_list_files_info_ir_sbd( ...
   a_listName, a_floatLaunchDate)

% output parameters initialization
o_fileName = [];
o_fileCycle = [];
o_fileDate = [];
o_fileSize = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;

% current float WMO number
global g_decArgo_floatNum;

% to use virtual buffers instead of directories
global g_decArgo_spoolFileList;
global g_decArgo_bufFileList;

% SBD sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_archiveSbdDirectory;


if (~ismember(a_listName, [{'spool'} {'buffer'}]))
   fprintf('BUFF_ERROR: Float #%d: add_to_list: unknown list name (''%s'')\n', ...
      g_decArgo_floatNum, a_listName);
   return
end

% check the files of the directory
if (strcmp(a_listName, 'spool'))
   list = g_decArgo_spoolFileList;
   directory = g_decArgo_archiveDirectory;
   ext = '.txt';
elseif (strcmp(a_listName, 'buffer'))
   list = g_decArgo_bufFileList;
   directory = g_decArgo_archiveSbdDirectory;
   ext = '.sbd';
end
for idFile = 1:length(list)
   
   file = list{idFile};
   file = [file(1:end-4) ext];
   files = dir([directory '/' file]);
   fileName = files(1).name;
   fileDate = datenum([fileName(4:11) fileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   o_fileName{end+1} = files(1).name;
   o_fileDate(end+1) = fileDate;
   o_fileSize(end+1) = files(1).bytes;
end

if (isempty(o_fileName))
   return
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

return
