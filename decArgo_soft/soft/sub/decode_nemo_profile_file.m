% ------------------------------------------------------------------------------
% Parse one .profile file and store information by category.
%
% SYNTAX :
%  [o_metaInfo, o_metaData, o_configInfo, o_techInfo, o_techData, ...
%    o_timeInfo, o_timeData, o_parkData, o_rafosData, o_profileData] = ...
%    decode_nemo_profile_file(a_profileFile)
%
% INPUT PARAMETERS :
%   a_profileFile : name of input .profile file
%
% OUTPUT PARAMETERS :
%   o_metaInfo    : meta-data information
%   o_metaData    : meta-data
%   o_configInfo  : config info
%   o_techInfo    : tech information
%   o_techData    : tech data
%   o_timeInfo    : time information
%   o_timeData    : time data
%   o_parkData    : park data
%   o_rafosData   : RAFOS data
%   o_profileData : profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/31/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaInfo, o_metaData, o_configInfo, o_techInfo, o_techData, ...
   o_timeInfo, o_timeData, o_parkData, o_rafosData, o_profileData] = ...
   decode_nemo_profile_file(a_profileFile)

% output parameters initialization
o_metaInfo = [];
o_metaData = [];
o_configInfo = [];
o_techInfo = [];
o_techData = [];
o_timeInfo = [];
o_timeData = [];
o_parkData = [];
o_rafosData = [];
o_profileData = [];


% read .profile file
[ ...
   error, ...
   floatIdentificationStr, ...
   overallMissionInformationStr, ...
   deploymentInfoStr, ...
   profileTechnicalDataStr, ...
   bottomValuesDuringDriftStr, ...
   rafosValuesFormatStr, ...
   rafosValuesStr, ...
   profileHeaderStr, ...
   qualityControlHeaderStr, ...
   profileDataHeaderStr, ...
   profileDataStr, ...
   surfaceGpsDataFormatStr, ...
   surfaceGpsDataStr, ...
   iridiumPositionsFormatStr, ...
   iridiumPositionsStr, ...
   iridiumDataFormatStr, ...
   iridiumDataStr, ...
   startupMessageStr, ...
   secondOrderInformationStr ...
   ] = read_nemo_profile_file(a_profileFile);
if (error == 1)
   fprintf('ERROR: Error in file: %s => ignored\n', a_profileFile);
   return
elseif (error == 2)
   return
end

% parse information and parameter measurements
floatIdentification = parse_nemo_info(floatIdentificationStr);
[metaInfo, metaData, configInfo, techInfo, techData, timeInfo, timeData, ~] = ...
   store_nemo_info(floatIdentification, 'FLOAT_IDENTIFICATION');
o_metaInfo = [o_metaInfo metaInfo];
o_metaData = [o_metaData; metaData];
o_configInfo = [o_configInfo configInfo];
o_techInfo = [o_techInfo techInfo];
o_techData = [o_techData techData];

overallMissionInformation = parse_nemo_info(overallMissionInformationStr);
[metaInfo, metaData, configInfo, techInfo, techData, ~, ~, ~] = ...
   store_nemo_info(overallMissionInformation, 'OVERALL_MISSION_INFORMATION');
o_metaInfo = [o_metaInfo metaInfo];
o_metaData = [o_metaData; metaData];
o_configInfo = [o_configInfo configInfo];
o_techInfo = [o_techInfo techInfo];
o_techData = [o_techData techData];

deploymentInfo = parse_nemo_info(deploymentInfoStr);
[metaInfo, metaData, configInfo, techInfo, techData, ~, ~, ~] = ...
   store_nemo_info(deploymentInfo, 'DEPLOYMENT_INFO');
o_metaInfo = [o_metaInfo metaInfo];
o_metaData = [o_metaData; metaData];
o_configInfo = [o_configInfo configInfo];
o_techInfo = [o_techInfo techInfo];
o_techData = [o_techData techData];

profileTechnicalData = parse_nemo_info(profileTechnicalDataStr);
[metaInfo, metaData, configInfo, techInfo, techData, timeInfo, timeData, ~] = ...
   store_nemo_info(profileTechnicalData, 'PROFILE_TECHNICAL_DATA');
o_metaInfo = [o_metaInfo metaInfo];
o_metaData = [o_metaData; metaData];
o_configInfo = [o_configInfo configInfo];
o_techInfo = [o_techInfo techInfo];
o_techData = [o_techData techData];
o_timeInfo = [o_timeInfo timeInfo];
o_timeData = [o_timeData timeData];

bottomValuesDuringDrift = parse_nemo_info(bottomValuesDuringDriftStr);
[~, ~, ~, ~, ~, ~, ~, o_parkData] = ...
   store_nemo_info(bottomValuesDuringDrift, 'BOTTOM_VALUES_DURING_DRIFT');

rafosValues = parse_nemo_data(rafosValuesFormatStr, rafosValuesStr, ...
   [{'rtcJulD'} {2:7}], 'RAFOS_VALUES_FORMAT');
[o_rafosData, ~] = store_nemo_data(rafosValues, 'RAFOS_VALUES');

% profileHeader = parse_nemo_info(profileHeaderStr);
% qualityControlHeader = parse_nemo_info(qualityControlHeaderStr);

profileData = parse_nemo_data(profileDataHeaderStr, profileDataStr, [], 'PROFILE_DATA_HEADER');
[~, o_profileData] = store_nemo_data(profileData, 'PROFILE_DATA');

% surfaceGpsData = parse_nemo_data(surfaceGpsDataFormatStr, surfaceGpsDataStr, ...
%    [{'rtcJulD'} {2:7}; {'GPSJulD'} {8:13}], 'SURFACE_GPS_DATA_FORMAT');

% iridiumPositions = parse_nemo_data(iridiumPositionsFormatStr, iridiumPositionsStr, ...
%    [{'julD'} {4:9}], 'IRIDIUM_POSITIONS_FORMAT');

% iridiumData = parse_nemo_data(iridiumDataFormatStr, iridiumDataStr, ...
%    [{'julD'} {4:9}], 'IRIDIUM_DATA_FORMAT');

startupMessage = parse_nemo_info(startupMessageStr);
[metaInfo, metaData, configInfo, techInfo, techData, ~, ~, ~] = ...
   store_nemo_info(startupMessage, 'STARTUP_MESSAGE');
o_metaInfo = [o_metaInfo metaInfo];
o_metaData = [o_metaData; metaData];
o_configInfo = [o_configInfo configInfo];
o_techInfo = [o_techInfo techInfo];
o_techData = [o_techData techData];

secondOrderInformation = parse_nemo_info(secondOrderInformationStr);
[metaInfo, metaData, configInfo, techInfo, techData, ~, ~, ~] = ...
   store_nemo_info(secondOrderInformation, 'SECOND_ORDER_INFORMATION');
o_metaInfo = [o_metaInfo metaInfo];
o_metaData = [o_metaData; metaData];
o_configInfo = [o_configInfo configInfo];
o_techInfo = [o_techInfo techInfo];
o_techData = [o_techData techData];

return
