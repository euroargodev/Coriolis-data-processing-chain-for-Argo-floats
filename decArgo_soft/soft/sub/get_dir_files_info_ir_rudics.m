% ------------------------------------------------------------------------------
% Retrieve information from files in a given directory.
%
% SYNTAX :
%  [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_dir_files_info_ir_rudics( ...
%    a_dirName, a_floatLoginName, a_fileName)
%
% INPUT PARAMETERS :
%   a_dirName        : concerned directory
%   a_floatLoginName : float name
%   a_fileName       : file name (when we want to consider only one file)
%
% OUTPUT PARAMETERS :
%   o_fileName : file names
%   o_fileDate : file cycle numbers
%   o_fileDate : file dates
%   o_fileSize : file sizes
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileName, o_fileCycle, o_fileDate, o_fileSize] = get_dir_files_info_ir_rudics( ...
   a_dirName, a_floatLoginName, a_fileName)

% output parameters initialization
o_fileName = [];
o_fileCycle = [];
o_fileDate = [];
o_fileSize = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% check the SBD files of the directory
if (isempty(a_fileName))
   sbdFiles = dir([a_dirName '/' sprintf('*_%s_*.b*.sbd', ...
      a_floatLoginName)]);
else
   sbdFiles = dir([a_dirName '/' a_fileName]);
end
for idFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(idFile).name;
   idFUs = strfind(sbdFileName, '_');
   sbdFileDate = datenum(sbdFileName(1:13), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   o_fileName{end+1} = sbdFileName;
   o_fileCycle(end+1) = str2double(sbdFileName(idFUs(end)+1:end-4));
   o_fileDate(end+1) = sbdFileDate;
   o_fileSize(end+1) = sbdFiles(idFile).bytes;
end

% chronologically sort the files
[o_fileDate, idSort] = sort(o_fileDate);
o_fileName = o_fileName(idSort);
o_fileCycle = o_fileCycle(idSort);
o_fileSize = o_fileSize(idSort);

return
