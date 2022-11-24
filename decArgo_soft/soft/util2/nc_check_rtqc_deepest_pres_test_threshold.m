% ------------------------------------------------------------------------------
% Check the impact of different alternatives for setting the threshold of the
% RTQC deepest pressure test.
%  - in current core RTQC manual (V3.5): 10% of CONFIG_ProfilePressure_dbar
% Alternatives
%  1- coriolis implementation: percentage linear from 10 dbar to 1 000 dbar
%  (from 150% of CONFIG_ProfilePressure_dbar at 10 dbar to 10% of
%  CONFIG_ProfilePressure_dbar at 1 000 dbar) and constant (10% of
%  CONFIG_ProfilePressure_dbar) below 1 000 dbar
%  2- a table with pressure ranges
%  less than 100 dbar tolerance 200 dbar
%  100-200 dbar tolerance 300 dbar
%  200-700 dbar tolerance 400 dbar
%  700-900 dbar tolerance 300 dbar
%  900-1000 dbar tolerance 200 dbar
%  more than 1000 dbar tolerance 200 dbar
%  3- percentage linear from 10 dbar to 1 000 dbar, threshold of 200 dbar below
%  1 000 dbar
%  4- percentage linear from 10 dbar to 1 000 dbar, threshold of 100 dbar below
%  1 000 dbar
%
% SYNTAX :
%   nc_check_rtqc_deepest_pres_test_threshold or nc_check_rtqc_deepest_pres_test_threshold(6900189, 7900118)
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
%   09/28/2021 - RNU - creation
%   10/13/2021 - RNU - added alternative #4
% ------------------------------------------------------------------------------
function nc_check_rtqc_deepest_pres_test_threshold(varargin)

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of Argo NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
DIR_INPUT_NC_FILES = 'E:\202110-ArgoData\coriolis\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';


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

currentTime = datestr(now, 'yyyymmddTHHMMSS');

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_check_rtqc_deepest_pres_test_threshold_' currentTime '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_check_rtqc_deepest_pres_test_threshold_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
NB_PREV = 5;
header = 'QC_4;ALTERNATIVE #;WMO;FILE;N_PROF;PROFILE_PRESSURE;THRESHOLD;NB_QC_4;MAX_PRES_VAL';
for id = 1:NB_PREV
   header = [header ';PRES_VAL_' num2str(id)];
end
header = [header ';PRES_VALUES'];
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
            
            % retrieve nominal profile pressure from meta.nc
            metaFilePathName = [floatDirPathName '/' sprintf('%d_meta.nc', floatWmo)];
            if (exist(metaFilePathName, 'file') == 2)
               [profPresMeta, confNum] = get_prof_pres(metaFilePathName);
               if (isempty(profPresMeta))
                  fprintf('ERROR: Unable to retrieve PROFILE_PRESSURE from file: %s\n', metaFilePathName);
                  continue
               end
            else
               fprintf('ERROR: Unable to find file: %s\n', metaFilePathName);
               continue
            end
            
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
                     reportData = process_prof_nc_file(floatFilePathName, floatWmo, profPresMeta, confNum);
                     if (~isempty(reportData))
                        reportDataFloat = [reportDataFloat reportData];
                     end
                  end
               end
               
               % output results
               if (~isempty(reportDataFloat))
                  for idR = 1:length(reportDataFloat)
                     reportData = reportDataFloat(idR);
                     
                     [~, fileName, fileExt] = fileparts(reportData.profFile);
                     
                     profPresMeta = reportData.profPresMeta;
                     presVal = reportData.presVal;
                     idG = find(presVal > profPresMeta);
                     
                     qc4Flag = 0;
                     qc4Tab = zeros(1, 4);
                     for idA = 1:4
                        if (idA == 1)
                           % coriolis implementation
                           maxPres = compute_max_pres_alternative_1(profPresMeta);
                        elseif (idA == 2)
                           % alternative 2
                           maxPres = compute_max_pres_alternative_2(profPresMeta);
                        elseif (idA == 3)
                           % alternative 3
                           maxPres = compute_max_pres_alternative_3(profPresMeta);
                        elseif (idA == 4)
                           % alternative 4
                           maxPres = compute_max_pres_alternative_4(profPresMeta);
                        end
                        qc4Tab(idA) = length(find(presVal > maxPres));
                     end
                     if (length(unique(qc4Tab)) > 1)
                        qc4Flag = 2;
                     elseif ((length(unique(qc4Tab)) == 1) && (qc4Tab(1) ~= 0))
                        qc4Flag = 1;
                     end
                     
                     if (qc4Flag == 2)
                        for idA = 0:4
                           if (idA == 0)
                              % 10% of PROFILE_PRESSURE
                              maxPres = profPresMeta*1.1;
                           elseif (idA == 1)
                              % coriolis implementation
                              maxPres = compute_max_pres_alternative_1(profPresMeta);
                           elseif (idA == 2)
                              % alternative 2
                              maxPres = compute_max_pres_alternative_2(profPresMeta);
                           elseif (idA == 3)
                              % alternative 3
                              maxPres = compute_max_pres_alternative_3(profPresMeta);
                           elseif (idA == 4)
                              % alternative 4
                              maxPres = compute_max_pres_alternative_4(profPresMeta);
                           end
                           
                           idQc4 = find(presVal > maxPres);
                           fprintf(fidOut, '%d;%d;%d;%s;%d;%d;%.1f;%d;%.1f', ...
                              qc4Flag, ...
                              idA, ...
                              reportData.floatNum, ...
                              [fileName fileExt], ...
                              reportData.profId, ...
                              reportData.profPresMeta, ...
                              maxPres, ...
                              length(idQc4), ...
                              max(presVal));
                           for idL = idG-NB_PREV:length(presVal)
                              if (idL > 1)
                                 if (presVal(idL) > maxPres)
                                    presValStr = sprintf(';%.1f (4)', presVal(idL));
                                 else
                                    presValStr = sprintf(';%.1f (1)', presVal(idL));
                                 end
                              else
                                 presValStr = ';99999 ( )';
                              end
                              fprintf(fidOut, '%s', presValStr);
                           end
                           fprintf(fidOut, '\n');
                        end
                        fprintf(fidOut, '%d;%d;%d\n', ...
                           qc4Flag, ...
                           -1, ...
                           reportData.floatNum);
                     end
                  end
               end
            else
               fprintf('ERROR: Directory not found: %s\n', profDirPathName);
               continue
            end
            floatNum = floatNum + 1;
         end
      end
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
%   09/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportData] = process_prof_nc_file(a_ncProfPathFileName, a_floatNum, a_profPresMeta, a_confNum)

% output parameters initialization
o_reportData = [];


if (exist(a_ncProfPathFileName, 'file') == 2)
   
   % get information from the file
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      {'PRES'} ...
      {'CONFIG_MISSION_NUMBER'} ...
      ];
   [inputData] = get_data_from_nc_file(a_ncProfPathFileName, wantedInputVars);
   if (~isempty(inputData))
      
      idVal = find(strcmp('FORMAT_VERSION', inputData(1:2:end)) == 1, 1);
      formatVersion = strtrim(inputData{2*idVal}');
      if (strcmp(formatVersion, '3.1'))

         idVal = find(strcmp('PRES', inputData(1:2:end)) == 1, 1);
         pres = inputData{2*idVal};
         idVal = find(strcmp('CONFIG_MISSION_NUMBER', inputData(1:2:end)) == 1, 1);
         configMissonNumber = inputData{2*idVal};

         [~, nProf] = size(pres);
         for idProf = 1:nProf
            presVal = pres(:, idProf);
            
            % clean trailing fill values
            presVal = flipud(presVal);
            idF = find(presVal ~= 99999, 1, 'first');
            if (isempty(idF))
               continue
            end
            presVal(1:idF-1) = [];
            presVal = flipud(presVal);
            
            % retrieve meta PROFILE_PRESSURE
            profConfigNum = configMissonNumber(idProf);
            idF = find(a_confNum == profConfigNum);
            if (isempty(idF))
               fprintf('ERROR: profile #%d configuration number (%d) not found in meta data\n', ...
                  idProf, profConfigNum);
               continue
            end
            profPresMeta = a_profPresMeta(idF);
            
            if (any(presVal > profPresMeta))
               reportData = [];
               reportData.floatNum = a_floatNum;
               reportData.profFile = a_ncProfPathFileName;
               reportData.profId = idProf;
               reportData.profPresMeta = profPresMeta;
               reportData.presVal = presVal;
               o_reportData = [o_reportData reportData];
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
%   09/28/2021 - RNU - creation
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
%   09/28/2021 - RNU - creation
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
%   09/28/2021 - RNU - creation
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
%  [o_maxPres] = compute_max_pres_alternative_1(a_profilePressure)
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
%   09/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_maxPres] = compute_max_pres_alternative_1(a_profilePressure)

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

% ------------------------------------------------------------------------------
% Compute the new threshold for test #19 along the following rules:
%  less than 100 dbar tolerance 200 dbar
%  100-200 dbar tolerance 300 dbar
%  200-700 dbar tolerance 400 dbar
%  700-900 dbar tolerance 300 dbar
%  900-1000 dbar tolerance 200 dbar
%  more than 1000 dbar tolerance 200 dbar
%
% SYNTAX :
%  [o_maxPres] = compute_max_pres_alternative_2(a_profilePressure)
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
%   09/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_maxPres] = compute_max_pres_alternative_2(a_profilePressure)

if (a_profilePressure < 100)
   o_maxPres = a_profilePressure + 200;
elseif (a_profilePressure < 200)
   o_maxPres = a_profilePressure + 300;
elseif (a_profilePressure < 700)
   o_maxPres = a_profilePressure + 400;
elseif (a_profilePressure < 900)
   o_maxPres = a_profilePressure + 300;
elseif (a_profilePressure < 1000)
   o_maxPres = a_profilePressure + 200;
else
   o_maxPres = a_profilePressure + 200;
end

return

% ------------------------------------------------------------------------------
% Compute the new threshold for test #19 along the following rules:
%  percentage linear from 10 dbar to 1 000 dbar, threshold of 200 dbar below
%  1 000 dbar
%
% SYNTAX :
%  [o_maxPres] = compute_max_pres_alternative_3(a_profilePressure)
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
%   09/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_maxPres] = compute_max_pres_alternative_3(a_profilePressure)

if (a_profilePressure >= 1000)
   % 200 dbar for profile pressures deeper than 1000 dbar
   o_maxPres = a_profilePressure + 200;
else
   % for profile pressures shallower than 1000 dbar, the coefficient will
   % vary linearly between 150 % at 10 dbar and 20 % at 1000 dbar
   coefA = (150-20)/(10-1000);
   coefB = 20 - coefA*1000;
   coef = coefA*a_profilePressure + coefB;
   o_maxPres = a_profilePressure*(1+coef/100);
end

return

% ------------------------------------------------------------------------------
% Compute the new threshold for test #19 along the following rules:
%  percentage linear from 10 dbar to 1 000 dbar, threshold of 100 dbar below
%  1 000 dbar
%
% SYNTAX :
%  [o_maxPres] = compute_max_pres_alternative_4(a_profilePressure)
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
%   10/13/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_maxPres] = compute_max_pres_alternative_4(a_profilePressure)

if (a_profilePressure >= 1000)
   % 100 dbar for profile pressures deeper than 1000 dbar
   o_maxPres = a_profilePressure + 100;
else
   % for profile pressures shallower than 1000 dbar, the coefficient will
   % vary linearly between 150 % at 10 dbar and 10 % at 1000 dbar
   coefA = (150-10)/(10-1000);
   coefB = 10 - coefA*1000;
   coef = coefA*a_profilePressure + coefB;
   o_maxPres = a_profilePressure*(1+coef/100);
end

return
