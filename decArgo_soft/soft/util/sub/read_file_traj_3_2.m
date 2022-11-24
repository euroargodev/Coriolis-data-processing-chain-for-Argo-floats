% ------------------------------------------------------------------------------
% Read a NetCDF trajectory file contents.
%
% SYNTAX :
%  [o_nMeasData, o_nCycleData, o_calibrationData, o_historyData] = ...
%    read_file_traj_3_2(a_inputPathFileName)
%
% INPUT PARAMETERS :
%   a_inputPathFileName : trajectory file path name
%
% OUTPUT PARAMETERS :
%   o_nMeasData       : N_MEASUREMENT data
%   o_nCycleData      : N_CYCLE data
%   o_calibrationData : CALIBRATION data
%   o_historyData     : HISTORY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nMeasData, o_nCycleData, o_calibrationData, o_historyData] = ...
   read_file_traj_3_2(a_inputPathFileName)

% output parameters initialization
o_nMeasData = [];
o_nCycleData = [];
o_calibrationData = [];
o_historyData = [];

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_qcDef;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrUnused2;

% sort the parameters according to a given list
SORT_PARAM = 1;


% check the NetCDF file
if ~(exist(a_inputPathFileName, 'file') == 2)
   fprintf('File not found : %s\n', a_inputPathFileName);
   return
end

% open NetCDF file
fCdf = netcdf.open(a_inputPathFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_inputPathFileName);
   return
end

formatVersion = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'))';

if (str2double(formatVersion) ~= 3.2)
   
   fprintf('File format version is %s (3.2 expected) => exit\n', ...
      formatVersion, a_inputPathFileName);
   
   netcdf.close(fCdf);
   return
end

% dimensions
nParam = [];
if (dim_is_present_dec_argo(fCdf, 'N_PARAM'))
   [~, nParam] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_PARAM'));
end

% misc
platformNumber = strtrim(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_NUMBER'))');

% parameter variables
trajectoryParameters = [];
if (var_is_present_dec_argo(fCdf, 'TRAJECTORY_PARAMETERS'))
   trajectoryParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRAJECTORY_PARAMETERS'));
end

% N_MEASUREMENT variables
cycleNumber = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'))';
cycleNumberAdj = '';
if (var_is_present_dec_argo(fCdf, 'CYCLE_NUMBER_ADJUSTED'))
   cycleNumberAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_ADJUSTED'))';
end

measCode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'MEASUREMENT_CODE'))';

juld = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'));
juldFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD'), '_FillValue');
juld(find(juld == juldFillVal)) = g_decArgo_dateDef;
juldStatus = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_STATUS'));
juldQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'));

juldAdj = '';
juldAdjStatus = '';
juldAdjQc = '';
if (var_is_present_dec_argo(fCdf, 'JULD_ADJUSTED'))
   juldAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ADJUSTED'));
   juldAdjFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD_ADJUSTED'), '_FillValue');
   juldAdj(find(juldAdj == juldAdjFillVal)) = g_decArgo_dateDef;
   juldAdjStatus = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ADJUSTED_STATUS'));
   juldAdjQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ADJUSTED_QC'));
end

latitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'));
latitudeFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), '_FillValue');
latitude(find(latitude == latitudeFillVal)) = g_decArgo_argosLatDef;

longitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'));
longitudeFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), '_FillValue');
longitude(find(longitude == longitudeFillVal)) = g_decArgo_argosLonDef;

positionAccuracy = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_ACCURACY'));
positionQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'));
positioAxErrEllMajor = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'AXES_ERROR_ELLIPSE_MAJOR'));
positioAxErrEllMinor = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'AXES_ERROR_ELLIPSE_MINOR'));
positioAxErrEllAngle = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'AXES_ERROR_ELLIPSE_ANGLE'));
positionSat = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SATELLITE_NAME'));

juldDataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DATA_MODE'));
paramDataModeOri = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRAJECTORY_PARAMETER_DATA_MODE'));

paramNameList = [];
paramNum = [];
paramDataFormatList = [];
paramDataNbDimList = [];
paramData = [];
paramDataMode = [];
paramDataModeNum = [];
paramQcNameList = [];
paramQcNum = [];
paramQcData = [];
paramAdjNameList = [];
paramAdjNum = [];
paramAdjDataFormatList = [];
paramAdjDataNbDimList = [];
paramAdjData = [];
paramAdjQcNameList = [];
paramAdjQcNum = [];
paramAdjQcData = [];
paramAdjErrorNameList = [];
paramAdjErrorDataFormatList = [];
paramAdjErrorDataNbDimList = [];
paramAdjErrorData = [];

sufixList = [{''} {'_STD'} {'_MED'}];

paramNumCpt = 1;
paramAdjNumCpt = 1;
for idParam = 1:nParam
   parameterName = strtrim(trajectoryParameters(:, idParam)');
   if (isempty(parameterName))
      continue
   end
   
   for idS = 1:length(sufixList)
      paramName = [parameterName sufixList{idS}];
      
      paramQcName = sprintf('%s_QC', paramName);
      
      if ((idS == 1) || ((idS > 1) && (var_is_present_dec_argo(fCdf, paramName))))
         if (any(strcmp(paramName, paramNameList)))
            continue
         end
         % there is no PARAMETER_DATA_MODE for statistical parameters, we thus
         % should add a column of ' '
         if (idS == 1)
            paramDataMode = [paramDataMode; paramDataModeOri(idParam, :)];
         else
            paramDataMode = [paramDataMode; repmat(' ', 1, size(paramDataModeOri, 2))];
         end
         paramNameList = [paramNameList {paramName}];
         if (idS == 1)
            paramNum = [paramNum {num2str(paramNumCpt)}];
            paramQcNum = [paramQcNum {num2str(paramNumCpt)}];
            paramDataModeNum = [paramDataModeNum {num2str(paramNumCpt)}];
            paramNumCpt = paramNumCpt + 1;
         else
            paramNum = [paramNum {''}];
            paramQcNum = [paramQcNum {''}];
            paramDataModeNum = [paramDataModeNum {''}];
         end
         paramFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramName), 'C_format');
         paramDataFormatList = [paramDataFormatList {paramFormat}];
         paramQcNameList = [paramQcNameList {paramQcName}];         
         data = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramName));
         if (var_is_present_dec_argo(fCdf, paramQcName))
            dataQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramQcName));
            dataQc(find(dataQc == g_decArgo_qcStrDef)) = g_decArgo_qcStrUnused2;
            dataQc = str2num(dataQc);
            dataQc(find(dataQc == str2num(g_decArgo_qcStrUnused2))) = -1;
         else
            dataQc = ones(size(data, 1), 1)*g_decArgo_qcDef;
         end
         if (size(data, 2) == 1)
            paramDataNbDimList = [paramDataNbDimList 1];
            paramData = [paramData double(data)];
            paramQcData = [paramQcData dataQc];
         else
            paramDataNbDimList = [paramDataNbDimList size(data, 1)];
            paramData = [paramData double(data)'];
            paramQcData = [paramQcData dataQc];
         end
         
         paramAdjName = sprintf('%s_ADJUSTED', paramName);
         paramAdjQcName = sprintf('%s_QC', paramAdjName);
         
         if (var_is_present_dec_argo(fCdf, paramAdjName))
            paramAdjFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramAdjName), '_FillValue');
            dataAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramAdjName));
            paramAdjNameList = [paramAdjNameList {paramAdjName}];
            if (idS == 1)
               paramAdjNum = [paramAdjNum {num2str(paramAdjNumCpt)}];
               paramAdjQcNum = [paramAdjQcNum {num2str(paramAdjNumCpt)}];
               paramAdjNumCpt = paramAdjNumCpt + 1;
            else
               paramAdjNum = [paramAdjNum {''}];
               paramAdjQcNum = [paramAdjQcNum {''}];
            end
            paramAdjFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramAdjName), 'C_format');
            paramAdjDataFormatList = [paramAdjDataFormatList {paramAdjFormat}];
            paramAdjQcNameList = [paramAdjQcNameList {paramAdjQcName}];
            dataAdjQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramAdjQcName));
            if (size(dataAdj, 2) == 1)
               paramAdjDataNbDimList = [paramAdjDataNbDimList 1];
               paramAdjData = [paramAdjData double(dataAdj)];
               paramAdjQcData = [paramAdjQcData dataAdjQc];
            else
               paramAdjDataNbDimList = [paramAdjDataNbDimList size(dataAdj, 1)];
               paramAdjData = [paramAdjData double(dataAdj)'];
               paramAdjQcData = [paramAdjQcData dataAdjQc'];
            end
         end
         
         paramAdjErrorName = sprintf('%s_ADJUSTED_ERROR', paramName);
         
         if (var_is_present_dec_argo(fCdf, paramAdjErrorName))
            paramAdjErrorFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramAdjErrorName), '_FillValue');
            dataAdjError = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramAdjErrorName));
            
            paramAdjErrorNameList = [paramAdjErrorNameList {paramAdjErrorName}];
            paramAdjErrorFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramAdjErrorName), 'C_format');
            paramAdjErrorDataFormatList = [paramAdjErrorDataFormatList {paramAdjErrorFormat}];
            if (size(dataAdjError, 2) == 1)
               paramAdjErrorDataNbDimList = [paramAdjErrorDataNbDimList 1];
               paramAdjErrorData = [paramAdjErrorData double(dataAdjError)];
            else
               paramAdjErrorDataNbDimList = [paramAdjErrorDataNbDimList size(dataAdjError, 1)];
               paramAdjErrorData = [paramAdjErrorData double(dataAdjError)'];
            end
         end
      end
   end
end

if (SORT_PARAM == 1)
   
   % sort parameters according to a given list
   paramSortedList = [ ...
      {'PRES'}; ...
      {'TEMP'}; ...
      {'CNDC'}; ...
      {'PSAL'}; ...
      {'NB_SAMPLE_CTD'}; ...
      {'DOXY'}; ...
      {'PPOX_DOXY'}; ...
      {'VOLTAGE_DOXY'}; ...
      {'FREQUENCY_DOXY'}; ...
      {'COUNT_DOXY'}; ...
      {'BPHASE_DOXY'}; ...
      {'DPHASE_DOXY'}; ...
      {'TPHASE_DOXY'}; ...
      {'RPHASE_DOXY'}; ...
      {'PHASE_DELAY_DOXY'}; ...
      {'C1PHASE_DOXY'}; ...
      {'C2PHASE_DOXY'}; ...
      {'MOLAR_DOXY'}; ...
      {'MLPL_DOXY'}; ...
      {'TEMP_DOXY'}; ...
      {'DOXY2'}; ...
      {'PHASE_DELAY_DOXY2'}; ...
      {'TEMP_DOXY2'}; ...
      {'CHLA'}; ...
      {'FLUORESCENCE_CHLA'}; ...
      {'TEMP_CPU_CHLA'}; ...
      {'BBP700'}; ...
      {'BETA_BACKSCATTERING700'}; ...
      {'BBP532'}; ...
      {'BETA_BACKSCATTERING532'}; ...
      {'CDOM'}; ...
      {'FLUORESCENCE_CDOM'}; ...
      {'DOWN_IRRADIANCE380'}; ...
      {'DOWN_IRRADIANCE412'}; ...
      {'DOWN_IRRADIANCE490'}; ...
      {'DOWNWELLING_PAR'}; ...
      {'RAW_DOWNWELLING_IRRADIANCE380'}; ...
      {'RAW_DOWNWELLING_IRRADIANCE412'}; ...
      {'RAW_DOWNWELLING_IRRADIANCE490'}; ...
      {'RAW_DOWNWELLING_PAR'}; ...
      {'PH_IN_SITU_TOTAL'}; ...
      {'VRS_PH'}; ...
      {'PH_IN_SITU_FREE'}; ...
      {'NB_SAMPLE_SFET'}; ...      
      {'TURBIDITY'}; ...
      {'SIDE_SCATTERING_TURBIDITY'}; ...
      {'CP660'}; ...
      {'NITRATE'}; ...
      {'BISULFIDE'}; ...
      {'MOLAR_NITRATE'}; ...
      {'TEMP_NITRATE'}; ...
      {'TEMP_SPECTROPHOTOMETER_NITRATE'}; ...
      {'HUMIDITY_NITRATE'}; ...
      {'UV_INTENSITY_DARK_NITRATE'}; ...
      {'FIT_ERROR_NITRATE'}; ...
      {'UV_INTENSITY_NITRATE'}; ...
      ];
   
   sufixList = [{''} {'_STD'} {'_MED'}];
   
   paramNameListTmp = [];
   paramNumTmp = [];
   paramDataFormatListTmp = [];
   paramDataNbDimListTmp = [];
   paramDataTmp = [];
   paramDataModeTmp = [];
   paramDataModeNumTmp = [];
   paramQcNameListTmp = [];
   paramQcNumTmp = [];
   paramQcDataTmp = [];
   paramAdjNameListTmp = [];
   paramAdjNumTmp = [];
   paramAdjDataFormatListTmp = [];
   paramAdjDataNbDimListTmp = [];
   paramAdjDataTmp = [];
   paramAdjQcNameListTmp = [];
   paramAdjQcNumTmp = [];
   paramAdjQcDataTmp = [];
   paramAdjErrorNameListTmp = [];
   paramAdjErrorDataFormatListTmp = [];
   paramAdjErrorDataNbDimListTmp = [];
   paramAdjErrorDataTmp = [];

   paramDone = zeros(length(paramNameList), 1);
   
   offset = zeros(length(paramNameList), 1);
   for idParam = 1:length(paramNameList)
      offset(idParam) = sum(paramDataNbDimList(1:idParam-1)) - idParam + 1;
   end
   offsetAdj = zeros(length(paramAdjNameList), 1);
   for idParam = 1:length(paramAdjNameList)
      offsetAdj(idParam) = sum(paramAdjDataNbDimList(1:idParam-1)) - idParam + 1;
   end
   for idParam = 1:length(paramSortedList)
      for idS = 1:length(sufixList)
         paramName = [paramSortedList{idParam} sufixList{idS}];
         
         idF = find(strcmp(paramName, paramNameList) == 1);
         if (~isempty(idF))
            
            paramNameListTmp = [paramNameListTmp paramNameList(idF)];
            paramNumTmp = [paramNumTmp paramNum(idF)];
            paramDataFormatListTmp = [paramDataFormatListTmp paramDataFormatList(idF)];
            paramDataNbDimListTmp = [paramDataNbDimListTmp paramDataNbDimList(idF)];
            paramDataTmp = [paramDataTmp paramData(:, idF+offset(idF):idF+paramDataNbDimList(idF)-1+offset(idF))];
            paramDataModeTmp = [paramDataModeTmp; paramDataMode(idF, :)];
            paramDataModeNumTmp = [paramDataModeNumTmp paramDataModeNum(idF)];
            paramQcNameListTmp = [paramQcNameListTmp paramQcNameList(idF)];
            paramQcNumTmp = [paramQcNumTmp paramQcNum(idF)];
            paramQcDataTmp = [paramQcDataTmp paramQcData(:, idF)];
            
            paramDone(idF) = 1;
         end
         
         paramAdjName = sprintf('%s_ADJUSTED', paramName);
         
         idF = find(strcmp(paramAdjName, paramAdjNameList) == 1);
         if (~isempty(idF))
            
            paramAdjNameListTmp = [paramAdjNameListTmp paramAdjNameList(idF)];
            paramAdjNumTmp = [paramAdjNumTmp paramAdjNum(idF)];
            paramAdjDataFormatListTmp = [paramAdjDataFormatListTmp paramAdjDataFormatList(idF)];
            paramAdjDataNbDimListTmp = [paramAdjDataNbDimListTmp paramAdjDataNbDimList(idF)];
            paramAdjDataTmp = [paramAdjDataTmp paramAdjData(:, idF+offsetAdj(idF):idF+paramAdjDataNbDimList(idF)-1+offsetAdj(idF))];
            paramAdjQcNameListTmp = [paramAdjQcNameListTmp paramAdjQcNameList(idF)];
            paramAdjQcNumTmp = [paramAdjQcNumTmp paramAdjQcNum(idF)];
            paramAdjQcDataTmp = [paramAdjQcDataTmp paramAdjQcData(:, idF)];
         end
         
         paramAdjErrorName = sprintf('%s_ADJUSTED_ERROR', paramName);
         
         idF = find(strcmp(paramAdjErrorName, paramAdjErrorNameList) == 1);
         if (~isempty(idF))
            
            paramAdjErrorNameListTmp = [paramAdjErrorNameListTmp paramAdjErrorNameList(idF)];
            paramAdjErrorDataFormatListTmp = [paramAdjErrorDataFormatListTmp paramAdjErrorDataFormatList(idF)];
            paramAdjErrorDataNbDimListTmp = [paramAdjErrorDataNbDimListTmp paramAdjErrorDataNbDimList(idF)];
            paramAdjErrorDataTmp = [paramAdjErrorDataTmp paramAdjErrorData(:, idF+offsetAdj(idF):idF+paramAdjErrorDataNbDimList(idF)-1+offsetAdj(idF))];
         end
      end
   end
   
   idList = find(paramDone == 0);
   for idParam = 1:length(idList)
      paramName = paramNameList{idList(idParam)};
      
      idF = find(strcmp(paramName, paramNameList) == 1);
      if (~isempty(idF))
         
         fprintf('INFO: PARAMETER ''%s'' is not in the sorted list yet\n', paramName);
         
         paramNameListTmp = [paramNameListTmp paramNameList(idF)];
         paramNumTmp = [paramNumTmp paramNum(idF)];
         paramDataFormatListTmp = [paramDataFormatListTmp paramDataFormatList(idF)];
         paramDataNbDimListTmp = [paramDataNbDimListTmp paramDataNbDimList(idF)];
         paramDataTmp = [paramDataTmp paramData(:, idF+offset(idF):idF+paramDataNbDimList(idF)-1+offset(idF))];
         paramDataModeTmp = [paramDataModeTmp; paramDataMode(idF, :)];
         paramDataModeNumTmp = [paramDataModeNumTmp paramDataModeNum(idF)];
         paramQcNameListTmp = [paramQcNameListTmp paramQcNameList(idF)];
         paramQcNumTmp = [paramQcNumTmp paramQcNum(idF)];
         paramQcDataTmp = [paramQcDataTmp paramQcData(:, idF)];
         
         paramDone(idF) = 1;
      end
      
      paramAdjName = sprintf('%s_ADJUSTED', paramName);
      
      idF = find(strcmp(paramAdjName, paramAdjNameList) == 1);
      if (~isempty(idF))
         
         paramAdjNameListTmp = [paramAdjNameListTmp paramAdjNameList(idF)];
         paramAdjNumTmp = [paramAdjNumTmp paramAdjNum(idF)];
         paramAdjDataFormatListTmp = [paramAdjDataFormatListTmp paramAdjDataFormatList(idF)];
         paramAdjDataNbDimListTmp = [paramAdjDataNbDimListTmp paramAdjDataNbDimList(idF)];
         paramAdjDataTmp = [paramAdjDataTmp paramAdjData(:, idF+offsetAdj(idF):idF+paramAdjDataNbDimList(idF)-1+offsetAdj(idF))];
         paramAdjQcNameListTmp = [paramAdjQcNameListTmp paramAdjQcNameList(idF)];
         paramAdjQcNumTmp = [paramAdjQcNumTmp paramAdjQcNum(idF)];
         paramAdjQcDataTmp = [paramAdjQcDataTmp paramAdjQcData(:, idF)];
      end
      
      paramAdjErrorName = sprintf('%s_ADJUSTED_ERROR', paramName);
      
      idF = find(strcmp(paramAdjErrorName, paramAdjErrorNameList) == 1);
      if (~isempty(idF))
         
         paramAdjErrorNameListTmp = [paramAdjErrorNameListTmp paramAdjErrorNameList(idF)];
         paramAdjErrorDataFormatListTmp = [paramAdjErrorDataFormatListTmp paramAdjErrorDataFormatList(idF)];
         paramAdjErrorDataNbDimListTmp = [paramAdjErrorDataNbDimListTmp paramAdjErrorDataNbDimList(idF)];
         paramAdjErrorDataTmp = [paramAdjErrorDataTmp paramAdjErrorData(:, idF+offsetAdj(idF):idF+paramAdjErrorDataNbDimList(idF)-1+offsetAdj(idF))];
      end
   end
   
   paramNumCpt = 1;
   for idParam = 1:length(paramNumTmp)
      if (~isempty(paramNumTmp{idParam}))
         paramNumTmp{idParam} = num2str(paramNumCpt);
         paramDataModeNumTmp{idParam} = num2str(paramNumCpt);
         paramQcNumTmp{idParam} = num2str(paramNumCpt);
         paramNumCpt = paramNumCpt + 1;
      end
   end
   paramAdjNumCpt = 1;
   for idParam = 1:length(paramAdjNumTmp)
      if (~isempty(paramAdjNumTmp{idParam}))
         paramAdjNumTmp{idParam} = num2str(paramAdjNumCpt);
         paramAdjQcNumTmp{idParam} = num2str(paramAdjNumCpt);
         paramAdjNumCpt = paramAdjNumCpt + 1;
      end
   end
   
   paramNameList = paramNameListTmp;
   paramNum = paramNumTmp;
   paramDataFormatList = paramDataFormatListTmp;
   paramDataNbDimList = paramDataNbDimListTmp;
   paramData = paramDataTmp;
   paramDataMode = paramDataModeTmp;
   paramDataModeNum = paramDataModeNumTmp;
   paramQcNameList = paramQcNameListTmp;
   paramQcNum = paramQcNumTmp;
   paramQcData = paramQcDataTmp;
   paramAdjNameList = paramAdjNameListTmp;
   paramAdjNum = paramAdjNumTmp;
   paramAdjDataFormatList = paramAdjDataFormatListTmp;
   paramAdjDataNbDimList = paramAdjDataNbDimListTmp;
   paramAdjData = paramAdjDataTmp;
   paramAdjQcNameList = paramAdjQcNameListTmp;
   paramAdjQcNum = paramAdjQcNumTmp;
   paramAdjQcData = paramAdjQcDataTmp;
   paramAdjErrorNameList = paramAdjErrorNameListTmp;
   paramAdjErrorDataFormatList = paramAdjErrorDataFormatListTmp;
   paramAdjErrorDataNbDimList = paramAdjErrorDataNbDimListTmp;
   paramAdjErrorData = paramAdjErrorDataTmp;

end

% store the N_MEASUREMENT data
o_nMeasData = struct( ...
   'platformNumber', platformNumber, ...
   'cycleNumber', cycleNumber', ...
   'cycleNumberAdj', cycleNumberAdj', ...
   'measCode', measCode', ...
   'juld', juld, ...
   'juldDataMode', juldDataMode, ...
   'juldStatus', juldStatus, ...
   'juldQc', juldQc, ...
   'juldAdj', juldAdj, ...
   'juldAdjStatus', juldAdjStatus, ...
   'juldAdjQc', juldAdjQc, ...
   'latitude', latitude, ...
   'longitude', longitude, ...
   'positionAccuracy', positionAccuracy, ...
   'positionQc', positionQc, ...
   'positioAxErrEllMajor', positioAxErrEllMajor, ...
   'positioAxErrEllMinor', positioAxErrEllMinor, ...
   'positioAxErrEllAngle', positioAxErrEllAngle, ...
   'positionSat', positionSat, ...
   'paramNameList', {paramNameList}, ...
   'paramNum', {paramNum}, ...
   'paramDataFormat', {paramDataFormatList}, ...
   'paramDataNbDim', paramDataNbDimList, ...
   'paramData', paramData, ...
   'paramDataMode', paramDataMode, ...
   'paramDataModeNum', {paramDataModeNum}, ...
   'paramQcNameList', {paramQcNameList}, ...
   'paramQcNum', {paramQcNum}, ...
   'paramQcData', paramQcData, ...
   'adjParamNameList', {paramAdjNameList}, ...
   'adjParamNum', {paramAdjNum}, ...
   'adjParamDataFormat', {paramAdjDataFormatList}, ...
   'adjParamDataNbDim', paramAdjDataNbDimList, ...
   'adjParamData', paramAdjData, ...
   'adjParamQcNameList', {paramAdjQcNameList}, ...
   'adjParamQcNum', {paramAdjQcNum}, ...
   'adjParamQcData', paramAdjQcData, ...
   'adjErrorParamNameList', {paramAdjErrorNameList}, ...
   'adjErrorParamDataFormat', {paramAdjErrorDataFormatList}, ...
   'adjErrorParamDataNbDim', paramAdjErrorDataNbDimList, ...
   'adjErrorParamData', paramAdjErrorData);

% N_CYCLE variables

% store the N_CYCLE data
if (var_is_present_dec_argo(fCdf, 'JULD_DESCENT_START'))
   o_nCycleData = struct( ...
      'juldDescentStart', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DESCENT_START')), ...
      'juldDescentStartStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DESCENT_START_STATUS')), ...
      'juldFirstStab', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_FIRST_STABILIZATION')), ...
      'juldFirstStabStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_FIRST_STABILIZATION_STATUS')), ...
      'juldDescentEnd', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DESCENT_END')), ...
      'juldDescentEndStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DESCENT_END_STATUS')), ...
      'juldParkStart', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_PARK_START')), ...
      'juldParkStartStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_PARK_START_STATUS')), ...
      'juldParkEnd', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_PARK_END')), ...
      'juldParkEndStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_PARK_END_STATUS')), ...
      'juldDeepDescentEnd', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DEEP_DESCENT_END')), ...
      'juldDeepDescentEndStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DEEP_DESCENT_END_STATUS')), ...
      'juldDeepParkStart', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DEEP_PARK_START')), ...
      'juldDeepParkStartStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DEEP_PARK_START_STATUS')), ...
      'juldAscentStart', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ASCENT_START')), ...
      'juldAscentStartStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ASCENT_START_STATUS')), ...
      'juldAscentEnd', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ASCENT_END')), ...
      'juldAscentEndStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_ASCENT_END_STATUS')), ...
      'juldTransmissionStart', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_TRANSMISSION_START')), ...
      'juldTransmissionStartStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_TRANSMISSION_START_STATUS')), ...
      'juldFirstMessage', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_FIRST_MESSAGE')), ...
      'juldFirstMessageStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_FIRST_MESSAGE_STATUS')), ...
      'juldFirstLocation', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_FIRST_LOCATION')), ...
      'juldFirstLocationStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_FIRST_LOCATION_STATUS')), ...
      'juldLastLocation', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LAST_LOCATION')), ...
      'juldLastLocationStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LAST_LOCATION_STATUS')), ...
      'juldLastMessage', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LAST_MESSAGE')), ...
      'juldLastMessageStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LAST_MESSAGE_STATUS')), ...
      'juldTransmissionEnd', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_TRANSMISSION_END')), ...
      'juldTransmissionEndStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_TRANSMISSION_END_STATUS')), ...
      'juldClockOffset', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CLOCK_OFFSET')), ...
      'grounded', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'GROUNDED')), ...
      'representativeParkPressure', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'REPRESENTATIVE_PARK_PRESSURE')), ...
      'representativeParkPressureStatus', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'REPRESENTATIVE_PARK_PRESSURE_STATUS')), ...
      'configMissionNumber', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER')), ...
      'cycleNumberIndex', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_INDEX')), ...
      'cycleNumberIndexAdj', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_INDEX_ADJUSTED')), ...
      'dataMode', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE')));
else
   if (var_is_present_dec_argo(fCdf, 'CONFIG_MISSION_NUMBER') && ...
         var_is_present_dec_argo(fCdf, 'CYCLE_NUMBER_INDEX') && ...
         var_is_present_dec_argo(fCdf, 'DATA_MODE'))
      o_nCycleData = struct( ...
         'configMissionNumber', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER')), ...
         'cycleNumberIndex', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_INDEX')), ...
         'dataMode', netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE')));
   end
end

% retrieve CALIBRATION information
calibItemList = [ ...
   {'SCIENTIFIC_CALIB_PARAMETER'} ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'SCIENTIFIC_CALIB_DATE'} ...
   ];
for idC = 1:length(calibItemList)
   varName = calibItemList{idC};
   if (var_is_present_dec_argo(fCdf, varName))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   else
      fprintf('WARNING: Variable %s is missing in file %s\n', ...
         varName, inputFileName);
      varValue = [];
   end
   o_calibrationData{end+1} = varName;
   o_calibrationData{end+1} = varValue;
end

% retrieve HISTORY information
historyItemList = [ ...
   {'HISTORY_INSTITUTION'} ...
   {'HISTORY_STEP'} ...
   {'HISTORY_SOFTWARE'} ...
   {'HISTORY_SOFTWARE_RELEASE'} ...
   {'HISTORY_REFERENCE'} ...
   {'HISTORY_DATE'} ...
   {'HISTORY_ACTION'} ...
   {'HISTORY_PARAMETER'} ...
   {'HISTORY_PREVIOUS_VALUE'} ...
   {'HISTORY_INDEX_DIMENSION'} ...
   {'HISTORY_START_INDEX'} ...
   {'HISTORY_STOP_INDEX'} ...
   {'HISTORY_QCTEST'} ...
   ];
for idH = 1:length(historyItemList)
   varName = historyItemList{idH};
   if (var_is_present_dec_argo(fCdf, varName))
      varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
   else
      fprintf('WARNING: Variable %s is missing in file %s\n', ...
         varName, inputFileName);
      varValue = [];
   end
   o_historyData{end+1} = varName;
   o_historyData{end+1} = varValue;
end

netcdf.close(fCdf);

return
