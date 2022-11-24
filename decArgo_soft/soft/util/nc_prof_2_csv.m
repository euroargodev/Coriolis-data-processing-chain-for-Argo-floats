% ------------------------------------------------------------------------------
% Convert NetCDF profile file contents in CSV format.
%
% SYNTAX :
%   nc_prof_2_csv or nc_prof_2_csv(6900189, 7900118)
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
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_prof_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_rnuokRem&PrvIr\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_cm.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.45.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default values initialization
init_default_values;

% to compare different set of files do not print current dates
COMPARISON_MODE = 0;

% to print the parameter Qc values
WRITE_QC_FLAG = 1;


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

logFile = [DIR_LOG_FILE '/' 'nc_prof_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
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
      
      % convert multi-profile c file
      profFileName = sprintf('%d_prof.nc', floatNum);
      profFilePathName = [ncFileDirRef profFileName];
      
      if (exist(profFilePathName, 'file') == 2)
         
         outputFileName = [profFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDirRef outputFileName];
         cFileFlag = 1;
         nc_prof_2_csv_file(profFilePathName, outputFilePathName, floatNum, COMPARISON_MODE, WRITE_QC_FLAG, cFileFlag);
      end
      
      % convert multi-profile b file
      profFileName = sprintf('%d_Bprof.nc', floatNum);
      profFilePathName = [ncFileDirRef profFileName];
      
      if (exist(profFilePathName, 'file') == 2)
         
         outputFileName = [profFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDirRef outputFileName];
         cFileFlag = 0;
         nc_prof_2_csv_file(profFilePathName, outputFilePathName, floatNum, COMPARISON_MODE, WRITE_QC_FLAG, cFileFlag);
      end
      
      % convert multi-profile m file
      profFileName = sprintf('%d_Mprof.nc', floatNum);
      profFilePathName = [ncFileDirRef profFileName];
      
      if (exist(profFilePathName, 'file') == 2)
         
         outputFileName = [profFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDirRef outputFileName];
         cFileFlag = 0;
         nc_prof_2_csv_file(profFilePathName, outputFilePathName, floatNum, COMPARISON_MODE, WRITE_QC_FLAG, cFileFlag);
      end
      
      % convert mono-profile files
      ncFileDir = [ncFileDirRef '/profiles/'];
      
      if (exist(ncFileDir, 'dir') == 7)
         
         ncFiles = dir([ncFileDir '*.nc']);
         for idFile = 1:length(ncFiles)
            
            ncFileName = ncFiles(idFile).name;
            if (ncFileName(1) == 'S')
               continue
            end
            ncFilePathName = [ncFileDir '/' ncFileName];
            
            outputFileName = [ncFileName(1:end-3) '.csv'];
            outputFilePathName = [ncFileDir outputFileName];
            cFileFlag = 1;
            if (ncFileName(1) == 'B')
               cFileFlag = 0;
            end
            nc_prof_2_csv_file(ncFilePathName, outputFilePathName, floatNum, COMPARISON_MODE, WRITE_QC_FLAG, cFileFlag);
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncFileDir);
      end
      
      % convert mono-profile aux files
      ncAuxFileDir = [ncFileDirRef '/auxiliary/profiles/'];
      
      if (exist(ncAuxFileDir, 'dir') == 7)
         
         ncFiles = dir([ncAuxFileDir '*_aux.nc']);
         for idFile = 1:length(ncFiles)
            
            ncFileName = ncFiles(idFile).name;
            if (ncFileName(1) == 'S')
               continue
            end
            ncFilePathName = [ncAuxFileDir '/' ncFileName];
            
            outputFileName = [ncFileName(1:end-3) '.csv'];
            outputFilePathName = [ncAuxFileDir outputFileName];
            cFileFlag = -1;
            nc_prof_2_csv_file(ncFilePathName, outputFilePathName, floatNum, COMPARISON_MODE, WRITE_QC_FLAG, cFileFlag);
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
%  nc_prof_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
%    a_floatNum, a_comparisonFlag, a_writeQcFlag, a_cfileFlag)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%   a_floatNum           : float WMO number
%   a_comparisonFlag     : if 1, do not print current dates
%   a_writeQcFlag        : if 1, print parameter QC values
%   a_cfileFlag          : 0 if B file, 1 if C file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_prof_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag, a_writeQcFlag, a_cfileFlag)

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
nHistory = -1;
nCalib = -1;
dimList = [ ...
   {'N_PROF'} ...
   {'N_PARAM'} ...
   {'N_LEVELS'} ...
   {'N_HISTORY'} ...
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
      if (strcmp(dimName, 'N_HISTORY'))
         nHistory = dimLen;
      end
      if (strcmp(dimName, 'N_CALIB'))
         nCalib = dimLen;
      end
   end
end
[dimName, dimLength] = dim_is_present2_dec_argo(fCdf, 'N_VALUES');
for idDim = 1:length(dimName)
   fprintf(fidOut, ' %d; ; ; %s; %d\n', a_floatNum, dimName{idDim}, dimLength(idDim));
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
      if (a_cfileFlag ~= -1)
         fprintf('WARNING: Variable %s is missing in file %s\n', ...
            varList{idVar}, inputFileName);
      end
   end
end

% profile meta-data
varList = [ ...
   {'PLATFORM_NUMBER'} ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'DATA_CENTRE'} ...
   {'DC_REFERENCE'} ...
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

varName = 'DATA_MODE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   dataMode = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'DATA_STATE_INDICATOR';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   dataStateIndicator = varValue;
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

varName = 'VERTICAL_SAMPLING_SCHEME';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   verticalSamplingScheme = varValue;
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

paramList2 = [ ...
   {'TEMP_STD'} ...
   {'TEMP_MED'} ...
   {'PSAL_STD'} ...
   {'PSAL_MED'} ...
   ];
sufixList = [{''} {'_STD'} {'_MED'}];
paramList = [];
if (a_cfileFlag <= 0)
   for idP = 1:length(paramList2)
      if (var_is_present_dec_argo(fCdf, paramList2{idP}))
         paramList = [paramList {paramList2{idP}}];
      end
   end
end
for id3 = 1:size(stationParameters, 3)
   for id2 = 1:size(stationParameters, 2)
      paramName = strtrim(stationParameters(:, id2, id3)');
      if (~isempty(paramName))
         paramList = [paramList {paramName}];
         paramNameStd = [paramName '_STD'];
         if (var_is_present_dec_argo(fCdf, paramNameStd))
            paramList = [paramList {paramNameStd}];
         end
         paramNameMed = [paramName '_MED'];
         if (var_is_present_dec_argo(fCdf, paramNameMed))
            paramList = [paramList {paramNameMed}];
         end
      end
   end
end
paramList = unique(paramList);

if (a_writeQcFlag == 0)
   
   paramData = [];
   paramFormat = [];
   paramFillValue = [];
   profileParamQc = [];
   for idParam = 1:length(paramList)
      if (var_is_present_dec_argo(fCdf, paramList{idParam}))
         
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'double');
         else
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}));
         end
         paramData = [paramData {varValue}];
         varFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'C_format');
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varFormat = '%u';
         else
            varFormat = '%g';
         end
         paramFormat = [paramFormat {varFormat}];
         varFillValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), '_FillValue');
         paramFillValue = [paramFillValue {varFillValue}];
      else
         fprintf('WARNING: Variable %s is missing in file %s\n', ...
            paramList{idParam}, inputFileName);
         paramData = [paramData ''];
         paramFormat = [paramFormat ''];
         paramFillValue = [paramFillValue ''];
      end
      profileParamVarName = ['PROFILE_' paramList{idParam} '_QC'];
      if (var_is_present_dec_argo(fCdf, profileParamVarName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, profileParamVarName));
         profileParamQc = [profileParamQc {varValue}];
      else
         if ~((a_cfileFlag == 0) && ...
               (strcmp(paramList{idParam}, 'PRES') || ...
               strcmp(paramList{idParam}, 'PRES2') || ...
               strcmp(paramList{idParam}(end-3:end), '_STD') || ...
               strcmp(paramList{idParam}(end-3:end), '_MED')))
            fprintf('WARNING: Variable %s is missing in file %s\n', ...
               profileParamVarName, inputFileName);
         end
         profileParamQc = [profileParamQc {''}];
      end
   end
   
   % profile data
   for idP = 1:nProf
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_META-DATA\n');
      
      fprintf(fidOut, ' %d; %d; %d; VERTICAL_SAMPLING_SCHEME;"%s"\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(verticalSamplingScheme(:, idP)'));
      fprintf(fidOut, ' %d; %d; %d; CONFIG_MISSION_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         configMissionNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; CYCLE_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         cycleNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; DIRECTION; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         direction(idP));
      fprintf(fidOut, ' %d; %d; %d; DATA_MODE; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         dataMode(idP));
      fprintf(fidOut, ' %d; %d; %d; DATA_STATE_INDICATOR; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(dataStateIndicator(:, idP)'));
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
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  fprintf(fidOut, '; %s', ...
                     paramName);
               else
                  for id1 = 1:size(dataTmp, 1);
                     fprintf(fidOut, '; %s', ...
                        sprintf('%s_%d', paramName, id1));
                  end
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES') || strcmp(parameterName, 'PRES2'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        fprintf(fidOut, '; %s', ...
                           paramName);
                     else
                        for id1 = 1:size(dataTmp, 1);
                           fprintf(fidOut, '; %s', ...
                              sprintf('%s_%d', paramName, id1));
                        end
                     end
                  end
               end
            end
         end
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; PROFILE_<PARAM>_QC; ', ...
         a_floatNum, cycleNumber(idP), idP);
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               profileParamQcTmp = profileParamQc{idF};
               if (~isempty(profileParamQcTmp))
                  fprintf(fidOut, '%c; ', ...
                     profileParamQcTmp(idP));
                  dataTmp = paramData{idF};
                  if (ndims(dataTmp) == 3)
                     for id1 = 2:size(dataTmp, 1);
                        fprintf(fidOut, '; ');
                     end
                  end
               else
                  fprintf(fidOut, '; ');
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES') || strcmp(parameterName, 'PRES2'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     profileParamQcTmp = profileParamQc{idF};
                     if (~isempty(profileParamQcTmp))
                        fprintf(fidOut, '%c; ', ...
                           profileParamQcTmp(idP));
                        dataTmp = paramData{idF};
                        if (ndims(dataTmp) == 3)
                           for id1 = 2:size(dataTmp, 1);
                              fprintf(fidOut, '; ');
                           end
                        end
                     else
                        fprintf(fidOut, '; ');
                     end
                  end
               end
            end
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
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  data = [data double(dataTmp(:, idP))];
                  dataFillValue = [dataFillValue paramFillValue{idF}];
                  format = [format '; ' paramFormat{idF}];
               else
                  for id1 = 1:size(dataTmp, 1);
                     data = [data double(dataTmp(id1, :, idP)')];
                     dataFillValue = [dataFillValue paramFillValue{idF}];
                     format = [format '; ' paramFormat{idF}];
                  end
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES') || strcmp(parameterName, 'PRES2'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        data = [data double(dataTmp(:, idP))];
                        dataFillValue = [dataFillValue paramFillValue{idF}];
                        format = [format '; ' paramFormat{idF}];
                     else
                        for id1 = 1:size(dataTmp, 1);
                           data = [data double(dataTmp(id1, :, idP)')];
                           dataFillValue = [dataFillValue paramFillValue{idF}];
                           format = [format '; ' paramFormat{idF}];
                        end
                     end
                  end
               end
            end
         end
      end
      
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_MEAS\n');
      for idLev = 1:size(data, 1)
         if (sum(data(idLev, :) == dataFillValue) ~= size(data, 2))
            fprintf(fidOut, ' %d; %d; %d; MEAS #%d', ...
               a_floatNum, cycleNumber(idP), idP, idLev);
            fprintf(fidOut, format, ...
               data(idLev, :));
            fprintf(fidOut, '\n');
         end
      end
      
   end
else
   
   paramData = [];
   paramDataQc = [];
   paramFormat = [];
   paramFillValue = [];
   profileParamQc = [];
   for idParam = 1:length(paramList)
      if (var_is_present_dec_argo(fCdf, paramList{idParam}))
         
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'double');
         else
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}));
         end
         paramData = [paramData {varValue}];
         varFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), 'C_format');
         if ((strncmp(paramList{idParam}, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
               (strncmp(paramList{idParam}, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
            varFormat = '%u';
         else
            varFormat = '%g';
         end
         paramFormat = [paramFormat {varFormat}];
         varFillValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramList{idParam}), '_FillValue');
         paramFillValue = [paramFillValue {varFillValue}];
         
         if ((a_cfileFlag == 0) && ...
               (strcmp(paramList{idParam}, 'PRES') || ...
               strcmp(paramList{idParam}, 'PRES2') || ...
               strcmp(paramList{idParam}(end-3:end), '_STD') || ...
               strcmp(paramList{idParam}(end-3:end), '_MED')))
            paramDataQc = [paramDataQc {''}];
         else
            if (var_is_present_dec_argo(fCdf, [paramList{idParam} '_QC']))
               varQcValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, [paramList{idParam} '_QC']));
               paramDataQc = [paramDataQc {varQcValue}];
            else
               paramDataQc = [paramDataQc {''}];
            end
         end
      else
         fprintf('WARNING: Variable %s is missing in file %s\n', ...
            paramList{idParam}, inputFileName);
         paramData = [paramData ''];
         paramFormat = [paramFormat ''];
         paramFillValue = [paramFillValue ''];
         paramDataQc = [paramDataQc ''];
      end
      profileParamVarName = ['PROFILE_' paramList{idParam} '_QC'];
      if (var_is_present_dec_argo(fCdf, profileParamVarName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, profileParamVarName));
         profileParamQc = [profileParamQc {varValue}];
      else
         if ~((a_cfileFlag == 0) && ...
               (strcmp(paramList{idParam}, 'PRES') || ...
               strcmp(paramList{idParam}, 'PRES2') || ...
               strcmp(paramList{idParam}(end-3:end), '_STD') || ...
               strcmp(paramList{idParam}(end-3:end), '_MED')))
            fprintf('WARNING: Variable %s is missing in file %s\n', ...
               profileParamVarName, inputFileName);
         end
         profileParamQc = [profileParamQc {''}];
      end
   end
   
   % profile data
   for idP = 1:nProf
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_META-DATA\n');
      
      fprintf(fidOut, ' %d; %d; %d; VERTICAL_SAMPLING_SCHEME;"%s"\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(verticalSamplingScheme(:, idP)'));
      fprintf(fidOut, ' %d; %d; %d; CONFIG_MISSION_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         configMissionNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; CYCLE_NUMBER; %d\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         cycleNumber(idP));
      fprintf(fidOut, ' %d; %d; %d; DIRECTION; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         direction(idP));
      fprintf(fidOut, ' %d; %d; %d; DATA_MODE; %c\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         dataMode(idP));
      fprintf(fidOut, ' %d; %d; %d; DATA_STATE_INDICATOR; %s\n', ...
         a_floatNum, cycleNumber(idP), idP, ...
         strtrim(dataStateIndicator(:, idP)'));
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
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  fprintf(fidOut, '; %s', ...
                     paramName);
               else
                  for id1 = 1:size(dataTmp, 1);
                     fprintf(fidOut, '; %s', ...
                        sprintf('%s_%d', paramName, id1));
                  end
               end
               if ~((a_cfileFlag == 0) && ...
                     (strcmp(paramName, 'PRES') || ...
                     strcmp(paramName, 'PRES2') || ...
                     strcmp(paramName(end-3:end), '_STD') || ...
                     strcmp(paramName(end-3:end), '_MED')))
                  fprintf(fidOut, '; QC');
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES') || strcmp(parameterName, 'PRES2'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        fprintf(fidOut, '; %s', ...
                           paramName);
                     else
                        for id1 = 1:size(dataTmp, 1);
                           fprintf(fidOut, '; %s', ...
                              sprintf('%s_%d', paramName, id1));
                        end
                     end
                     if ~((a_cfileFlag == 0) && ...
                           (strcmp(paramName, 'PRES') || ...
                           strcmp(paramName, 'PRES2') || ...
                           strcmp(paramName(end-3:end), '_STD') || ...
                           strcmp(paramName(end-3:end), '_MED')))
                        fprintf(fidOut, '; QC');
                     end
                  end
               end
            end
         end
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, ' %d; %d; %d; PROFILE_<PARAM>_QC; ', ...
         a_floatNum, cycleNumber(idP), idP);
      for idParam = 1:nParam
         parameterName = strtrim(stationParameters(:, idParam, idP)');
         if (isempty(parameterName))
            continue
         end
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               profileParamQcTmp = profileParamQc{idF};
               if (~isempty(profileParamQcTmp))
                  fprintf(fidOut, '%c; ', ...
                     profileParamQcTmp(idP));
                  dataTmp = paramData{idF};
                  if (ndims(dataTmp) == 3)
                     for id1 = 2:size(dataTmp, 1);
                        fprintf(fidOut, '; ');
                     end
                  end
                  fprintf(fidOut, '; ');
               else
                  fprintf(fidOut, '; ');
               end
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES') || strcmp(parameterName, 'PRES2'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     profileParamQcTmp = profileParamQc{idF};
                     if (~isempty(profileParamQcTmp))
                        fprintf(fidOut, '%c; ', ...
                           profileParamQcTmp(idP));
                        dataTmp = paramData{idF};
                        if (ndims(dataTmp) == 3)
                           for id1 = 2:size(dataTmp, 1);
                              fprintf(fidOut, '; ');
                           end
                        end
                        fprintf(fidOut, '; ');
                     else
                        fprintf(fidOut, '; ');
                     end
                  end
               end
            end
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
         
         for idS = 1:length(sufixList)
            paramName = [parameterName sufixList{idS}];
            
            idF = find(strcmp(paramList, paramName) == 1, 1);
            if (~isempty(idF))
               dataTmp = paramData{idF};
               if (ndims(dataTmp) == 2)
                  data = [data double(dataTmp(:, idP))];
                  dataFillValue = [dataFillValue paramFillValue{idF}];
                  format = [format '; ' paramFormat{idF}];
               else
                  for id1 = 1:size(dataTmp, 1);
                     data = [data double(dataTmp(id1, :, idP)')];
                     dataFillValue = [dataFillValue paramFillValue{idF}];
                     format = [format '; ' paramFormat{idF}];
                  end
               end
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
            elseif (idS == 1)
               fprintf('ERROR: Variable %s is missing in file %s\n', ...
                  paramName, inputFileName);
            end
         end
         
         if (a_cfileFlag == 0)
            if (strcmp(parameterName, 'PRES') || strcmp(parameterName, 'PRES2'))
               for idP2 = 1:length(paramList2)
                  paramName = paramList2{idP2};
                  
                  idF = find(strcmp(paramList, paramName) == 1, 1);
                  if (~isempty(idF))
                     dataTmp = paramData{idF};
                     if (ndims(dataTmp) == 2)
                        data = [data double(dataTmp(:, idP))];
                        dataFillValue = [dataFillValue paramFillValue{idF}];
                        format = [format '; ' paramFormat{idF}];
                     else
                        for id1 = 1:size(dataTmp, 1);
                           data = [data double(dataTmp(id1, :, idP)')];
                           dataFillValue = [dataFillValue paramFillValue{idF}];
                           format = [format '; ' paramFormat{idF}];
                        end
                     end
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
                  end
               end
            end
         end
      end
      
      fprintf(fidOut, ' WMO; Cy#; N_PROF; PROFILE_MEAS\n');
      for idLev = 1:size(data, 1);
         if (sum(data(idLev, :) == dataFillValue) ~= size(data, 2))
            fprintf(fidOut, ' %d; %d; %d; MEAS #%d', ...
               a_floatNum, cycleNumber(idP), idP, idLev);
            fprintf(fidOut, format, ...
               data(idLev, :));
            fprintf(fidOut, '\n');
         end
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

varName = 'HISTORY_INSTITUTION';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyInstitution = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_STEP';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyStep = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_SOFTWARE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historySoftware = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_SOFTWARE_RELEASE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historySoftwareRelease = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_REFERENCE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyReference = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_DATE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyDate = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_ACTION';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyAction = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_PARAMETER';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyParameter = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_START_PRES';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyStartPres = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_STOP_PRES';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyStopPres = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_PREVIOUS_VALUE';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyPreviousValue = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

varName = 'HISTORY_QCTEST';
if (var_is_present_dec_argo(fCdf, varName))
   varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   historyQcTest = varValue;
else
   fprintf('WARNING: Variable %s is missing in file %s\n', ...
      varName, inputFileName);
end

% history information
fprintf(fidOut, ' WMO; N_HISTORY; N_PROF; HISTORY_DATA\n');
for idH = 1:nHistory
   for idP = 1:nProf
      fprintf(fidOut, ' %d; %d; %d; HISTORY_INSTITUTION; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyInstitution(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_STEP; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyStep(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_SOFTWARE; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historySoftware(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_SOFTWARE_RELEASE; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historySoftwareRelease(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_REFERENCE; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyReference(:, idP, idH)'));
      if (a_comparisonFlag == 0)
         fprintf(fidOut, ' %d; %d; %d; HISTORY_DATE; %s\n', ...
            a_floatNum, idH, idP, ...
            strtrim(historyDate(:, idP, idH)'));
      end
      fprintf(fidOut, ' %d; %d; %d; HISTORY_ACTION; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyAction(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_PARAMETER; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyParameter(:, idP, idH)'));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_START_PRES; %g\n', ...
         a_floatNum, idH, idP, ...
         historyStartPres(idP, idH));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_STOP_PRES; %g\n', ...
         a_floatNum, idH, idP, ...
         historyStopPres(idP, idH));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_PREVIOUS_VALUE; %g\n', ...
         a_floatNum, idH, idP, ...
         historyPreviousValue(idP, idH));
      fprintf(fidOut, ' %d; %d; %d; HISTORY_QCTEST; %s\n', ...
         a_floatNum, idH, idP, ...
         strtrim(historyQcTest(:, idP, idH)'));
   end
end

fclose(fidOut);

netcdf.close(fCdf);

return
