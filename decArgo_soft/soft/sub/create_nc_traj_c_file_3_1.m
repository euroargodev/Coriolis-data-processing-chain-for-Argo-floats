% ------------------------------------------------------------------------------
% Create NetCDF TRAJECTORY c file.
%
% SYNTAX :
%  create_nc_traj_c_file_3_1( ...
%    a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabTrajNMeas     : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle    : N_CYCLE trajectory data
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/19/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_traj_c_file_3_1( ...
   a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_applyRtqc;

% decoder version
global g_decArgo_decoderVersion;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% global default values
global g_decArgo_qcDef;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabTrajNMeas) && isempty(a_tabTrajNCycle))
   return;
end

% collect information on trajectory
measParamName = [];
for idNM = 1:length(a_tabTrajNMeas)
   nMeas = a_tabTrajNMeas(idNM);
   for idM = 1:length(nMeas.tabMeas)
      if (~isempty(nMeas.tabMeas(idM).paramList))
         measParamNameList = {nMeas.tabMeas(idM).paramList.name};
         measParamName = unique([measParamName measParamNameList(find([nMeas.tabMeas(idM).paramList.paramType] == 'c'))], 'stable');
      end
   end
end
measUniqueParamName = unique(measParamName, 'stable');
nbMeasParam = length(measUniqueParamName);

% mandatory parameter list
mandatoryParamList = [ ...
   {'PRES'} ...
   {'TEMP'} ...
   ];
measAddParamName = [];
for idParam = 1:length(mandatoryParamList)
   if (isempty(find(strcmp(mandatoryParamList{idParam}, measUniqueParamName) == 1, 1)))
      measAddParamName = [measAddParamName mandatoryParamList(idParam)];
   end
end
nbMeasAddParam = length(measAddParamName);

% create output file pathname
floatNumStr = num2str(g_decArgo_floatNum);
outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

ncFileName = [floatNumStr '_Rtraj.nc'];
ncPathFileName = [outputDirName  ncFileName];

% information to retrieve from a possible existing trajectory file
ncCreationDate = '';
histoInstitution = '';
histoStep = '';
histoSoftware = '';
histoSoftwareRelease = '';
histoDate = '';
if (exist(ncPathFileName, 'file') == 2)
   
   % retrieve information from existing file
   wantedTrajVars = [ ...
      {'DATE_CREATION'} ...
      {'DATA_MODE'} ...
      {'HISTORY_INSTITUTION'} ...
      {'HISTORY_STEP'} ...
      {'HISTORY_SOFTWARE'} ...
      {'HISTORY_SOFTWARE_RELEASE'} ...
      {'HISTORY_DATE'} ...
      ];
   
   % retrieve information from TRAJ netCDF file
   [trajData] = get_data_from_nc_file(ncPathFileName, wantedTrajVars);
   
   idVal = find(strcmp('DATE_CREATION', trajData) == 1);
   if (~isempty(idVal))
      ncCreationDate = trajData{idVal+1}';
   end
   idVal = find(strcmp('DATA_MODE', trajData) == 1);
   if (~isempty(idVal))
      ncDataMode = trajData{idVal+1};
   end
   idVal = find(strcmp('HISTORY_INSTITUTION', trajData) == 1);
   if (~isempty(idVal))
      histoInstitution = trajData{idVal+1};
   end
   idVal = find(strcmp('HISTORY_STEP', trajData) == 1);
   if (~isempty(idVal))
      histoStep = trajData{idVal+1};
   end
   idVal = find(strcmp('HISTORY_SOFTWARE', trajData) == 1);
   if (~isempty(idVal))
      histoSoftware = trajData{idVal+1};
   end
   idVal = find(strcmp('HISTORY_SOFTWARE_RELEASE', trajData) == 1);
   if (~isempty(idVal))
      histoSoftwareRelease = trajData{idVal+1};
   end
   idVal = find(strcmp('HISTORY_DATE', trajData) == 1);
   if (~isempty(idVal))
      histoDate = trajData{idVal+1};
   end
   
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Updating NetCDF TRAJECTORY file (%s) ...\n', ncFileName);
   end
   
else
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Creating NetCDF TRAJECTORY file (%s) ...\n', ncFileName);
   end
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

% create and open NetCDF file
fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
if (isempty(fCdf))
   fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
   return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE MODE BEGIN
if (VERBOSE_MODE == 2)
   fprintf('START DEFINE MODE\n');
end

% create dimensions
dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
paramNameLength = 16;
string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbMeasParam+nbMeasAddParam);

nMeasurementDimId = netcdf.defDim(fCdf, 'N_MEASUREMENT', netcdf.getConstant('NC_UNLIMITED'));

cycles = [];
nCycle = 0;
if (~isempty(a_tabTrajNCycle))
   cycles =  sort(unique([a_tabTrajNCycle.outputCycleNumber]));
   nCycle = length(cycles);
end
if (nCycle == 0)
   nCycle = 1;
end
nCycleDimId = netcdf.defDim(fCdf, 'N_CYCLE', nCycle);

nHistoryDim = 1;
if (~isempty(histoInstitution))
   if (length(ncDataMode) <= length(cycles))
      nHistoryDim = size(histoInstitution, 2) + 1;
   end
end
nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', nHistoryDim);

if (VERBOSE_MODE == 2)
   fprintf('N_PARAM = %d\n', nbMeasParam+nbMeasAddParam);
   fprintf('N_CYCLE = %d\n', length(cycles));
end

% create global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float trajectory file');
institution = 'CORIOLIS';
idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   dataCentre = char(a_metaDataFromJson{idVal+1});
   [institution] = get_institution_from_data_centre(dataCentre);
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
netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.1');
netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectory');

resGlobalComment = get_global_comment_on_resolution(a_decoderId);
if (~isempty(resGlobalComment))
   netcdf.putAtt(fCdf, globalVarId, 'comment_on_resolution', resGlobalComment);
end

measGlobalComment = get_global_comment_on_measurement_code(a_decoderId);
if (~isempty(measGlobalComment))
   netcdf.putAtt(fCdf, globalVarId, 'comment_on_measurement_code', measGlobalComment);
end

% general information on the trajectory file
dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string16DimId);
netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
netcdf.putAtt(fCdf, dataTypeVarId, 'conventions', 'Argo reference table 1');
netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');

formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');

handbookVersionVarId = netcdf.defVar(fCdf, 'HANDBOOK_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, handbookVersionVarId, 'long_name', 'Data handbook version');
netcdf.putAtt(fCdf, handbookVersionVarId, '_FillValue', ' ');

referenceDateTimeVarId = netcdf.defVar(fCdf, 'REFERENCE_DATE_TIME', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, referenceDateTimeVarId, 'long_name', 'Date of reference for Julian days');
netcdf.putAtt(fCdf, referenceDateTimeVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, referenceDateTimeVarId, '_FillValue', ' ');

dateCreationVarId = netcdf.defVar(fCdf, 'DATE_CREATION', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateCreationVarId, 'long_name', 'Date of file creation');
netcdf.putAtt(fCdf, dateCreationVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateCreationVarId, '_FillValue', ' ');

dateUpdateVarId = netcdf.defVar(fCdf, 'DATE_UPDATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateUpdateVarId, 'long_name', 'Date of update of this file');
netcdf.putAtt(fCdf, dateUpdateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateUpdateVarId, '_FillValue', ' ');

% general information on the float
platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', string8DimId);
netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');

projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Name of the project');
netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');

piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');

trajectoryParametersVarId = netcdf.defVar(fCdf, 'TRAJECTORY_PARAMETERS', 'NC_CHAR', fliplr([nParamDimId string16DimId]));
netcdf.putAtt(fCdf, trajectoryParametersVarId, 'long_name', 'List of available parameters for the station');
netcdf.putAtt(fCdf, trajectoryParametersVarId, 'conventions', 'Argo reference table 3');
netcdf.putAtt(fCdf, trajectoryParametersVarId, '_FillValue', ' ');

dataCentreVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', string2DimId);
netcdf.putAtt(fCdf, dataCentreVarId, 'long_name', 'Data centre in charge of float data processing');
netcdf.putAtt(fCdf, dataCentreVarId, 'conventions', 'Argo reference table 4');
netcdf.putAtt(fCdf, dataCentreVarId, '_FillValue', ' ');

dataStateIndicatorVarId = netcdf.defVar(fCdf, 'DATA_STATE_INDICATOR', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'long_name', 'Degree of processing the data have passed through');
netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'conventions', 'Argo reference table 6');
netcdf.putAtt(fCdf, dataStateIndicatorVarId, '_FillValue', ' ');

platformTypeVarId = netcdf.defVar(fCdf, 'PLATFORM_TYPE', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, platformTypeVarId, 'long_name', 'Type of float');
netcdf.putAtt(fCdf, platformTypeVarId, 'conventions', 'Argo reference table 23');
netcdf.putAtt(fCdf, platformTypeVarId, '_FillValue', ' ');

floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');

firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Instrument firmware version');
netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');

wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');

positioningSystemVarId = netcdf.defVar(fCdf, 'POSITIONING_SYSTEM', 'NC_CHAR', string8DimId);
netcdf.putAtt(fCdf, positioningSystemVarId, 'long_name', 'Positioning system');
netcdf.putAtt(fCdf, positioningSystemVarId, '_FillValue', ' ');

% locations and measurements from the float
% N_MEASUREMENT variables

juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nMeasurementDimId);
netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD', a_decoderId);
netcdf.putAtt(fCdf, juldVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');
if (~isempty(resComment))
   netcdf.putAtt(fCdf, juldVarId, 'comment_on_resolution', resComment);
end

juldStatusVarId = netcdf.defVar(fCdf, 'JULD_STATUS', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, juldStatusVarId, 'long_name', 'Status of the date and time');
netcdf.putAtt(fCdf, juldStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldStatusVarId, '_FillValue', ' ');

juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');

juldAdjustedVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED', 'NC_DOUBLE', nMeasurementDimId);
netcdf.putAtt(fCdf, juldAdjustedVarId, 'long_name', 'Adjusted julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
netcdf.putAtt(fCdf, juldAdjustedVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldAdjustedVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldAdjustedVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_ADJUSTED', a_decoderId);
netcdf.putAtt(fCdf, juldAdjustedVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldAdjustedVarId, '_FillValue', double(999999));
netcdf.putAtt(fCdf, juldAdjustedVarId, 'axis', 'T');
if (~isempty(resComment))
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'comment_on_resolution', resComment);
end

juldAdjustedStatusVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED_STATUS', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, juldAdjustedStatusVarId, 'long_name', 'Status of the JULD_ADJUSTED date');
netcdf.putAtt(fCdf, juldAdjustedStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldAdjustedStatusVarId, '_FillValue', ' ');

juldAdjustedQcVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED_QC', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, juldAdjustedQcVarId, 'long_name', 'Quality on adjusted date and time');
netcdf.putAtt(fCdf, juldAdjustedQcVarId, 'conventions', 'Argo reference table 2');
netcdf.putAtt(fCdf, juldAdjustedQcVarId, '_FillValue', ' ');

latitudeVarId = netcdf.defVar(fCdf, 'LATITUDE', 'NC_DOUBLE', nMeasurementDimId);
netcdf.putAtt(fCdf, latitudeVarId, 'long_name', 'Latitude of each location');
netcdf.putAtt(fCdf, latitudeVarId, 'standard_name', 'latitude');
netcdf.putAtt(fCdf, latitudeVarId, 'units', 'degree_north');
netcdf.putAtt(fCdf, latitudeVarId, '_FillValue', double(99999));
netcdf.putAtt(fCdf, latitudeVarId, 'valid_min', double(-90));
netcdf.putAtt(fCdf, latitudeVarId, 'valid_max', double(90));
netcdf.putAtt(fCdf, latitudeVarId, 'axis', 'Y');

longitudeVarId = netcdf.defVar(fCdf, 'LONGITUDE', 'NC_DOUBLE', nMeasurementDimId);
netcdf.putAtt(fCdf, longitudeVarId, 'long_name', 'Longitude of each location');
netcdf.putAtt(fCdf, longitudeVarId, 'standard_name', 'longitude');
netcdf.putAtt(fCdf, longitudeVarId, 'units', 'degree_east');
netcdf.putAtt(fCdf, longitudeVarId, '_FillValue', double(99999));
netcdf.putAtt(fCdf, longitudeVarId, 'valid_min', double(-180));
netcdf.putAtt(fCdf, longitudeVarId, 'valid_max', double(180));
netcdf.putAtt(fCdf, longitudeVarId, 'axis', 'X');

positionAccuracyVarId = netcdf.defVar(fCdf, 'POSITION_ACCURACY', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, positionAccuracyVarId, 'long_name', 'Estimated accuracy in latitude and longitude');
netcdf.putAtt(fCdf, positionAccuracyVarId, 'conventions', 'Argo reference table 5');
netcdf.putAtt(fCdf, positionAccuracyVarId, '_FillValue', ' ');

positionQcVarId = netcdf.defVar(fCdf, 'POSITION_QC', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, positionQcVarId, 'long_name', 'Quality on position');
netcdf.putAtt(fCdf, positionQcVarId, 'conventions', 'Argo reference table 2');
netcdf.putAtt(fCdf, positionQcVarId, '_FillValue', ' ');

cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nMeasurementDimId);
netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number of the measurement');
netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));

cycleNumberAdjustedVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_ADJUSTED', 'NC_INT', nMeasurementDimId);
netcdf.putAtt(fCdf, cycleNumberAdjustedVarId, 'long_name', 'Adjusted float cycle number of the measurement');
netcdf.putAtt(fCdf, cycleNumberAdjustedVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
netcdf.putAtt(fCdf, cycleNumberAdjustedVarId, '_FillValue', int32(99999));

measurementCodeVarId = netcdf.defVar(fCdf, 'MEASUREMENT_CODE', 'NC_INT', nMeasurementDimId);
netcdf.putAtt(fCdf, measurementCodeVarId, 'long_name', 'Flag referring to a measurement event in the cycle');
netcdf.putAtt(fCdf, measurementCodeVarId, 'conventions', 'Argo reference table 15');
netcdf.putAtt(fCdf, measurementCodeVarId, '_FillValue', int32(99999));

axesErrorEllipseMajorVarId = netcdf.defVar(fCdf, 'AXES_ERROR_ELLIPSE_MAJOR', 'NC_FLOAT', nMeasurementDimId);
netcdf.putAtt(fCdf, axesErrorEllipseMajorVarId, 'long_name', 'Major axis of error ellipse from positioning system');
netcdf.putAtt(fCdf, axesErrorEllipseMajorVarId, 'units', 'meters');
netcdf.putAtt(fCdf, axesErrorEllipseMajorVarId, '_FillValue', single(99999));

axesErrorEllipseMinorVarId = netcdf.defVar(fCdf, 'AXES_ERROR_ELLIPSE_MINOR', 'NC_FLOAT', nMeasurementDimId);
netcdf.putAtt(fCdf, axesErrorEllipseMinorVarId, 'long_name', 'Minor axis of error ellipse from positioning system');
netcdf.putAtt(fCdf, axesErrorEllipseMinorVarId, 'units', 'meters');
netcdf.putAtt(fCdf, axesErrorEllipseMinorVarId, '_FillValue', single(99999));

axesErrorEllipseAngleVarId = netcdf.defVar(fCdf, 'AXES_ERROR_ELLIPSE_ANGLE', 'NC_FLOAT', nMeasurementDimId);
netcdf.putAtt(fCdf, axesErrorEllipseAngleVarId, 'long_name', 'Angle of error ellipse from positioning system');
netcdf.putAtt(fCdf, axesErrorEllipseAngleVarId, 'units', 'Degrees (from North when heading East)');
netcdf.putAtt(fCdf, axesErrorEllipseAngleVarId, '_FillValue', single(99999));

satelliteNameVarId = netcdf.defVar(fCdf, 'SATELLITE_NAME', 'NC_CHAR', nMeasurementDimId);
netcdf.putAtt(fCdf, satelliteNameVarId, 'long_name', 'Satellite name from positioning system');
netcdf.putAtt(fCdf, satelliteNameVarId, '_FillValue', ' ');

% parameter variables
paramNameDone = [];
for idNM = 1:length(a_tabTrajNMeas)
   nMeas = a_tabTrajNMeas(idNM);
   for idM = 1:length(nMeas.tabMeas)
      meas = nMeas.tabMeas(idM);
      measParamList = meas.paramList;
      for idParam = 1:length(measParamList)
         if (measParamList(idParam).paramType == 'c')
            measParam = measParamList(idParam);
            measParamName = measParam.name;
            
            if (isempty(find(strcmp(measParamName, paramNameDone) == 1, 1)))
               
               paramNameDone = [paramNameDone; {measParamName}];
               
               % create parameter variable and attributes
               if (~var_is_present_dec_argo(fCdf, measParamName))
                  
                  measParamVarId = netcdf.defVar(fCdf, measParamName, 'NC_FLOAT', nMeasurementDimId);
                  
                  if (~isempty(measParam.longName))
                     netcdf.putAtt(fCdf, measParamVarId, 'long_name', measParam.longName);
                  end
                  if (~isempty(measParam.standardName))
                     netcdf.putAtt(fCdf, measParamVarId, 'standard_name', measParam.standardName);
                  end
                  if (~isempty(measParam.fillValue))
                     netcdf.putAtt(fCdf, measParamVarId, '_FillValue', measParam.fillValue);
                  end
                  if (~isempty(measParam.units))
                     netcdf.putAtt(fCdf, measParamVarId, 'units', measParam.units);
                  end
                  if (~isempty(measParam.validMin))
                     netcdf.putAtt(fCdf, measParamVarId, 'valid_min', measParam.validMin);
                  end
                  if (~isempty(measParam.validMax))
                     netcdf.putAtt(fCdf, measParamVarId, 'valid_max', measParam.validMax);
                  end
                  if (~isempty(measParam.cFormat))
                     netcdf.putAtt(fCdf, measParamVarId, 'C_format', measParam.cFormat);
                  end
                  if (~isempty(measParam.fortranFormat))
                     netcdf.putAtt(fCdf, measParamVarId, 'FORTRAN_format', measParam.fortranFormat);
                  end
                  
                  [resNominal, resComment] = get_param_comment_on_resolution(measParamName, a_decoderId);
                  if (isempty(resNominal))
                     if (~isempty(measParam.resolution))
                        netcdf.putAtt(fCdf, measParamVarId, 'resolution', measParam.resolution);
                     end
                  else
                     netcdf.putAtt(fCdf, measParamVarId, 'resolution', resNominal);
                  end
                  if (~isempty(resComment))
                     netcdf.putAtt(fCdf, measParamVarId, 'comment_on_resolution', resComment);
                  end
                  
                  if (~isempty(measParam.axis))
                     netcdf.putAtt(fCdf, measParamVarId, 'axis', measParam.axis);
                  end
               end
               
               % parameter QC variable and attributes
               measParamQcName = sprintf('%s_QC', measParamName);
               if (~var_is_present_dec_argo(fCdf, measParamQcName))
                  
                  measParamQcVarId = netcdf.defVar(fCdf, measParamQcName, 'NC_CHAR', nMeasurementDimId);
                  
                  netcdf.putAtt(fCdf, measParamQcVarId, 'long_name', 'quality flag');
                  netcdf.putAtt(fCdf, measParamQcVarId, 'conventions', 'Argo reference table 2');
                  netcdf.putAtt(fCdf, measParamQcVarId, '_FillValue', ' ');
               end
               
               if (measParam.adjAllowed == 1)
                  % parameter adjusted variable and attributes
                  measParamAdjName = sprintf('%s_ADJUSTED', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamAdjName))
                     
                     measParamAdjVarId = netcdf.defVar(fCdf, measParamAdjName, 'NC_FLOAT', nMeasurementDimId);
                     
                     if (~isempty(measParam.longName))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'long_name', measParam.longName);
                     end
                     if (~isempty(measParam.standardName))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'standard_name', measParam.standardName);
                     end
                     if (~isempty(measParam.fillValue))
                        netcdf.putAtt(fCdf, measParamAdjVarId, '_FillValue', measParam.fillValue);
                     end
                     if (~isempty(measParam.units))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'units', measParam.units);
                     end
                     if (~isempty(measParam.validMin))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'valid_min', measParam.validMin);
                     end
                     if (~isempty(measParam.validMax))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'valid_max', measParam.validMax);
                     end
                     if (~isempty(measParam.cFormat))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'C_format', measParam.cFormat);
                     end
                     if (~isempty(measParam.fortranFormat))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'FORTRAN_format', measParam.fortranFormat);
                     end
                     
                     [resNominal, resComment] = get_param_comment_on_resolution(measParamAdjName, a_decoderId);
                     if (isempty(resNominal))
                        if (~isempty(measParam.resolution))
                           netcdf.putAtt(fCdf, measParamAdjVarId, 'resolution', measParam.resolution);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'resolution', resNominal);
                     end
                     if (~isempty(resComment))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'comment_on_resolution', resComment);
                     end
                     
                     if (~isempty(measParam.axis))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'axis', measParam.axis);
                     end
                  end
                  
                  % parameter adjusted QC variable and attributes
                  measParamAdjQcName = sprintf('%s_ADJUSTED_QC', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamAdjQcName))
                     
                     measParamAdjQcVarId = netcdf.defVar(fCdf, measParamAdjQcName, 'NC_CHAR', nMeasurementDimId);
                     
                     netcdf.putAtt(fCdf, measParamAdjQcVarId, 'long_name', 'quality flag');
                     netcdf.putAtt(fCdf, measParamAdjQcVarId, 'conventions', 'Argo reference table 2');
                     netcdf.putAtt(fCdf, measParamAdjQcVarId, '_FillValue', ' ');
                  end
                  
                  % parameter adjusted error variable and attributes
                  measParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamAdjErrName))
                     
                     measParamAdjErrVarId = netcdf.defVar(fCdf, measParamAdjErrName, 'NC_FLOAT', nMeasurementDimId);
                     
                     netcdf.putAtt(fCdf, measParamAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
                     if (~isempty(measParam.fillValue))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, '_FillValue', measParam.fillValue);
                     end
                     if (~isempty(measParam.units))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'units', measParam.units);
                     end
                     if (~isempty(measParam.cFormat))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'C_format', measParam.cFormat);
                     end
                     if (~isempty(measParam.fortranFormat))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'FORTRAN_format', measParam.fortranFormat);
                     end
                     
                     [resNominal, resComment] = get_param_comment_on_resolution(measParamAdjErrName, a_decoderId);
                     if (isempty(resNominal))
                        if (~isempty(measParam.resolution))
                           netcdf.putAtt(fCdf, measParamAdjErrVarId, 'resolution', measParam.resolution);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'resolution', resNominal);
                     end
                     if (~isempty(resComment))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'comment_on_resolution', resComment);
                     end
                  end
               end
            end
         end
      end
   end
end

% add mandatory parameter variables
for idParam = 1:length(measAddParamName)
   
   measParamName = measAddParamName{idParam};
   
   % create parameter variable and attributes
   if (~var_is_present_dec_argo(fCdf, measParamName))
      
      measParamVarId = netcdf.defVar(fCdf, measParamName, 'NC_FLOAT', nMeasurementDimId);
      measParam = get_netcdf_param_attributes(measParamName);
      
      if (~isempty(measParam.longName))
         netcdf.putAtt(fCdf, measParamVarId, 'long_name', measParam.longName);
      end
      if (~isempty(measParam.standardName))
         netcdf.putAtt(fCdf, measParamVarId, 'standard_name', measParam.standardName);
      end
      if (~isempty(measParam.fillValue))
         netcdf.putAtt(fCdf, measParamVarId, '_FillValue', measParam.fillValue);
      end
      if (~isempty(measParam.units))
         netcdf.putAtt(fCdf, measParamVarId, 'units', measParam.units);
      end
      if (~isempty(measParam.validMin))
         netcdf.putAtt(fCdf, measParamVarId, 'valid_min', measParam.validMin);
      end
      if (~isempty(measParam.validMax))
         netcdf.putAtt(fCdf, measParamVarId, 'valid_max', measParam.validMax);
      end
      if (~isempty(measParam.cFormat))
         netcdf.putAtt(fCdf, measParamVarId, 'C_format', measParam.cFormat);
      end
      if (~isempty(measParam.fortranFormat))
         netcdf.putAtt(fCdf, measParamVarId, 'FORTRAN_format', measParam.fortranFormat);
      end
      
      [resNominal, resComment] = get_param_comment_on_resolution(measParamName, a_decoderId);
      if (isempty(resNominal))
         if (~isempty(measParam.resolution))
            netcdf.putAtt(fCdf, measParamVarId, 'resolution', measParam.resolution);
         end
      else
         netcdf.putAtt(fCdf, measParamVarId, 'resolution', resNominal);
      end
      if (~isempty(resComment))
         netcdf.putAtt(fCdf, measParamVarId, 'comment_on_resolution', resComment);
      end
      
      if (~isempty(measParam.axis))
         netcdf.putAtt(fCdf, measParamVarId, 'axis', measParam.axis);
      end
   end
   
   % parameter QC variable and attributes
   measParamQcName = sprintf('%s_QC', measParamName);
   if (~var_is_present_dec_argo(fCdf, measParamQcName))
      
      measParamQcVarId = netcdf.defVar(fCdf, measParamQcName, 'NC_CHAR', nMeasurementDimId);
      
      netcdf.putAtt(fCdf, measParamQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, measParamQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, measParamQcVarId, '_FillValue', ' ');
   end
   
   if (measParam.adjAllowed == 1)
      % parameter adjusted variable and attributes
      measParamAdjName = sprintf('%s_ADJUSTED', measParamName);
      if (~var_is_present_dec_argo(fCdf, measParamAdjName))
         
         measParamAdjVarId = netcdf.defVar(fCdf, measParamAdjName, 'NC_FLOAT', nMeasurementDimId);
         
         if (~isempty(measParam.longName))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'long_name', measParam.longName);
         end
         if (~isempty(measParam.standardName))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'standard_name', measParam.standardName);
         end
         if (~isempty(measParam.fillValue))
            netcdf.putAtt(fCdf, measParamAdjVarId, '_FillValue', measParam.fillValue);
         end
         if (~isempty(measParam.units))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'units', measParam.units);
         end
         if (~isempty(measParam.validMin))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'valid_min', measParam.validMin);
         end
         if (~isempty(measParam.validMax))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'valid_max', measParam.validMax);
         end
         if (~isempty(measParam.cFormat))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'C_format', measParam.cFormat);
         end
         if (~isempty(measParam.fortranFormat))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'FORTRAN_format', measParam.fortranFormat);
         end
         
         [resNominal, resComment] = get_param_comment_on_resolution(measParamAdjName, a_decoderId);
         if (isempty(resNominal))
            if (~isempty(measParam.resolution))
               netcdf.putAtt(fCdf, measParamAdjVarId, 'resolution', measParam.resolution);
            end
         else
            netcdf.putAtt(fCdf, measParamAdjVarId, 'resolution', resNominal);
         end
         if (~isempty(resComment))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'comment_on_resolution', resComment);
         end
         
         if (~isempty(measParam.axis))
            netcdf.putAtt(fCdf, measParamAdjVarId, 'axis', measParam.axis);
         end
      end
      
      % parameter adjusted QC variable and attributes
      measParamAdjQcName = sprintf('%s_ADJUSTED_QC', measParamName);
      if (~var_is_present_dec_argo(fCdf, measParamAdjQcName))
         
         measParamAdjQcVarId = netcdf.defVar(fCdf, measParamAdjQcName, 'NC_CHAR', nMeasurementDimId);
         
         netcdf.putAtt(fCdf, measParamAdjQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, measParamAdjQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, measParamAdjQcVarId, '_FillValue', ' ');
      end
      
      % parameter adjusted error variable and attributes
      measParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', measParamName);
      if (~var_is_present_dec_argo(fCdf, measParamAdjErrName))
         
         measParamAdjErrVarId = netcdf.defVar(fCdf, measParamAdjErrName, 'NC_FLOAT', nMeasurementDimId);
         
         netcdf.putAtt(fCdf, measParamAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
         if (~isempty(measParam.fillValue))
            netcdf.putAtt(fCdf, measParamAdjErrVarId, '_FillValue', measParam.fillValue);
         end
         if (~isempty(measParam.units))
            netcdf.putAtt(fCdf, measParamAdjErrVarId, 'units', measParam.units);
         end
         if (~isempty(measParam.cFormat))
            netcdf.putAtt(fCdf, measParamAdjErrVarId, 'C_format', measParam.cFormat);
         end
         if (~isempty(measParam.fortranFormat))
            netcdf.putAtt(fCdf, measParamAdjErrVarId, 'FORTRAN_format', measParam.fortranFormat);
         end
         
         [resNominal, resComment] = get_param_comment_on_resolution(measParamAdjErrName, a_decoderId);
         if (isempty(resNominal))
            if (~isempty(measParam.resolution))
               netcdf.putAtt(fCdf, measParamAdjErrVarId, 'resolution', measParam.resolution);
            end
         else
            netcdf.putAtt(fCdf, measParamAdjErrVarId, 'resolution', resNominal);
         end
         if (~isempty(resComment))
            netcdf.putAtt(fCdf, measParamAdjErrVarId, 'comment_on_resolution', resComment);
         end
      end
   end
end

% cycle information from the float
% N_CYCLE variables

juldDescentStartVarId = netcdf.defVar(fCdf, 'JULD_DESCENT_START', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldDescentStartVarId, 'long_name', 'Descent start date of the cycle');
netcdf.putAtt(fCdf, juldDescentStartVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldDescentStartVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldDescentStartVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_DESCENT_START', a_decoderId);
netcdf.putAtt(fCdf, juldDescentStartVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldDescentStartVarId, '_FillValue', double(999999));

juldDescentStartStatusVarId = netcdf.defVar(fCdf, 'JULD_DESCENT_START_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldDescentStartStatusVarId, 'long_name', 'Status of descent start date of the cycle');
netcdf.putAtt(fCdf, juldDescentStartStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldDescentStartStatusVarId, '_FillValue', ' ');

juldFirstStabilizationVarId = netcdf.defVar(fCdf, 'JULD_FIRST_STABILIZATION', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldFirstStabilizationVarId, 'long_name', 'Time when a float first becomes water-neutral');
netcdf.putAtt(fCdf, juldFirstStabilizationVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldFirstStabilizationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldFirstStabilizationVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_FIRST_STABILIZATION', a_decoderId);
netcdf.putAtt(fCdf, juldFirstStabilizationVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldFirstStabilizationVarId, '_FillValue', double(999999));

juldFirstStabilizationStatusVarId = netcdf.defVar(fCdf, 'JULD_FIRST_STABILIZATION_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldFirstStabilizationStatusVarId, 'long_name', 'Status of time when a float first becomes water-neutral');
netcdf.putAtt(fCdf, juldFirstStabilizationStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldFirstStabilizationStatusVarId, '_FillValue', ' ');

juldDescentEndVarId = netcdf.defVar(fCdf, 'JULD_DESCENT_END', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldDescentEndVarId, 'long_name', 'Descent end date of the cycle');
netcdf.putAtt(fCdf, juldDescentEndVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldDescentEndVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldDescentEndVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_DESCENT_END', a_decoderId);
netcdf.putAtt(fCdf, juldDescentEndVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldDescentEndVarId, '_FillValue', double(999999));

juldDescentEndStatusVarId = netcdf.defVar(fCdf, 'JULD_DESCENT_END_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldDescentEndStatusVarId, 'long_name', 'Status of descent end date of the cycle');
netcdf.putAtt(fCdf, juldDescentEndStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldDescentEndStatusVarId, '_FillValue', ' ');

juldParkStartVarId = netcdf.defVar(fCdf, 'JULD_PARK_START', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldParkStartVarId, 'long_name', 'Drift start date of the cycle');
netcdf.putAtt(fCdf, juldParkStartVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldParkStartVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldParkStartVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_PARK_START', a_decoderId);
netcdf.putAtt(fCdf, juldParkStartVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldParkStartVarId, '_FillValue', double(999999));

juldParkStartStatusVarId = netcdf.defVar(fCdf, 'JULD_PARK_START_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldParkStartStatusVarId, 'long_name', 'Status of drift start date of the cycle');
netcdf.putAtt(fCdf, juldParkStartStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldParkStartStatusVarId, '_FillValue', ' ');

juldParkEndVarId = netcdf.defVar(fCdf, 'JULD_PARK_END', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldParkEndVarId, 'long_name', 'Drift end date of the cycle');
netcdf.putAtt(fCdf, juldParkEndVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldParkEndVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldParkEndVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_PARK_END', a_decoderId);
netcdf.putAtt(fCdf, juldParkEndVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldParkEndVarId, '_FillValue', double(999999));

juldParkEndStatusVarId = netcdf.defVar(fCdf, 'JULD_PARK_END_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldParkEndStatusVarId, 'long_name', 'Status of drift end date of the cycle');
netcdf.putAtt(fCdf, juldParkEndStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldParkEndStatusVarId, '_FillValue', ' ');

juldDeepDescentEndVarId = netcdf.defVar(fCdf, 'JULD_DEEP_DESCENT_END', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldDeepDescentEndVarId, 'long_name', 'Deep descent end date of the cycle');
netcdf.putAtt(fCdf, juldDeepDescentEndVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldDeepDescentEndVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldDeepDescentEndVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_DEEP_DESCENT_END', a_decoderId);
netcdf.putAtt(fCdf, juldDeepDescentEndVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldDeepDescentEndVarId, '_FillValue', double(999999));

juldDeepDescentEndStatusVarId = netcdf.defVar(fCdf, 'JULD_DEEP_DESCENT_END_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldDeepDescentEndStatusVarId, 'long_name', 'Status of deep descent end date of the cycle');
netcdf.putAtt(fCdf, juldDeepDescentEndStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldDeepDescentEndStatusVarId, '_FillValue', ' ');

juldDeepParkStartVarId = netcdf.defVar(fCdf, 'JULD_DEEP_PARK_START', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldDeepParkStartVarId, 'long_name', 'Deep park start date of the cycle');
netcdf.putAtt(fCdf, juldDeepParkStartVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldDeepParkStartVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldDeepParkStartVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_DEEP_PARK_START', a_decoderId);
netcdf.putAtt(fCdf, juldDeepParkStartVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldDeepParkStartVarId, '_FillValue', double(999999));

juldDeepParkStartStatusVarId = netcdf.defVar(fCdf, 'JULD_DEEP_PARK_START_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldDeepParkStartStatusVarId, 'long_name', 'Status of deep park start date of the cycle');
netcdf.putAtt(fCdf, juldDeepParkStartStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldDeepParkStartStatusVarId, '_FillValue', ' ');

juldAscentStartVarId = netcdf.defVar(fCdf, 'JULD_ASCENT_START', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldAscentStartVarId, 'long_name', 'Start date of the ascent to the surface');
netcdf.putAtt(fCdf, juldAscentStartVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldAscentStartVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldAscentStartVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_ASCENT_START', a_decoderId);
netcdf.putAtt(fCdf, juldAscentStartVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldAscentStartVarId, '_FillValue', double(999999));

juldAscentStartStatusVarId = netcdf.defVar(fCdf, 'JULD_ASCENT_START_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldAscentStartStatusVarId, 'long_name', 'Status of start date of the ascent to the surface');
netcdf.putAtt(fCdf, juldAscentStartStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldAscentStartStatusVarId, '_FillValue', ' ');

juldDeepAscentStartVarId = netcdf.defVar(fCdf, 'JULD_DEEP_ASCENT_START', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldDeepAscentStartVarId, 'long_name', 'Deep ascent start date of the cycle');
netcdf.putAtt(fCdf, juldDeepAscentStartVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldDeepAscentStartVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldDeepAscentStartVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_DEEP_ASCENT_START', a_decoderId);
netcdf.putAtt(fCdf, juldDeepAscentStartVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldDeepAscentStartVarId, '_FillValue', double(999999));

juldDeepAscentStartStatusVarId = netcdf.defVar(fCdf, 'JULD_DEEP_ASCENT_START_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldDeepAscentStartStatusVarId, 'long_name', 'Status of deep ascent start date of the cycle');
netcdf.putAtt(fCdf, juldDeepAscentStartStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldDeepAscentStartStatusVarId, '_FillValue', ' ');

juldAscentEndVarId = netcdf.defVar(fCdf, 'JULD_ASCENT_END', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldAscentEndVarId, 'long_name', 'End date of ascent to the surface');
netcdf.putAtt(fCdf, juldAscentEndVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldAscentEndVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldAscentEndVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_ASCENT_END', a_decoderId);
netcdf.putAtt(fCdf, juldAscentEndVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldAscentEndVarId, '_FillValue', double(999999));

juldAscentEndStatusVarId = netcdf.defVar(fCdf, 'JULD_ASCENT_END_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldAscentEndStatusVarId, 'long_name', 'Status of end date of ascent to the surface');
netcdf.putAtt(fCdf, juldAscentEndStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldAscentEndStatusVarId, '_FillValue', ' ');

juldTransmissionStartVarId = netcdf.defVar(fCdf, 'JULD_TRANSMISSION_START', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldTransmissionStartVarId, 'long_name', 'Start date of transmission');
netcdf.putAtt(fCdf, juldTransmissionStartVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldTransmissionStartVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldTransmissionStartVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_TRANSMISSION_START', a_decoderId);
netcdf.putAtt(fCdf, juldTransmissionStartVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldTransmissionStartVarId, '_FillValue', double(999999));

juldTransmissionStartStatusVarId = netcdf.defVar(fCdf, 'JULD_TRANSMISSION_START_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldTransmissionStartStatusVarId, 'long_name', 'Status of start date of transmission');
netcdf.putAtt(fCdf, juldTransmissionStartStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldTransmissionStartStatusVarId, '_FillValue', ' ');

juldFirstMessageVarId = netcdf.defVar(fCdf, 'JULD_FIRST_MESSAGE', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldFirstMessageVarId, 'long_name', 'Date of earliest float message received');
netcdf.putAtt(fCdf, juldFirstMessageVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldFirstMessageVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldFirstMessageVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_FIRST_MESSAGE', a_decoderId);
netcdf.putAtt(fCdf, juldFirstMessageVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldFirstMessageVarId, '_FillValue', double(999999));

juldFirstMessageStatusVarId = netcdf.defVar(fCdf, 'JULD_FIRST_MESSAGE_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldFirstMessageStatusVarId, 'long_name', 'Status of date of earliest float message received');
netcdf.putAtt(fCdf, juldFirstMessageStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldFirstMessageStatusVarId, '_FillValue', ' ');

juldFirstLocationVarId = netcdf.defVar(fCdf, 'JULD_FIRST_LOCATION', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldFirstLocationVarId, 'long_name', 'Date of earliest location');
netcdf.putAtt(fCdf, juldFirstLocationVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldFirstLocationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldFirstLocationVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_FIRST_LOCATION', a_decoderId);
netcdf.putAtt(fCdf, juldFirstLocationVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldFirstLocationVarId, '_FillValue', double(999999));

juldFirstLocationStatusVarId = netcdf.defVar(fCdf, 'JULD_FIRST_LOCATION_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldFirstLocationStatusVarId, 'long_name', 'Status of date of earliest location');
netcdf.putAtt(fCdf, juldFirstLocationStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldFirstLocationStatusVarId, '_FillValue', ' ');

juldLastLocationVarId = netcdf.defVar(fCdf, 'JULD_LAST_LOCATION', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldLastLocationVarId, 'long_name', 'Date of latest location');
netcdf.putAtt(fCdf, juldLastLocationVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldLastLocationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldLastLocationVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_LAST_LOCATION', a_decoderId);
netcdf.putAtt(fCdf, juldLastLocationVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldLastLocationVarId, '_FillValue', double(999999));

juldLastLocationStatusVarId = netcdf.defVar(fCdf, 'JULD_LAST_LOCATION_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldLastLocationStatusVarId, 'long_name', 'Status of date of latest location');
netcdf.putAtt(fCdf, juldLastLocationStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldLastLocationStatusVarId, '_FillValue', ' ');

juldLastMessageVarId = netcdf.defVar(fCdf, 'JULD_LAST_MESSAGE', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldLastMessageVarId, 'long_name', 'Date of latest float message received');
netcdf.putAtt(fCdf, juldLastMessageVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldLastMessageVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldLastMessageVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_LAST_MESSAGE', a_decoderId);
netcdf.putAtt(fCdf, juldLastMessageVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldLastMessageVarId, '_FillValue', double(999999));

juldLastMessageStatusVarId = netcdf.defVar(fCdf, 'JULD_LAST_MESSAGE_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldLastMessageStatusVarId, 'long_name', 'Status of date of latest float message received');
netcdf.putAtt(fCdf, juldLastMessageStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldLastMessageStatusVarId, '_FillValue', ' ');

juldTransmissionEndVarId = netcdf.defVar(fCdf, 'JULD_TRANSMISSION_END', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, juldTransmissionEndVarId, 'long_name', 'Transmission end date');
netcdf.putAtt(fCdf, juldTransmissionEndVarId, 'standard_name', 'time');
netcdf.putAtt(fCdf, juldTransmissionEndVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
netcdf.putAtt(fCdf, juldTransmissionEndVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
[resNominal, resComment] = get_param_comment_on_resolution('JULD_TRANSMISSION_END', a_decoderId);
netcdf.putAtt(fCdf, juldTransmissionEndVarId, 'resolution', resNominal);
netcdf.putAtt(fCdf, juldTransmissionEndVarId, '_FillValue', double(999999));

juldTransmissionEndStatusVarId = netcdf.defVar(fCdf, 'JULD_TRANSMISSION_END_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, juldTransmissionEndStatusVarId, 'long_name', 'Status of transmission end date');
netcdf.putAtt(fCdf, juldTransmissionEndStatusVarId, 'conventions', 'Argo reference table 19');
netcdf.putAtt(fCdf, juldTransmissionEndStatusVarId, '_FillValue', ' ');

clockOffsetVarId = netcdf.defVar(fCdf, 'CLOCK_OFFSET', 'NC_DOUBLE', nCycleDimId);
netcdf.putAtt(fCdf, clockOffsetVarId, 'long_name', 'Time of float clock drift');
netcdf.putAtt(fCdf, clockOffsetVarId, 'units', 'days');
netcdf.putAtt(fCdf, clockOffsetVarId, 'conventions', 'Days with decimal part (as parts of day)');
netcdf.putAtt(fCdf, clockOffsetVarId, '_FillValue', double(999999));

groundedVarId = netcdf.defVar(fCdf, 'GROUNDED', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, groundedVarId, 'long_name', 'Did the profiler touch the ground for that cycle?');
netcdf.putAtt(fCdf, groundedVarId, 'conventions', 'Argo reference table 20');
netcdf.putAtt(fCdf, groundedVarId, '_FillValue', ' ');

rPPVarId = netcdf.defVar(fCdf, 'REPRESENTATIVE_PARK_PRESSURE', 'NC_FLOAT', nCycleDimId);
netcdf.putAtt(fCdf, rPPVarId, 'long_name', 'Best pressure value during park phase');
netcdf.putAtt(fCdf, rPPVarId, 'units', 'decibar');
netcdf.putAtt(fCdf, rPPVarId, '_FillValue', single(99999));

rPPStatusVarId = netcdf.defVar(fCdf, 'REPRESENTATIVE_PARK_PRESSURE_STATUS', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, rPPStatusVarId, 'long_name', 'Status of best pressure value during park phase');
netcdf.putAtt(fCdf, rPPStatusVarId, 'conventions', 'Argo reference table 21');
netcdf.putAtt(fCdf, rPPStatusVarId, '_FillValue', ' ');

configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nCycleDimId);
netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));

cycleNumberIndexVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_INDEX', 'NC_INT', nCycleDimId);
netcdf.putAtt(fCdf, cycleNumberIndexVarId, 'long_name', 'Cycle number that corresponds to the current index');
netcdf.putAtt(fCdf, cycleNumberIndexVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
netcdf.putAtt(fCdf, cycleNumberIndexVarId, '_FillValue', int32(99999));

cycleNumberIndexAdjustedVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_INDEX_ADJUSTED', 'NC_INT', nCycleDimId);
netcdf.putAtt(fCdf, cycleNumberIndexAdjustedVarId, 'long_name', 'Adjusted cycle number that corresponds to the current index');
netcdf.putAtt(fCdf, cycleNumberIndexAdjustedVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
netcdf.putAtt(fCdf, cycleNumberIndexAdjustedVarId, '_FillValue', int32(99999));

dataModeVarId = netcdf.defVar(fCdf, 'DATA_MODE', 'NC_CHAR', nCycleDimId);
netcdf.putAtt(fCdf, dataModeVarId, 'long_name', 'Delayed mode or real time data');
netcdf.putAtt(fCdf, dataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
netcdf.putAtt(fCdf, dataModeVarId, '_FillValue', ' ');

% history information
historyInstitutionVarId = netcdf.defVar(fCdf, 'HISTORY_INSTITUTION', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
netcdf.putAtt(fCdf, historyInstitutionVarId, 'long_name', 'Institution which performed action');
netcdf.putAtt(fCdf, historyInstitutionVarId, 'conventions', 'Argo reference table 4');
netcdf.putAtt(fCdf, historyInstitutionVarId, '_FillValue', ' ');

historyStepVarId = netcdf.defVar(fCdf, 'HISTORY_STEP', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
netcdf.putAtt(fCdf, historyStepVarId, 'long_name', 'Step in data processing');
netcdf.putAtt(fCdf, historyStepVarId, 'conventions', 'Argo reference table 12');
netcdf.putAtt(fCdf, historyStepVarId, '_FillValue', ' ');

historySoftwareVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
netcdf.putAtt(fCdf, historySoftwareVarId, 'long_name', 'Name of software which performed action');
netcdf.putAtt(fCdf, historySoftwareVarId, 'conventions', 'Institution dependent');
netcdf.putAtt(fCdf, historySoftwareVarId, '_FillValue', ' ');

historySoftwareReleaseVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE_RELEASE', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'long_name', 'Version/release of software which performed action');
netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'conventions', 'Institution dependent');
netcdf.putAtt(fCdf, historySoftwareReleaseVarId, '_FillValue', ' ');

historyReferenceVarId = netcdf.defVar(fCdf, 'HISTORY_REFERENCE', 'NC_CHAR', fliplr([nHistoryDimId string64DimId]));
netcdf.putAtt(fCdf, historyReferenceVarId, 'long_name', 'Reference of database');
netcdf.putAtt(fCdf, historyReferenceVarId, 'conventions', 'Institution dependent');
netcdf.putAtt(fCdf, historyReferenceVarId, '_FillValue', ' ');

historyDateVarId = netcdf.defVar(fCdf, 'HISTORY_DATE', 'NC_CHAR', fliplr([nHistoryDimId dateTimeDimId]));
netcdf.putAtt(fCdf, historyDateVarId, 'long_name', 'Date the history record was created');
netcdf.putAtt(fCdf, historyDateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, historyDateVarId, '_FillValue', ' ');

historyActionVarId = netcdf.defVar(fCdf, 'HISTORY_ACTION', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
netcdf.putAtt(fCdf, historyActionVarId, 'long_name', 'Action performed on data');
netcdf.putAtt(fCdf, historyActionVarId, 'conventions', 'Argo reference table 7');
netcdf.putAtt(fCdf, historyActionVarId, '_FillValue', ' ');

historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId string16DimId]));
netcdf.putAtt(fCdf, historyParameterVarId, 'long_name', 'Station parameter action is performed on');
netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Argo reference table 3');
netcdf.putAtt(fCdf, historyParameterVarId, '_FillValue', ' ');

historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', nHistoryDimId);
netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));

historyIndexDimensionVarId = netcdf.defVar(fCdf, 'HISTORY_INDEX_DIMENSION', 'NC_CHAR', nHistoryDimId);
netcdf.putAtt(fCdf, historyIndexDimensionVarId, 'long_name', 'Name of dimension to which HISTORY_START_INDEX and HISTORY_STOP_INDEX correspond');
netcdf.putAtt(fCdf, historyIndexDimensionVarId, 'conventions', 'C: N_CYCLE, M: N_MEASUREMENT');
netcdf.putAtt(fCdf, historyIndexDimensionVarId, '_FillValue', ' ');

historyStartIndexVarId = netcdf.defVar(fCdf, 'HISTORY_START_INDEX', 'NC_INT', nHistoryDimId);
netcdf.putAtt(fCdf, historyStartIndexVarId, 'long_name', 'Start index action applied on');
netcdf.putAtt(fCdf, historyStartIndexVarId, '_FillValue', int32(99999));

historyStopIndexVarId = netcdf.defVar(fCdf, 'HISTORY_STOP_INDEX', 'NC_INT', nHistoryDimId);
netcdf.putAtt(fCdf, historyStopIndexVarId, 'long_name', 'Stop index action applied on');
netcdf.putAtt(fCdf, historyStopIndexVarId, '_FillValue', int32(99999));

historyQcTestVarId = netcdf.defVar(fCdf, 'HISTORY_QCTEST', 'NC_CHAR', fliplr([nHistoryDimId string16DimId]));
netcdf.putAtt(fCdf, historyQcTestVarId, 'long_name', 'Documentation of tests performed, tests failed (in hex form)');
netcdf.putAtt(fCdf, historyQcTestVarId, 'conventions', 'Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
netcdf.putAtt(fCdf, historyQcTestVarId, '_FillValue', ' ');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % DEFINE MODE END
if (VERBOSE_MODE == 2)
   fprintf('STOP DEFINE MODE\n');
end

netcdf.endDef(fCdf);

% general information on the trajectory file
valueStr = 'Argo trajectory';
netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);

valueStr = '3.1';
netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);

valueStr = '1.2';
netcdf.putVar(fCdf, handbookVersionVarId, 0, length(valueStr), valueStr);

netcdf.putVar(fCdf, referenceDateTimeVarId, '19500101000000');

if (isempty(ncCreationDate))
   netcdf.putVar(fCdf, dateCreationVarId, currentDate);
else
   netcdf.putVar(fCdf, dateCreationVarId, ncCreationDate);
end

netcdf.putVar(fCdf, dateUpdateVarId, currentDate);

% general information on the float
valueStr = sprintf('%d', g_decArgo_floatNum);
netcdf.putVar(fCdf, platformNumberVarId, 0, length(valueStr), valueStr);

valueStr = ' ';
idVal = find(strcmp('PROJECT_NAME', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   valueStr = char(a_metaDataFromJson{idVal+1});
end
netcdf.putVar(fCdf, projectNameVarId, 0, length(valueStr), valueStr);

valueStr = ' ';
idVal = find(strcmp('PI_NAME', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   valueStr = char(a_metaDataFromJson{idVal+1});
end
netcdf.putVar(fCdf, piNameVarId, 0, length(valueStr), valueStr);

% add trajectory parameters
for idParam = 1:length(measUniqueParamName)
   valueStr = measUniqueParamName{idParam};
   
   if (length(valueStr) > paramNameLength)
      fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) => name truncated\n', ...
         g_decArgo_floatNum, valueStr, paramNameLength);
      valueStr = valueStr(1:paramNameLength);
   end
   
   netcdf.putVar(fCdf, trajectoryParametersVarId, ...
      fliplr([idParam-1  0]), fliplr([1 length(valueStr)]), valueStr');
end

% add mandatory trajectory parameters
for idParam = 1:length(measAddParamName)
   valueStr = measAddParamName{idParam};
   
   if (length(valueStr) > paramNameLength)
      fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) => name truncated\n', ...
         g_decArgo_floatNum, valueStr, paramNameLength);
      valueStr = valueStr(1:paramNameLength);
   end
   
   netcdf.putVar(fCdf, trajectoryParametersVarId, ...
      fliplr([idParam-1  0]), fliplr([1 length(valueStr)]), valueStr');
end

valueStr = ' ';
idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   valueStr = char(a_metaDataFromJson{idVal+1});
end
netcdf.putVar(fCdf, dataCentreVarId, 0, length(valueStr), valueStr);

valueStr = '1A';
netcdf.putVar(fCdf, dataStateIndicatorVarId, 0, length(valueStr), valueStr);

valueStr = get_platform_type(a_decoderId);
valueStr = [valueStr blanks(32-length(valueStr))];
netcdf.putVar(fCdf, platformTypeVarId, 0, length(valueStr), valueStr);

valueStr = ' ';
idVal = find(strcmp('FLOAT_SERIAL_NO', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   valueStr = char(a_metaDataFromJson{idVal+1});
end
netcdf.putVar(fCdf, floatSerialNoVarId, 0, length(valueStr), valueStr);

valueStr = ' ';
idVal = find(strcmp('FIRMWARE_VERSION', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   valueStr = char(a_metaDataFromJson{idVal+1});
end
netcdf.putVar(fCdf, firmwareVersionVarId, 0, length(valueStr), valueStr);

valueStr = get_wmo_instrument_type(a_decoderId);
netcdf.putVar(fCdf, wmoInstTypeVarId, 0, length(valueStr), valueStr);

valueStr = get_positioning_system(a_decoderId);
netcdf.putVar(fCdf, positioningSystemVarId, 0, length(valueStr), valueStr);

% copy existing history information
if (~isempty(histoInstitution))
   if (length(ncDataMode) <= length(cycles))
      netcdf.putVar(fCdf, historyInstitutionVarId, ...
         fliplr([0 0]), fliplr([size(histoInstitution, 2) size(histoInstitution, 1)]), histoInstitution);
      netcdf.putVar(fCdf, historyStepVarId, ...
         fliplr([0 0]), fliplr([size(histoStep, 2) size(histoStep, 1)]), histoStep);
      netcdf.putVar(fCdf, historySoftwareVarId, ...
         fliplr([0 0]), fliplr([size(histoSoftware, 2) size(histoSoftware, 1)]), histoSoftware);
      netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
         fliplr([0 0]), fliplr([size(histoSoftwareRelease, 2) size(histoSoftwareRelease, 1)]), histoSoftwareRelease);
      netcdf.putVar(fCdf, historyDateVarId, ...
         fliplr([0 0]), fliplr([size(histoDate, 2) size(histoDate, 1)]), histoDate);
   else
      fprintf('WARNING: Float #%d : N_CYCLE=%d in existing file, N_CYCLE=%d in updated file => history information not copied when updating file %s\n', ...
         g_decArgo_floatNum, length(ncDataMode), length(cycles), ncPathFileName);
   end
end

% N_MEASUREMENT data
measPos = 0;
for idNM = 1:length(a_tabTrajNMeas)
   nMeas = a_tabTrajNMeas(idNM);
   
   % find the cycle data mode
   adjustedCycle = 0;
   if (~isempty(a_tabTrajNCycle))
      idF = find([a_tabTrajNCycle.cycleNumber] == nMeas.cycleNumber);
      if (~isempty(idF))
         %          if (a_tabTrajNCycle(idF).dataMode == 'A') % not enough for Remocean where length(idF) could be > 1
         if (any([a_tabTrajNCycle(idF).dataMode] == 'A'))
            adjustedCycle = 1;
         end
      end
   end

   for idM = 1:length(nMeas.tabMeas)
      meas = nMeas.tabMeas(idM);
      
      netcdf.putVar(fCdf, cycleNumberVarId, measPos, 1, nMeas.outputCycleNumber);
      netcdf.putVar(fCdf, measurementCodeVarId, measPos, 1, meas.measCode);
      
      if (~isempty(meas.juld))
         netcdf.putVar(fCdf, juldVarId, measPos, 1, meas.juld);
      end
      if (~isempty(meas.juldStatus))
         netcdf.putVar(fCdf, juldStatusVarId, measPos, 1, meas.juldStatus);
      end
      if (~isempty(meas.juldQc))
         netcdf.putVar(fCdf, juldQcVarId, measPos, 1, meas.juldQc);
      end
      if (~isempty(meas.juldAdj))
         netcdf.putVar(fCdf, juldAdjustedVarId, measPos, 1, meas.juldAdj);
      end
      if (~isempty(meas.juldAdjStatus))
         netcdf.putVar(fCdf, juldAdjustedStatusVarId, measPos, 1, meas.juldAdjStatus);
      end
      if (~isempty(meas.juldAdjQc))
         netcdf.putVar(fCdf, juldAdjustedQcVarId, measPos, 1, meas.juldAdjQc);
      end
      if (~isempty(meas.latitude))
         netcdf.putVar(fCdf, latitudeVarId, measPos, 1, meas.latitude);
      end
      if (~isempty(meas.longitude))
         netcdf.putVar(fCdf, longitudeVarId, measPos, 1, meas.longitude);
      end
      if (~isempty(meas.posAccuracy))
         netcdf.putVar(fCdf, positionAccuracyVarId, measPos, 1, meas.posAccuracy);
      end
      if (~isempty(meas.posQc))
         netcdf.putVar(fCdf, positionQcVarId, measPos, 1, meas.posQc);
      end
      if (~isempty(meas.satelliteName))
         netcdf.putVar(fCdf, satelliteNameVarId, measPos, 1, meas.satelliteName);
      end
      
      % parameters
      measParamList = meas.paramList;
      for idParam = 1:length(measParamList)
         
         if (measParamList(idParam).paramType == 'c')
            
            measParam = measParamList(idParam);
            
            measParamName = measParam.name;
            measParamVarId = netcdf.inqVarID(fCdf, measParamName);
            
            measParamQcName = sprintf('%s_QC', measParamName);
            measParamQcVarId = netcdf.inqVarID(fCdf, measParamQcName);
            
            if (measParam.adjAllowed == 1)
               % parameter adjusted variable and attributes
               measParamAdjName = sprintf('%s_ADJUSTED', measParam.name);
               measParamAdjVarId = netcdf.inqVarID(fCdf, measParamAdjName);
               
               % parameter adjusted QC variable and attributes
               measParamAdjQcName = sprintf('%s_ADJUSTED_QC', measParam.name);
               measParamAdjQcVarId = netcdf.inqVarID(fCdf, measParamAdjQcName);
            end
            
            % parameter data
            paramData = meas.paramData(:, idParam);
            
            % store the data
            netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
            
            if (isempty(meas.paramDataQc))
               paramDataQcStr = repmat(' ', size(paramData, 1), 1);
               paramDataQcStr(find(paramData ~= measParam.fillValue)) = '0';
            else
               paramDataQc = meas.paramDataQc(:, idParam);
               if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                  paramDataQcStr = repmat(' ', size(paramData, 1), 1);
                  paramDataQcStr(find(paramData ~= measParam.fillValue)) = '0';
               else
                  paramDataQcStr = repmat(' ', length(paramDataQc), 1);
                  idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                  paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
               end
            end
            netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
            
            % RT PRES adjustment of Apex float
            if (adjustedCycle == 1)
               
               % process RT adjustment of this parameter
               paramAdjData = paramData;
               if (strcmp(measParamName, 'PRES') && ~isempty(meas.presOffset))
                  [paramAdjData] = compute_adjusted_pres(paramData, meas.presOffset);
               end
               
               % store the data
               netcdf.putVar(fCdf, measParamAdjVarId, measPos, size(paramAdjData, 1), paramAdjData);
               
               if (isempty(meas.paramDataQc))
                  paramAdjDataQcStr = repmat(' ', size(paramAdjData, 1), 1);
                  paramAdjDataQcStr(find(paramAdjData ~= measParam.fillValue)) = '0';
               else
                  paramAdjDataQc = meas.paramDataQc(:, idParam);
                  if ((length(unique(paramAdjDataQc)) == 1) && (unique(paramAdjDataQc) == g_decArgo_qcDef))
                     paramAdjDataQcStr = repmat(' ', size(paramAdjData, 1), 1);
                     paramAdjDataQcStr(find(paramAdjData ~= measParam.fillValue)) = '0';
                  else
                     paramAdjDataQcStr = repmat(' ', length(paramAdjDataQc), 1);
                     idNoDef = find(paramAdjDataQc ~= g_decArgo_qcDef);
                     paramAdjDataQcStr(idNoDef) = num2str(paramAdjDataQc(idNoDef));
                  end
               end
               netcdf.putVar(fCdf, measParamAdjQcVarId, measPos, size(paramAdjData, 1), paramAdjDataQcStr);
            end
         end
      end
      measPos = measPos + 1;
   end
end

% N_CYCLE data
if (~isempty(cycles))
   for idNC = 1:length(a_tabTrajNCycle)
      nCycle = a_tabTrajNCycle(idNC);
      
      idC = find(cycles == nCycle.outputCycleNumber);
      
      if (~isempty(nCycle.juldDescentStart))
         netcdf.putVar(fCdf, juldDescentStartVarId, idC-1, 1, nCycle.juldDescentStart);
      end
      if (~isempty(nCycle.juldDescentStartStatus))
         netcdf.putVar(fCdf, juldDescentStartStatusVarId, idC-1, 1, nCycle.juldDescentStartStatus);
      end
      if (~isempty(nCycle.juldFirstStab))
         netcdf.putVar(fCdf, juldFirstStabilizationVarId, idC-1, 1, nCycle.juldFirstStab);
      end
      if (~isempty(nCycle.juldFirstStabStatus))
         netcdf.putVar(fCdf, juldFirstStabilizationStatusVarId, idC-1, 1, nCycle.juldFirstStabStatus);
      end
      if (~isempty(nCycle.juldParkStart))
         netcdf.putVar(fCdf, juldParkStartVarId, idC-1, 1, nCycle.juldParkStart);
      end
      if (~isempty(nCycle.juldParkStartStatus))
         netcdf.putVar(fCdf, juldParkStartStatusVarId, idC-1, 1, nCycle.juldParkStartStatus);
      end
      if (~isempty(nCycle.juldParkEnd))
         netcdf.putVar(fCdf, juldParkEndVarId, idC-1, 1, nCycle.juldParkEnd);
      end
      if (~isempty(nCycle.juldParkEndStatus))
         netcdf.putVar(fCdf, juldParkEndStatusVarId, idC-1, 1, nCycle.juldParkEndStatus);
      end
      if (~isempty(nCycle.juldDeepParkStart))
         netcdf.putVar(fCdf, juldDeepParkStartVarId, idC-1, 1, nCycle.juldDeepParkStart);
      end
      if (~isempty(nCycle.juldDeepParkStartStatus))
         netcdf.putVar(fCdf, juldDeepParkStartStatusVarId, idC-1, 1, nCycle.juldDeepParkStartStatus);
      end
      if (~isempty(nCycle.juldAscentStart))
         netcdf.putVar(fCdf, juldAscentStartVarId, idC-1, 1, nCycle.juldAscentStart);
      end
      if (~isempty(nCycle.juldAscentStartStatus))
         netcdf.putVar(fCdf, juldAscentStartStatusVarId, idC-1, 1, nCycle.juldAscentStartStatus);
      end
      if (~isempty(nCycle.juldAscentEnd))
         netcdf.putVar(fCdf, juldAscentEndVarId, idC-1, 1, nCycle.juldAscentEnd);
      end
      if (~isempty(nCycle.juldAscentEndStatus))
         netcdf.putVar(fCdf, juldAscentEndStatusVarId, idC-1, 1, nCycle.juldAscentEndStatus);
      end
      if (~isempty(nCycle.juldTransmissionStart))
         netcdf.putVar(fCdf, juldTransmissionStartVarId, idC-1, 1, nCycle.juldTransmissionStart);
      end
      if (~isempty(nCycle.juldTransmissionStartStatus))
         netcdf.putVar(fCdf, juldTransmissionStartStatusVarId, idC-1, 1, nCycle.juldTransmissionStartStatus);
      end
      if (~isempty(nCycle.juldFirstMessage))
         netcdf.putVar(fCdf, juldFirstMessageVarId, idC-1, 1, nCycle.juldFirstMessage);
      end
      if (~isempty(nCycle.juldFirstMessageStatus))
         netcdf.putVar(fCdf, juldFirstMessageStatusVarId, idC-1, 1, nCycle.juldFirstMessageStatus);
      end
      if (~isempty(nCycle.juldFirstLocation))
         netcdf.putVar(fCdf, juldFirstLocationVarId, idC-1, 1, nCycle.juldFirstLocation);
      end
      if (~isempty(nCycle.juldFirstLocationStatus))
         netcdf.putVar(fCdf, juldFirstLocationStatusVarId, idC-1, 1, nCycle.juldFirstLocationStatus);
      end
      if (~isempty(nCycle.juldLastLocation))
         netcdf.putVar(fCdf, juldLastLocationVarId, idC-1, 1, nCycle.juldLastLocation);
      end
      if (~isempty(nCycle.juldLastLocationStatus))
         netcdf.putVar(fCdf, juldLastLocationStatusVarId, idC-1, 1, nCycle.juldLastLocationStatus);
      end
      if (~isempty(nCycle.juldLastMessage))
         netcdf.putVar(fCdf, juldLastMessageVarId, idC-1, 1, nCycle.juldLastMessage);
      end
      if (~isempty(nCycle.juldLastMessageStatus))
         netcdf.putVar(fCdf, juldLastMessageStatusVarId, idC-1, 1, nCycle.juldLastMessageStatus);
      end
      if (~isempty(nCycle.juldTransmissionEnd))
         netcdf.putVar(fCdf, juldTransmissionEndVarId, idC-1, 1, nCycle.juldTransmissionEnd);
      end
      if (~isempty(nCycle.juldTransmissionEndStatus))
         netcdf.putVar(fCdf, juldTransmissionEndStatusVarId, idC-1, 1, nCycle.juldTransmissionEndStatus);
      end
      if (~isempty(nCycle.clockOffset))
         netcdf.putVar(fCdf, clockOffsetVarId, idC-1, 1, nCycle.clockOffset);
      end
      if (~isempty(nCycle.grounded))
         netcdf.putVar(fCdf, groundedVarId, idC-1, 1, nCycle.grounded);
      end
      if (~isempty(nCycle.repParkPres))
         netcdf.putVar(fCdf, rPPVarId, idC-1, 1, nCycle.repParkPres);
      end
      if (~isempty(nCycle.repParkPresStatus))
         netcdf.putVar(fCdf, rPPStatusVarId, idC-1, 1, nCycle.repParkPresStatus);
      end
      if (~isempty(nCycle.outputCycleNumber))
         netcdf.putVar(fCdf, cycleNumberIndexVarId, idC-1, 1, nCycle.outputCycleNumber);
      end
      if (~isempty(nCycle.dataMode))
         netcdf.putVar(fCdf, dataModeVarId, idC-1, 1, nCycle.dataMode);
      end
      
      if (~isempty(nCycle.configMissionNumber))
         netcdf.putVar(fCdf, configMissionNumberVarId, idC-1, 1, nCycle.configMissionNumber);
      end
      
   end
else
   netcdf.putVar(fCdf, dataModeVarId, 0, 1, 'R');
end

% history information
currentHistoId = 0;
if (~isempty(histoInstitution))
   if (length(ncDataMode) <= length(cycles))
      currentHistoId = size(histoInstitution, 2);
   end
end
value = 'IF';
netcdf.putVar(fCdf, historyInstitutionVarId, ...
   fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
value = 'ARFM';
netcdf.putVar(fCdf, historyStepVarId, ...
   fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
value = 'CODA';
netcdf.putVar(fCdf, historySoftwareVarId, ...
   fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
value = g_decArgo_decoderVersion;
netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
   fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
value = currentDate;
netcdf.putVar(fCdf, historyDateVarId, ...
   fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');

netcdf.close(fCdf);

if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
   % store information for the XML report
   g_decArgo_reportStruct.outputTrajFiles = [g_decArgo_reportStruct.outputTrajFiles ...
      {ncPathFileName}];
end

fprintf('... NetCDF TRAJECTORY c file created\n');

return;
