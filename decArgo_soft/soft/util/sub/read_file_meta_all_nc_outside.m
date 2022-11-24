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
%    o_deepestPressureDescending] = read_file_meta_all_nc_outside(a_fileName)
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
%   03/01/2007 - RNU - creation
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
   o_deepestPressureDescending] = read_file_meta_all_nc_outside(a_fileName)

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

ncstartup;

if ~(exist(a_fileName, 'file') == 2)
   fprintf('Fichier introuvable : %s\n', a_fileName);
   return
end

fCdf = netcdf(a_fileName, 'read');

if (isempty(fCdf))
   fprintf('Echec ouverture fichier : %s\n', a_fileName);
   return
end

% dimensions
o_nCycles = length(fCdf('N_CYCLES'));
o_nParam = length(fCdf('N_PARAM'));

% caractéristiques du flotteur
o_platformNumber = fCdf{'PLATFORM_NUMBER'}(:);
o_ptt = fCdf{'PTT'}(:);
o_transSystem = fCdf{'TRANS_SYSTEM'}(:);
o_transSystemId = fCdf{'TRANS_SYSTEM_ID'}(:);
o_transFrequency = fCdf{'TRANS_FREQUENCY'}(:);
o_transRepetition = fCdf{'TRANS_REPETITION'}(:);
idFillValue = find(o_transRepetition == fCdf{'TRANS_REPETITION'}.FillValue_(:));
if (~isempty(idFillValue))
   o_transRepetition(idFillValue) = g_durationDef;
end
o_positioningSystem = fCdf{'POSITIONING_SYSTEM'}(:);
o_clockDrift = fCdf{'CLOCK_DRIFT'}(:);
idFillValue = find(o_clockDrift == fCdf{'CLOCK_DRIFT'}.FillValue_(:));
if (~isempty(idFillValue))
   o_clockDrift(idFillValue) = g_durationDef;
end
o_platformModel = fCdf{'PLATFORM_MODEL'}(:);
o_platformMaker = fCdf{'PLATFORM_MAKER'}(:);
o_instReference = fCdf{'INST_REFERENCE'}(:);
o_wmoInstType = fCdf{'WMO_INST_TYPE'}(:);
o_direction = fCdf{'DIRECTION'}(:);
o_projectName = fCdf{'PROJECT_NAME'}(:);
o_dataCentre = fCdf{'DATA_CENTRE'}(:);
o_piName = fCdf{'PI_NAME'}(:);
o_anomaly = fCdf{'ANOMALY'}(:);

% déploiement du flotteur et informations sur la mission du flotteur
o_launchDate = fCdf{'LAUNCH_DATE'}(:);
o_launchLatitude = fCdf{'LAUNCH_LATITUDE'}(:);
idFillValue = find(o_launchLatitude == fCdf{'LAUNCH_LATITUDE'}.FillValue_(:));
if (~isempty(idFillValue))
   o_launchLatitude(idFillValue) = g_latDef;
end
o_launchLongitude = fCdf{'LAUNCH_LONGITUDE'}(:);
idFillValue = find(o_launchLongitude == fCdf{'LAUNCH_LONGITUDE'}.FillValue_(:));
if (~isempty(idFillValue))
   o_launchLongitude(idFillValue) = g_lonDef;
end
o_launchQc = fCdf{'LAUNCH_QC'}(:);
o_startDate = fCdf{'START_DATE'}(:);
o_startDateQc = fCdf{'START_DATE_QC'}(:);
o_deployPlatform = fCdf{'DEPLOY_PLATFORM'}(:);
o_deployMission = fCdf{'DEPLOY_MISSION'}(:);
o_deployAvailableProfileId = fCdf{'DEPLOY_AVAILABLE_PROFILE_ID'}(:);
o_endMissionDate = fCdf{'END_MISSION_DATE'}(:);
o_endMissionStatus = fCdf{'END_MISSION_STATUS'}(:);

% informations sur les capteurs
o_sensor = fCdf{'SENSOR'}(:);
o_sensorMaker = fCdf{'SENSOR_MAKER'}(:);
o_sensorModel = fCdf{'SENSOR_MODEL'}(:);
o_sensorSerialNo = fCdf{'SENSOR_SERIAL_NO'}(:);
o_sensorUnits = fCdf{'SENSOR_UNITS'}(:);
o_sensorAccuracy = fCdf{'SENSOR_ACCURACY'}(:);
o_sensorResolution = fCdf{'SENSOR_RESOLUTION'}(:);

% informations de calibration
o_parameter = fCdf{'PARAMETER'}(:);
o_predeploymentCalibEquation = fCdf{'PREDEPLOYMENT_CALIB_EQUATION'}(:);
o_predeploymentCalibCoefficient = fCdf{'PREDEPLOYMENT_CALIB_COEFFICIENT'}(:);
o_predeploymentCalibComment = fCdf{'PREDEPLOYMENT_CALIB_COMMENT'}(:);

% paramètres de mission du flotteur
o_repetitionRate = fCdf{'REPETITION_RATE'}(:);
o_cycleTime = fCdf{'CYCLE_TIME'}(:);
o_parkingTime = fCdf{'PARKING_TIME'}(:);
o_descendingProfilingTime = fCdf{'DESCENDING_PROFILING_TIME'}(:);
o_ascendingProfilingTime = fCdf{'ASCENDING_PROFILING_TIME'}(:);
o_surfaceTime = fCdf{'SURFACE_TIME'}(:);
o_parkingPressure = fCdf{'PARKING_PRESSURE'}(:);
idFillValue = find(o_parkingPressure == fCdf{'PARKING_PRESSURE'}.FillValue_(:));
if (~isempty(idFillValue))
   o_parkingPressure(idFillValue) = g_presDef;
end
o_deepestPressure = fCdf{'DEEPEST_PRESSURE'}(:);
idFillValue = find(o_deepestPressure == fCdf{'DEEPEST_PRESSURE'}.FillValue_(:));
if (~isempty(idFillValue))
   o_deepestPressure(idFillValue) = g_presDef;
end
o_deepestPressureDescending = fCdf{'DEEPEST_PRESSURE_DESCENDING'}(:);
idFillValue = find(o_deepestPressureDescending == fCdf{'DEEPEST_PRESSURE_DESCENDING'}.FillValue_(:));
if (~isempty(idFillValue))
   o_deepestPressureDescending(idFillValue) = g_presDef;
end

close(fCdf);

return
