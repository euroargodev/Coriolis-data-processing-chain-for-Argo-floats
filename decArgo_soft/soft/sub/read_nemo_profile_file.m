% ------------------------------------------------------------------------------
% Read NEMO .profile file
%
% SYNTAX :
%  [ ...
%    o_error, ...
%    o_floatIdentificationStr, ...
%    o_overallMissionInformationStr, ...
%    o_deploymentInfoStr, ...
%    o_profileTechnicalDataStr, ...
%    o_bottomValuesDuringDriftStr, ...
%    o_rafosValuesFormatStr, ...
%    o_rafosValuesStr, ...
%    o_profileHeaderStr, ...
%    o_qualityControlHeaderStr, ...
%    o_profileDataHeaderStr, ...
%    o_profileDataStr, ...
%    o_surfaceGpsDataFormatStr, ...
%    o_surfaceGpsDataStr, ...
%    o_iridiumPositionsFormatStr, ...
%    o_iridiumPositionsStr, ...
%    o_iridiumDataFormatStr, ...
%    o_iridiumDataStr, ...
%    o_startupMessageStr, ...
%    o_secondOrderInformationStr ...
%    ] = read_nemo_profile_file(a_profileFileName)
%
% INPUT PARAMETERS :
%   a_profileFileName : .profile file path name
%
% OUTPUT PARAMETERS :
%   o_error                        : parsing error flag
%   o_floatIdentificationStr       : information of the [FLOAT_IDENTIFICATION] part
%   o_overallMissionInformationStr : information of the [OVERALL_MISSION_INFORMATION] part
%   o_deploymentInfoStr            : information of the [DEPLOYMENT_INFO] part
%   o_profileTechnicalDataStr      : information of the [PROFILE_TECHNICAL_DATA] part
%   o_bottomValuesDuringDriftStr   : information of the [BOTTOM_VALUES_DURING_DRIFT] part
%   o_rafosValuesFormatStr         : information of the [RAFOS_VALUES_FORMAT] part
%   o_rafosValuesStr               : information of the [RAFOS_VALUES] part
%   o_profileHeaderStr             : information of the [PROFILE_HEADER] part
%   o_qualityControlHeaderStr      : information of the [QUALITY_CONTROL_HEADER] part
%   o_profileDataHeaderStr         : information of the [PROFILE_DATA_HEADER] part
%   o_profileDataStr               : information of the [PROFILE_DATA] part
%   o_surfaceGpsDataFormatStr      : information of the [SURFACE_GPS_DATA_FORMAT] part
%   o_surfaceGpsDataStr            : information of the [SURFACE_GPS_DATA] part
%   o_iridiumPositionsFormatStr    : information of the [IRIDIUM_POSITIONS_FORMAT] part
%   o_iridiumPositionsStr          : information of the [IRIDIUM_POSITIONS] part
%   o_iridiumDataFormatStr         : information of the [IRIDIUM_DATA_FORMAT] part
%   o_iridiumDataStr               : information of the [IRIDIUM_DATA] part
%   o_startupMessageStr            : information of the [STARTUP_MESSAGE] part
%   o_secondOrderInformationStr    : information of the [SECOND_ORDER_INFORMATION] part
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [ ...
   o_error, ...
   o_floatIdentificationStr, ...
   o_overallMissionInformationStr, ...
   o_deploymentInfoStr, ...
   o_profileTechnicalDataStr, ...
   o_bottomValuesDuringDriftStr, ...
   o_rafosValuesFormatStr, ...
   o_rafosValuesStr, ...
   o_profileHeaderStr, ...
   o_qualityControlHeaderStr, ...
   o_profileDataHeaderStr, ...
   o_profileDataStr, ...
   o_surfaceGpsDataFormatStr, ...
   o_surfaceGpsDataStr, ...
   o_iridiumPositionsFormatStr, ...
   o_iridiumPositionsStr, ...
   o_iridiumDataFormatStr, ...
   o_iridiumDataStr, ...
   o_startupMessageStr, ...
   o_secondOrderInformationStr ...
   ] = read_nemo_profile_file(a_profileFileName)

% output parameters initialization
o_error = 0;
o_floatIdentificationStr = [];
o_overallMissionInformationStr = [];
o_deploymentInfoStr = [];
o_profileTechnicalDataStr = [];
o_bottomValuesDuringDriftStr = [];
o_rafosValuesFormatStr = [];
o_rafosValuesStr = [];
o_profileHeaderStr = [];
o_qualityControlHeaderStr = [];
o_profileDataHeaderStr = [];
o_profileDataStr = [];
o_surfaceGpsDataFormatStr = [];
o_surfaceGpsDataStr = [];
o_iridiumPositionsFormatStr = [];
o_iridiumPositionsStr = [];
o_iridiumDataFormatStr = [];
o_iridiumDataStr = [];
o_startupMessageStr = [];
o_secondOrderInformationStr = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

if ~(exist(a_profileFileName, 'file') == 2)
   fprintf('ERROR: %sFile not found: %s\n', errorHeader, a_profileFileName);
   return
end

% open the file and read the data
fId = fopen(a_profileFileName, 'r');
if (fId == -1)
   fprintf('ERROR: %sUnable to open file: %s\n', errorHeader, a_profileFileName);
   return
end

floatIdentification = 0;
overallMissionInformation = 0;
deploymentInfoStr = 0;
profileTechnicalData = 0;
bottomValuesDuringDrift = 0;
rafosValuesFormat = 0;
rafosValues = 0;
profileHeader = 0;
qualityControlHeader = 0;
profileDataHeader = 0;
profileData = 0;
surfaceGpsDataFormat = 0;
surfaceGpsData = 0;
iridiumPositionsFormat = 0;
iridiumPositions = 0;
iridiumDataFormat = 0;
iridiumData = 0;
startupMessage = 0;
secondOrderInformation = 0;

lineNum = 0;
while 1
   line = fgetl(fId);
   
   if (line == -1)
      break
   end
   
   lineNum = lineNum + 1;
   line = strtrim(line);
   
   if (isempty(line))
      continue
   end
   
   if (line(1) == '[')
      % set flags
      switch (line(2:end-1))
         case 'FLOAT_IDENTIFICATION'
            floatIdentification = 1;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'OVERALL_MISSION_INFORMATION'
            floatIdentification = 0;
            overallMissionInformation = 1;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'DEPLOYMENT_INFO'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 1;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'PROFILE_TECHNICAL_DATA'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 1;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'BOTTOM_VALUES_DURING_DRIFT'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 1;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'RAFOS_VALUES_FORMAT'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 1;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'RAFOS_VALUES'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 1;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'PROFILE_HEADER'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 1;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'QUALITY_CONTROL_HEADER'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 1;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'PROFILE_DATA_HEADER'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 1;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'PROFILE_DATA'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 1;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'SURFACE_GPS_DATA_FORMAT'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 1;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'SURFACE_GPS_DATA'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 1;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'IRIDIUM_POSITIONS_FORMAT'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 1;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'IRIDIUM_POSITIONS'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 1;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'IRIDIUM_DATA_FORMAT'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 1;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'IRIDIUM_DATA'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 1;
            startupMessage = 0;
            secondOrderInformation = 0;
         case 'STARTUP_MESSAGE'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 1;
            secondOrderInformation = 0;
         case 'SECOND_ORDER_INFORMATION'
            floatIdentification = 0;
            overallMissionInformation = 0;
            deploymentInfoStr = 0;
            profileTechnicalData = 0;
            bottomValuesDuringDrift = 0;
            rafosValuesFormat = 0;
            rafosValues = 0;
            profileHeader = 0;
            qualityControlHeader = 0;
            profileDataHeader = 0;
            profileData = 0;
            surfaceGpsDataFormat = 0;
            surfaceGpsData = 0;
            iridiumPositionsFormat = 0;
            iridiumPositions = 0;
            iridiumDataFormat = 0;
            iridiumData = 0;
            startupMessage = 0;
            secondOrderInformation = 1;
         otherwise
            fprintf('WARNING: %s unexpected label ''%s''\n', errorHeader, line);
            o_error = 1;
      end
   else
      % store lines according to flags
      if (floatIdentification == 1)
         o_floatIdentificationStr{end+1} = line;
      elseif (overallMissionInformation == 1)
         o_overallMissionInformationStr{end+1} = line;
      elseif (deploymentInfoStr == 1)
         o_deploymentInfoStr{end+1} = line;
      elseif (profileTechnicalData == 1)
         o_profileTechnicalDataStr{end+1} = line;
      elseif (bottomValuesDuringDrift == 1)
         o_bottomValuesDuringDriftStr{end+1} = line;
      elseif (rafosValuesFormat == 1)
         o_rafosValuesFormatStr{end+1} = line;
      elseif (rafosValues == 1)
         o_rafosValuesStr{end+1} = line;
      elseif (profileHeader == 1)
         o_profileHeaderStr{end+1} = line;
      elseif (qualityControlHeader == 1)
         o_qualityControlHeaderStr{end+1} = line;
      elseif (profileDataHeader == 1)
         o_profileDataHeaderStr{end+1} = line;
      elseif (profileData == 1)
         o_profileDataStr{end+1} = line;
      elseif (surfaceGpsDataFormat == 1)
         o_surfaceGpsDataFormatStr{end+1} = line;
      elseif (surfaceGpsData == 1)
         o_surfaceGpsDataStr{end+1} = line;
      elseif (iridiumPositionsFormat == 1)
         o_iridiumPositionsFormatStr{end+1} = line;
      elseif (iridiumPositions == 1)
         o_iridiumPositionsStr{end+1} = line;
      elseif (iridiumDataFormat == 1)
         o_iridiumDataFormatStr{end+1} = line;
      elseif (iridiumData == 1)
         o_iridiumDataStr{end+1} = line;
      elseif (startupMessage == 1)
         o_startupMessageStr{end+1} = line;
      elseif (secondOrderInformation == 1)
         o_secondOrderInformationStr{end+1} = line;
      else
         if (line(1) ~= '%')
            fprintf('WARNING: %s unused data ''%s''\n', errorHeader, line);
         end
      end
   end
end

fclose(fId);

if (lineNum == 0)
   fprintf('WARNING: %s empty file: %s\n', errorHeader, a_profileFileName);
   if (o_error == 0)
      o_error = 2;
   end
end

return
