% ------------------------------------------------------------------------------
% Create NetCDF META-DATA AUX file.
%
% SYNTAX :
%  create_nc_meta_aux_file_2_0( ...
%    a_inputAuxMetaName, a_inputAuxMetaId, a_inputAuxMetaValue, a_inputAuxMetaDescription, ...
%    a_inputAuxStaticConfigName, a_inputAuxStaticConfigId, a_inputAuxStaticConfigValue, ...
%    a_launchAuxConfigName, a_launchAuxConfigId, a_launchAuxConfigValue, ...
%    a_missionAuxConfigName, a_missionAuxConfigId, a_missionAuxConfigValue, a_configMissionNumber, ...
%    a_metaDataAux)
%
% INPUT PARAMETERS :
%   a_inputAuxMetaName          : AUX meta-data names
%   a_inputAuxMetaId            : AUX meta-data Ids
%   a_inputAuxMetaValue         : AUX meta-data values
%   a_inputAuxMetaDescription   : AUX meta-data description
%   a_inputAuxStaticConfigName  : static AUX configuration names
%   a_inputAuxStaticConfigId    : static AUX configuration Ids
%   a_inputAuxStaticConfigValue : static AUX configuration values
%   a_launchAuxConfigName       : launch AUX configuration names
%   a_launchAuxConfigId         : launch AUX configuration Ids
%   a_launchAuxConfigValue      : launch AUX configuration values
%   a_missionAuxConfigName      : mission AUX configuration names
%   a_missionAuxConfigId        : mission AUX configuration Ids
%   a_missionAuxConfigValue     : mission AUX configuration values
%   a_configMissionNumber       : mission configuration numbers
%   a_metaDataAux               : SENSOR AUX meta-data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_meta_aux_file_2_0( ...
   a_inputAuxMetaName, a_inputAuxMetaId, a_inputAuxMetaValue, a_inputAuxMetaDescription, ...
   a_inputAuxStaticConfigName, a_inputAuxStaticConfigId, a_inputAuxStaticConfigValue, ...
   a_launchAuxConfigName, a_launchAuxConfigId, a_launchAuxConfigValue, ...
   a_missionAuxConfigName, a_missionAuxConfigId, a_missionAuxConfigValue, a_configMissionNumber, ...
   a_metaDataAux)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_applyRtqc;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% output NetCDF configuration parameter descriptions
global g_decArgo_outputNcConfParamDescription;

% decoder version
global g_decArgo_decoderVersion;


if (isempty(a_inputAuxMetaName) && isempty(a_inputAuxStaticConfigName) && ...
      isempty(a_launchAuxConfigName) && isempty(a_missionAuxConfigName) && ...
      ~isfield(a_metaDataAux, 'SENSOR') && ~isfield(a_metaDataAux, 'PARAMETER'))
   return
end

% verbose mode flag
VERBOSE_MODE = 1;

% collect dimensions in input meta-data
nbFloatMetaData = length(a_inputAuxMetaName);
nbStaticConfigParam = length(a_inputAuxStaticConfigName);
nbLaunchConfigParam = length(a_launchAuxConfigName);
nbConfigParam = length(a_missionAuxConfigName);
nbSensor = 0;
if (~isempty(a_metaDataAux) && isfield(a_metaDataAux, 'SENSOR') && ~isempty(a_metaDataAux.SENSOR))
   nbSensor = length(fieldnames(a_metaDataAux.SENSOR));
end
nbParam = 0;
if (~isempty(a_metaDataAux) && isfield(a_metaDataAux, 'PARAMETER') && ~isempty(a_metaDataAux.PARAMETER))
   nbParam = length(fieldnames(a_metaDataAux.PARAMETER));
end

% create output file pathname
floatNumStr = num2str(g_decArgo_floatNum);
outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end
outputDirName = [outputDirName '/auxiliary/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

ncFileName = [floatNumStr '_meta_aux.nc'];
ncPathFileName = [outputDirName  ncFileName];

% information to retrieve from a possible existing meta-data file
ncCreationDate = '';
if (exist(ncPathFileName, 'file') == 2)
   
   % retrieve information from existing file
   wantedMetaVars = [ ...
      {'DATE_CREATION'} ...
      ];
   
   % retrieve information from META-DATA netCDF file
   [ncMetaData] = get_data_from_nc_file(ncPathFileName, wantedMetaVars);
   
   idVal = find(strcmp('DATE_CREATION', ncMetaData) == 1);
   if (~isempty(idVal))
      ncCreationDate = ncMetaData{idVal+1}';
   end
   
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Updating NetCDF META-DATA file (%s) ...\n', ncFileName);
   end
   
else
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Creating NetCDF META-DATA file (%s) ...\n', ncFileName);
   end
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

% create and open NetCDF file
fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
if (isempty(fCdf))
   fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE MODE BEGIN
if (VERBOSE_MODE == 2)
   fprintf('START DEFINE MODE\n');
end

% create dimensions
dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
string4096DimId = netcdf.defDim(fCdf, 'STRING4096', 4096);
string1024DimId = netcdf.defDim(fCdf, 'STRING1024', 1024);
string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
string128DimId = netcdf.defDim(fCdf, 'STRING128', 128);
string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

if (nbFloatMetaData == 0)
   nbFloatMetaData = 1;
end
nFloatMetaDataDimId = netcdf.defDim(fCdf, 'N_FLOAT_META_DATA', nbFloatMetaData);

if (nbStaticConfigParam == 0)
   nbStaticConfigParam = 1;
end
nStaticConfigParamDimId = netcdf.defDim(fCdf, 'N_STATIC_CONFIG_PARAM', nbStaticConfigParam);

if (nbLaunchConfigParam == 0)
   nbLaunchConfigParam = 1;
end
nLaunchConfigParamDimId = netcdf.defDim(fCdf, 'N_LAUNCH_CONFIG_PARAM', nbLaunchConfigParam);

if (nbConfigParam == 0)
   nbConfigParam = 1;
end
nConfigParamDimId = netcdf.defDim(fCdf, 'N_CONFIG_PARAM', nbConfigParam);

if (nbSensor == 0)
   nbSensor = 1;
end
nSensorDimId = netcdf.defDim(fCdf, 'N_SENSOR', nbSensor);

if (nbParam == 0)
   nbParam = 1;
end
nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbParam);

nMissionsDimId = netcdf.defDim(fCdf, 'N_MISSIONS', netcdf.getConstant('NC_UNLIMITED'));

if (VERBOSE_MODE == 2)
   fprintf('N_FLOAT_META_DATA = %d\n', nbFloatMetaData);
   fprintf('N_STATIC_CONFIG_PARAM = %d\n', nbStaticConfigParam);
   fprintf('N_LAUNCH_CONFIG_PARAM = %d\n', nbLaunchConfigParam);
   fprintf('N_CONFIG_PARAM = %d\n', nbConfigParam);
   fprintf('N_SENSOR = %d\n', nbSensor);
   fprintf('N_PARAM = %d\n', nbParam);
end

% create global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float auxiliary metadata file');

institution = 'CORIOLIS';
inputElt = getfield(a_metaDataAux, 'DATA_CENTRE');
if (~isempty(inputElt))
   dataCentre = getfield(a_metaDataAux, 'DATA_CENTRE');
   [institution] = get_institution_from_data_centre(dataCentre, 1);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
if (isempty(ncCreationDate))
   globalHistoryText = [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
else
   globalHistoryText = [datestr(datenum(ncCreationDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
end
globalHistoryText = [globalHistoryText ...
   datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis float real time data processing)'];
netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '1.0');
netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'CF-1.6 Coriolis-Argo-Aux-2.0');
netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));
netcdf.putAtt(fCdf, globalVarId, 'id', 'https://doi.org/10.17882/42182');

% general information on the meta-data file
dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
netcdf.putAtt(fCdf, dataTypeVarId, 'conventions', 'Reference table AUX_1');
netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');

formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');

dateCreationVarId = netcdf.defVar(fCdf, 'DATE_CREATION', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateCreationVarId, 'long_name', 'Date of file creation');
netcdf.putAtt(fCdf, dateCreationVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateCreationVarId, '_FillValue', ' ');

dateUpdateVarId = netcdf.defVar(fCdf, 'DATE_UPDATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateUpdateVarId, 'long_name', 'Date of update of this file');
netcdf.putAtt(fCdf, dateUpdateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateUpdateVarId, '_FillValue', ' ');

% float characteristics
floatNcVarId = [];
floatNcVarName = [];
platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', string8DimId);
netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; platformNumberVarId];
floatNcVarName{end+1} = 'PLATFORM_NUMBER';

floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; floatSerialNoVarId];
floatNcVarName{end+1} = 'FLOAT_SERIAL_NO';

dataCentreVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', string2DimId);
netcdf.putAtt(fCdf, dataCentreVarId, 'long_name', 'Data centre in charge of float data processing');
netcdf.putAtt(fCdf, dataCentreVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; dataCentreVarId];
floatNcVarName{end+1} = 'DATA_CENTRE';

% float misc. meta-data
floatMetaDataNameVarId = netcdf.defVar(fCdf, 'FLOAT_META_DATA_NAME', 'NC_CHAR', fliplr([nFloatMetaDataDimId string128DimId]));
netcdf.putAtt(fCdf, floatMetaDataNameVarId, 'long_name', 'Name of miscellaneous float metadata');
netcdf.putAtt(fCdf, floatMetaDataNameVarId, '_FillValue', ' ');

floatMetaDataValueVarId = netcdf.defVar(fCdf, 'FLOAT_META_DATA_VALUE', 'NC_CHAR', fliplr([nFloatMetaDataDimId string4096DimId]));
netcdf.putAtt(fCdf, floatMetaDataValueVarId, 'long_name', 'Value of miscellaneous float metadata');
netcdf.putAtt(fCdf, floatMetaDataValueVarId, '_FillValue', ' ');

floatMetaDataDescriptionVarId = netcdf.defVar(fCdf, 'FLOAT_META_DATA_DESCRIPTION', 'NC_CHAR', fliplr([nFloatMetaDataDimId string1024DimId]));
netcdf.putAtt(fCdf, floatMetaDataDescriptionVarId, 'long_name', 'Description of miscellaneous float metadata');
netcdf.putAtt(fCdf, floatMetaDataDescriptionVarId, '_FillValue', ' ');

% static configuration parameters
staticConfigurationParameterNameVarId = netcdf.defVar(fCdf, 'STATIC_CONFIG_PARAMETER_NAME', 'NC_CHAR', fliplr([nStaticConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, staticConfigurationParameterNameVarId, 'long_name', 'Name of static configuration parameter');
netcdf.putAtt(fCdf, staticConfigurationParameterNameVarId, '_FillValue', ' ');

staticConfigurationParameterValueVarId = netcdf.defVar(fCdf, 'STATIC_CONFIG_PARAMETER_VALUE', 'NC_CHAR', fliplr([nStaticConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, staticConfigurationParameterValueVarId, 'long_name', 'Value of static configuration parameter');
netcdf.putAtt(fCdf, staticConfigurationParameterValueVarId, '_FillValue', ' ');

staticConfigurationParameterDescriptionVarId = netcdf.defVar(fCdf, 'STATIC_CONFIG_PARAMETER_DESCRIPTION', 'NC_CHAR', fliplr([nStaticConfigParamDimId string1024DimId]));
netcdf.putAtt(fCdf, staticConfigurationParameterDescriptionVarId, 'long_name', 'Description of static configuration parameter');
netcdf.putAtt(fCdf, staticConfigurationParameterDescriptionVarId, '_FillValue', ' ');

% launch configuration parameters
launchConfigParameterNameVarId = netcdf.defVar(fCdf, 'LAUNCH_CONFIG_PARAMETER_NAME', 'NC_CHAR', fliplr([nLaunchConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, launchConfigParameterNameVarId, 'long_name', 'Name of configuration parameter at launch');
netcdf.putAtt(fCdf, launchConfigParameterNameVarId, '_FillValue', ' ');

launchConfigParameterValueVarId = netcdf.defVar(fCdf, 'LAUNCH_CONFIG_PARAMETER_VALUE', 'NC_CHAR', fliplr([nLaunchConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, launchConfigParameterValueVarId, 'long_name', 'Value of configuration parameter at launch');
netcdf.putAtt(fCdf, launchConfigParameterValueVarId, '_FillValue', ' ');

launchConfigParameterDescriptionVarId = netcdf.defVar(fCdf, 'LAUNCH_CONFIG_PARAMETER_DESCRIPTION', 'NC_CHAR', fliplr([nLaunchConfigParamDimId string1024DimId]));
netcdf.putAtt(fCdf, launchConfigParameterDescriptionVarId, 'long_name', 'Description of configuration parameter at launch');
netcdf.putAtt(fCdf, launchConfigParameterDescriptionVarId, '_FillValue', ' ');

% configuration parameters
configParameterNameVarId = netcdf.defVar(fCdf, 'CONFIG_PARAMETER_NAME', 'NC_CHAR', fliplr([nConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, configParameterNameVarId, 'long_name', 'Name of configuration parameter');
netcdf.putAtt(fCdf, configParameterNameVarId, '_FillValue', ' ');

configParameterValueVarId = netcdf.defVar(fCdf, 'CONFIG_PARAMETER_VALUE', 'NC_CHAR', fliplr([nMissionsDimId nConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, configParameterValueVarId, 'long_name', 'Value of configuration parameter');
netcdf.putAtt(fCdf, configParameterValueVarId, '_FillValue', ' ');

configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nMissionsDimId);
netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));

configMissionCommentVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_COMMENT', 'NC_CHAR', fliplr([nMissionsDimId string256DimId]));
netcdf.putAtt(fCdf, configMissionCommentVarId, 'long_name', 'Comment on configuration');
netcdf.putAtt(fCdf, configMissionCommentVarId, '_FillValue', ' ');

% float sensor information
sensorVarId = netcdf.defVar(fCdf, 'SENSOR', 'NC_CHAR', fliplr([nSensorDimId string32DimId]));
netcdf.putAtt(fCdf, sensorVarId, 'long_name', 'Name of the sensor mounted on the float');
netcdf.putAtt(fCdf, sensorVarId, 'conventions', 'Reference table AUX_25');
netcdf.putAtt(fCdf, sensorVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorVarId];
floatNcVarName{end+1} = 'SENSOR';

sensorMakerVarId = netcdf.defVar(fCdf, 'SENSOR_MAKER', 'NC_CHAR', fliplr([nSensorDimId string256DimId]));
netcdf.putAtt(fCdf, sensorMakerVarId, 'long_name', 'Name of the sensor manufacturer');
netcdf.putAtt(fCdf, sensorMakerVarId, 'conventions', 'Reference table AUX_26');
netcdf.putAtt(fCdf, sensorMakerVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorMakerVarId];
floatNcVarName{end+1} = 'SENSOR_MAKER';

sensorModelVarId = netcdf.defVar(fCdf, 'SENSOR_MODEL', 'NC_CHAR', fliplr([nSensorDimId string256DimId]));
netcdf.putAtt(fCdf, sensorModelVarId, 'long_name', 'Type of sensor');
netcdf.putAtt(fCdf, sensorModelVarId, 'conventions', 'Reference table AUX_27');
netcdf.putAtt(fCdf, sensorModelVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorModelVarId];
floatNcVarName{end+1} = 'SENSOR_MODEL';

sensorSerialNoVarId = netcdf.defVar(fCdf, 'SENSOR_SERIAL_NO', 'NC_CHAR', fliplr([nSensorDimId string16DimId]));
netcdf.putAtt(fCdf, sensorSerialNoVarId, 'long_name', 'Serial number of the sensor');
netcdf.putAtt(fCdf, sensorSerialNoVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorSerialNoVarId];
floatNcVarName{end+1} = 'SENSOR_SERIAL_NO';

% float parameter information
parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nParamDimId string64DimId]));
netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'Name of parameter computed from float measurements');
netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Reference table AUX_3a');
netcdf.putAtt(fCdf, parameterVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterVarId];
floatNcVarName{end+1} = 'PARAMETER';

parameterSensorVarId = netcdf.defVar(fCdf, 'PARAMETER_SENSOR', 'NC_CHAR', fliplr([nParamDimId string128DimId]));
netcdf.putAtt(fCdf, parameterSensorVarId, 'long_name', 'Name of the sensor that measures this parameter');
netcdf.putAtt(fCdf, parameterSensorVarId, 'conventions', 'Reference table AUX_25');
netcdf.putAtt(fCdf, parameterSensorVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterSensorVarId];
floatNcVarName{end+1} = 'PARAMETER_SENSOR';

parameterUnitsVarId = netcdf.defVar(fCdf, 'PARAMETER_UNITS', 'NC_CHAR', fliplr([nParamDimId string32DimId]));
netcdf.putAtt(fCdf, parameterUnitsVarId, 'long_name', 'Units of value, accuracy and resolution of the parameter');
netcdf.putAtt(fCdf, parameterUnitsVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterUnitsVarId];
floatNcVarName{end+1} = 'PARAMETER_UNITS';

parameterAccuracyVarId = netcdf.defVar(fCdf, 'PARAMETER_ACCURACY', 'NC_CHAR', fliplr([nParamDimId string32DimId]));
netcdf.putAtt(fCdf, parameterAccuracyVarId, 'long_name', 'Accuracy of the parameter');
netcdf.putAtt(fCdf, parameterAccuracyVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterAccuracyVarId];
floatNcVarName{end+1} = 'PARAMETER_ACCURACY';

parameterResolutionVarId = netcdf.defVar(fCdf, 'PARAMETER_RESOLUTION', 'NC_CHAR', fliplr([nParamDimId string32DimId]));
netcdf.putAtt(fCdf, parameterResolutionVarId, 'long_name', 'Resolution of the parameter');
netcdf.putAtt(fCdf, parameterResolutionVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterResolutionVarId];
floatNcVarName{end+1} = 'PARAMETER_RESOLUTION';

% float calibration information
predeploymentCalibEquationVarId = netcdf.defVar(fCdf, 'PREDEPLOYMENT_CALIB_EQUATION', 'NC_CHAR', fliplr([nParamDimId string4096DimId]));
netcdf.putAtt(fCdf, predeploymentCalibEquationVarId, 'long_name', 'Calibration equation for this parameter');
netcdf.putAtt(fCdf, predeploymentCalibEquationVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; predeploymentCalibEquationVarId];
floatNcVarName{end+1} = 'PREDEPLOYMENT_CALIB_EQUATION';

predeploymentCalibCoefficientVarId = netcdf.defVar(fCdf, 'PREDEPLOYMENT_CALIB_COEFFICIENT', 'NC_CHAR', fliplr([nParamDimId string4096DimId]));
netcdf.putAtt(fCdf, predeploymentCalibCoefficientVarId, 'long_name', 'Calibration coefficients for this equation');
netcdf.putAtt(fCdf, predeploymentCalibCoefficientVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; predeploymentCalibCoefficientVarId];
floatNcVarName{end+1} = 'PREDEPLOYMENT_CALIB_COEFFICIENT';

predeploymentCalibCommentVarId = netcdf.defVar(fCdf, 'PREDEPLOYMENT_CALIB_COMMENT', 'NC_CHAR', fliplr([nParamDimId string4096DimId]));
netcdf.putAtt(fCdf, predeploymentCalibCommentVarId, 'long_name', 'Comment applying to this parameter calibration');
netcdf.putAtt(fCdf, predeploymentCalibCommentVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; predeploymentCalibCommentVarId];
floatNcVarName{end+1} = 'PREDEPLOYMENT_CALIB_COMMENT';

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % DEFINE MODE END
if (VERBOSE_MODE == 2)
   fprintf('STOP DEFINE MODE\n');
end

netcdf.endDef(fCdf);

% general information on the meta-data file
valueStr = 'Argo auxiliary meta-data';
netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);

valueStr = '2.0';
netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);

if (isempty(ncCreationDate))
   netcdf.putVar(fCdf, dateCreationVarId, currentDate);
else
   netcdf.putVar(fCdf, dateCreationVarId, ncCreationDate);
end

netcdf.putVar(fCdf, dateUpdateVarId, currentDate);

% float characteristics
% float deployment and mission information
% configuration parameters
% float sensor information
% float calibration information

metaFieldNames = fieldnames(a_metaDataAux);
for idField = 1:length(metaFieldNames)
   % field name of the json structure is also the nc var name
   fieldName = metaFieldNames{idField};
   
   % corresponding nc varId
   idMeta = find(strcmp(floatNcVarName, fieldName) == 1);
   if (isempty(idMeta))
      continue
   end
   
   % field values are to be stored in the nc META file
   inputElt = a_metaDataAux.(fieldName);
   if (~isempty(inputElt))
      
      if (isa(inputElt, 'char'))
         
         % meta-data with no dimension
         
         % values of type char
         [varName, xType, dimIds, nAtts] = netcdf.inqVar(fCdf, floatNcVarId(idMeta));
         if (~isempty(dimIds))
            netcdf.putVar(fCdf, floatNcVarId(idMeta), 0, length(inputElt), inputElt);
         else
            netcdf.putVar(fCdf, floatNcVarId(idMeta), inputElt);
         end
         
      elseif (isa(inputElt, 'struct'))
         
         % meta-data with one dimension
         fieldNames = fieldnames(inputElt);
         for id = 1:length(fieldNames)
            valueStr = inputElt.(fieldNames{id});
            if (strcmp(fieldName, 'SENSOR') || strcmp(fieldName, 'PARAMETER_SENSOR'))
               valueStr = regexprep(valueStr, 'AUX_', '');
            end
            if (~isempty(valueStr))
               [varName, xType, dimIds, nAtts] = netcdf.inqVar(fCdf, floatNcVarId(idMeta));
               if (xType == netcdf.getConstant('NC_CHAR'))
                  % values of type char
                  netcdf.putVar(fCdf, floatNcVarId(idMeta), ...
                     fliplr([id-1  0]), fliplr([1 length(valueStr)]), valueStr');
               else
                  % values of type double
                  netcdf.putVar(fCdf, floatNcVarId(idMeta), ...
                     fliplr([id-1  0]), fliplr([1 1]), str2num(valueStr));
               end
            end
         end

      else
         fprintf('WARNING: Float #%d: unexpected type in the input Json meta-ada structure\n', ...
            g_decArgo_floatNum);
      end
   end
end

% float misc. meta-data
for idMeta = 1:length(a_inputAuxMetaName)
   metaName = a_inputAuxMetaName{idMeta};
   metaValue = a_inputAuxMetaValue{idMeta};
   metaDescription = a_inputAuxMetaDescription{idMeta};
   metaName = regexprep(metaName, 'META_AUX_', '');
   
   netcdf.putVar(fCdf, floatMetaDataNameVarId, ...
      fliplr([idMeta-1  0]), fliplr([1 length(metaName)]), metaName');
   netcdf.putVar(fCdf, floatMetaDataValueVarId, ...
      fliplr([idMeta-1  0]), fliplr([1 length(metaValue)]), metaValue');
   netcdf.putVar(fCdf, floatMetaDataDescriptionVarId, ...
      fliplr([idMeta-1  0]), fliplr([1 length(metaDescription)]), metaDescription');
end

% static configuration parameters
for idConf = 1:length(a_inputAuxStaticConfigName)
   confName = a_inputAuxStaticConfigName{idConf};
   confValue = a_inputAuxStaticConfigValue{idConf};
   if (~isempty(a_inputAuxStaticConfigId))
      idF = find(g_decArgo_outputNcConfParamId == a_inputAuxStaticConfigId(idConf));
      confDescription = g_decArgo_outputNcConfParamDescription{idF};
   else
      confDescription = g_decArgo_outputNcConfParamDescription{find(strcmp(confName, g_decArgo_outputNcConfParamLabel), 1)};
   end
   confName = regexprep(confName, 'CONFIG_AUX_', 'CONFIG_');
   
   netcdf.putVar(fCdf, staticConfigurationParameterNameVarId, ...
      fliplr([idConf-1  0]), fliplr([1 length(confName)]), confName');
   netcdf.putVar(fCdf, staticConfigurationParameterValueVarId, ...
      fliplr([idConf-1  0]), fliplr([1 length(confValue)]), confValue');
   netcdf.putVar(fCdf, staticConfigurationParameterDescriptionVarId, ...
      fliplr([idConf-1  0]), fliplr([1 length(confDescription)]), confDescription');
end

% store launch configuration data
minChar = 999;
for idConf = 1:length(g_decArgo_outputNcConfParamLabel)
   confName = fliplr(g_decArgo_outputNcConfParamLabel{idConf});
   idF = strfind(confName, '>');
   if (~isempty(idF))
      minChar = min(minChar, idF(1)-1);
   end
end

for idConf = 1:length(a_launchAuxConfigName)
   confName = a_launchAuxConfigName{idConf};
   confValue = a_launchAuxConfigValue{idConf};
   if (~isempty(confValue))
      confValue = strtrim(confValue);
   end

   % retrieve configuration parameter description
   confDescription = '';
   if (~isempty(a_launchAuxConfigId))
      if (iscell(g_decArgo_outputNcConfParamId))
         idF = find(strcmp(a_launchAuxConfigId(idConf), g_decArgo_outputNcConfParamId)); % config name Ids are numbers for NKE floats and strings for APF11
         confDescription = g_decArgo_outputNcConfParamDescription{idF};
      else
         idF = find(g_decArgo_outputNcConfParamId == a_launchAuxConfigId(idConf));
         confDescription = g_decArgo_outputNcConfParamDescription{idF};
      end
   else
      idDesc = find(strcmp(confName, g_decArgo_outputNcConfParamLabel), 1);
      if (isempty(idDesc))
         idFz = strfind(confName, 'Zone');
         if (length(idFz) == 1)
            confNameBis = [confName(1:idFz-1) 'Zone<N>' confName(idFz+5:end)];
            idDesc = find(strcmp(confNameBis, g_decArgo_outputNcConfParamLabel), 1);
         elseif (length(idFz) == 2)
            confNameBis = [confName(1:idFz(1)-1) 'Zone<N>' confName(idFz(1)+5:idFz(2)-1) 'Zone<N+1>' confName(idFz(2)+5:end)];
            idDesc = find(strcmp(confNameBis, g_decArgo_outputNcConfParamLabel), 1);
         end
         if (isempty(idDesc))
            idDescAll = find(cellfun(@(x) (length(x) > minChar-1) && ~isempty(strfind(x(end-(minChar-1):end), confName(end-(minChar-1):end))), g_decArgo_outputNcConfParamLabel));
            if (length(idDescAll) == 1)
               idDesc = idDescAll;
            end
         end
      end
      if (~isempty(idDesc))
         confDescription = g_decArgo_outputNcConfParamDescription{idDesc};
      end
   end
   if (isempty(confDescription))
      confDescription = 'DESCRIPTION CANNOT BE RETRIEVED';
      fprintf('ERROR: Float #%d: unable to retrieve description of AUX configuration parameter ''%s''\n', ...
         g_decArgo_floatNum, confName);
   end

   confName = regexprep(confName, 'CONFIG_AUX_', 'CONFIG_');

   netcdf.putVar(fCdf, launchConfigParameterNameVarId, ...
      fliplr([idConf-1  0]), fliplr([1 length(confName)]), confName');
   if (~isempty(confValue))
      netcdf.putVar(fCdf, launchConfigParameterValueVarId, ...
         fliplr([idConf-1  0]), fliplr([1 length(confValue)]), confValue');
   end
   netcdf.putVar(fCdf, launchConfigParameterDescriptionVarId, ...
      fliplr([idConf-1  0]), fliplr([1 length(confDescription)]), confDescription');
end

% store mission configuration data
for idConf = 1:size(a_missionAuxConfigValue, 1)
   confName = a_missionAuxConfigName{idConf};
   confName = regexprep(confName, 'CONFIG_AUX_', 'CONFIG_');

   netcdf.putVar(fCdf, configParameterNameVarId, ...
      fliplr([idConf-1  0]), fliplr([1 length(confName)]), confName');

   for idMis = 1:size(a_missionAuxConfigValue, 2)
      confValue = a_missionAuxConfigValue{idConf, idMis};
      if (~isempty(confValue))
         confValue = strtrim(confValue);
      end
      if (~isempty(confValue))
         netcdf.putVar(fCdf, configParameterValueVarId, ...
            fliplr([idMis-1 idConf-1 0]), fliplr([1 1 length(confValue)]), confValue');
      end
   end
end

% store mission configuration numbers
if (~isempty(a_configMissionNumber))
   netcdf.putVar(fCdf, configMissionNumberVarId, 0, length(a_configMissionNumber), a_configMissionNumber);
end

netcdf.close(fCdf);

if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
   % store information for the XML report
   g_decArgo_reportStruct.outputMetaAuxFiles = [g_decArgo_reportStruct.outputMetaAuxFiles ...
      {ncPathFileName}];
end

fprintf('... NetCDF META-DATA AUX file created\n');

return
