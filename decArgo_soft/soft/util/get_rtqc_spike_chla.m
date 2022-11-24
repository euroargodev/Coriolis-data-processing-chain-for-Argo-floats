% ------------------------------------------------------------------------------
% Retrieve profiles that failed the RTQC spike test for CHLA parameter.
%
% SYNTAX :
%   get_rtqc_spike_chla or get_rtqc_spike_chla(6900189, 7900118)
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
%   01/21/2019 - RNU - creation
% ------------------------------------------------------------------------------
function get_rtqc_spike_chla(varargin)

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of Argo NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\201809-ArgoData\coriolis\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% report information structure
global g_cortqc_floatNum;
global g_cortqc_reportData;
g_cortqc_reportData.float = [];
g_cortqc_reportData.profFile = [];
g_cortqc_reportData.profId = [];
g_cortqc_reportData.rtqcTestDate = [];
g_cortqc_reportData.spikeTestFlag = [];

% default values initialization
init_default_values;


floatList = '';
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      % floats to process come from floatListFileName
      if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
         fprintf('File not found: %s\n', FLOAT_LIST_FILE_NAME);
         return
      end
      
      fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
      floatList = load(FLOAT_LIST_FILE_NAME);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/' 'get_rtqc_spike_chla_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'get_rtqc_spike_chla_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['WMO; File; N_PROF; HISTORY_DATE; CHLA SPIKE TEST FAILED'];
fprintf(fidOut, '%s\n', header);

% process input directory contents
floatNum = 1;
floatDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(floatDir)
   
   floatDirName = floatDir(idDir).name;
   floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
   if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
      
      [floatWmo, status] = str2num(floatDirName);
      if (status == 1)
         
         if ((isempty(floatList)) || (~isempty(floatList) && ismember(floatWmo, floatList)))
            
            if (isempty(floatList))
               fprintf('%03d/%03d %d\n', floatNum, length(floatDir)-2, floatWmo);
            else
               fprintf('%03d/%03d %d\n', floatNum, length(floatList), floatWmo);
            end
            g_cortqc_floatNum = floatWmo;
            
            % B mono-profile files
            profDirPathName = [floatDirPathName '/profiles'];
            if (exist(profDirPathName, 'dir') == 7)
               floatFiles = dir([profDirPathName '/' sprintf('B*%d_*.nc', floatWmo)]);
               for idFile = 1:length(floatFiles)
                  
                  floatFileName = floatFiles(idFile).name;
                  floatFilePathName = [floatDirPathName '/profiles/' floatFileName];
                  if (exist(floatFilePathName, 'file') == 2)
                     process_nc_file(floatFilePathName);
                  end
               end
            end
            floatNum = floatNum + 1;
         end
      end
   end
end

if (~isempty(g_cortqc_reportData.float))
   for idL = 1:length(g_cortqc_reportData.float)
      fprintf(fidOut, '%d;%s;%d;%s;%c\n', ...
         g_cortqc_reportData.float(idL), ...
         g_cortqc_reportData.profFile{idL}, ...
         g_cortqc_reportData.profId(idL), ...
         g_cortqc_reportData.rtqcTestDate{idL}, ...
         g_cortqc_reportData.spikeTestFlag(idL));
   end
end
        
fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one NetCDF file.
%
% SYNTAX :
%  process_nc_file(a_ncPathFileName)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : name of the file to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2019 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_ncPathFileName)

% report information structure
global g_cortqc_floatNum;
global g_cortqc_reportData;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % get information from the file
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      {'STATION_PARAMETERS'} ...
      {'HISTORY_INSTITUTION'} ...
      {'HISTORY_STEP'} ...
      {'HISTORY_SOFTWARE'} ...
      {'HISTORY_DATE'} ...
      {'HISTORY_ACTION'} ...
      {'HISTORY_QCTEST'} ...
      ];
   [inputData] = get_data_from_nc_file(a_ncPathFileName, wantedInputVars);
   if (~isempty(inputData))
      
      idVal = find(strcmp('FORMAT_VERSION', inputData(1:2:end)) == 1, 1);
      formatVersion = strtrim(inputData{2*idVal}');
      if (strcmp(formatVersion, '3.1'))
         
         % get profiles with CHLA
         idVal = find(strcmp('STATION_PARAMETERS', inputData(1:2:end)) == 1, 1);
         stationParameters = inputData{2*idVal};
         [~, inputNParam, inputNProf] = size(stationParameters);
         profWithParam = [];
         for idProf = 1:inputNProf
            for idParam = 1:inputNParam
               parameter = deblank(stationParameters(:, idParam, idProf)');
               if (strcmp(parameter, 'CHLA'))
                  profWithParam = [profWithParam idProf];
                  break
               end
            end
         end
         
         % process profiles with CHLA
         if (~isempty(profWithParam))
            
            idVal = find(strcmp('HISTORY_INSTITUTION', inputData(1:2:end)) == 1, 1);
            historyInstitution = inputData{2*idVal};
            [~, inputNProf, inputNHistory] = size(historyInstitution);
            idVal = find(strcmp('HISTORY_STEP', inputData(1:2:end)) == 1, 1);
            historyStep = inputData{2*idVal};
            idVal = find(strcmp('HISTORY_SOFTWARE', inputData(1:2:end)) == 1, 1);
            historySoftware = inputData{2*idVal};
            idVal = find(strcmp('HISTORY_DATE', inputData(1:2:end)) == 1, 1);
            historyDate = inputData{2*idVal};
            idVal = find(strcmp('HISTORY_ACTION', inputData(1:2:end)) == 1, 1);
            historyAction = inputData{2*idVal};
            idVal = find(strcmp('HISTORY_QCTEST', inputData(1:2:end)) == 1, 1);
            historyQcTest = inputData{2*idVal};
            
            for idProf = profWithParam
               for idHisto = inputNHistory:-1:1
                  histoAct = deblank(historyAction(:, idProf, idHisto)');
                  if (strcmp(histoAct, 'QCF$'))
                     histoInst = deblank(historyInstitution(:, idProf, idHisto)');
                     histoStep = deblank(historyStep(:, idProf, idHisto)');
                     histoSoft = deblank(historySoftware(:, idProf, idHisto)');
                     histoDate = deblank(historyDate(:, idProf, idHisto)');
                     histoQctest = deblank(historyQcTest(:, idProf, idHisto)');
                     
                     if (strcmp(histoInst, 'IF') && strcmp(histoStep, 'ARGQ') && strcmp(histoSoft, 'COQC'))
                        qcTestFlag = get_qctest_flag(histoQctest);
                        spikeTestFlag = qcTestFlag(9);
                        
                        g_cortqc_reportData.float = [g_cortqc_reportData.float g_cortqc_floatNum];
                        g_cortqc_reportData.profFile = [g_cortqc_reportData.profFile {a_ncPathFileName}];
                        g_cortqc_reportData.profId = [g_cortqc_reportData.profId idProf];
                        g_cortqc_reportData.rtqcTestDate = [g_cortqc_reportData.rtqcTestDate {histoDate}];
                        g_cortqc_reportData.spikeTestFlag = [g_cortqc_reportData.spikeTestFlag spikeTestFlag];
                        break
                     end
                  end
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Decode RTQC results HEX code to get individual test results.
%
% SYNTAX :
%  [o_qcTestFlag] = get_qctest_flag(a_qcTestHex)
%
% INPUT PARAMETERS :
%   a_qcTestHex : HEX code
%
% OUTPUT PARAMETERS :
%   o_qcTestFlag : list of individual test results
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_qcTestFlag] = get_qctest_flag(a_qcTestHex)

% output parameters initialization
o_qcTestFlag = '';


for id = 1:length(a_qcTestHex)
   o_qcTestFlag = [o_qcTestFlag dec2bin(hex2dec(a_qcTestHex(id)), 4)];
end

o_qcTestFlag = fliplr(o_qcTestFlag);
o_qcTestFlag(1) = [];

return
