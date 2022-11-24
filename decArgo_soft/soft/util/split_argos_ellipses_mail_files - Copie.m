% ------------------------------------------------------------------------------
% Processs mail files of Argos error ellipses
%
% SYNTAX :
%   split_argos_ellipses_mail_files
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
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function split_argos_ellipses_mail_files

DIR_INPUT_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS_ELLIPSES\mails\IN\';
DIR_INPUT_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS_ELLIPSES\mails\ellipses_argos_mails_20210823\archive\message\';
% DIR_INPUT_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS_ELLIPSES\mails\ellipses_argos_mails_20210823\message\';
DIR_OUTPUT_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS_ELLIPSES\mails\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

global g_argosIdList;
g_argosIdList = [];


% create the output directory
if ~(exist(DIR_OUTPUT_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_FILES);
end

currentDate = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'split_argos_ellipses_mail_files_' currentDate '.log'];
diary(logFile);
tic;

% process the files of the input directory
fprintf('Processing directory %s\n', DIR_INPUT_FILES);
process_directory(DIR_INPUT_FILES, DIR_OUTPUT_FILES);

% process the sub- directories of the input directory
dirs = dir(DIR_INPUT_FILES);
nbDirs = length(dirs);
for idDir = 1:nbDirs
   
   dirName = dirs(idDir).name;
   if (~strcmp(dirName, '.') && ~strcmp(dirName, '..'))
      dirPathName = [DIR_INPUT_FILES '/' dirName];
      if (exist(dirPathName, 'dir') == 7)
         fprintf('\nProcessing directory %s:\n', dirPathName);
         process_directory(dirPathName, DIR_OUTPUT_FILES);
      end
   end
end

% clean output files from duplicated lines
if (~isempty(g_argosIdList))
   fprintf('Cleaning %d output files\n', length(unique(g_argosIdList)));
   clean_files(unique(g_argosIdList), DIR_OUTPUT_FILES);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
diary off;

return

% ------------------------------------------------------------------------------
% Processs one directory of mail files of Argos error ellipses
%
% SYNTAX :
%  process_directory(a_inputDirPathName, a_outputDirPathName)
%
% INPUT PARAMETERS :
%   a_inputDirName  : name of input files directory
%   a_outputDirName : name of output files directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function process_directory(a_inputDirPathName, a_outputDirPathName)

% process the files of the input directory
files = dir(a_inputDirPathName);
nbFiles = length(files);
dataAll = [];
% for idFile = 1:300
for idFile = 1:nbFiles
   
   fileName = files(idFile).name;
   filePathName = [a_inputDirPathName '/' fileName];
   if (exist(filePathName, 'file') == 2)
      
      fprintf('   Processing file %s\n', fileName);
      data = process_file(filePathName);
      dataAll = [dataAll; data];
      
      % store processed data into output files
      if (size(dataAll, 1) > 10000)
         store_data(dataAll, a_outputDirPathName);
         dataAll = [];
      end
   end
end

% store processed data into output files
if (~isempty(dataAll))
   store_data(dataAll, a_outputDirPathName);
end

return

% ------------------------------------------------------------------------------
% Processs one mail file of Argos error ellipses
%
% SYNTAX :
%  [o_data] = process_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : name of input file to process
%
% OUTPUT PARAMETERS :
%   o_data : processed data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = process_file(a_filePathName)

% output parameters initialization
o_data = [];

% patterns used to parse the mail contents
CSV_HEADER = 'Program;PTT;Satellite;Location date;Location class;Latitude;Longitude;Latitude solution 2;Longitude solution 2;Number of messages;Nbr mes > - 120 dB;Best level;Pass duration;NOPC;Location index;Frequency;Altitude;Error radius;Semi-major axis;Semi-minor axis;Ellipse orientation;GDOP';


if ~(exist(a_filePathName, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_filePathName);
   return
end

fId = fopen(a_filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_filePathName);
   return
end

lineNum = 0;
startRecording = 0;
while 1
   line = fgetl(fId);
   if (line == -1)
      break
   end
   lineNum = lineNum + 1;
   
   if (isempty(line))
      continue
   end
   
   if (any(strfind(line, CSV_HEADER(1:8))))
      if (any(strfind(line, CSV_HEADER)))
         % BE CAREFUL: CSV_HEADER may apper twice (Ex: co_20170223T170004Z_25648.txt)
         startRecording = 1;
         continue
      else
         fprintf('ERROR: Not managed header in line #%d: %s\n', lineNum, line);
      end
   end
   
   if (startRecording)
      data = textscan(line, '%s', 'delimiter', ';');
      data = data{:};
      if (length(data) >= 21)
         if (~isempty(data{4}))
            o_data = [o_data; data([1:7 16 17 19:21])'];
         end
      else
         fprintf('ERROR: Anomaly in line #%d: %s\n', lineNum, line);
      end
   end

end

fclose(fId);

return

% ------------------------------------------------------------------------------
% Store processed data in output files
%
% SYNTAX :
%  store_data(a_data, a_outputDirPathName)
%
% INPUT PARAMETERS :
%   a_data          : processed data
%   a_outputDirName : name of output file directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function store_data(a_data, a_outputDirPathName)

global g_argosIdList;


argosIdList = unique({a_data{:, 2}});
for idA = 1:length(argosIdList)
   argosId = argosIdList{idA};
   
   % store list of processed Argos Ids
   g_argosIdList = [g_argosIdList; str2double(argosId)];
   
   argosIdForFileName = argosId;
   if (length(argosIdForFileName) < 6)
      argosIdForFileName = num2str(sprintf('%06d', str2double(argosIdForFileName)));
   end
      
   % create the output directory
   outputDirPathName = [a_outputDirPathName '/' argosIdForFileName];
   if ~(exist(outputDirPathName, 'dir') == 7)
      mkdir(outputDirPathName);
   end
   
   % clean new data from duplicated lines
   idF = find(strcmp(a_data(:, 2), argosId));
   dataNew = a_data(idF, :);
   idDel = [];
   for id1 = 1:size(dataNew, 1)-1
      if (any(idDel == id1))
         continue
      end
      for id2 = id1+1:size(dataNew, 1)
         if (any(idDel == id2))
            continue
         end
         if (~any(strcmp(dataNew(id1, :), dataNew(id2, :)) ~= 1))
            idDel = [idDel id2];
         end
      end
   end
   dataNew(idDel, :) = [];
   
   % append new data to output file
   outputFilePathName = [outputDirPathName '/' argosIdForFileName '_error_ellipses.csv'];
   append_file(dataNew, outputFilePathName);
end

return

% ------------------------------------------------------------------------------
% Append processed data to output file
%
% SYNTAX :
%  append_file(a_data, a_filePathName)
%
% INPUT PARAMETERS :
%   a_data         : processed data
%   a_filePathName : name of output file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function append_file(a_data, a_filePathName)

putHeader = 0;
if ~(exist(a_filePathName, 'file') == 2)
   putHeader = 1;
end

fidOut = fopen(a_filePathName, 'a');
if (fidOut == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_filePathName);
   return
end

if (putHeader == 1)
   header = 'Program;PTT;Satellite;Location date;Location class;Latitude;Longitude;Frequency;Altitude;Semi-major axis;Semi-minor axis;Ellipse orientation';
   fprintf(fidOut, '%s\n', header);
end

for idl = 1:size(a_data, 1)
   fprintf(fidOut, '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n', a_data{idl, :});
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Read output file contents
%
% SYNTAX :
%  [a_data] = read_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : name of output file
%
% OUTPUT PARAMETERS :
%   o_data : processed data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [a_data] = read_file(a_filePathName)

% output parameters initialization
a_data = [];


fidOut = fopen(a_filePathName, 'r');
if (fidOut == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_filePathName);
   return
end

a_data = textscan(fidOut, '%s', 'delimiter', ';');

fclose(fidOut);

a_data = a_data{:};
a_data = reshape(a_data, 12, size(a_data, 1)/12)';
a_data(1, :) = [];

return

% ------------------------------------------------------------------------------
% Clean output files from duplicated lines
%
% SYNTAX :
%  clean_files(a_argosIdList, a_outputDirPathName)
%
% INPUT PARAMETERS :
%   a_argosIdList    : list of processed Argos Ids
%   a_outputDirName : name of output files directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function clean_files(a_argosIdList, a_outputDirPathName)

for idA = 1:length(a_argosIdList)
   argosId = a_argosIdList(idA);
   
   argosIdForFileName = num2str(sprintf('%06d', argosId));
   filePathName = [a_outputDirPathName '/' argosIdForFileName '/' argosIdForFileName '_error_ellipses.csv'];
   if  ~(exist(filePathName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', filePathName);
      continue
   end
   
   data = read_file(filePathName);
   idDel = [];
   for id1 = 1:size(data, 1)-1
      if (any(idDel == id1))
         continue
      end
      for id2 = id1+1:size(data, 1)
         if (any(idDel == id2))
            continue
         end
         if (~any(strcmp(data(id1, :), data(id2, :)) ~= 1))
            idDel = [idDel id2];
         end
      end
   end
   data(idDel, :) = [];
   
   save_file(data, filePathName);
end

return

% ------------------------------------------------------------------------------
% Store processed data in output file
%
% SYNTAX :
%  save_file(a_data, a_filePathName)
%
% INPUT PARAMETERS :
%   a_data         : processed data
%   a_filePathName : name of output file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function save_file(a_data, a_filePathName)

if (exist(a_filePathName, 'file') == 2)
   delete(a_filePathName);
end

fidOut = fopen(a_filePathName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_filePathName);
   return
end
header = 'Program;PTT;Satellite;Location date;Location class;Latitude;Longitude;Frequency;Altitude;Semi-major axis;Semi-minor axis;Ellipse orientation';
fprintf(fidOut, '%s\n', header);

for idl = 1:size(a_data, 1)
   fprintf(fidOut, '%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n', a_data{idl, :});
end

fclose(fidOut);

return
