% ------------------------------------------------------------------------------
% Retrieve information on a given item of a given virtual buffer list.
%
% SYNTAX :
%  [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_list_files_info_ir_rudics( ...
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
function [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_list_files_info_ir_rudics( ...
   a_listName, a_fileName)

% output parameters initialization
o_fileName = [];
o_fileCycle = [];
o_fileDate = [];
o_fileSize = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;

% to use virtual buffers instead of directories
global g_decArgo_spoolFileList;
global g_decArgo_bufFileList;

% SBD sub-directories
global g_decArgo_archiveDirectory;


if (~ismember(a_listName, [{'spool'} {'buffer'}]))
   fprintf('BUFF_ERROR: Float #%d: add_to_list: unknown list name (''%s'')\n', ...
      g_decArgo_floatNum, a_listName);
   return;
end

% check the SBD files of the directory
if (strcmp(a_listName, 'spool'))
   list = g_decArgo_spoolFileList;
elseif (strcmp(a_listName, 'buffer'))
   list = g_decArgo_bufFileList;
end

if (isempty(a_fileName))
   sbdFileList = list;
else
   sbdFileList = {a_fileName};
end
for idFile = 1:length(sbdFileList)
   
   sbdFile = sbdFileList{idFile};
   sbdFiles = dir([g_decArgo_archiveDirectory '/' sbdFile]);
   sbdFileName = sbdFiles(1).name;
   sbdFileDate = datenum(sbdFileName(1:13), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   o_fileName{end+1} = sbdFileName;
   o_fileCycle(end+1) = str2num(sbdFileName(end-12:end-8));
   o_fileDate(end+1) = sbdFileDate;
   o_fileSize(end+1) = sbdFiles(1).bytes;
end

% chronologically sort the files
[o_fileDate, idSort] = sort(o_fileDate);
o_fileName = o_fileName(idSort);
o_fileCycle = o_fileCycle(idSort);
o_fileSize = o_fileSize(idSort);

return;
