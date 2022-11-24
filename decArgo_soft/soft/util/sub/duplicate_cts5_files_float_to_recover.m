% ------------------------------------------------------------------------------
% Duplicate newly received files from PROVOR CTS5 float.
%
% SYNTAX :
%  duplicate_cts5_files_float_to_recover( ...
%    a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDirName, a_maxFileAge)
%
% INPUT PARAMETERS :
%   a_floatWmo       : float WMO number
%   a_floatLoginName : float login name
%   a_rsyncDir       : RSYNC directory
%   a_spoolDir       : SPOOL directory
%   a_outputDir      : output directory
%   a_maxFileAge     : max age (in hours) of the files to consider
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function duplicate_cts5_files_float_to_recover( ...
   a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDirName, a_maxFileAge)

% list of CTS5 files
global g_decArgo_provorCts5UseaFileTypeListAll;


% type of files to copy
fileTypeList = g_decArgo_provorCts5UseaFileTypeListAll;

if ~(exist(a_outputDirName, 'dir') == 7)
   fprintf('Creating directory: %s\n', a_outputDirName);
   mkdir(a_outputDirName);
end

% current date
curUtcDate = now_utc;

% create the output directory of this float
floatOutputDirName = [a_outputDirName '/' a_floatLoginName '_' num2str(a_floatWmo)];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end
floatOutputDirName = [floatOutputDirName '/archive/'];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end

% copy files from DIR_INPUT_RSYNC_DATA
fprintf('DIR_INPUT_RSYNC_DATA files (%s):\n', a_rsyncDir);

fileNameList = [];
for idType = 1:length(fileTypeList)
   if (ismember(fileTypeList{idType, 1}, [3 4 5]))
      files = dir([a_rsyncDir '/' a_floatLoginName '/' fileTypeList{idType, 2}]);
      for idFile = 1:length(files)
         if ((curUtcDate - files(idFile).datenum) <= a_maxFileAge/24)
            fileNameList{end+1} = files(idFile).name;
         end
      end
   end
end
fileNameList = unique(fileNameList);

for idFile = 1:length(fileNameList)
   fileName = fileNameList{idFile};
   filePathName = [a_rsyncDir '/' a_floatLoginName '/' fileName];
   fileInfo = dir(filePathName);
   fileNameOut = [ ...
      fileName(1:end-4) '_' ...
      datestr(datenum(fileInfo.date, 'dd-mmmm-yyyy HH:MM:SS'), 'yyyymmddHHMMSS') ...
      fileName(end-3:end)];
   
   filePathNameOut = [floatOutputDirName '/' fileNameOut];
   if (exist(filePathNameOut, 'file') == 2)
      % file exists
      fprintf('%s => unchanged\n', fileNameOut);
   else
      % copy new file
      copy_file(filePathName, filePathNameOut);
      fprintf('%s => copy\n', fileNameOut);
   end
end

fprintf('\n');

% copy files from SPOOL_DIR
if (~isempty(a_spoolDir))
   fprintf('SPOOL_DIR files (%s):\n', a_spoolDir);
   
   fileNameList = [];
   for idType = 1:length(fileTypeList)
      if (ismember(fileTypeList{idType, 1}, [3 4 5]))
         files = dir([a_spoolDir '/' a_floatLoginName '/' fileTypeList{idType, 2}]);
         for idFile = 1:length(files)
            if ((curUtcDate - files(idFile).datenum) <= a_maxFileAge/24)
               fileNameList{end+1} = files(idFile).name;
            end
         end
      end
   end
   fileNameList = unique(fileNameList);
   
   for idFile = 1:length(fileNameList)
      fileName = fileNameList{idFile};
      filePathName = [a_spoolDir '/' a_floatLoginName '/' fileName];
      fileInfo = dir(filePathName);
      fileNameOut = [ ...
         fileName(1:end-4) '_' ...
         datestr(datenum(fileInfo.date, 'dd-mmmm-yyyy HH:MM:SS'), 'yyyymmddHHMMSS') ...
         fileName(end-3:end)];
      
      filePathNameOut = [floatOutputDirName '/' fileNameOut];
      if (exist(filePathNameOut, 'file') == 2)
         % file exists
         fprintf('%s => unchanged\n', fileNameOut);
      else
         % copy new file
         copy_file(filePathName, filePathNameOut);
         fprintf('%s => copy\n', fileNameOut);
      end
   end
   
   fprintf('\n');
end

return
