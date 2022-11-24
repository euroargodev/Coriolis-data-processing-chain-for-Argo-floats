% ------------------------------------------------------------------------------
% Retrieve, from NetCDF Argo mono-profil files, the list of failed RTQC tests.
%
% SYNTAX :
%   nc_get_rtqc_failed_tests or nc_get_rtqc_failed_tests(6900189, 7900118)
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
%   03/04/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_rtqc_failed_tests(varargin)

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of Argo NetCDF files
DIR_INPUT_NC_FILES = 'E:\201902-ArgoData\coriolis';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\Coriolis_deep_floats_20210205\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% report information structure
global g_ngrft_floatNum;
global g_ngrft_reportData;
g_ngrft_reportData.float = [];
g_ngrft_reportData.profFile = [];
g_ngrft_reportData.profId = [];
g_ngrft_reportData.profParam = [];
g_ngrft_reportData.rtqcTestDate = [];
g_ngrft_reportData.qcTestFailed = [];


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
logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_rtqc_failed_tests_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_rtqc_failed_tests_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO;File;N_PROF;PARAM_LIST;HISTORY_DATE';
testList = sprintf('Test#%d;', [1:25 57:63]);
fprintf(fidOut, '%s;%s\n', header, testList(1:end-1));

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
            g_ngrft_floatNum = floatWmo;
            
            % process mono-profile files
            profDirPathName = [floatDirPathName '/profiles'];
            if (exist(profDirPathName, 'dir') == 7)
               floatFiles = [ ...
                  dir([profDirPathName '/' sprintf('R%d_*.nc', floatWmo)]); ...
                  dir([profDirPathName '/' sprintf('D%d_*.nc', floatWmo)]); ...
                  dir([profDirPathName '/' sprintf('B*%d_*.nc', floatWmo)]) ...
                  ];
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

if (~isempty(g_ngrft_reportData.float))
   for idL = 1:length(g_ngrft_reportData.float)
      [~, fileName, fileExt] = fileparts(g_ngrft_reportData.profFile{idL});
      paramList = g_ngrft_reportData.profParam{idL};
      paramList = sprintf('%s/', paramList{:});
      testFailedFlag = get_qctest_flag(g_ngrft_reportData.qcTestFailed{idL});
      testFailedFlag(26:56) = [];
      testFailedFlag = sprintf('%c;', testFailedFlag);
      
      fprintf(fidOut, '%d;%s;%d;%s;%s;%s\n', ...
         g_ngrft_reportData.float(idL), ...
         [fileName fileExt], ...
         g_ngrft_reportData.profId(idL), ...
         paramList(1:end-1), ...
         g_ngrft_reportData.rtqcTestDate{idL}, ...
         testFailedFlag(1:end-1));
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
%   03/04/2019 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_ncPathFileName)

% report information structure
global g_ngrft_floatNum;
global g_ngrft_reportData;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % get information from the file
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      {'STATION_PARAMETERS'} ...
      {'HISTORY_INSTITUTION'} ...
      {'HISTORY_STEP'} ...
      {'HISTORY_SOFTWARE'} ...
      {'HISTORY_DATE'} ...
      {'HISTORY_PARAMETER'} ...
      {'HISTORY_ACTION'} ...
      {'HISTORY_QCTEST'} ...
      ];
   [inputData] = get_data_from_nc_file(a_ncPathFileName, wantedInputVars);
   if (~isempty(inputData))
      
      idVal = find(strcmp('FORMAT_VERSION', inputData(1:2:end)) == 1, 1);
      formatVersion = strtrim(inputData{2*idVal}');
      if (strcmp(formatVersion, '3.1'))
         
         idVal = find(strcmp('STATION_PARAMETERS', inputData(1:2:end)) == 1, 1);
         stationParameters = inputData{2*idVal};
         [~, inputNParam, ~] = size(stationParameters);
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
         
         for idProf = 1:inputNProf
            profHistoDate = [];
            profHistoQcTest = [];
            for idHisto = 1:inputNHistory
               histoAct = deblank(historyAction(:, idProf, idHisto)');
               histoQctest = deblank(historyQcTest(:, idProf, idHisto)');
               if (strcmp(histoAct, 'QCF$') && ~strcmp(unique(histoQctest), '0'))
                  histoInst = deblank(historyInstitution(:, idProf, idHisto)');
                  histoStep = deblank(historyStep(:, idProf, idHisto)');
                  histoSoft = deblank(historySoftware(:, idProf, idHisto)');
                  histoDate = historyDate(:, idProf, idHisto)';
                  histoQctest = historyQcTest(:, idProf, idHisto)';
                  
                  if (strcmp(histoInst, 'IF') && strcmp(histoStep, 'ARGQ') && strcmp(histoSoft, 'COQC'))
                     profHistoDate = [profHistoDate; histoDate];
                     profHistoQcTest = [profHistoQcTest; histoQctest];
                  end
               end
            end
            if (~isempty(profHistoDate))
               if (size(profHistoDate, 1) > 1)
                  [~, idMax] = max(datenum(profHistoDate, 'yyyymmddHHMMSS'));
                  profHistoDate = profHistoDate(idMax, :);
                  profHistoQcTest = profHistoQcTest(idMax, :);
               end
               
               paramList = [];
               for idParam = 1:inputNParam
                  paramName = deblank(stationParameters(:, idParam, idProf)');
                  if (~isempty(paramName))
                     paramList{end+1} = paramName;
                  end
               end
               
               g_ngrft_reportData.float = [g_ngrft_reportData.float g_ngrft_floatNum];
               g_ngrft_reportData.profFile = [g_ngrft_reportData.profFile {a_ncPathFileName}];
               g_ngrft_reportData.profId = [g_ngrft_reportData.profId idProf];
               g_ngrft_reportData.profParam = [g_ngrft_reportData.profParam {paramList}];
               g_ngrft_reportData.rtqcTestDate = [g_ngrft_reportData.rtqcTestDate {deblank(profHistoDate)}];
               g_ngrft_reportData.qcTestFailed = [g_ngrft_reportData.qcTestFailed {deblank(profHistoQcTest)}];
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
%   03/04/2019 - RNU - creation
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
%   03/04/2019 - RNU - creation
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

% ------------------------------------------------------------------------------
% Check if a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present_dec_argo(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present_dec_argo(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar= 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break
   end
end

return
