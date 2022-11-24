% ------------------------------------------------------------------------------
% Extract attachements of Apex Iridium SBD mail files and convert SBD files in
% raw .msg and .log files.
%
% SYNTAX :
%  apex_ir_sbd_generate_ascii_files
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
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function apex_ir_sbd_generate_ascii_files

MAIL_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_IR_SBD\DATA\300234062992840_merged\';

SBD_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_IR_SBD\DATA\300234062992840_sbd\';

ASCII_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_IR_SBD\DATA\300234062992840_ascii\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_FILE '/' 'apex_ir_sbd_generate_ascii_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

if (0)
   
   % extract mail attachements
   if (exist(SBD_DIR_NAME, 'dir') == 7)
      rmdir(SBD_DIR_NAME, 's');
   end
   mkdir(SBD_DIR_NAME);
   
   mails = dir([MAIL_DIR_NAME '*.txt']);
   for iFile = 1:length(mails)
      % for iFile = 1:20
      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         mails(iFile).name, MAIL_DIR_NAME, SBD_DIR_NAME);
      fprintf('%d/%d: %s (%d)\n', iFile, length(mails), mails(iFile).name, attachmentFound);
   end
   
end

% convert SBD files to ASCII
if (exist(ASCII_DIR_NAME, 'dir') == 7)
   rmdir(ASCII_DIR_NAME, 's');
end
mkdir(ASCII_DIR_NAME);

prevMomsn = -1;
sbdDataPrev = [];
currentData = [];
dataList = [];
sbdFiles = dir([SBD_DIR_NAME '*.sbd']);
for iFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(iFile).name;
   sbdFilePathName = [SBD_DIR_NAME sbdFiles(iFile).name];
   
   idFUs = strfind(sbdFileName, '_');
   momsn = str2num(sbdFileName(idFUs(3)+1:idFUs(4)-1));
   
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', sbdFilePathName);
   end
   [sbdData, sbdDataCount] = fread(fId);
   fclose(fId);
   
   if (sbdData(1) == 1)
      if (~isempty(currentData))
         dataList = [dataList; currentData];
      end
      currentData = [];
      
      idF = find(sbdData(4:end) == 0, 1)+2;
      asciiFileName = char(sbdData(4:idF)');
      
      currentData.asciiFileName = {asciiFileName};
      currentData.size = 256*sbdData(2)+sbdData(3);
      currentData.momsn = momsn;
      currentData.data = {sbdData(idF+2:end)'};
      currentData.dataRaw = {sbdData'};
      
      prevMomsn = -1;
      
   elseif (sbdData(1) == 2)
      if (isempty(currentData))
         currentData.asciiFileName = {'UNKNOWN'};
         currentData.size = -1;
         currentData.momsn = -1;
         fprintf('ERROR: Missing previous data for file : %s\n', sbdFileName);
      end
      
      currentData.momsn = [currentData.momsn momsn];
      currentData.data = [currentData.data {sbdData(2:end)'}];
      currentData.dataRaw = [currentData.dataRaw {sbdData'}];
   else
      fprintf('ERROR: Anomaly in file : %s\n', sbdFileName);
      continue;
   end
   
   if (prevMomsn ~= -1)
      if (momsn == prevMomsn)
         sbdDataPrev = currentData.dataRaw{end-1}';
         if ((length(sbdData) == length(sbdDataPrev)) && ~any(sbdData ~= sbdDataPrev))
            fprintf('INFO: Ignoring duplicated data : %s\n', sbdFileName);
            %             currentData.data{end} = [];
            %             currentData.dataRaw{end} = [];
         else
            fprintf('WARNING: Same MOMSN but data differ : %s\n', sbdFileName);
         end
      end
   end
   
   prevMomsn = momsn;
end

if (~isempty(currentData))
   dataList = [dataList; currentData];
end

if (length([dataList.asciiFileName]) ~= length(unique([dataList.asciiFileName])))
   fprintf('WARNING: Duplicates in file names\n');
end

fprintf('\n');

for iFile = 1:length(dataList)
   if (dataList(iFile).size ~= length(dataList(iFile).data))
      fprintf('\n=> ERROR: Missing data in file : %s\n', dataList(iFile).asciiFileName{:});
   end
   
   currentData = dataList(iFile);
   fprintf('\n####################################################################\n');
   fprintf('File name  : %s\n', currentData.asciiFileName{:});
   fprintf('File size  : %d\n', currentData.size);
   for id1 = 1:length(currentData.data)
      fprintf('####################\n');
      fprintf('File MOMSN  : %d\n', currentData.momsn(id1));
      fprintf('File number : %d\n', id1);
      fprintf('File data  : \n');
      fprintf('%%%%%%%%%%\n');
      data = currentData.data(id1);
      fprintf('%s', data{:});
      fprintf('%%%%%%%%%%\n');
   end   
end

for iFile = 1:length(dataList)
   
   asciiFilePathName = [ASCII_DIR_NAME dataList(iFile).asciiFileName{:}];
   
   % output file
   fIdOut = fopen(asciiFilePathName, 'wt');
   if (fIdOut == -1)
      fprintf('ERROR: Error while creating file : %s\n', asciiFilePathName);
      return;
   end
   
   data = dataList(iFile).data;
   for iL = 1:length(data)
      fprintf(fIdOut, '%s', data{iL});
   end
   fclose(fIdOut);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
