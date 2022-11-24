% ------------------------------------------------------------------------------
% Initialize list of sensor mounted on the float and calibration information.
%
% SYNTAX :
%  [o_ok] = init_float_config_prv_ir_rudics_cts4(a_jsonFilePathName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_jsonFilePathName : JSON META file
%   a_decoderId        : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ok : 1: if everithing is OK, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = init_float_config_prv_ir_rudics_cts4(a_jsonFilePathName, a_decoderId)

% output parameters initialization
o_ok = 0;

% current float WMO number
global g_decArgo_floatNum;

% sensor list
global g_decArgo_sensorList;
global g_decArgo_sensorMountedOnFloat;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;


% read meta-data file
metaData = loadjson(a_jsonFilePathName);

% list of sensors mounted on the float
sensorMountedOnFloat = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   sensorMountedOnFloat = jSensorNames';
end

% fill the sensor list
sensorList = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   for id = 1:length(jSensorNames)
      sensorName = jSensorNames{id};
      switch (sensorName)
         case 'CTD'
            sensorList = [sensorList 0];
         case 'OPTODE'
            sensorList = [sensorList 1];
         case 'OCR'
            sensorList = [sensorList 2];
         case 'ECO2'
            if (ismember(3, sensorList))
               fprintf('ERROR: Float #%d: Sensor #3 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 3];
         case 'ECO3'
            if (ismember(3, sensorList))
               fprintf('ERROR: Float #%d: Sensor #3 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 3];
         case 'FLNTU'
            if (ismember(4, sensorList))
               fprintf('ERROR: Float #%d: Sensor #4 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 4];
         case 'CROVER'
            sensorList = [sensorList 5];
         case 'SUNA'
            sensorList = [sensorList 6];
         case 'TRANSISTOR_PH'
            if (ismember(4, sensorList))
               fprintf('ERROR: Float #%d: Sensor #4 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 4];
         otherwise
            fprintf('ERROR: Float #%d: Unknown sensor name %s\n', ...
               g_decArgo_floatNum, ...
               sensorName);
      end
   end
   sensorList = unique(sensorList);
else
   fprintf('ERROR: Float #%d: SENSOR_MOUNTED_ON_FLOAT not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      a_jsonFilePathName);
   return
end

% store the sensor list
g_decArgo_sensorList = sensorList;
g_decArgo_sensorMountedOnFloat = sensorMountedOnFloat;

% fill the calibration coefficients
if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(metaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
      
      % create the tabDoxyCoef array
      switch (a_decoderId)
         
         case {111, 113}
            if (isfield(g_decArgo_calibInfo, 'OPTODE'))
               calibData = g_decArgo_calibInfo.OPTODE;
               tabDoxyCoef = [];
               for id = 0:3
                  fieldName = ['PhaseCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(1, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:6
                  fieldName = ['SVUFoilCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(2, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return
            end
      end
      
      % create the NITRATE calibration arrays
      if (ismember(6, g_decArgo_sensorList))
         if (isfield(g_decArgo_calibInfo, 'SUNA'))
            calibData = g_decArgo_calibInfo.SUNA;
            tabOpticalWavelengthUv = [];
            tabENitrate = [];
            tabESwaNitrate = [];
            tabEBisulfide = [];
            tabUvIntensityRefNitrate = [];
            for id = 1:256
               fieldName = ['OPTICAL_WAVELENGTH_UV_' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabOpticalWavelengthUv = [tabOpticalWavelengthUv calibData.(fieldName)];
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                  return
               end
               fieldName = ['E_NITRATE_' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabENitrate = [tabENitrate calibData.(fieldName)];
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                  return
               end
               fieldName = ['E_SWA_NITRATE_' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabESwaNitrate = [tabESwaNitrate calibData.(fieldName)];
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                  return
               end
               if (a_decoderId == 113)
                  fieldName = ['E_BISULFIDE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabEBisulfide = [tabEBisulfide calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               fieldName = ['UV_INTENSITY_REF_NITRATE_' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabUvIntensityRefNitrate = [tabUvIntensityRefNitrate calibData.(fieldName)];
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv = tabOpticalWavelengthUv;
            g_decArgo_calibInfo.SUNA.TabENitrate = tabENitrate;
            g_decArgo_calibInfo.SUNA.TabESwaNitrate = tabESwaNitrate;
            if (~isempty(tabEBisulfide))
               g_decArgo_calibInfo.SUNA.TabEBisulfide = tabEBisulfide;
            end
            g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = tabUvIntensityRefNitrate;
            
            g_decArgo_calibInfo.SUNA.SunaVerticalOffset = get_config_value_from_json('CONFIG_PX_1_6_0_0_0', metaData);
            g_decArgo_calibInfo.SUNA.FloatPixelBegin = get_config_value_from_json('CONFIG_PX_1_6_0_0_3', metaData);
            g_decArgo_calibInfo.SUNA.FloatPixelEnd = get_config_value_from_json('CONFIG_PX_1_6_0_0_4', metaData);
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
            return
         end
      end
   end
end

o_ok = 1;

return
