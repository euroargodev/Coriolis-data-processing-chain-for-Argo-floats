% ------------------------------------------------------------------------------
% Retrieve, from NetCDF Argo mono-profil files, the list of failed RTQC
% deepest pressure test.
%
% SYNTAX :
%   nc_get_rtqc_deepest_pres_test or nc_get_rtqc_deepest_pres_test(6900189, 7900118)
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
%   03/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_rtqc_deepest_pres_test(varargin)

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of Argo NetCDF files
DIR_INPUT_NC_FILES = 'F:\201905-ArgoData\coriolis';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% float WMO number
global g_ngrft_floatNum;


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
logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_rtqc_deepest_pres_test_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_rtqc_deepest_pres_test_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'Old/New;WMO;File;N_PROF;HISTORY_DATE;PROFILE_PRESSURE;MAX_PRES;NB_QC_4;PRES_VALUES';
fprintf(fidOut, '%s\n', header);

% process input directory contents
reportDataAll = [];
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
                  dir([profDirPathName '/' sprintf('D%d_*.nc', floatWmo)]) ...
                  ];
               reportDataFloat = [];
               for idFile = 1:length(floatFiles)
                  
                  floatFileName = floatFiles(idFile).name;
                  floatFilePathName = [floatDirPathName '/profiles/' floatFileName];
                  if (exist(floatFilePathName, 'file') == 2)
                     reportData = process_prof_nc_file(floatFilePathName);
                     if (~isempty(reportData))
                        reportDataFloat = [reportDataFloat reportData];
                     end
                  end
               end
               
               if (~isempty(reportDataFloat))
                  % retrieve nominal profile pressure from meta.nc
                  metaFilePathName = [floatDirPathName '/' sprintf('%d_meta.nc', floatWmo)];
                  if (exist(metaFilePathName, 'file') == 2)
                     [profPresMeta, confNum] = get_prof_pres(metaFilePathName);
                     if (~isempty(profPresMeta))
                        for idR = 1:length(reportDataFloat)
                           idF = find(reportDataFloat(idR).configNum == confNum);
                           if (~isempty(idF))
                              reportDataFloat(idR).profPresMeta = profPresMeta(idF);
                           end
                        end
                     else
                        fprintf('ERROR: Unable to retrieve PROFILE_PRESSURE from file: %s\n', metaFilePathName);
                     end
                  else
                     fprintf('ERROR: Unable to find file: %s\n', metaFilePathName);
                  end
                  reportDataAll = [reportDataAll reportDataFloat];
               end
            end
            floatNum = floatNum + 1;
         end
      end
   end
end

% output results
if (~isempty(reportDataAll))
   for idL = 1:length(reportDataAll)
      [~, fileName, fileExt] = fileparts(reportDataAll(idL).profFile);
      presValStr = sprintf('%.1f;', reportDataAll(idL).presVal);
      
      fprintf(fidOut, 'O;%d;%s;%d;%s;%d;%.1f;%d;%s\n', ...
         reportDataAll(idL).float, ...
         [fileName fileExt], ...
         reportDataAll(idL).profId, ...
         reportDataAll(idL).rtqcTestDate, ...
         reportDataAll(idL).profPresMeta, ...
         (reportDataAll(idL).profPresMeta)*1.1, ...
         length(reportDataAll(idL).presVal), ...
         presValStr(1:end-1));
      
      newMaxProfilePressure = compute_max_pres_for_rtqc_test19(reportDataAll(idL).profPresMeta);
      presValList = reportDataAll(idL).presVal;
      newPresValList = presValList(find((presValList < 0) | (presValList > newMaxProfilePressure)));
      newPresValListStr = sprintf('%.1f;', newPresValList);
      
      fprintf(fidOut, 'N;%d;%s;%d;%s;%d;%.1f;%d;%s\n', ...
         reportDataAll(idL).float, ...
         [fileName fileExt], ...
         reportDataAll(idL).profId, ...
         reportDataAll(idL).rtqcTestDate, ...
         reportDataAll(idL).profPresMeta, ...
         newMaxProfilePressure, ...
         length(newPresValList), ...
         newPresValListStr(1:end-1));
      
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one PROF NetCDF file.
%
% SYNTAX :
%  [o_reportData] = process_prof_nc_file(a_ncProfPathFileName)
%
% INPUT PARAMETERS :
%   a_ncProfPathFileName : name of the file to process
%
% OUTPUT PARAMETERS :
%   o_reportData : output stored information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportData] = process_prof_nc_file(a_ncProfPathFileName)

% output parameters initialization
o_reportData = [];

% float WMO number
global g_ngrft_floatNum;


if (exist(a_ncProfPathFileName, 'file') == 2)
   
   % get information from the file
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      ];
   [inputData] = get_data_from_nc_file(a_ncProfPathFileName, wantedInputVars);
   if (~isempty(inputData))
      
      idVal = find(strcmp('FORMAT_VERSION', inputData(1:2:end)) == 1, 1);
      formatVersion = strtrim(inputData{2*idVal}');
      if (strcmp(formatVersion, '3.1'))
         
         % get information from the file
         wantedInputVars = [ ...
            {'PRES'} ...
            {'PRES_QC'} ...
            {'CONFIG_MISSION_NUMBER'} ...
            {'HISTORY_INSTITUTION'} ...
            {'HISTORY_STEP'} ...
            {'HISTORY_SOFTWARE'} ...
            {'HISTORY_DATE'} ...
            {'HISTORY_PARAMETER'} ...
            {'HISTORY_ACTION'} ...
            {'HISTORY_QCTEST'} ...
            ];
         [inputData] = get_data_from_nc_file(a_ncProfPathFileName, wantedInputVars);
         if (~isempty(inputData))
            
            idVal = find(strcmp('PRES', inputData(1:2:end)) == 1, 1);
            pres = inputData{2*idVal};
            idVal = find(strcmp('PRES_QC', inputData(1:2:end)) == 1, 1);
            presQc = inputData{2*idVal};
            idVal = find(strcmp('CONFIG_MISSION_NUMBER', inputData(1:2:end)) == 1, 1);
            configMissonNumber = inputData{2*idVal};
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
                     profHistoDate = profHistoDate(idMax);
                     profHistoQcTest = profHistoQcTest(idMax);
                  end
                  
                  qcTestFlag = get_qctest_flag(profHistoQcTest);
                  deepestPresTestFlag = qcTestFlag(19);
                  if (deepestPresTestFlag == '1')
                     
                     idBottomQcFalse = find(presQc(:, idProf) == '4');
                     idF = find(diff(idBottomQcFalse) ~= 1, 1, 'last');
                     if (~isempty(idF))
                        idBottomQcFalse = idBottomQcFalse(idF+1:end);
                     end
                     
                     reportData = [];
                     reportData.float = g_ngrft_floatNum;
                     reportData.profFile = a_ncProfPathFileName;
                     reportData.profId = idProf;
                     reportData.rtqcTestDate = deblank(profHistoDate);
                     reportData.configNum = configMissonNumber(idProf);
                     reportData.profPresMeta = -1;
                     reportData.presVal = pres(idBottomQcFalse, idProf);
                     o_reportData = [o_reportData reportData];
                  end
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve PROFILE PRESSURE meta-data from meta NetCDF file.
%
% SYNTAX :
%  [o_profPresMeta, o_confNum] = get_prof_pres(a_ncMetaPathFileName)
%
% INPUT PARAMETERS :
%   a_ncMetaPathFileName : name of the meta data file
%
% OUTPUT PARAMETERS :
%   o_profPresMeta : PROFILE PRESSURE values
%   o_confNum      : associted configuration numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profPresMeta, o_confNum] = get_prof_pres(a_ncMetaPathFileName)

% output parameters initialization
o_profPresMeta = [];
o_confNum = [];


% retrieve information from NetCDF meta file
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   ];
[ncMetaData] = get_data_from_nc_file(a_ncMetaPathFileName, wantedVars);
if (~isempty(ncMetaData))
   idVal = find(strcmp('FORMAT_VERSION', ncMetaData(1:2:end)) == 1, 1);
   formatVersion = strtrim(ncMetaData{2*idVal}');
   if (strcmp(formatVersion, '3.1'))
      
      % retrieve information from NetCDF meta file
      wantedVars = [ ...
         {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
         {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_PARAMETER_NAME'} ...
         {'CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_MISSION_NUMBER'} ...
         {'PARAMETER'} ...
         {'PARAMETER_SENSOR'} ...
         ];
      [ncMetaData] = get_data_from_nc_file(a_ncMetaPathFileName, wantedVars);
      if (~isempty(ncMetaData))
         
         idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', ncMetaData(1:2:end)) == 1, 1);
         launchConfigParameterName = cellstr(ncMetaData{2*idVal}');
         idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', ncMetaData(1:2:end)) == 1, 1);
         launchConfigParameterValue = ncMetaData{2*idVal};
         idVal = find(strcmp('CONFIG_PARAMETER_NAME', ncMetaData(1:2:end)) == 1, 1);
         configParameterName = cellstr(ncMetaData{2*idVal}');
         idVal = find(strcmp('CONFIG_PARAMETER_VALUE', ncMetaData(1:2:end)) == 1, 1);
         configParameterValue = ncMetaData{2*idVal};
         idVal = find(strcmp('CONFIG_MISSION_NUMBER', ncMetaData(1:2:end)) == 1, 1);
         o_confNum = ncMetaData{2*idVal}';
         
         o_profPresMeta = [];
         idFl = find(strcmp('CONFIG_ProfilePressure_dbar', configParameterName) == 1);
         if (~isempty(idFl))
            o_profPresMeta = configParameterValue(idFl, :);
         else
            idFl = find(strcmp('CONFIG_ProfilePressure_dbar', launchConfigParameterName) == 1);
            if (~isempty(idFl))
               o_profPresMeta = launchConfigParameterValue(idFl);
               o_profPresMeta = repmat(o_profPresMeta, size(o_confNum));
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
%  [o_ncData] = get_data_from_nc_file(a_ncProfPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncProfPathFileName : NetCDF file name
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
%   03/20/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncProfPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncProfPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncProfPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncProfPathFileName);
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
            varName, a_ncProfPathFileName);
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
%   03/20/2019 - RNU - creation
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
%   03/20/2019 - RNU - creation
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

% ------------------------------------------------------------------------------
% Compute the new threshold for test #19 along the following rules:
%   - 10% for profile pressures deeper than 1000 dbar
%   - for profile pressures shallower than 1000 dbar, the coefficient varies
%     linearly between 10% at 1000 dbar and 150% at 10 dbar
%
% SYNTAX :
%  [o_maxPres] = compute_max_pres_for_rtqc_test19(a_profilePressure)
%
% INPUT PARAMETERS :
%   a_profilePressure : meta PROFILE_PRESSURE value
%
% OUTPUT PARAMETERS :
%   o_maxPres : profile pressure threshold
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_maxPres] = compute_max_pres_for_rtqc_test19(a_profilePressure)

if (a_profilePressure >= 1000)
   % 10 % for profile pressures deeper than 1000 dbar
   o_maxPres = a_profilePressure*1.1;
else
   % for profile pressures shallower than 1000 dbar, the coefficient will
   % vary linearly between 150 % at 10 dbar and 10 % at 1000 dbar
   coefA = (150-10)/(10-1000);
   coefB = 10 - coefA*1000;
   coef = coefA*a_profilePressure + coefB;
   o_maxPres = a_profilePressure*(1+coef/100);
end

return
