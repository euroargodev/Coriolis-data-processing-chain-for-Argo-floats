% ------------------------------------------------------------------------------
% Identify a float WMO from its Argos data.
%
% SYNTAX :
%   find_wmo_from_argos_data
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
%   05/14/2015 - RNU - creation
% ------------------------------------------------------------------------------
function find_wmo_from_argos_data()

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\tmp\OUT\STEP2\';

DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\tmp\OUT\STEP2\out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
init_default_values;

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'find_wmo_from_argos_data_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create output directories
argosId = 132029;
wmo27 = 6901596;
wmo30 = 6901609;
outputDir27 = [DIR_OUTPUT_ARGOS_FILES '/' num2str(argosId) '_' num2str(wmo27) '/'];
if (exist(outputDir27, 'dir') == 7)
   rmdir(outputDir27, 's');
end
outputDir27 = [DIR_OUTPUT_ARGOS_FILES '/' num2str(argosId) '_' num2str(wmo27) '/' num2str(argosId) '/'];
mkdir(outputDir27);
outputDir30 = [DIR_OUTPUT_ARGOS_FILES '/' num2str(argosId) '_' num2str(wmo30) '/'];
if (exist(outputDir30, 'dir') == 7)
   rmdir(outputDir30, 's');
end
outputDir30 = [DIR_OUTPUT_ARGOS_FILES '/' num2str(argosId) '_' num2str(wmo30) '/' num2str(argosId) '/'];
mkdir(outputDir30);

% process the Argos data
tabLocDate27 = [];
tabLocLon27 = [];
tabLocLat27 = [];

tabLocDate30 = [];
tabLocLon30 = [];
tabLocLat30 = [];

% process the directories of the input directory
dirs = dir(DIR_INPUT_ARGOS_FILES);
nbDirs = length(dirs);
for idDir = 1:nbDirs
   
   dirName = dirs(idDir).name;
   dirPathName = [DIR_INPUT_ARGOS_FILES '/' dirName];
   
   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         
         % first pass to collect Argos locations of each float
         fileList = [];
         files = dir([dirPathName '/*.txt']);
         nbFiles = length(files);
         for idFile = 1:nbFiles
            
            fileName = files(idFile).name;
            if ~(strcmp(fileName, '.') || strcmp(fileName, '..'))
                             
               fileList{end+1} = fileName;
               filePathName = [dirPathName '/' fileName];
               [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
                  argosDataDate, argosDataData, ...
                  satLine, floatMsgLines, floatMsgDuplicatedLines] = read_argos_file_fmt1_bis({filePathName}, argosId, 31);
               
               % select only the Argos messages with a good CRC
               idMsgCrcOk = 0;
               tabSensors = [];
               tabDates = [];
               tabMsg = [];
               for idMsg = 1:size(argosDataData, 1)
                  sensor = argosDataData(idMsg, :);
                  
                  if (check_crc_prv(sensor, 27) == 1)
                     % CRC check succeeded
                     idMsgCrcOk = idMsgCrcOk + 1;
                     tabSensors(idMsgCrcOk, :) = sensor';
                     tabDates(idMsgCrcOk, 1) = argosDataDate(idMsg);
                     tabMsg(idMsgCrcOk, 1) = idMsg;
                  end
               end
               
               if (~isempty(tabSensors))
                  
                  % format the data to be decoded
                  tabType = get_message_type(tabSensors, 27);
                  sensors = [tabType ones(size(tabSensors, 1), 1) tabSensors];
                  
                  [tabDecoderId] = find_decoder_id(sensors, tabDates);
                  uTabDecId = unique(tabDecoderId);
                  if (length(uTabDecId) == 1)
                     if (uTabDecId == 27)
                        if (~isempty(argosLocDate))
                           tabLocDate27 = [tabLocDate27; argosLocDate];
                           tabLocLon27 = [tabLocLon27; argosLocLon];
                           tabLocLat27 = [tabLocLat27; argosLocLat];
                        end
                     else
                        if (~isempty(argosLocDate))
                           tabLocDate30 = [tabLocDate30; argosLocDate];
                           tabLocLon30 = [tabLocLon30; argosLocLon];
                           tabLocLat30 = [tabLocLat30; argosLocLat];
                        end
                     end
                  end
               end
            end
         end
         
         % second pass to process the data
         for idFile = 1:length(fileList)
            
            fileName = fileList{idFile};
               
            %             fprintf('%03d/%03d Processing file %s\n', idFile, nbFiles, fileName);
            
            filePathName = [dirPathName '/' fileName];
            argosId = str2num(dirName);
            [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
               argosDataDate, argosDataData, ...
               satLine, floatMsgLines, floatMsgDuplicatedLines] = read_argos_file_fmt1_bis({filePathName}, argosId, 31);
            
            % select only the Argos messages with a good CRC
            idMsgCrcOk = 0;
            tabSensors = [];
            tabDates = [];
            tabMsg = [];
            for idMsg = 1:size(argosDataData, 1)
               sensor = argosDataData(idMsg, :);
               
               if (check_crc_prv(sensor, 27) == 1)
                  % CRC check succeeded
                  idMsgCrcOk = idMsgCrcOk + 1;
                  tabSensors(idMsgCrcOk, :) = sensor';
                  tabDates(idMsgCrcOk, 1) = argosDataDate(idMsg);
                  tabMsg(idMsgCrcOk, 1) = idMsg;
               end
            end
            
            if (~isempty(tabSensors))
               
               % format the data to be decoded
               tabType = get_message_type(tabSensors, 27);
               sensors = [tabType ones(size(tabSensors, 1), 1) tabSensors];
               
               [tabDecoderId] = find_decoder_id(sensors, tabDates);
               uTabDecId = unique(tabDecoderId);
               if (any(uTabDecId == 0))
                  fprintf('ERROR: no decoder Id for some messages in file %s\n', fileName);
               elseif (length(uTabDecId) == 1)
                  %                   fprintf('INFO: all of decoder Id #%d\n', uTabDecId);
                  
                  if (uTabDecId == 27)
                     print_output_file(outputDir27, fileName, satLine, floatMsgLines, floatMsgDuplicatedLines, 1:length(floatMsgLines));
                  else
                     print_output_file(outputDir30, fileName, satLine, floatMsgLines, floatMsgDuplicatedLines, 1:length(floatMsgLines));
                  end
               else
                  %                   fprintf('INFO: both decoders mixed\n');
                  if (~isempty(argosLocDate))
                     
                     idFB = strfind(satLine, ' ');
                     if (~isempty(tabLocDate27) && ~isempty(tabLocDate30))
                        [~, idMin27] = min(abs(tabLocDate27-argosLocDate));
                        [~, idMin30] = min(abs(tabLocDate30-argosLocDate));
                        
                        dist27 = distance_lpo([tabLocLat27(idMin27) argosLocLat], [tabLocLon27(idMin27) argosLocLon]);
                        dist30 = distance_lpo([tabLocLat30(idMin30) argosLocLat], [tabLocLon30(idMin30) argosLocLon]);
                        if (dist27 < dist30)
                           satLine27 = satLine;
                           satLine30 = satLine(1:idFB(5)-1);
                        else
                           satLine27 = satLine(1:idFB(5)-1);
                           satLine30 = satLine;
                        end
                     else
                        satLine27 = satLine(1:idFB(5)-1);
                        satLine30 = satLine(1:idFB(5)-1);
                     end
                  else
                     satLine27 = satLine;
                     satLine30 = satLine;
                  end
                  
                  idF27 = find(tabDecoderId == 27);
                  idF30 = find(tabDecoderId == 30);
                  print_output_file(outputDir27, fileName, satLine27, floatMsgLines, floatMsgDuplicatedLines, tabMsg(idF27));
                  print_output_file(outputDir30, fileName, satLine30, floatMsgLines, floatMsgDuplicatedLines, tabMsg(idF30));
                  if (size(argosDataData, 1) ~= length(tabMsg))
                     fprintf('INFO: file %s: %d messages with bad crc ignored\n', ...
                        fileName, size(argosDataData, 1)-length(tabMsg));
                  end
               end
            else
               fprintf('INFO: empty file (no message with good CRC) - %d messages ignored\n', size(argosDataData, 1));
            end
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
