% ------------------------------------------------------------------------------
% Convert CVS NOVA data provided by Metocean (Paul Lane) to email files so that
% they can be processed by the Matlab decoder.
%
% SYNTAX :
%   convert_nova_csv_2_mail_files
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
%   12/06/2017 - RNU - creation
% ------------------------------------------------------------------------------
function convert_nova_csv_2_mail_files

% directory of input CSV files
DIR_INPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\IN\NOVA\data_csv\';
DIR_INPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\IN\NOVA\data_csv2\';

% directory of output mail files
DIR_OUTPUT_MAIL_FILES = 'C:\Users\jprannou\_DATA\IN\NOVA\mail_from_data_csv2\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'convert_nova_csv_2_mail_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% clear output dir
if (exist(DIR_OUTPUT_MAIL_FILES, 'dir') == 7)
   rmdir(DIR_OUTPUT_MAIL_FILES, 's');
end
mkdir(DIR_OUTPUT_MAIL_FILES);

if (1) % NOMINAL CASE (CSV to mail file conversion)
   
   % process input CSV files
   csvFiles = dir([DIR_INPUT_CSV_FILES '/*.csv']);
   for idFile = 1:length(csvFiles)
      
      csvFileName = csvFiles(idFile).name;
      
      fprintf('%d/%d: processing file: %s\n', idFile, length(csvFiles), csvFileName);
      csvFilePathName = [DIR_INPUT_CSV_FILES '/' csvFileName];
      
      [filePath, fileName, fileExt] = fileparts(csvFilePathName);
      txtFilePathName = [filePath fileName '.txt'];
      copy_file(csvFilePathName, txtFilePathName);
      
      % open and read input CSV file
      fId = fopen(txtFilePathName, 'r');
      if (fId == -1)
         fprintf('ERROR: Error while opening CSV file: %s\n', txtFilePathName);
         return
      end
      
      % read the CSV file
      dataAll = textscan(fId, '%s', 'delimiter', '\n');
      
      fclose(fId);
      
      dataAll = dataAll{1};
      for idL = 2:size(dataAll, 1)
         dataL = textscan(dataAll{idL}, '%s', 'delimiter', ',');
         dataL = dataL{:};
         
         imei = strtrim(regexprep(dataL{2}, '"', ''));
         momsn = dataL{3};
         mtmsn = dataL{4};
         latitude = dataL{5};
         longitude = dataL{6};
         cepRadius = dataL{7};
         msgSize = dataL{8};
         sessionStatus = regexprep(dataL{9}, '"', '');
         sessionDate = regexprep(dataL{10}, '"', '');
         %       timeOfSession = datenum(sessionDate, 'dd-mmm-yy');
         timeOfSession = datenum(sessionDate, 'yyyy-mm-dd HH:MM:SS');
         dataHex = regexprep(dataL{11}, '"', '');
                  
         outputDirName = [DIR_OUTPUT_MAIL_FILES '/' imei];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end
         
         pidNum = 0;
         while (exist([outputDirName '/' sprintf('co_%sZ_%s_%06d_%06d_%05d.txt', ...
               datestr(timeOfSession, 'yyyymmddTHHMMSS'), ...
               imei, str2num(momsn), str2num(mtmsn), pidNum)], 'file') == 2)
            pidNum = pidNum + 1;
         end
         outputFileName = sprintf('co_%sZ_%s_%06d_%06d_%05d.txt', ...
            datestr(timeOfSession, 'yyyymmddTHHMMSS'), ...
            imei, str2num(momsn), str2num(mtmsn), pidNum);
         
         outputFilePathName = [outputDirName '/' outputFileName];
         
         % output mail file
         fIdOut = fopen(outputFilePathName, 'wt');
         if (fIdOut == -1)
            fprintf('ERROR: Error while creating file : %s\n', outputFilePathName);
            return
         end
         
         if (str2num(msgSize) ~= length(dataHex)/2)
            fprintf('WARNING: Message Size is %d bytes whereas it should be %d bytes - corrected in output file : %s\n', ...
               str2num(msgSize), length(dataHex)/2, outputFilePathName);
            msgSize = num2str(length(dataHex)/2);
         end
         
         fprintf(fIdOut, '%% mail file generated at Coriolis, with ''convert_nova_csv_2_mail_files'' tool, from CSV data files provided by Paul Lane (plane@metocean.com)\n');
         fprintf(fIdOut, 'Subject: SBD Msg From Unit: %s\n', imei);
         fprintf(fIdOut, 'boundary="SBD.Boundary.999999999"\n');
         fprintf(fIdOut, 'MOMSN:  %s\n', momsn);
         fprintf(fIdOut, 'MTMSN:  %s\n', mtmsn);
         fprintf(fIdOut, 'Time of Session (UTC): %s\n', datestr(timeOfSession, 'ddd mmm dd HH:MM:SS yyyy'));
         fprintf(fIdOut, 'Session Status: %s\n', sessionStatus);
         fprintf(fIdOut, 'Message Size (bytes): %s\n', msgSize);
         fprintf(fIdOut, 'Unit Location: Lat = %s Long = %s\n', latitude, longitude);
         fprintf(fIdOut, 'CEPradius = %s\n', cepRadius);
         
         fprintf(fIdOut, '--SBD.Boundary.999999999\n');
         fprintf(fIdOut, 'filename="%s"\n', sprintf('%s_%06d.sbd', imei, str2num(momsn)));
         
         data = [];
         for id = 1:length(dataHex)/2
            data(end+1) = hex2dec(dataHex(2*id-1:2*id));
         end
         dataEncoded = base64encode(data, 'matlab');
         fprintf(fIdOut, '\n%s\n\n', dataEncoded);
         
         fprintf(fIdOut, '--SBD.Boundary.999999999--\n');
         
         fclose(fIdOut);
      end
   end
end

if (0) % TO RETRIEVE IMEI VS FLOAT_SN
   
   % process input CSV files
   csvFiles = dir([DIR_INPUT_CSV_FILES '/*.csv']);
   for idFile = 1:length(csvFiles)
      
      csvFileName = csvFiles(idFile).name;
      
      fprintf('%d/%d: processing file: %s\n', idFile, length(csvFiles), csvFileName);
      csvFilePathName = [DIR_INPUT_CSV_FILES '/' csvFileName];
      
      [filePath, fileName, fileExt] = fileparts(csvFilePathName);
      txtFilePathName = [filePath fileName '.txt'];
      copy_file(csvFilePathName, txtFilePathName);
      
      % open and read input CSV file
      fId = fopen(txtFilePathName, 'r');
      if (fId == -1)
         fprintf('ERROR: Error while opening CSV file: %s\n', txtFilePathName);
         return
      end
      
      % read the CSV file
      dataAll = textscan(fId, '%s', 'delimiter', '\n');
      
      fclose(fId);
      
      tabFloatSn = [];
      tabImei = [];
      dataAll = dataAll{1};
      for idL = 2:size(dataAll, 1)
         dataL = textscan(dataAll{idL}, '%s', 'delimiter', ',');
         dataL = dataL{:};
         
         floatSN = regexprep(dataL{1}, '"', '');
         tabFloatSn{end+1} = floatSN;
         imei = strtrim(regexprep(dataL{2}, '"', ''));
         tabImei{end+1} = imei;
      end
      
      imei = unique(tabImei);
      floatSn = unique(tabFloatSn);
      fprintf('%s.csv;%s\n', imei{:}, floatSn{:});
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
