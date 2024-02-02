% ------------------------------------------------------------------------------
% Use the JAVA format checker on a set of floats.
%
% SYNTAX :
%   nc_check_file_format_detailed or nc_check_file_format_detailed(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_file_format_detailed(varargin)

% directory of the JAVA checker
% DIR_JAVA_CHECKER = 'C:\Users\jprannou\_RNU\Argo\checker_US\javaChecker\file_checker_exec_v2.7.03_2022-06-01_spec_v2.7.9_2022-11-25\';
% DIR_JAVA_CHECKER = 'C:\Users\jprannou\_RNU\Argo\checker_US\javaChecker\file_checker_java_v2.8_2023-02-27_spec_v2.8_2023-02-27\';
DIR_JAVA_CHECKER = 'C:\Users\jprannou\_RNU\Argo\checker_US\javaChecker\file_checker_java_v2.8.01_2023-04-11_spec_v2.8_2023-02-27\';
DIR_JAVA_CHECKER = 'C:\Users\jprannou\_RNU\Argo\checker_US\javaChecker\file_checker_java_v2.8.01_2023-04-11_spec_v2.8.3_20230721\';

% top directory of the NetCDF files to check
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'E:\work_traj_32\nc_output_decArgo_traj_32\';
% DIR_INPUT_NC_FILES = 'F:\work_traj_32\Traj_3.2_crashes\';

% json meta-data file directory
DIR_JSON_FLOAT_META = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\json_float_meta\';

% directory to store checker reports
DIR_OUTPUT_REPORT_FILES = 'C:\Users\jprannou\_DATA\OUT\checker_reports\';
% DIR_OUTPUT_REPORT_FILES = 'E:\work_traj_32\checker_reports\';

% default list of floats to check
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\lists_20230316\list_cts5_locean_all.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';
% DIR_LOG_FILE = 'E:\work_traj_32\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';
% DIR_CSV_FILE = 'E:\work_traj_32\csv\';

% nc file types to check
CHECK_NC_TRAJ = 1;
CHECK_NC_MULTI_PROF = 0;
CHECK_NC_MONO_PROF = 1;
CHECK_NC_TECH = 1;
CHECK_NC_META = 1;
% CHECK_NC_TRAJ = 0;
% CHECK_NC_MULTI_PROF = 0;
% CHECK_NC_MONO_PROF = 0;
% CHECK_NC_TECH = 0;
% CHECK_NC_META = 1;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;

   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end

   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_check_file_format_detailed' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_check_file_format_detailed' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'Line #; WMO; File type; File name; Status; Error numbers; Warning numbers; Error description; Warning description';
fprintf(fidOut, '%s\n', header);

% process the floats
lineNum = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   % json meta-data file for this float
   jsonInputFileName = [DIR_JSON_FLOAT_META '/' sprintf('%d_meta.json', floatNum)];

   % floatDac = 'INCOIS';
   floatDac = 'CORIOLIS';
   % floatDac = 'BODC';
   % floatDac = 'AOML';
   if (exist(jsonInputFileName, 'file') == 2)
      % read meta-data file
      metaData = loadjson(jsonInputFileName);

      inst = get_institution_from_data_centre(metaData.DATA_CENTRE);
      if (~isempty(inst))
         floatDac = inst;
      end
   end

   %    [floatDac] = get_float_dac(floatNum, metaWmoList, metaData);
   %    floatDac = 'incois';
   %    floatDac = 'aoml';
   %    floatDac = 'csio';
   %    floatDac = 'bodc';
   %    floatDac = 'coriolis';

   for idType = 1:5

      if ((idType == 1) && (CHECK_NC_TRAJ == 1))
         % check trajectory files
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
         ncFiles = dir([ncFileDir sprintf('%d_*traj.nc', floatNum)]);
         pattern = 'TRAJ';
      elseif ((idType == 2) && (CHECK_NC_MULTI_PROF == 1))
         % check multi-prof files
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
         ncFiles = dir([ncFileDir sprintf('%d_*prof.nc', floatNum)]);
         pattern = 'MULTI_PROF';
      elseif ((idType == 3) && (CHECK_NC_MONO_PROF == 1))
         % check mono-prof files
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/profiles/'];
         ncFiles = dir([ncFileDir sprintf('*%d*.nc', floatNum)]);
         pattern = 'MONO_PROF';
      elseif ((idType == 4) && (CHECK_NC_TECH == 1))
         % check tech file
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
         ncFiles = dir([ncFileDir sprintf('%d_tech.nc', floatNum)]);
         pattern = 'TECH';
      elseif ((idType == 5) && (CHECK_NC_META == 1))
         % check meat files
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
         ncFiles = dir([ncFileDir sprintf('%d_meta.nc', floatNum)]);
         pattern = 'META';
      else
         continue
      end

      if (exist(ncFileDir, 'dir') == 7)

         for idFile = 1:length(ncFiles)

            ncFileName = ncFiles(idFile).name;
            [~, name, ~] = fileparts(ncFileName);
            if (strcmp(name(end-3:end), '_aux'))
               continue
            end

            if (ispc)
               cmd = ['cd ' DIR_JAVA_CHECKER ' & ' ...
                  'java -classpath ' DIR_JAVA_CHECKER ' ' ...
                  '-jar ' DIR_JAVA_CHECKER '/ValidateSubmit.jar ' ...
                  lower(floatDac) ' ' ...
                  DIR_JAVA_CHECKER '/spec ' ...
                  DIR_OUTPUT_REPORT_FILES ' ' ...
                  ncFileDir ' ' ...
                  ncFileName];
               % cmd = ['cd ' DIR_JAVA_CHECKER ' & ' ...
               %    'java -Xmx2g -Xms2g -classpath ' DIR_JAVA_CHECKER ' ' ...
               %    '-jar ' DIR_JAVA_CHECKER '/ValidateSubmit.jar ' ...
               %    lower(floatDac) ' ' ...
               %    DIR_JAVA_CHECKER '/spec ' ...
               %    DIR_OUTPUT_REPORT_FILES ' ' ...
               %    ncFileDir ' ' ...
               %    ncFileName];
            elseif (isunix)
               cmd = ['cd ' DIR_JAVA_CHECKER ' & ' ...
                  DIR_JAVA_CHECKER '/ArgoFileChecker.csh ' ...
                  lower(floatDac) ' ' ...
                  DIR_OUTPUT_REPORT_FILES ' ' ...
                  ncFileDir ' ' ...
                  ncFileName];
            else
               fprintf('Cannot determine operating system\n');
               return
            end

            [status, cmdOut] = system(cmd);
            if (status == 0)

               reportFilePathName = [DIR_OUTPUT_REPORT_FILES '/' ncFileName '.filecheck'];
               if ~(exist(reportFilePathName, 'file') == 2)
                  fprintf('ERROR: Report file not found: %s\n', reportFilePathName);
                  continue
               end

               fId = fopen(reportFilePathName, 'r');
               if (fId == -1)
                  fprintf('ERROR: Unable to open file: %s\n', reportFilePathName);
                  continue
               end

               status = '';
               errorNum = -1;
               errorText = '';
               warningNum = -1;
               warningText = '';
               while 1
                  line = fgetl(fId);
                  if (line == -1)
                     break
                  end

                  % collect information
                  if (~isempty(strfind(line, '<status>')))
                     idFStatus1 = strfind(line, '<status>');
                     idFStatus2 = strfind(line, '</status>');
                     if (~isempty(idFStatus1) && ~isempty(idFStatus2))
                        idFStatus1 = idFStatus1 + length('<status>');
                        status = line(idFStatus1:idFStatus2-1);
                     end
                  end
                  if (~isempty(strfind(line, '<errors number="')))
                     idFError1 = strfind(line, '<errors number="');
                     idFError2 = strfind(line, '">');
                     if (isempty(idFError2))
                        idFError2 = strfind(line, '"/>');
                     end
                     if (~isempty(idFError1) && ~isempty(idFError2))
                        idFError1 = idFError1 + length('<errors number="');
                        errorNum = str2num(line(idFError1:idFError2-1));
                        if (errorNum > 0)
                           text = '';
                           while 1
                              line = fgetl(fId);
                              if (line == -1)
                                 break
                              end
                              if (~isempty(strfind(line, '</errors>')))
                                 break
                              end
                              text{end+1} = line;
                           end
                           errStr = sprintf('%s', text{:});
                           errStr = regexprep(errStr, ';', ':');
                           idStart = strfind(errStr, '<error>');
                           idStop = strfind(errStr, '</error>');
                           if (length(idStart) == length(idStop))
                              for id = 1:length(idStart)
                                 errorText{end+1} = errStr(idStart(id)+length('<error>'):idStop(id)-1);
                              end
                           else
                              fprintf('ERROR: Anomaly detected while parsing file: %s\n', reportFilePathName);
                           end
                        end
                     end
                  end
                  if (~isempty(strfind(line, '<warnings number="')))
                     idFWarning1 = strfind(line, '<warnings number="');
                     idFWarning2 = strfind(line, '">');
                     if (isempty(idFWarning2))
                        idFWarning2 = strfind(line, '"/>');
                     end
                     if (~isempty(idFWarning1) && ~isempty(idFWarning2))
                        idFWarning1 = idFWarning1 + length('<warnings number="');
                        warningNum = str2num(line(idFWarning1:idFWarning2-1));
                        if (warningNum > 0)
                           text = '';
                           while 1
                              line = fgetl(fId);
                              if (line == -1)
                                 break
                              end
                              if (~isempty(strfind(line, '</warnings>')))
                                 break
                              end
                              text{end+1} = line;
                           end
                           warStr = sprintf('%s', text{:});
                           warStr = regexprep(warStr, ';', ':');
                           idStart = strfind(warStr, '<warning>');
                           idStop = strfind(warStr, '</warning>');
                           if (length(idStart) == length(idStop))
                              for id = 1:length(idStart)
                                 warningText{end+1} = warStr(idStart(id)+length('<warning>'):idStop(id)-1);
                              end
                           else
                              fprintf('ERROR: Anomaly detected while parsing file: %s\n', reportFilePathName);
                           end
                        end
                     end
                     break,
                  end
               end

               fclose(fId);


               % print collected information in the output CSV file
               if ((errorNum == 0) && (warningNum == 0))
                  fprintf(fidOut, '%d; %d; %s; %s; %s; %d; %d\n', ...
                     lineNum, floatNum, pattern, ncFileName, status, errorNum, warningNum);
                  lineNum = lineNum + 1;
               else
                  for idE = 1:errorNum
                     fprintf(fidOut, '%d; %d; %s; %s; %s; %d; %d; %s\n', ...
                        lineNum, floatNum, pattern, ncFileName, status, errorNum, warningNum, errorText{idE});
                     lineNum = lineNum + 1;
                  end
                  for idE = 1:warningNum
                     fprintf(fidOut, '%d; %d; %s; %s; %s; %d; %d;; %s\n', ...
                        lineNum, floatNum, pattern, ncFileName, status, errorNum, warningNum, warningText{idE});
                     lineNum = lineNum + 1;
                  end
               end

            else
               fprintf('ERROR: Status %d returned by system cmd ''%s''\n', status, cmd);
            end
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncFileDir);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

fclose(fidOut);

diary off;

return
