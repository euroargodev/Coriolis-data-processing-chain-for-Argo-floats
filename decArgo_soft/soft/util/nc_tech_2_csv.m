% ------------------------------------------------------------------------------
% Convert NetCDF technical file contents in CSV format.
%
% SYNTAX :
%   nc_tech_2_csv or nc_tech_2_csv(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_tech_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% default list of floats to convert
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_cm.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_4.54.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_032213.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.45.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.74.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_5.64.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_argos.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_212.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_214.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_216.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_217.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_6.11_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_decId_1121.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_decId_1321&1322.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\ICE_check_lists\apex_apf9_argos_ice_detected.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% to compare different set of files do not print current dates
COMPARISON_MODE = 0;


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

logFile = [DIR_LOG_FILE '/' 'nc_tech_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];

   if (exist(ncFileDir, 'dir') == 7)

      % convert tech file
      techFileName = sprintf('%d_tech.nc', floatNum);
      techFilePathName = [ncFileDir techFileName];

      if (exist(techFilePathName, 'file') == 2)

         outputFileName = [techFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDir outputFileName];
         nc_tech_2_csv_file(techFilePathName, outputFilePathName, floatNum, COMPARISON_MODE);
      end

      ncAuxFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/auxiliary/'];

      if (exist(ncAuxFileDir, 'dir') == 7)

         % convert auxiliary tech file
         techFileName = sprintf('%d_tech_aux.nc', floatNum);
         techFilePathName = [ncAuxFileDir techFileName];

         if (exist(techFilePathName, 'file') == 2)

            outputFileName = [techFileName(1:end-3) '.csv'];
            outputFilePathName = [ncAuxFileDir outputFileName];
            nc_tech_aux_2_csv_file(techFilePathName, outputFilePathName, floatNum, COMPARISON_MODE);
         end
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Convert one NetCDF technical file contents in CSV format.
%
% SYNTAX :
%  nc_tech_aux_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
%    a_floatNum, a_comparisonFlag)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%   a_floatNum           : float WMO number
%   a_comparisonFlag     : if 1, do not print current dates
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_tech_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag)

% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('Converting: %s to %s\n', inputFileName, ourputFileName);

% retrieve timeseries information from tech file
timeSeriesData = get_timeseries_data(a_inputPathFileName);

% retrieve information from tech file
wantedTechVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'DATA_CENTRE'} ...
   {'TECHNICAL_PARAMETER_NAME'} ...
   {'TECHNICAL_PARAMETER_VALUE'} ...
   {'CYCLE_NUMBER'} ...
   ];
if (a_comparisonFlag == 0)
   wantedTechVars = [ ...
      wantedTechVars ...
      {'DATE_CREATION'} ...
      {'DATE_UPDATE'} ...
      ];
end
if (~isempty(timeSeriesData))
   wantedTechVars = [wantedTechVars ...
      {'JULD'} ...
      {'CYCLE_NUMBER_MEAS'} ...
      {'MEASUREMENT_CODE'} ...
      timeSeriesData.PARAM_LIST ...
      ];
   fixedParamList = [ ...
      {'JULD'} ...
      {'CYCLE_NUMBER_MEAS'} ...
      {'MEASUREMENT_CODE'} ...
      ];
end

% retrieve information from TECH netCDF file
[techData] = get_data_from_nc_file(a_inputPathFileName, wantedTechVars);

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return
end

fprintf(fidOut, ' WMO; ------------------------------; DIMENSIONS\n');

idVal = find(strcmp('CYCLE_NUMBER', techData));
if (~isempty(idVal))
   val = techData{idVal+1}';
   fprintf(fidOut, ' %d; N_TECH_PARAM; %d\n', a_floatNum, length(val));
else
   fprintf(fidOut, ' %d; N_TECH_PARAM\n', a_floatNum);
end
if (~isempty(timeSeriesData))
   fprintf(fidOut, ' %d; N_TECH_MEASUREMENT; %d\n', a_floatNum, timeSeriesData.N_TECH_MEASUREMENT);
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; ------------------------------; GENERAL INFORMATION\n');

techVars = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'DATA_CENTRE'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   ];

for idL = 1:length(techVars)

   name = techVars{idL};
   val = '';
   idVal = find(strcmp(name, techData));
   if (~isempty(idVal))
      val = techData{idVal+1}';
   end
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, name, strtrim(val));
end

if (~isempty(timeSeriesData))
   fprintf(fidOut, ' %d\n', a_floatNum);
   fprintf(fidOut, ' WMO; ------------------------------; N_TECH_MEASUREMENT PARAMETERS\n');

   for idParam = 1:size(timeSeriesData.PARAM_INFO, 1)
      att = [];
      for idAtt = 3:2:size(timeSeriesData.PARAM_INFO, 2)
         att = [att timeSeriesData.PARAM_INFO{idParam, idAtt} ':''' timeSeriesData.PARAM_INFO{idParam, idAtt+1} '''' '/'];
      end
      fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, timeSeriesData.PARAM_INFO{idParam, 2}, att(1:end-1));
   end
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' %d; ------------------------------; --------------------------------------------------------------------------------\n', a_floatNum);
fprintf(fidOut, ' WMO; Cycle #; TECHNICAL DATA\n');

techParamName = '';
idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData));
if (~isempty(idVal))
   techParamName = techData{idVal+1}';
end

techParamValue = '';
idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData));
if (~isempty(idVal))
   techParamValue = techData{idVal+1}';
end

cycleNumber = '';
idVal = find(strcmp('CYCLE_NUMBER', techData));
if (~isempty(idVal))
   cycleNumber = techData{idVal+1};
end

for idCycle = min(cycleNumber):max(cycleNumber)

   idForCy = find(cycleNumber == idCycle);
   if (~isempty(idForCy))
      for  idT = 1:length(idForCy)
         fprintf(fidOut, ' %d; %d; %s; %s\n', a_floatNum, idCycle, strtrim(techParamName(idForCy(idT), :)), strtrim(techParamValue(idForCy(idT), :)));
      end
   else
      fprintf(fidOut, ' %d; %d; NONE\n', a_floatNum, idCycle);
   end

   fprintf(fidOut, ' %d; ------------------------------; --------------------------------------------------------------------------------\n', a_floatNum);
end

if (~isempty(timeSeriesData))
   fprintf(fidOut, ' %d\n', a_floatNum);
   fprintf(fidOut, [' %d; ---;---;---;---' repmat(';---', 1, length(timeSeriesData.PARAM_LIST)) '\n'], a_floatNum);
   fprintf(fidOut, ' WMO; Meas #; JULD; CYCLE_NUMBER_MEAS; MEASUREMENT_CODE');
   for idParam = 1:length(timeSeriesData.PARAM_LIST)
      fprintf(fidOut, '; %s', timeSeriesData.PARAM_LIST{idParam});
   end
   fprintf(fidOut, '\n');

   juld = nan(timeSeriesData.N_TECH_MEASUREMENT, 1);
   idVal = find(strcmp(techData, 'JULD'));
   if (~isempty(idVal))
      juld = techData{idVal+1};
   end

   cycleNumberMeas = nan(timeSeriesData.N_TECH_MEASUREMENT, 1);
   idVal = find(strcmp(techData, 'CYCLE_NUMBER_MEAS'));
   if (~isempty(idVal))
      cycleNumberMeas = techData{idVal+1};
   end

   measurementCode = nan(timeSeriesData.N_TECH_MEASUREMENT, 1);
   idVal = find(strcmp(techData, 'MEASUREMENT_CODE'));
   if (~isempty(idVal))
      measurementCode = techData{idVal+1};
   end

   paramData = nan(timeSeriesData.N_TECH_MEASUREMENT, length(timeSeriesData.PARAM_LIST));
   for idParam = 1:length(timeSeriesData.PARAM_LIST)
      idVal = find(strcmp(techData, timeSeriesData.PARAM_LIST{idParam}));
      if (~isempty(idVal))
         paramData(:, idParam) = techData{idVal+1};
      end
   end

   for idMeas = 1:length(juld)
      fprintf(fidOut, [' %d; MEAS #%04d; %s; %d; %s' repmat('; %g', 1, size(paramData, 2)) '\n'], ...
         a_floatNum, idMeas,  ...
         julian_2_gregorian_dec_argo(juld(idMeas)), ...
         cycleNumberMeas(idMeas), ...
         get_meas_code_name(measurementCode(idMeas)), ...
         paramData(idMeas, :));
   end
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Convert one NetCDF auxiliary technical file contents in CSV format.
%
% SYNTAX :
%  nc_tech_aux_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
%    a_floatNum, a_comparisonFlag)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%   a_floatNum           : float WMO number
%   a_comparisonFlag     : if 1, do not print current dates
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_tech_aux_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag)

% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('Converting: %s to %s\n', inputFileName, ourputFileName);

% retrieve information from tech file
wantedTechVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'REFERENCE_DATE_TIME'} ...
   {'TECHNICAL_MEASUREMENT_PARAMETERS'} ...
   {'DATA_CENTRE'} ...
   {'TECHNICAL_PARAMETER_NAME'} ...
   {'TECHNICAL_PARAMETER_VALUE'} ...
   {'CYCLE_NUMBER'} ...
   {'TECH_AUX_PARAM_LABEL'} ...
   {'TECH_AUX_PARAM_DESCRIPTION'} ...
   {'JULD'} ...
   {'JULD_STATUS'} ...
   {'JULD_QC'} ...
   {'JULD_ADJUSTED'} ...
   {'JULD_ADJUSTED_STATUS'} ...
   {'JULD_ADJUSTED_QC'} ...
   {'CYCLE_NUMBER_MEAS'} ...
   {'MEASUREMENT_CODE'} ...
   ];
if (a_comparisonFlag == 0)
   wantedTechVars = [ ...
      wantedTechVars ...
      {'DATE_CREATION'} ...
      {'DATE_UPDATE'} ...
      ];
end

% retrieve information from TECH netCDF file
[techData] = get_data_from_nc_file(a_inputPathFileName, wantedTechVars);

techAuxParamLabel = '';
idVal = find(strcmp('TECH_AUX_PARAM_LABEL', techData));
nTechAuxlabel = 0;
if (~isempty(idVal))
   techAuxParamLabel = techData{idVal+1}';
   if (techAuxParamLabel == ' ')
      techAuxParamLabel = '';
   end
   nTechAuxlabel = size(techAuxParamLabel, 1);
end

techAuxParamDescription = '';
idVal = find(strcmp('TECH_AUX_PARAM_DESCRIPTION', techData));
if (~isempty(idVal))
   techAuxParamDescription = techData{idVal+1}';
end

idVal = find(strcmp('TECHNICAL_MEASUREMENT_PARAMETERS', techData));
nTechMeasParam = 0;
if (~isempty(idVal))
   technicalMeasurementParameters = techData{idVal+1}';
   nTechMeasParam = size(technicalMeasurementParameters, 1);

   wantedTechVars2 = [];
   for idParam = 1:nTechMeasParam
      parameterName = strtrim(technicalMeasurementParameters(idParam, :));
      wantedTechVars2 = [wantedTechVars2 {parameterName} {[parameterName '_QC']}];
   end

   [techData2] = get_data_from_nc_file(a_inputPathFileName, wantedTechVars2);
   techData = [techData techData2];
end

idVal = find(strcmp('CYCLE_NUMBER_MEAS', techData));
nTechMeas = 0;
if (~isempty(idVal))
   var = techData{idVal+1}';
   nTechMeas = length(var);
end

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return
end

fprintf(fidOut, ' WMO; ------------------------------; DIMENSIONS\n');

if (nTechAuxlabel > 0)
   fprintf(fidOut, ' %d; N_TECH_AUX_LABEL; %d\n', a_floatNum, nTechAuxlabel);
end

if (nTechMeasParam > 0)
   fprintf(fidOut, ' %d; N_TECH_MEAS_PARAM ; %d\n', a_floatNum, nTechMeasParam);
end

idVal = find(strcmp('CYCLE_NUMBER', techData));
if (~isempty(idVal))
   val = techData{idVal+1}';
   fprintf(fidOut, ' %d; N_TECH_PARAM; %d\n', a_floatNum, length(val));
else
   fprintf(fidOut, ' %d; N_TECH_PARAM\n', a_floatNum);
end

if (nTechMeas > 0)
   fprintf(fidOut, ' %d; N_TECH_MEASUREMENT ; %d\n', a_floatNum, nTechMeas);
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; ------------------------------; GENERAL INFORMATION\n');

techVars = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'REFERENCE_DATE_TIME'} ...
   {'DATA_CENTRE'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   ];

for idL = 1:length(techVars)

   name = techVars{idL};
   val = '';
   idVal = find(strcmp(name, techData));
   if (~isempty(idVal))
      val = techData{idVal+1}';
   end
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, name, strtrim(val));
end

for idParam = 1:nTechMeasParam
   parameterName = strtrim(technicalMeasurementParameters(idParam, :));
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, ['TECHNICAL_MEASUREMENT_PARAMETERS_' num2str(idParam)], parameterName);
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' %d; ------------------------------; --------------------------------------------------------------------------------; --------------------------------------------------------------------------------\n', a_floatNum);
fprintf(fidOut, ' WMO; Param #; TECHNICAL PARAMETER LABEL; TECHNICAL PARAMETER DESCRIPTION\n');

for idParam = 1:size(techAuxParamLabel, 1)
   fprintf(fidOut, ' %d; %d; %s; %s\n', a_floatNum, idParam, strtrim(techAuxParamLabel(idParam, :)), strtrim(techAuxParamDescription(idParam, :)));
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' %d; ------------------------------; --------------------------------------------------------------------------------\n', a_floatNum);
fprintf(fidOut, ' WMO; Cycle #; TECHNICAL DATA\n');

techParamName = '';
idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData));
if (~isempty(idVal))
   techParamName = techData{idVal+1}';
end

techParamValue = '';
idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData));
if (~isempty(idVal))
   techParamValue = techData{idVal+1}';
end

cycleNumber = '';
idVal = find(strcmp('CYCLE_NUMBER', techData));
if (~isempty(idVal))
   cycleNumber = techData{idVal+1};
end

if (~isempty(cycleNumber))
   for idCycle = min(cycleNumber):max(cycleNumber)

      idForCy = find(cycleNumber == idCycle);
      if (~isempty(idForCy))
         for  idT = 1:length(idForCy)
            fprintf(fidOut, ' %d; %d; %s; %s\n', a_floatNum, idCycle, strtrim(techParamName(idForCy(idT), :)), strtrim(techParamValue(idForCy(idT), :)));
         end
      else
         fprintf(fidOut, ' %d; %d; NONE\n', a_floatNum, idCycle);
      end

      fprintf(fidOut, ' %d; ------------------------------; --------------------------------------------------------------------------------\n', a_floatNum);
   end
end

if (nTechMeas > 0)

   juld = [];
   idVal = find(strcmp('JULD', techData));
   if (~isempty(idVal))
      juld = techData{idVal+1};
      if (juld == ' ')
         juld = [];
      end
   end
   juldStatus = [];
   idVal = find(strcmp('JULD_STATUS', techData));
   if (~isempty(idVal))
      juldStatus = techData{idVal+1};
   end
   juldQc = [];
   idVal = find(strcmp('JULD_QC', techData));
   if (~isempty(idVal))
      juldQc = techData{idVal+1};
   end
   juldAdj = [];
   idVal = find(strcmp('JULD_ADJUSTED', techData));
   if (~isempty(idVal))
      juldAdj = techData{idVal+1};
   end
   juldAdjStatus = [];
   idVal = find(strcmp('JULD_ADJUSTED_STATUS', techData));
   if (~isempty(idVal))
      juldAdjStatus = techData{idVal+1};
   end
   juldAdjQc = [];
   idVal = find(strcmp('JULD_ADJUSTED_QC', techData));
   if (~isempty(idVal))
      juldAdjQc = techData{idVal+1};
   end
   cycleNumberMeas = [];
   idVal = find(strcmp('CYCLE_NUMBER_MEAS', techData));
   if (~isempty(idVal))
      cycleNumberMeas = techData{idVal+1};
   end
   measCode = [];
   idVal = find(strcmp('MEASUREMENT_CODE', techData));
   if (~isempty(idVal))
      measCode = techData{idVal+1};
   end

   paramName = [];
   paramFormats = repmat('; %g', 1, nTechMeasParam);
   paramQcFormats = repmat('; %c', 1, nTechMeasParam);
   paramData = [];
   paramQcData = [];
   for idParam = 1:nTechMeasParam
      parameterName = strtrim(technicalMeasurementParameters(idParam, :));
      paramName = [paramName {parameterName}];
      idVal = find(strcmp(parameterName, techData));
      if (~isempty(idVal))
         data = techData{idVal+1};
         paramData = [paramData double(data)];
      end
      parameterQcName = [parameterName '_QC'];
      idVal = find(strcmp(parameterQcName, techData));
      if (~isempty(idVal))
         data = techData{idVal+1};
         paramQcData = [paramQcData data];
      end
   end

   fprintf(fidOut, ' %d\n', a_floatNum);
   fprintf(fidOut, ' %d; ---;---;---;---;---;---;---;---;---;---;---;---;---;---;\n', a_floatNum);
   fprintf(fidOut, ' WMO; Meas #; Cy #; Meas. code; JULD; ; ; JULD_ADJ; ; ;');
   for idParam = 1:nTechMeasParam
      fprintf(fidOut, '; %s', paramName{idParam});
   end
   fprintf(fidOut, '\n');

   fillValueStr = sprintf('%d', -1);
   for idMeas = 1:length(juld)
      paramDataStr = regexprep(sprintf(paramFormats, paramData(idMeas, :)), fillValueStr, ' ');
      fprintf(fidOut, [' %d; MEAS #%04d; %d; %s; %s; %c; %c; %s; %c; %c; %s' paramQcFormats '\n'], ...
         a_floatNum, idMeas, cycleNumberMeas(idMeas), get_meas_code_name(measCode(idMeas)), ...
         julian_2_gregorian_dec_argo(juld(idMeas)), juldStatus(idMeas), juldQc(idMeas), ...
         julian_2_gregorian_dec_argo(juldAdj(idMeas)), juldAdjStatus(idMeas), juldAdjQc(idMeas), ...
         paramDataStr, paramQcData(idMeas, :));
   end
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Retrieve timeseries information from NetCDF TECH file.
%
% SYNTAX :
%  [o_timeData] = get_timeseries_data(a_ncPathFileName)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF TECH file name
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeData] = get_timeseries_data(a_ncPathFileName)

% output parameters initialization
o_timeData = [];


if (exist(a_ncPathFileName, 'file') == 2)

   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end

   try

      if (dim_is_present_dec_argo(fCdf, 'N_TECH_MEASUREMENT'))

         o_timeData.N_TECH_MEASUREMENT = nan;
         o_timeData.JULD = [];
         o_timeData.CYCLE_NUMBER_MEAS = [];
         o_timeData.MEASUREMENT_CODE = [];
         o_timeData.PARAM_LIST= [];
         o_timeData.PARAM_INFO = [];

         fixedParamList = [ ...
            {'JULD'} ...
            {'CYCLE_NUMBER_MEAS'} ...
            {'MEASUREMENT_CODE'} ...
            ];

         [~, o_timeData.N_TECH_MEASUREMENT] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_TECH_MEASUREMENT'));

         nMeasVarList = var_list_using_dim(fCdf, 'N_TECH_MEASUREMENT');
         tabParamInfo = [];
         for idV = 1:length(nMeasVarList)
            idVar = netcdf.inqVarID(fCdf, nMeasVarList{idV});
            [varName, varType, varDims, nbAtts] = netcdf.inqVar(fCdf, idVar);
            paramInfo = [{'NAME'} {varName}];
            for idAtt = 0:nbAtts-1
               attName = netcdf.inqAttName(fCdf, idVar, idAtt);
               attValue = netcdf.getAtt(fCdf, idVar, attName);
               if (strcmp(attName, '_FillValue'))
                  attValue = num2str(attValue);
               end
               paramInfo = [paramInfo {attName} {attValue}];
            end
            if (ismember(varName, fixedParamList))
               o_timeData.(varName) = paramInfo;
            else
               tabParamInfo = [tabParamInfo; paramInfo];
               o_timeData.PARAM_LIST= [o_timeData.PARAM_LIST {varName}];
            end
         end
         o_timeData.PARAM_INFO = tabParamInfo;
      end

      netcdf.close(fCdf);

   catch MException
      netcdf.close(fCdf);
      rethrow(MException)
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve the name list of variables which have a given dim in their
% dimensions
%
% SYNTAX :
%  [o_varNameList] = var_list_using_dim(a_ncId, a_dimName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_dimName : name of the concerned dimension
%
% OUTPUT PARAMETERS :
%   o_varNameList : variable name list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varNameList] = var_list_using_dim(a_ncId, a_dimName)

o_varNameList = [];

if (~dim_is_present_dec_argo(a_ncId, a_dimName))
   return
end

dimId = netcdf.inqDimID(a_ncId, a_dimName);

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar = 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (~isempty(find(varDims == dimId, 1)))
      o_varNameList{end+1} = varName;
   end
end

return
