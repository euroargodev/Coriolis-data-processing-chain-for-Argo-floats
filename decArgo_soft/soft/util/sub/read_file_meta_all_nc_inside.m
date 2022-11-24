% ------------------------------------------------------------------------------
% Lecture d'un fichier de méta données.
%
% SYNTAX :
%   [o_nCycles, o_nParam, ...
%    o_platformNumber, o_ptt, o_transSystem, o_transSystemId, o_transFrequency, ...
%    o_transRepetition, o_positioningSystem, o_clockDrift, o_platformModel, ...
%    o_platformMaker, o_instReference, o_wmoInstType, o_direction, o_projectName, ...
%    o_dataCentre, o_piName, o_anomaly, ...
%    o_launchDate, o_launchLatitude, o_launchLongitude, o_launchQc, o_startDate, ...
%    o_startDateQc, o_deployPlatform, o_deployMission, o_deployAvailableProfileId, ...
%    o_endMissionDate, o_endMissionStatus, ...
%    o_sensor, o_sensorMaker, o_sensorModel, o_sensorSerialNo, o_sensorUnits, ...
%    o_sensorAccuracy, o_sensorResolution, ...
%    o_parameter, o_predeploymentCalibEquation, o_predeploymentCalibCoefficient, ...
%    o_predeploymentCalibComment, ...
%    o_repetitionRate, o_cycleTime, o_parkingTime, o_descendingProfilingTime, ...
%    o_ascendingProfilingTime, o_surfaceTime, o_parkingPressure, o_deepestPressure, ...
%    o_deepestPressureDescending] = read_file_meta_all_nc_inside(a_fileName)
%
% INPUT PARAMETERS :
%   a_fileName : nom du fichier de meta données à lire
%
% OUTPUT PARAMETERS :
%   paramètres lus dans le fichier
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/03/2011 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nCycles, o_nParam, ...
   o_platformNumber, o_ptt, o_transSystem, o_transSystemId, o_transFrequency, ...
   o_transRepetition, o_positioningSystem, o_clockDrift, o_platformModel, ...
   o_platformMaker, o_instReference, o_wmoInstType, o_direction, o_projectName, ...
   o_dataCentre, o_piName, o_anomaly, ...
   o_launchDate, o_launchLatitude, o_launchLongitude, o_launchQc, o_startDate, ...
   o_startDateQc, o_deployPlatform, o_deployMission, o_deployAvailableProfileId, ...
   o_endMissionDate, o_endMissionStatus, ...
   o_sensor, o_sensorMaker, o_sensorModel, o_sensorSerialNo, o_sensorUnits, ...
   o_sensorAccuracy, o_sensorResolution, ...
   o_parameter, o_predeploymentCalibEquation, o_predeploymentCalibCoefficient, ...
   o_predeploymentCalibComment, ...
   o_repetitionRate, o_cycleTime, o_parkingTime, o_descendingProfilingTime, ...
   o_ascendingProfilingTime, o_surfaceTime, o_parkingPressure, o_deepestPressure, ...
   o_deepestPressureDescending] = read_file_meta_all_nc_inside(a_fileName)

global g_latDef g_lonDef g_presDef g_durationDef;

% initialisation des valeurs par défaut
init_valdef;

o_nCycles = -1;
o_nParam = -1;

o_platformNumber = [];
o_ptt = [];
o_transSystem = [];
o_transSystemId = [];
o_transFrequency = [];
o_transRepetition = [];
o_positioningSystem = [];
o_clockDrift = [];
o_platformModel = [];
o_platformMaker = [];
o_instReference = [];
o_wmoInstType = [];
o_direction = [];
o_projectName = [];
o_dataCentre = [];
o_piName = [];
o_anomaly = [];

o_launchDate = [];
o_launchLatitude = [];
o_launchLongitude = [];
o_launchQc = [];
o_startDate = [];
o_startDateQc = [];
o_deployPlatform = [];
o_deployMission = [];
o_deployAvailableProfileId = [];
o_endMissionDate = [];
o_endMissionStatus = [];

o_sensor = [];
o_sensorMaker = [];
o_sensorModel = [];
o_sensorSerialNo = [];
o_sensorUnits = [];
o_sensorAccuracy = [];
o_sensorResolution = [];

o_parameter = [];
o_predeploymentCalibEquation = [];
o_predeploymentCalibCoefficient = [];
o_predeploymentCalibComment = [];

o_repetitionRate = [];
o_cycleTime = [];
o_parkingTime = [];
o_descendingProfilingTime = [];
o_ascendingProfilingTime = [];
o_surfaceTime = [];
o_parkingPressure = [];
o_deepestPressure = [];
o_deepestPressureDescending = [];

if ~(exist(a_fileName, 'file') == 2)
   fprintf('Fichier introuvable : %s\n', a_fileName);
   return
end

fCdf = netcdf.open(a_fileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('Unable to open NetCDF file: %s\n', a_fileName);
   return
end

% dimensions
[~, o_nCycles] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_CYCLES'));
[~, o_nParam] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_PARAM'));

% caractéristiques du flotteur
o_platformNumber = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_NUMBER'))';
o_ptt = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PTT'))';
o_transSystem = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRANS_SYSTEM'))';
o_transSystemId = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRANS_SYSTEM_ID'))';
o_transFrequency = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRANS_FREQUENCY'))';
o_transRepetition = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRANS_REPETITION'));
transRepFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'TRANS_REPETITION'), '_FillValue');
idFillValue = find(o_transRepetition == transRepFillVal);
if (~isempty(idFillValue))
   o_transRepetition(idFillValue) = g_durationDef;
end
o_positioningSystem = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITIONING_SYSTEM'))';
o_clockDrift = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CLOCK_DRIFT'));
clockDriftFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'CLOCK_DRIFT'), '_FillValue');
idFillValue = find(o_clockDrift == clockDriftFillVal);
if (~isempty(idFillValue))
   o_clockDrift(idFillValue) = g_durationDef;
end
o_platformModel = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_MODEL'))';
o_platformMaker = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_MAKER'))';
o_instReference = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'INST_REFERENCE'))';
o_wmoInstType = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'WMO_INST_TYPE'))';
o_direction = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'));
o_projectName = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PROJECT_NAME'))';
o_dataCentre = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_CENTRE'))';
o_piName = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PI_NAME'))';
o_anomaly = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'ANOMALY'))';

% déploiement du flotteur et informations sur la mission du flotteur
o_launchDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LAUNCH_DATE'))';

o_launchLatitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LAUNCH_LATITUDE'));
launchLatFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LAUNCH_LATITUDE'), '_FillValue');
idFillValue = find(o_launchLatitude == launchLatFillVal);
if (~isempty(idFillValue))
   o_launchLatitude(idFillValue) = g_latDef;
end

o_launchLongitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LAUNCH_LONGITUDE'));
launchLonFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'LAUNCH_LONGITUDE'), '_FillValue');
idFillValue = find(o_launchLongitude == launchLonFillVal);
if (~isempty(idFillValue))
   o_launchLongitude(idFillValue) = g_lonDef;
end

o_launchQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LAUNCH_QC'));
o_startDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'START_DATE'))';
o_startDateQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'START_DATE_QC'))';
o_deployPlatform = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPLOY_PLATFORM'))';
o_deployMission = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPLOY_MISSION'))';
o_deployAvailableProfileId = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEPLOY_AVAILABLE_PROFILE_ID'))';
o_endMissionDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'END_MISSION_DATE'))';
o_endMissionStatus = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'END_MISSION_STATUS'));

% informations sur les capteurs
o_sensor = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR'))';
o_sensorMaker = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR_MAKER'))';
o_sensorModel = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR_MODEL'))';
o_sensorSerialNo = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR_SERIAL_NO'))';
o_sensorUnits = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR_UNITS'))';
o_sensorAccuracy = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR_ACCURACY'));
o_sensorResolution = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SENSOR_RESOLUTION'));

% informations de calibration
o_parameter = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER'))';
o_predeploymentCalibEquation = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PREDEPLOYMENT_CALIB_EQUATION'))';
o_predeploymentCalibCoefficient = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PREDEPLOYMENT_CALIB_COEFFICIENT'))';
o_predeploymentCalibComment = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PREDEPLOYMENT_CALIB_COMMENT'))';

% paramètres de mission du flotteur
o_repetitionRate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'REPETITION_RATE'));
o_cycleTime = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_TIME'));
o_parkingTime = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARKING_TIME'));
o_descendingProfilingTime = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DESCENDING_PROFILING_TIME'));
o_ascendingProfilingTime = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'ASCENDING_PROFILING_TIME'));
o_surfaceTime = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SURFACE_TIME'));

o_parkingPressure = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARKING_PRESSURE'));
parkPresFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PARKING_PRESSURE'), '_FillValue');
idFillValue = find(o_parkingPressure == parkPresFillVal);
if (~isempty(idFillValue))
   o_parkingPressure(idFillValue) = g_presDef;
end

o_deepestPressure = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEEPEST_PRESSURE'));
deepPresFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'DEEPEST_PRESSURE'), '_FillValue');
idFillValue = find(o_deepestPressure == deepPresFillVal);
if (~isempty(idFillValue))
   o_deepestPressure(idFillValue) = g_presDef;
end

o_deepestPressureDescending = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DEEPEST_PRESSURE_DESCENDING'));
deepPresDescFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'DEEPEST_PRESSURE_DESCENDING'), '_FillValue');
idFillValue = find(o_deepestPressureDescending == deepPresDescFillVal);
if (~isempty(idFillValue))
   o_deepestPressureDescending(idFillValue) = g_presDef;
end

netcdf.close(fCdf);

return
