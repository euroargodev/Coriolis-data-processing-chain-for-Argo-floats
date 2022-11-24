% ------------------------------------------------------------------------------
% Convert NetCDF synthetic profile file contents in CSV format.
%
% SYNTAX :
%   nc_synthetic_prof_adj_2_csv or nc_synthetic_prof_adj_2_csv(6900189, 7900118)
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
%   08/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_synthetic_prof_adj_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_rudics_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_navis_ir_rudics_061113.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_5.64.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
init_default_values;

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

logFile = [DIR_LOG_FILE '/' 'nc_synthetic_prof_adj_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncFileDirRef = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncFileDirRef, 'dir') == 7)
      
      % convert multi-profile file
      profFileName = sprintf('%d_Sprof.nc', floatNum);
      profFilePathName = [ncFileDirRef profFileName];
      
      if (exist(profFilePathName, 'file') == 2)
         
         outputFileName = [profFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDirRef outputFileName];
         nc_synthetic_prof_adj_2_csv_file(profFilePathName, outputFilePathName, floatNum, COMPARISON_MODE);
      end
      
      % convert mono-profile files
      ncFileDir = [ncFileDirRef '/profiles/'];
      
      if (exist(ncFileDir, 'dir') == 7)
         
         ncFiles = dir([ncFileDir 'S*.nc']);
         for idFile = 1:length(ncFiles)
            
            ncFileName = ncFiles(idFile).name;
            ncFilePathName = [ncFileDir '/' ncFileName];
            
            outputFileName = [ncFileName(1:end-3) '.csv'];
            outputFilePathName = [ncFileDir outputFileName];
            nc_synthetic_prof_adj_2_csv_file(ncFilePathName, outputFilePathName, floatNum, COMPARISON_MODE);
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncFileDir);
      end
      
      % convert mono-profile aux files
      ncAuxFileDir = [ncFileDirRef '/auxiliary/profiles/'];
      
      if (exist(ncAuxFileDir, 'dir') == 7)
         
         ncFiles = dir([ncAuxFileDir 'S*_aux.nc']);
         for idFile = 1:length(ncFiles)
            
            ncFileName = ncFiles(idFile).name;
            ncFilePathName = [ncAuxFileDir '/' ncFileName];
            
            outputFileName = [ncFileName(1:end-3) '.csv'];
            outputFilePathName = [ncAuxFileDir outputFileName];
            cFileFlag = -1;
            nc_synthetic_prof_adj_2_csv_file(ncFilePathName, outputFilePathName, floatNum, COMPARISON_MODE, WRITE_QC_FLAG);
         end
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDirRef);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Convert one NetCDF profile file contents in CSV format.
%
% SYNTAX :
%  nc_synthetic_prof_adj_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_synthetic_prof_adj_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag)

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrUnused2;


% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('Converting: %s to %s\n', inputFileName, ourputFileName);

% open NetCDF file
fCdf = netcdf.open(a_inputPathFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_inputPathFileName);
   return
end

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return
end

% dimensions
nProf = -1;
nParam = -1;
nCalib = -1;
dimList = [ ...
   {'N_PROF'} ...
   {'N_PARAM'} ...
   {'N_LEVELS'} ...
   {'N_CALIB'} ...
   ];
fprintf(fidOut, ' WMO; ----------; ----------; DIMENSION\n');
for idDim = 1:length(dimList)
   if (dim_is_present_dec_argo(fCdf, dimList{idDim}))
      [dimName, dimLen] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, dimList{idDim}));
      fprintf(fidOut, ' %d; ; ; %s; %d\n', a_floatNum, dimName, dimLen);
      if (strcmp(dimName, 'N_PROF'))
         nProf = dimLen;
      end
      if (strcmp(dimName, 'N_PARAM'))
         nParam = dimLen;
      end
      if (strcmp(dimName, 'N_CALIB'))
         nCalib = dimLen;
      end
   end
end

% global attributes
globAttList = [ ...
   {'title'} ...
   {'institution'} ...
   {'source'} ...
   {'history'} ...
   {'references'} ...
   {'user_manual_version'} ...
   {'Conventions'} ...
   {'featureType'} ...
   ];
if (a_comparisonFlag == 1)
   globAttList = [ ...
      {'title'} ...
      {'institution'} ...
      {'source'} ...
      {'references'} ...
      {'user_manual_version'} ...
      {'Conventions'} ...
      {'featureType'} ...
      ];
end
fprintf(fidOut, ' WMO; ----------; ----------; GLOBAL_ATT\n');
for idAtt = 1:length(globAttList)
   if (global_att_is_present_dec_argo(fCdf, globAttList{idAtt}))
      attValue = netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), globAttList{idAtt});
      fprintf(fidOut, ' %d; ; ; %s; %s\n', a_floatNum, globAttList{idAtt}, strtrim(attValue));
   else
      fprintf('WARNING: Global attribute %s is missing in file %s\n', ...
         globAttList{idAtt}, inputFileName);
   end
end

% file meta-data
varList = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'REFERENCE_DATE_TIME'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   ];
if (a_comparisonFlag == 1)
   varList = [ ...
      {'DATA_TYPE'} ...
      {'FORMAT_VERSION'} ...
      {'HANDBOOK_VERSION'} ...
      {'REFERENCE_DATE_TIME'} ...
      ];
end
fprintf(fidOut, ' WMO; ----------; ----------; META-DATA\n');
for idVar = 1:length(varList)
   if (var_is_present_dec_argo(fCdf, varList{idVar}))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varList{idVar}));
      fprintf(fidOut, ' %d; ; ; %s; %s\n', a_floatNum, varList{idVar}, strtrim(varValue));
   else
      fprintf('WARNING: Variable %s is missing in file %s\n', ...
         varList{idVar}, inputFileName);
   end
end

% profile meta-data
varList = [ ...
   {'PLATFORM_NUMBER'} ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'DATA_CENTRE'} ...
   {'PLATFORM_TYPE'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'FIRMWARE_VERSION'} ...
   {'WMO_INST_TYPE'} ...
   ];
for idVar = 1:length(varList)
   if (var_is_present_dec_argo(fCdf, varList{idVar}))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varList{idVar}));
      fprintf(fidOut, ' %d; ; ; %s', a_floatNum, varList{idVar});
      for idP = 1:nProf
         fprintf(fidOut, '; %s', strtrim(varValue(:, idP)'));
      end
      fprintf(fidOut, '\n');
   else
      fprintf('WARNING: Variable %s is missing in file %s\n', ...
         varList{idVar}, inputFileName);
   end
end

varName = 'CYCLE_NUMBER';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   cycleNumber = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'DIRECTION';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   direction = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'PARAMETER_DATA_MODE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   parameterDataMode = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'JULD';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   julD = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'JULD_QC';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   julDQc = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'JULD_LOCATION';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   julDLocation = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'LATITUDE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   latitude = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'LONGITUDE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   longitude = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'POSITION_QC';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   positionQc = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'POSITIONING_SYSTEM';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   positioningSystem = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'STATION_PARAMETERS';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   stationParameters = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'CONFIG_MISSION_NUMBER';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   configMissionNumber = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

paramList = [];
for id = 1:size(stationParameters, 3)
   for id2 = 1:size(stationParameters, 2)
      paramName = strtrim(stationParameters(:, id2, id)');
      if (~isempty(paramName))
         if (~strcmp(paramName, 'PRES'))
            paramList = [paramList {paramName} {[paramName '_dPRES']} {[paramName '_ADJUSTED']}];
         else
            paramList = [paramList {paramName} {[paramName '_ADJUSTED']}];
         end
      end
   end
end
paramList = unique(paramList, 'stable');

paramData = [];
paramDataQc = [];
paramFormat = [];
paramFillValue = [];
profileParamQc = [];
for idParam = 1:length(paramList)
   
   paramName = paramList{idParam};
   if (var_is_present_dec_argo(fCdf, paramName))
      
      if (strncmp(paramName, 'JULD_LEVEL', length('JULD_LEVEL')))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramName), 'double');
      else
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramName));
      end
      paramData = [paramData {varValue}];
      if (strncmp(paramName, 'JULD_LEVEL', length('JULD_LEVEL')))
         varFormat = '%s';
      else
         varFormat = '%g';
      end
      paramFormat = [paramFormat {varFormat}];
      varFillValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramName), '_FillValue');
      paramFillValue = [paramFillValue {varFillValue}];
      if ((length(paramName) < 7) || ~strcmp(paramName(end-5:end), '_dPRES'))
         varQcValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, [paramList{idParam} '_QC']));
         paramDataQc = [paramDataQc {varQcValue}];
      else
         paramDataQc = [paramDataQc {repmat(' ', size(varValue))}];
      end
   else
      fprintf('WARNING: Variable %s is missing in file %s\n', ...
         paramName, inputFileName);
      paramData = [paramData ''];
      paramFormat = [paramFormat ''];
      paramFillValue = [paramFillValue ''];
      paramDataQc = [paramDataQc ''];
   end
   profileParamVarName = ['PROFILE_' paramName '_QC'];
   if (var_is_present_dec_argo(fCdf, profileParamVarName))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, profileParamVarName));
      profileParamQc = [profileParamQc {varValue}];
   else
      profileParamQc = [profileParamQc {''}];
   end
end

% profile data
for idP = 1:nProf
   fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_META-DATA\n');
   
   fprintf(fidOut, ' %d; %d; %d; CONFIG_MISSION_NUMBER; %d\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      configMissionNumber(idP));
   fprintf(fidOut, ' %d; %d; %d; CYCLE_NUMBER; %d\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      cycleNumber(idP));
   fprintf(fidOut, ' %d; %d; %d; DIRECTION; %c\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      direction(idP));
   fprintf(fidOut, ' %d; %d; %d; PARAMETER_DATA_MODE; %s\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      parameterDataMode(:, idP)');
   fprintf(fidOut, ' %d; %d; %d; JULD; %s\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      julian_2_gregorian_dec_argo(julD(idP)));
   fprintf(fidOut, ' %d; %d; %d; JULD_QC; %c\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      julDQc(idP));
   fprintf(fidOut, ' %d; %d; %d; JULD_LOCATION; %s\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      julian_2_gregorian_dec_argo(julDLocation(idP)));
   fprintf(fidOut, ' %d; %d; %d; LATITUDE; %.3f\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      latitude(idP));
   fprintf(fidOut, ' %d; %d; %d; LONGITUDE; %.3f\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      longitude(idP));
   fprintf(fidOut, ' %d; %d; %d; POSITION_QC; %c\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      positionQc(idP));
   fprintf(fidOut, ' %d; %d; %d; POSITIONING_SYSTEM; %s\n', ...
      a_floatNum, cycleNumber(idP), idP, ...
      strtrim(positioningSystem(:, idP)'));
   
   fprintf(fidOut, ' %d; %d; %d; STATION_PARAMETERS', ...
      a_floatNum, cycleNumber(idP), idP);
   for idParam = 1:nParam
      parameterName = strtrim(stationParameters(:, idParam, idP)');
      if (isempty(parameterName))
         continue
      end
      
      % PARAM
      paramName = parameterName;
      idF = find(strcmp(paramList, paramName) == 1, 1);
      if (~isempty(idF))
         fprintf(fidOut, '; %s; QC', ...
            paramName);
      else
         fprintf('ERROR: Variable %s is missing in file %s\n', ...
            paramName, inputFileName);
      end
      
      % PARAM_dPRES
      if (~strcmp(parameterName, 'PRES'))
         paramName = [parameterName '_dPRES'];
         idF = find(strcmp(paramList, paramName) == 1, 1);
         if (~isempty(idF))
            fprintf(fidOut, '; %s', ...
               paramName);
         else
            fprintf('ERROR: Variable %s is missing in file %s\n', ...
               paramName, inputFileName);
         end
      end
      
      % PARAM_ADJUSTED
      paramName = [parameterName '_ADJUSTED'];
      idF = find(strcmp(paramList, paramName) == 1, 1);
      if (~isempty(idF))
         fprintf(fidOut, '; %s; QC', ...
            paramName);
      else
         fprintf('ERROR: Variable %s is missing in file %s\n', ...
            paramName, inputFileName);
      end
   end
   fprintf(fidOut, '\n');
   
   fprintf(fidOut, ' %d; %d; %d; PROFILE_<PARAM>_QC; ;', ...
      a_floatNum, cycleNumber(idP), idP);
   for idParam = 1:nParam
      parameterName = strtrim(stationParameters(:, idParam, idP)');
      if (isempty(parameterName))
         continue
      end
      
      % PARAM
      paramName = parameterName;
      idF = find(strcmp(paramList, paramName) == 1, 1);
      if (~isempty(idF))
         profileParamQcTmp = profileParamQc{idF};
         if (~strcmp(parameterName, 'PRES'))
            if (~isempty(profileParamQcTmp))
               fprintf(fidOut, '%c; ; ; ; ; ', ...
                  profileParamQcTmp(idP));
            else
               fprintf(fidOut, '; ; ; ; ; ');
            end
         else
            if (~isempty(profileParamQcTmp))
               fprintf(fidOut, '%c; ; ; ; ', ...
                  profileParamQcTmp(idP));
            else
               fprintf(fidOut, '; ; ; ; ');
            end
         end
      else
         fprintf('ERROR: Variable %s is missing in file %s\n', ...
            paramName, inputFileName);
      end
   end
   fprintf(fidOut, '\n');
   
   data = [];
   dataFillValue = [];
   format = '';
   for idParam = 1:nParam
      parameterName = strtrim(stationParameters(:, idParam, idP)');
      if (isempty(parameterName))
         continue
      end
      
      % PARAM
      paramName = parameterName;
      idF = find(strcmp(paramList, paramName) == 1, 1);
      if (~isempty(idF))
         dataTmp = paramData{idF};
         data = [data double(dataTmp(:, idP))];
         dataFillValue = [dataFillValue paramFillValue{idF}];
         format = [format '; ' paramFormat{idF}];
         dataQcTmp = paramDataQc{idF};
         if (~isempty(dataQcTmp))
            dataQcTmp = dataQcTmp(:, idP);
            dataQcTmp(find(dataQcTmp == g_decArgo_qcStrDef)) = g_decArgo_qcStrUnused2;
            dataQcTmp = str2num(dataQcTmp);
            dataQcTmp(find(dataQcTmp == str2num(g_decArgo_qcStrUnused2))) = -1;
            data = [data double(dataQcTmp)];
            dataFillValue = [dataFillValue -1];
            format = [format '; ' '%d'];
         end
      else
         fprintf('ERROR: Variable %s is missing in file %s\n', ...
            paramName, inputFileName);
      end
      
      % PARAM_dPRES
      if (~strcmp(parameterName, 'PRES'))
         paramInfo = get_netcdf_param_attributes(parameterName);
         paramName = [parameterName '_dPRES'];
         idF = find(strcmp(paramList, paramName) == 1, 1);
         if (~isempty(idF))
            dataTmp = paramData{idF};
            data = [data double(dataTmp(:, idP))];
            dataFillValue = [dataFillValue paramFillValue{idF}];
            format = [format '; ' paramFormat{idF}];
         else
            fprintf('ERROR: Variable %s is missing in file %s\n', ...
               paramName, inputFileName);
         end
      end
      
      % PARAM_ADJUSTED
      paramInfo = get_netcdf_param_attributes(parameterName);
      if (paramInfo.adjAllowed == 1)
         paramName = [parameterName '_ADJUSTED'];
         idF = find(strcmp(paramList, paramName) == 1, 1);
         if (~isempty(idF))
            dataTmp = paramData{idF};
            data = [data double(dataTmp(:, idP))];
            dataFillValue = [dataFillValue paramFillValue{idF}];
            format = [format '; ' paramFormat{idF}];
            dataQcTmp = paramDataQc{idF};
            if (~isempty(dataQcTmp))
               dataQcTmp = dataQcTmp(:, idP);
               dataQcTmp(find(dataQcTmp == g_decArgo_qcStrDef)) = g_decArgo_qcStrUnused2;
               dataQcTmp = str2num(dataQcTmp);
               dataQcTmp(find(dataQcTmp == str2num(g_decArgo_qcStrUnused2))) = -1;
               data = [data double(dataQcTmp)];
               dataFillValue = [dataFillValue -1];
               format = [format '; ' '%d'];
            end
         else
            fprintf('ERROR: Variable %s is missing in file %s\n', ...
               paramName, inputFileName);
         end
      end
   end
   
   fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_MEAS\n');
   for idLev = 1:size(data, 1);
      if (sum(data(idLev, :) == dataFillValue) ~= size(data, 2))
         fprintf(fidOut, ' %d; %d; %d; MEAS #%d', ...
            a_floatNum, cycleNumber(idP), idP, idLev);
         if (strcmp(paramList{1}, 'JULD_LEVEL'))
            fprintf(fidOut, format, ...
               julian_2_gregorian_dec_argo(data(idLev, 1)), data(idLev, 2), ...
               julian_2_gregorian_dec_argo(data(idLev, 3)), data(idLev, 4), ...
               data(idLev, 5:end));
         else
            fprintf(fidOut, format, ...
               data(idLev, :));
         end
         fprintf(fidOut, '\n');
      end
   end
   
end

varName = 'PARAMETER';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   parameter = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_EQUATION';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibEquation = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_COEFFICIENT';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibCoefficient = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_COMMENT';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibComment = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'SCIENTIFIC_CALIB_DATE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   scientificCalibDate = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

% calibration information
fprintf(fidOut, ' WMO; N_PROF; N_CALIB; CALIB_DATA\n');
for idP = 1:nProf
   for idC = 1:nCalib
      fprintf(fidOut, ' %d; %d; %d; PARAMETER', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(parameter(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_EQUATION', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibEquation(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_COEFFICIENT', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibCoefficient(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_COMMENT', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibComment(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; SCIENTIFIC_CALIB_DATE', ...
         a_floatNum, idP, idC);
      for idParam = 1:nParam
         fprintf(fidOut, '; %s', ...
            strtrim(scientificCalibDate(:, idParam, idC, idP)'));
      end
      fprintf(fidOut, '\n');
   end
end

fclose(fidOut);

netcdf.close(fCdf);

return
