% ------------------------------------------------------------------------------
% For Apex APF11 Iridium-SBD floats, compare the contents of the float files
% decoded from Matlab code VS from Teledyn (python) code.
%
% SYNTAX :
%   check_apex_apf11_ir_float_files
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_apex_apf11_ir_float_files

% directory of the mail files
DIR_INPUT_MAIL_FILE = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\apex_apf11_ir_sbd\300234066126530_3901988\archive\';

% working directory
DIR_WORK = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\Iridium\CHECK_DECODING\WORK\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory with Teledyne python code
DIR_TELEDYNE_CODE = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\Iridium\CHECK_DECODING\TELEDYNE_CODE\';

% default values initialization
init_default_values;

% output CSv path file name (used in read_apx_apf11_ir_binary_log_file)
global g_decArgo_debug_outputCsvPathName;
g_decArgo_debug_outputCsvPathName = [DIR_WORK '\ARGO\FLOAT_FILES\ASCII\'];

% float launch date
global g_decArgo_floatLaunchDate;
g_decArgo_floatLaunchDate = []; % to consider all reported information (even prior to float launch date)


logFile = [DIR_LOG_FILE '/' 'check_apex_apf11_ir_float_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create working directory
if ~(exist(DIR_WORK, 'dir') == 7)
   mkdir(DIR_WORK);
end

% duplicate mail files
mailFileDir = [DIR_WORK '\MAIL\'];
if ~(exist(mailFileDir, 'dir') == 7)
   mkdir(mailFileDir);
   
   fprintf('Duplicating mail files ...\n');
   tic;
   mailFiles = dir([DIR_INPUT_MAIL_FILE '*.txt']);
   for iFile = 1:length(mailFiles)
      copy_file([DIR_INPUT_MAIL_FILE mailFiles(iFile).name], mailFileDir);
   end
   ellapsedTime = toc;
   fprintf('=> %d mail files duplicated (%.1f sec)\n', length(mailFiles), ellapsedTime);
else
   fprintf('Mail files exist\n');
end

% extract SBD files
sbdFileDir = [DIR_WORK '\SBD\'];
if ~(exist(sbdFileDir, 'dir') == 7)
   mkdir(sbdFileDir);
   
   fprintf('Extracting mail file attachements ...\n');
   tic;
   mailFiles = dir([mailFileDir '*.txt']);
   for iFile = 1:length(mailFiles)
      
      mailFileName = mailFiles(iFile).name;
      
      % extract the attachement
      read_mail_and_extract_attachment( ...
         mailFileName, mailFileDir, sbdFileDir);
   end
   sbdFiles = dir([sbdFileDir '*.sbd']);
   ellapsedTime = toc;
   fprintf('=> %d SBD files extracted (%.1f sec)\n', length(sbdFiles), ellapsedTime);
else
   fprintf('SBD files exist\n');
end

fprintf('\nTELEDYNE PROCESSING\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Teledyne processing

% create Teledyne directory
teledyneDir = [DIR_WORK '\TELEDYNE\'];
if ~(exist(teledyneDir, 'dir') == 7)
   mkdir(teledyneDir);
end

% convert SBD files to float files
floatFileDir = [teledyneDir '\FLOAT_FILES\'];
if ~(exist(floatFileDir, 'dir') == 7)
   mkdir(floatFileDir);
   
   fprintf('Duplicating SBD files to Teledyne code dir ...\n');
   tic;
   sbdFiles = dir([sbdFileDir '*.sbd']);
   for iFile = 1:length(sbdFiles)
      copy_file([sbdFileDir sbdFiles(iFile).name], DIR_TELEDYNE_CODE);
   end
   ellapsedTime = toc;
   fprintf('=> %d SBD files duplicated (%.1f sec)\n', length(sbdFiles), ellapsedTime);
   
   fprintf('Converting SBD files to Teledyne float files ...\n');
   tic;
   cmd = ['cd ' DIR_TELEDYNE_CODE '& python stitch.py *.sbd'];
   [status, cmdOut] = system(cmd);
   if (status ~= 0)
      fprintf('Anomaly while using stitch.py\n');
   end
   ellapsedTime = toc;
   fprintf('=> done (%.1f sec)\n', ellapsedTime);
   
   fprintf('Retrieving float files to Teledyne float files dir ...\n');
   tic;
   floatFiles = [dir([DIR_TELEDYNE_CODE '*.txt']); dir([DIR_TELEDYNE_CODE '*.gz'])];
   for iFile = 1:length(floatFiles)
      move_file([DIR_TELEDYNE_CODE floatFiles(iFile).name], floatFileDir);
   end
   ellapsedTime = toc;
   fprintf('=> %d float files retrieved (%.1f sec)\n', length(floatFiles), ellapsedTime);
   
   % remove processed SBD files
   if (exist([DIR_TELEDYNE_CODE '\archive\'], 'dir') == 7)
      rmdir([DIR_TELEDYNE_CODE '\archive\'], 's');
   end
   % remove processed SBD files
   sbdFiles = dir([DIR_TELEDYNE_CODE '*.sbd']);
   for iFile = 1:length(sbdFiles)
      delete([DIR_TELEDYNE_CODE sbdFiles(iFile).name]);
   end
   
   % uncompress .gz files
   fprintf('Uncompressing float files in Teledyne float files dir ...\n');
   tic;
   gzFiles = dir([floatFileDir '*.gz']);
   for iFile = 1:length(gzFiles)
      gzFilePathName = [floatFileDir gzFiles(iFile).name];
      gunzip(gzFilePathName);
      delete(gzFilePathName);
   end
   ellapsedTime = toc;
   fprintf('=> %d float files uncompressed (%.1f sec)\n', length(gzFiles), ellapsedTime);
else
   fprintf('Teledyne float files exist\n');
end

% created .csv files from bianry float files
asciiFileDir = [floatFileDir '\ASCII\'];
if ~(exist(asciiFileDir, 'dir') == 7)
   mkdir(asciiFileDir);
   
   fprintf('Converting Teledyne binary float files to CSV ones ...\n');
   tic;
   binFiles = dir([floatFileDir '*.bin']);
   for iFile = 1:length(binFiles)
      move_file([floatFileDir binFiles(iFile).name], DIR_TELEDYNE_CODE);
      cmd = ['cd ' DIR_TELEDYNE_CODE '& python apf11dec.py ' [DIR_TELEDYNE_CODE binFiles(iFile).name]];
      [status, cmdOut] = system(cmd);
      if (status ~= 0)
         fprintf('Anomaly while applying apf11dec.py to %s\n', binFiles(iFile).name);
      end
      move_file([DIR_TELEDYNE_CODE binFiles(iFile).name], floatFileDir);
      move_file([DIR_TELEDYNE_CODE regexprep(binFiles(iFile).name, '.bin', '.csv')], asciiFileDir);
   end
   ellapsedTime = toc;
   fprintf('=> %d binary files converted (%.1f sec)\n', length(binFiles), ellapsedTime);
   
   % duplicate .txt files
   txtFiles = dir([floatFileDir '*.txt']);
   for iFile = 1:length(txtFiles)
      copy_file([floatFileDir txtFiles(iFile).name], asciiFileDir);
   end
else
   fprintf('Teledyne ASCII float files exist\n');
end

fprintf('\nARGO DECODER PROCESSING\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Argo processing

% create Argo directory
argoDir = [DIR_WORK '\ARGO\'];
if ~(exist(argoDir, 'dir') == 7)
   mkdir(argoDir);
end

% convert SBD files to float files
floatFileDir = [argoDir '\FLOAT_FILES\'];
if ~(exist(floatFileDir, 'dir') == 7)
   mkdir(floatFileDir);
   
   fprintf('Converting SBD files to Argo float files ...\n');
   tic;
   convert_sbd_files_apex_apf11_iridium_sbd(sbdFileDir, floatFileDir);
   ellapsedTime = toc;
   fprintf('=> done (%.1f sec)\n', ellapsedTime);
else
   fprintf('Teledyne float files exist\n');
end

% created .csv files from bianry float files
asciiFileDir = [floatFileDir '\ASCII\'];
if ~(exist(asciiFileDir, 'dir') == 7)
   mkdir(asciiFileDir);
   
   fprintf('Converting Argo binary float files to CSV ones ...\n');
   tic;
   binSciFiles = dir([floatFileDir '*.science_log.bin']);
   for iFile = 1:length(binSciFiles)
      read_apx_apf11_ir_binary_log_file([floatFileDir binSciFiles(iFile).name], 'science');
   end
   binVitFiles = dir([floatFileDir '*.vitals_log.bin']);
   for iFile = 1:length(binVitFiles)
      read_apx_apf11_ir_binary_log_file([floatFileDir binVitFiles(iFile).name], 'vitals');
   end
   ellapsedTime = toc;
   fprintf('=> %d binary files converted (%.1f sec)\n', length(binSciFiles)+length(binVitFiles), ellapsedTime);
   
   % duplicate .txt files
   txtFiles = dir([floatFileDir '*.txt']);
   for iFile = 1:length(txtFiles)
      copy_file([floatFileDir txtFiles(iFile).name], asciiFileDir);
   end
else
   fprintf('Teledyne ASCII float files exist\n');
end

diary off;

return;
