% ------------------------------------------------------------------------------
% Use the JAVA format checker on a set of floats.
%
% SYNTAX :
%   nc_check_file_format or nc_check_file_format(6900189, 7900118)
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
%   06/26/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_file_format(varargin)

% directory of the JAVA checker
DIR_JAVA_CHECKER = 'C:\users\RNU\Glider\Checker\EGO_NetCDF_Checker\'; 

% top directory of the NetCDF files to check
DIR_INPUT_NC_FILES = 'C:\users\RNU\Argo\work\DM_updated_data_20140729\'; 
DIR_INPUT_NC_FILES = 'E:\nc_output_updated\'; 
DIR_INPUT_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_decPrv\';

% default list of floats to check
FLOAT_LIST_FILE_NAME = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/nke_all_with_DM.txt'; 

% directory to store the log and csv files
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 

% nc file types to check
CHECK_NC_TRAJ = 1;
CHECK_NC_MULTI_PROF = 0;
CHECK_NC_MONO_PROF = 1;
CHECK_NC_TECH = 0;
CHECK_NC_META = 0;


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

logFile = [DIR_LOG_FILE '/' 'nc_check_file_format' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_FILE '/' 'nc_check_file_format' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['Line #; WMO; File type; File name; Status; Compliance; Version; Cmd'];
fprintf(fidOut, '%s\n', header);

% process the floats
lineNum = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
     
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
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
            ncFilePathName = [ncFileDir '/' ncFileName];
            
            %             cmd = ['cd ' DIR_JAVA_CHECKER '& java -jar egoNetcdfChecker_2013_06_10.jar ' ...
            %                ncFilePathName];
            cmd = ['cd ' DIR_JAVA_CHECKER '& C:\"Program Files"\Java\jre7_1.7.0_02_pourCheckerCoriolis\bin\java.exe -jar egoNetcdfChecker_2013_06_10.jar ' ...
               ncFilePathName];
            
            [status, cmdOut] = system(cmd);
            if (status == 0)
               idFComp1 = strfind(cmdOut, '<file_compliant>');
               idFComp2 = strfind(cmdOut, '</file_compliant>');
               idFStatus1 = strfind(cmdOut, '<status>');
               idFStatus2 = strfind(cmdOut, '</status>');
               if (~isempty(idFComp1) && ~isempty(idFComp2) && ...
                     ~isempty(idFStatus1) && ~isempty(idFStatus2))
                  idFComp1 = idFComp1 + length('<file_compliant>');
                  compliant = cmdOut(idFComp1:idFComp2-1);
                  idFStatus1 = idFStatus1 + length('<status>');
                  status = cmdOut(idFStatus1:idFStatus2-1);
                  idFVer1 = strfind(cmdOut, '<format_version>');
                  idFVer1 = idFVer1 + length('<format_version>');
                  idFVer2 = strfind(cmdOut, '</format_version>');
                  version = cmdOut(idFVer1:idFVer2-1);
                  if (strcmp(compliant, 'yes') && strcmp(status, 'ok'))
                     fprintf(fidOut, '%d; %d; %s; %s; %s; %s; %s\n', ...
                        lineNum, floatNum, pattern, ncFileName, status, compliant, version);
                  else
                     fprintf(fidOut, '%d; %d; %s; %s; %s; %s; %s; %s\n', ...
                        lineNum, floatNum, pattern, ncFileName, status, compliant, version, cmd);
                  end
                  lineNum = lineNum + 1;
                  fprintf('%s: %s/%s (%s)\n', ncFileName, status, compliant, version);
               else
                  fprintf('WARNING: <file_compliant> or <status> patterns not found in output of system cmd ''%s''\n', cmd);
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
