% ------------------------------------------------------------------------------
% Duplicate newly received files from remocean float.
%
% SYNTAX :
%  duplicate_remocean_sbd_files_float_to_recover( ...
%    a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDir, a_maxFileAge)
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
function duplicate_remocean_sbd_files_float_to_recover( ...
   a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDir, a_maxFileAge)

if ~(exist(a_outputDir, 'dir') == 7)
   fprintf('Creating directory: %s\n', a_outputDir);
   mkdir(a_outputDir);
end

% current date
curUtcDate = now_utc;

% create the output directory of this float
floatOutputDir = [a_outputDir '/' a_floatLoginName '_' num2str(a_floatWmo)];
if ~(exist(floatOutputDir, 'dir') == 7)
   mkdir(floatOutputDir);
end
floatOutputDir = [floatOutputDir '/archive/'];
if ~(exist(floatOutputDir, 'dir') == 7)
   mkdir(floatOutputDir);
end

% copy files from DIR_INPUT_RSYNC_DATA
fprintf('DIR_INPUT_RSYNC_DATA files (%s):\n', a_rsyncDir);
sbdFile = [dir([a_rsyncDir '/' a_floatLoginName '/' sprintf('*_%s_*.b64', a_floatLoginName)]); ...
   dir([a_rsyncDir '/' a_floatLoginName '/' sprintf('*_%s_*.bin', a_floatLoginName)])];
for idFile = 1:length(sbdFile)
   sbdFileName = sbdFile(idFile).name;
   sbdFilePathName = [a_rsyncDir '/' a_floatLoginName '/' sbdFileName];
   
   if ((curUtcDate - sbdFile(idFile).datenum) <= a_maxFileAge/24)
      sbdFilePathNameOut = [floatOutputDir '/' sbdFileName];
      if (exist(sbdFilePathNameOut, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         sbdFileOut = dir(sbdFilePathNameOut);
         if (~strcmp(sbdFile(idFile).date, sbdFileOut.date))
            copy_file(sbdFilePathName, sbdFilePathNameOut);
            fprintf('%s => copy\n', sbdFileName);
         else
            fprintf('%s => unchanged\n', sbdFileName);
         end
      else
         % copy the file if it doesn't exist
         copy_file(sbdFilePathName, sbdFilePathNameOut);
         fprintf('%s => copy\n', sbdFileName);
      end
   end
end

% copy files from SPOOL_DIR
if (~isempty(a_spoolDir))
   fprintf('SPOOL_DIR files (%s):\n', a_spoolDir);
   sbdFile = [dir([a_spoolDir '/' a_floatLoginName '/' sprintf('*_%s_*.b64', a_floatLoginName)]); ...
      dir([a_spoolDir '/' a_floatLoginName '/' sprintf('*_%s_*.bin', a_floatLoginName)])];
   for idFile = 1:length(sbdFile)
      sbdFileName = sbdFile(idFile).name;
      sbdFilePathName = [a_spoolDir '/' a_floatLoginName '/' sbdFileName];
      
      if ((curUtcDate - sbdFile(idFile).datenum) <= a_maxFileAge/24)
         sbdFilePathNameOut = [floatOutputDir '/' sbdFileName];
         if (exist(sbdFilePathNameOut, 'file') == 2)
            % when the file already exists, check (with its date) if it needs to be
            % updated
            sbdFileOut = dir(sbdFilePathNameOut);
            if (~strcmp(sbdFile(idFile).date, sbdFileOut.date))
               copy_file(sbdFilePathName, sbdFilePathNameOut);
               fprintf('%s => copy\n', sbdFileName);
            else
               fprintf('%s => unchanged\n', sbdFileName);
            end
         else
            % copy the file if it doesn't exist
            copy_file(sbdFilePathName, sbdFilePathNameOut);
            fprintf('%s => copy\n', sbdFileName);
         end
      end
   end
end

return
