% ------------------------------------------------------------------------------
% Duplicate newly received files from Apex APF11 Iridium RUDICS float.
%
% SYNTAX :
%  duplicate_apx_apf11_iridium_rudics_files_float_to_recover( ...
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
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function duplicate_apx_apf11_iridium_rudics_files_float_to_recover( ...
   a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDirName, a_maxFileAge)

if ~(exist(a_outputDirName, 'dir') == 7)
   fprintf('Creating directory: %s\n', a_outputDir);
   mkdir(a_outputDir);
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
floatFiles = dir([a_rsyncDir '/' a_floatLoginName '/' sprintf('%s*', a_floatLoginName)]);
for idFile = 1:length(floatFiles)
   floatFileName = floatFiles(idFile).name;
   floatFilePathName = [a_rsyncDir '/' a_floatLoginName '/' floatFileName];
   
   if ((curUtcDate - floatFiles(idFile).datenum) <= a_maxFileAge/24)
      floatFilePathNameOut = [floatOutputDirName '/' floatFileName];
      if (exist(floatFilePathNameOut, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         floatFileOut = dir(floatFilePathNameOut);
         if (~strcmp(floatFiles(idFile).date, floatFileOut.date))
            copy_file(floatFilePathName, floatOutputDirName);
            fprintf('%s => copy\n', floatFileName);
         else
            fprintf('%s => unchanged\n', floatFileName);
         end
      else
         % copy the file if it doesn't exist
         copy_file(floatFilePathName, floatOutputDirName);
         fprintf('%s => copy\n', floatFileName);
      end
   end
end

% copy files from SPOOL_DIR
if (~isempty(a_spoolDir))
   fprintf('SPOOL_DIR files (%s):\n', a_spoolDir);
   floatFiles = dir([a_spoolDir '/' a_floatLoginName '/' sprintf('%s*', a_floatLoginName)]);
   for idFile = 1:length(floatFiles)
      floatFileName = floatFiles(idFile).name;
      floatFilePathName = [a_spoolDir '/' a_floatLoginName '/' floatFileName];
      
      if ((curUtcDate - floatFiles(idFile).datenum) <= a_maxFileAge/24)
         floatFilePathNameOut = [floatOutputDirName '/' floatFileName];
         if (exist(floatFilePathNameOut, 'file') == 2)
            % when the file already exists, check (with its date) if it needs to be
            % updated
            floatFileOut = dir(floatFilePathNameOut);
            if (~strcmp(floatFiles(idFile).date, floatFileOut.date))
               copy_file(floatFilePathName, floatOutputDirName);
               fprintf('%s => copy\n', floatFileName);
            else
               fprintf('%s => unchanged\n', floatFileName);
            end
         else
            % copy the file if it doesn't exist
            copy_file(floatFilePathName, floatOutputDirName);
            fprintf('%s => copy\n', floatFileName);
         end
      end
   end
end

return
