% ------------------------------------------------------------------------------
% Process RTQC on NetCDF mono, multi profile files and on trajectory file.
% Real time CHLA adjustment is also performed.
%
% SYNTAX :
%   nc_add_rtqc_flags_prof_and_traj or nc_add_rtqc_flags_prof_and_traj(6900189, 7900118)
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
%   02/10/2016 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function nc_add_rtqc_flags_prof_and_traj(varargin)

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decPrv_all - copie pour test RTQC\';

% top directory of the output NetCDF files (should be set to '' if we want to
% update the existing files
DIR_OUTPUT_NC_FILES = ''; % update existing files
% DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_rtqc\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_rem_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% ETOPO2 file
ETOPO2_FILE_PATH_NAME = 'C:\Users\jprannou\_RNU\_ressources\ETOPO2\ETOPO2v2g_i2_MSB.bin';

% grey list file
GREY_LIST_FILE_PATH_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\ar_greylist.txt';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% temporary trajectory data
global g_rtqc_trajData;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% maximum number of mono profile files to process for each float
NB_FILES_TO_PROCESS = -1;

% the RTQC on profiles and trajectory data are linked (they should always be
% performed together), however the 2 following flags can be used to report or
% not the QC values in the concerned files
UPDATE_PROFILE_FILE_FLAG = 1;
UPDATE_TRAJECTORY_FILE_FLAG = 1;


% list of tests to perform
% CORIOLIS
testToPerformList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} {1} ...
   {'TEST002_IMPOSSIBLE_DATE'} {1} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
   {'TEST004_POSITION_ON_LAND'} {1} ...
   {'TEST005_IMPOSSIBLE_SPEED'} {1} ...
   {'TEST006_GLOBAL_RANGE'} {1} ...
   {'TEST007_REGIONAL_RANGE'} {1} ...
   {'TEST008_PRESSURE_INCREASING'} {1} ...
   {'TEST009_SPIKE'} {1} ...
   {'TEST011_GRADIENT'} {1} ...
   {'TEST012_DIGIT_ROLLOVER'} {1} ...
   {'TEST013_STUCK_VALUE'} {1} ...
   {'TEST014_DENSITY_INVERSION'} {1} ...
   {'TEST015_GREY_LIST'} {1} ...
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {0} ...
   {'TEST018_FROZEN_PRESSURE'} {0} ...
   {'TEST019_DEEPEST_PRESSURE'} {1} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {1} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} {1} ...
   {'TEST022_NS_MIXED_AIR_WATER'} {1} ...
   {'TEST023_DEEP_FLOAT'} {1} ...
   {'TEST057_DOXY'} {1} ...
   {'TEST059_NITRATE'} {1} ...
   {'TEST062_BBP'} {1} ...
   {'TEST063_CHLA'} {1} ...
   ];

% ALL
testToPerformList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} {1} ...
   {'TEST002_IMPOSSIBLE_DATE'} {1} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
   {'TEST004_POSITION_ON_LAND'} {1} ...
   {'TEST005_IMPOSSIBLE_SPEED'} {1} ...
   {'TEST006_GLOBAL_RANGE'} {1} ...
   {'TEST007_REGIONAL_RANGE'} {1} ...
   {'TEST008_PRESSURE_INCREASING'} {1} ...
   {'TEST009_SPIKE'} {1} ...
   {'TEST011_GRADIENT'} {1} ...
   {'TEST012_DIGIT_ROLLOVER'} {1} ...
   {'TEST013_STUCK_VALUE'} {1} ...
   {'TEST014_DENSITY_INVERSION'} {1} ...
   {'TEST015_GREY_LIST'} {1} ...
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {1} ...
   {'TEST018_FROZEN_PRESSURE'} {1} ...
   {'TEST019_DEEPEST_PRESSURE'} {1} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {1} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} {1} ...
   {'TEST022_NS_MIXED_AIR_WATER'} {1} ...
   {'TEST023_DEEP_FLOAT'} {1} ...
   {'TEST057_DOXY'} {1} ...
   {'TEST059_NITRATE'} {1} ...
   {'TEST062_BBP'} {1} ...
   {'TEST063_CHLA'} {1} ...
   ];

% one test
% testToPerformList = [ ...
%    {'TEST001_PLATFORM_IDENTIFICATION'} {1} ...
%    {'TEST002_IMPOSSIBLE_DATE'} {1} ...
%    {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
%    {'TEST004_POSITION_ON_LAND'} {1} ...
%    {'TEST005_IMPOSSIBLE_SPEED'} {1} ...
%    {'TEST006_GLOBAL_RANGE'} {0} ...
%    {'TEST007_REGIONAL_RANGE'} {0} ...
%    {'TEST008_PRESSURE_INCREASING'} {0} ...
%    {'TEST009_SPIKE'} {0} ...
%    {'TEST011_GRADIENT'} {0} ...
%    {'TEST012_DIGIT_ROLLOVER'} {0} ...
%    {'TEST013_STUCK_VALUE'} {0} ...
%    {'TEST014_DENSITY_INVERSION'} {0} ...
%    {'TEST015_GREY_LIST'} {1} ...
%    {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {0} ...
%    {'TEST018_FROZEN_PRESSURE'} {0} ...
%    {'TEST019_DEEPEST_PRESSURE'} {0} ...
%    {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {0} ...
%    {'TEST021_NS_UNPUMPED_SALINITY'} {0} ...
%    {'TEST022_NS_MIXED_AIR_WATER'} {0} ...
%    {'TEST023_DEEP_FLOAT'} {0} ...
%    {'TEST057_DOXY'} {0} ...
%    {'TEST059_NITRATE'} {0} ...
%    {'TEST062_BBP'} {0} ...
%    {'TEST063_CHLA'} {0} ...
%    ];

% meta-data associated to each test
testMetaData = [ ...
   {'TEST000_FLOAT_DECODER_ID'} {''} ...
   {'TEST004_ETOPO2_FILE'} {ETOPO2_FILE_PATH_NAME} ...
   {'TEST015_GREY_LIST_FILE'} {GREY_LIST_FILE_PATH_NAME} ...
   {'TEST019_METADA_DATA_FILE'} {''} ...
   {'TEST021_METADA_DATA_FILE'} {''} ...
   {'TEST023_DEEP_FLOAT_FLAG'} {''} ...
   {'TEST057_METADA_DATA_FILE'} {''} ...
   {'TEST063_DARK_CHLA'} {''} ...
   {'TEST063_SCALE_CHLA'} {''} ...
   ];

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

% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_JSON_FLOAT_META_DATA_FILE';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};
dirInputJsonFloatMetaDataFile = configVal{2};

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_add_rtqc_flags_prof_and_traj' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% update existing files flag
updateFiles = 0;
if (isempty(DIR_OUTPUT_NC_FILES))
   updateFiles = 1;
end

% create output directory
if (updateFiles == 0)
   if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
      mkdir(DIR_OUTPUT_NC_FILES);
   end
end

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncInputFileDir, 'dir') == 7)
      
      % get float decoder Id
      
      % get floats information
      [listWmoNum, listDecId, listArgosId, listFrameLen, ...
         listCycleTime, listDriftSamplingPeriod, listDelay, ...
         listLaunchDate, listLaunchLon, listLaunchLat, ...
         listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
      
      % find current float decoder Id
      floatDecoderId = [];
      idF = find(listWmoNum == floatNum, 1);
      if (~isempty(idF))
         floatDecoderId = listDecId(idF);
         idVal = find(strcmp('TEST000_FLOAT_DECODER_ID', testMetaData) == 1);
         if (~isempty(idVal))
            testMetaData{idVal+1} = floatDecoderId;
         end
      else
         fprintf('WARNING: Cannot retrieve float decoder Id for float #%d\n', floatNum);
      end
            
      if (test_to_perform('TEST019_DEEPEST_PRESSURE', testToPerformList) == 1)
         
         % add meta file path name
         ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
         if (exist(ncMetaFilePathName, 'file') == 2)
            idVal = find(strcmp('TEST019_METADA_DATA_FILE', testMetaData) == 1);
            if (~isempty(idVal))
               testMetaData{idVal+1} = ncMetaFilePathName;
            end
         else
            fprintf('WARNING: TEST019: No meta file to perform test#19\n');
         end
      end
            
      if (test_to_perform('TEST021_NS_UNPUMPED_SALINITY', testToPerformList) == 1)
         
         % add meta file path name
         ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
         if (exist(ncMetaFilePathName, 'file') == 2)
            idVal = find(strcmp('TEST021_METADA_DATA_FILE', testMetaData) == 1);
            if (~isempty(idVal))
               testMetaData{idVal+1} = ncMetaFilePathName;
            end
         else
            fprintf('WARNING: TEST021: No meta file to perform test#21\n');
         end
      end
            
      if (test_to_perform('TEST023_DEEP_FLOAT', testToPerformList) == 1)
         
         if (~isempty(floatDecoderId))
            idVal = find(strcmp('TEST023_DEEP_FLOAT_FLAG', testMetaData) == 1);
            if (~isempty(idVal))
               if (ismember(floatDecoderId, [201 202 203]))
                  testMetaData{idVal+1} = 1;
               else
                  testMetaData{idVal+1} = 0;
               end
            end
         else
            fprintf('WARNING: TEST023: Unable to retrieve the float decoder Id to set the deep float flag to perform test#23\n');
         end
      end
      
      if (test_to_perform('TEST057_DOXY', testToPerformList) == 1)
         
         % add meta file path name
         ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
         if (exist(ncMetaFilePathName, 'file') == 2)
            idVal = find(strcmp('TEST057_METADA_DATA_FILE', testMetaData) == 1);
            if (~isempty(idVal))
               testMetaData{idVal+1} = ncMetaFilePathName;
            end
         else
            fprintf('WARNING: TEST057: No meta file to perform test#57\n');
         end
      end
      
      if (test_to_perform('TEST059_NITRATE', testToPerformList) == 1)
      
         % create the NITRATE calibration arrays
         
         % json meta-data file for this float
         jsonInputFileName = [dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', floatNum)];
         
         if (exist(jsonInputFileName, 'file') == 2)
            
            % read meta-data file
            metaData = loadjson(jsonInputFileName);
            
            if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
               jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
               if (any(strcmp(jSensorNames, 'SUNA')))
                  
                  if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
                     if (~isempty(metaData.CALIBRATION_COEFFICIENT))
                        fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
                        for idF = 1:length(fieldNames)
                           g_decArgo_calibInfo.(fieldNames{idF}) = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
                        end
                     end
                  end
                  
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
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', floatNum);
                           return
                        end
                        fieldName = ['E_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabENitrate = [tabENitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', floatNum);
                           return
                        end
                        fieldName = ['E_SWA_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabESwaNitrate = [tabESwaNitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', floatNum);
                           return
                        end
                        if (floatDecoderId == 110)
                           fieldName = ['E_BISULFIDE_' num2str(id)];
                           if (isfield(calibData, fieldName))
                              tabEBisulfide = [tabEBisulfide calibData.(fieldName)];
                           else
                              fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', floatNum);
                              return
                           end
                        end
                        fieldName = ['UV_INTENSITY_REF_NITRATE_' num2str(id)];
                        if (isfield(calibData, fieldName))
                           tabUvIntensityRefNitrate = [tabUvIntensityRefNitrate calibData.(fieldName)];
                        else
                           fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', floatNum);
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
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', floatNum);
                  end
               end
            end
         else
            
            fprintf('INFO: TEST059: Json meta-data file not found: %s, using NetCDF meta file\n', jsonInputFileName);
            
            % use NetCDF meta file
            ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
            if (exist(ncMetaFilePathName, 'file') == 2)
               
               % retrieve information from NetCDF meta file
               wantedVars = [ ...
                  {'PARAMETER'} ...
                  {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
                  {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
                  {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
                  ];
               
               % retrieve information from NetCDF meta file
               [ncMetaData] = get_data_from_nc_file(ncMetaFilePathName, wantedVars);
               
               coefData = [];
               idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
               idCoef = find(strcmp('PREDEPLOYMENT_CALIB_COEFFICIENT', ncMetaData) == 1);
               if (~isempty(idVal) && ~isempty(idCoef))
                  parameterMetaTmp = ncMetaData{idVal+1}';
                  parameterCoefTmp = ncMetaData{idCoef+1}';
                  
                  for id = 1:size(parameterMetaTmp, 1)
                     if (strcmp(deblank(parameterMetaTmp(id, :)), 'NITRATE'))
                        coefData = deblank(parameterCoefTmp(id, :));
                     end
                  end
               end
               
               launchConfigParameterName = [];
               idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', ncMetaData) == 1);
               if (~isempty(idVal))
                  launchConfigParameterNameTmp = ncMetaData{idVal+1}';
                  
                  for id = 1:size(launchConfigParameterNameTmp, 1)
                     launchConfigParameterName{end+1} = deblank(launchConfigParameterNameTmp(id, :));
                  end
               end
               
               launchConfigParameterValue = [];
               idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', ncMetaData) == 1);
               if (~isempty(idVal))
                  launchConfigParameterValue = ncMetaData{idVal+1}';
               end
               
               % retrieve needed information
               tempCalNitrate = [];
               opticalWavelengthUv = [];
               eNitrate = [];
               eSwaNitrate = [];
               eBisulfide = [];
               uvIntensityRefNitrate = [];
               
               if (~isempty(coefData))
                  
                  % TEMP_CAL_NITRATE
                  idF1 = strfind(coefData, 'TEMP_CAL_NITRATE');
                  if (~isempty(idF1))
                     strTmp = coefData(idF1(1):end);
                     idF2 = strfind(strTmp, '=');
                     if (~isempty(idF2))
                        strTmp = strTmp(idF2(1)+1:end);
                        idF3 = strfind(strTmp, ';');
                        if (~isempty(idF3))
                           strTmp = strTmp(1:idF3(1)-1);
                           tempCalNitrate = str2double(strTmp);
                        end
                     end
                  end
                  
                  % OPTICAL_WAVELENGTH_UV
                  idF1 = strfind(coefData, 'OPTICAL_WAVELENGTH_UV');
                  if (~isempty(idF1))
                     strTmp = coefData(idF1(1):end);
                     idF2 = strfind(strTmp, '=');
                     if (~isempty(idF2))
                        strTmp = strTmp(idF2(1):end);
                        idF3 = strfind(strTmp, '[');
                        if (~isempty(idF3))
                           strTmp = strTmp(idF3(1)+1:end);
                           idF4 = strfind(strTmp, ']');
                           if (~isempty(idF4))
                              strTmp = strTmp(1:idF4(1)-1);
                              opticalWavelengthUv = str2double(strsplit(strTmp, ','));
                           end
                        end
                     end
                  end
                  % E_NITRATE
                  idF1 = strfind(coefData, 'E_NITRATE');
                  if (~isempty(idF1))
                     strTmp = coefData(idF1(1):end);
                     idF2 = strfind(strTmp, '=');
                     if (~isempty(idF2))
                        strTmp = strTmp(idF2(1):end);
                        idF3 = strfind(strTmp, '[');
                        if (~isempty(idF3))
                           strTmp = strTmp(idF3(1)+1:end);
                           idF4 = strfind(strTmp, ']');
                           if (~isempty(idF4))
                              strTmp = strTmp(1:idF4(1)-1);
                              eNitrate = str2double(strsplit(strTmp, ','));
                           end
                        end
                     end
                  end
                  % E_SWA_NITRATE
                  idF1 = strfind(coefData, 'E_SWA_NITRATE');
                  if (~isempty(idF1))
                     strTmp = coefData(idF1(1):end);
                     idF2 = strfind(strTmp, '=');
                     if (~isempty(idF2))
                        strTmp = strTmp(idF2(1):end);
                        idF3 = strfind(strTmp, '[');
                        if (~isempty(idF3))
                           strTmp = strTmp(idF3(1)+1:end);
                           idF4 = strfind(strTmp, ']');
                           if (~isempty(idF4))
                              strTmp = strTmp(1:idF4(1)-1);
                              eSwaNitrate = str2double(strsplit(strTmp, ','));
                           end
                        end
                     end
                  end
                  if (ismember(floatDecoderId, [110, 113]))
                     % E_BISULFIDE
                     idF1 = strfind(coefData, 'E_BISULFIDE');
                     if (~isempty(idF1))
                        strTmp = coefData(idF1(1):end);
                        idF2 = strfind(strTmp, '=');
                        if (~isempty(idF2))
                           strTmp = strTmp(idF2(1):end);
                           idF3 = strfind(strTmp, '[');
                           if (~isempty(idF3))
                              strTmp = strTmp(idF3(1)+1:end);
                              idF4 = strfind(strTmp, ']');
                              if (~isempty(idF4))
                                 strTmp = strTmp(1:idF4(1)-1);
                                 eBisulfide = str2double(strsplit(strTmp, ','));
                              end
                           end
                        end
                     end
                  end
                  % UV_INTENSITY_REF_NITRATE
                  idF1 = strfind(coefData, 'UV_INTENSITY_REF_NITRATE');
                  if (~isempty(idF1))
                     strTmp = coefData(idF1(1):end);
                     idF2 = strfind(strTmp, '=');
                     if (~isempty(idF2))
                        strTmp = strTmp(idF2(1):end);
                        idF3 = strfind(strTmp, '[');
                        if (~isempty(idF3))
                           strTmp = strTmp(idF3(1)+1:end);
                           idF4 = strfind(strTmp, ']');
                           if (~isempty(idF4))
                              strTmp = strTmp(1:idF4(1)-1);
                              uvIntensityRefNitrate = str2double(strsplit(strTmp, ','));
                           end
                        end
                     end
                  end
                  
                  if (~isempty(launchConfigParameterName))
                     if (~isempty(launchConfigParameterValue))
                        
                        % sunaVerticalOffset
                        idF = find(strcmp(launchConfigParameterName, 'CONFIG_SunaVerticalPressureOffset_dbar'), 1);
                        if (~isempty(idF))
                           g_decArgo_calibInfo.SUNA.SunaVerticalOffset = launchConfigParameterValue(idF);
                        end
                        % floatPixelBegin
                        idF = find(strcmp(launchConfigParameterName, 'CONFIG_SunaApfFrameOutputPixelBegin_NUMBER'), 1);
                        if (~isempty(idF))
                           g_decArgo_calibInfo.SUNA.FloatPixelBegin = launchConfigParameterValue(idF);
                        end
                        % floatPixelEnd
                        idF = find(strcmp(launchConfigParameterName, 'CONFIG_SunaApfFrameOutputPixelEnd_NUMBER'), 1);
                        if (~isempty(idF))
                           g_decArgo_calibInfo.SUNA.FloatPixelEnd = launchConfigParameterValue(idF);
                        end
                     else
                        fprintf('ERROR: TEST059: unable to retrieve LAUNCH_CONFIG_PARAMETER_VALUE from NetCDF meta file: %s\n', ncMetaFilePathName);
                     end
                  else
                     fprintf('ERROR: TEST059: unable to retrieve LAUNCH_CONFIG_PARAMETER_NAME from NetCDF meta file: %s\n', ncMetaFilePathName);
                  end
                  
                  if ~((~ismember(floatDecoderId, [110, 113]) && ...
                        (isempty(tempCalNitrate) || ...
                        isempty(opticalWavelengthUv) || ...
                        isempty(eNitrate) || ...
                        isempty(eSwaNitrate) || ...
                        isempty(uvIntensityRefNitrate))) || ...
                        (ismember(floatDecoderId, [110, 113]) && ...
                        (isempty(tempCalNitrate) || ...
                        isempty(opticalWavelengthUv) || ...
                        isempty(eNitrate) || ...
                        isempty(eSwaNitrate) || ...
                        isempty(eBisulfide) || ...
                        isempty(uvIntensityRefNitrate))))
                     
                     g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv = nan(1, 256);
                     g_decArgo_calibInfo.SUNA.TabENitrate = nan(1, 256);
                     g_decArgo_calibInfo.SUNA.TabESwaNitrate = nan(1, 256);
                     if (~isempty(eBisulfide))
                        g_decArgo_calibInfo.SUNA.TabEBisulfide = nan(1, 256);
                     end
                     g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = nan(1, 256);
                     
                     pixelRange = g_decArgo_calibInfo.SUNA.FloatPixelBegin:g_decArgo_calibInfo.SUNA.FloatPixelEnd;
                     
                     g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE(pixelRange) = tempCalNitrate;
                     g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv(pixelRange) = opticalWavelengthUv;
                     g_decArgo_calibInfo.SUNA.TabENitrate(pixelRange) = eNitrate;
                     g_decArgo_calibInfo.SUNA.TabESwaNitrate(pixelRange) = eSwaNitrate;
                     if (~isempty(eBisulfide))
                        g_decArgo_calibInfo.SUNA.TabEBisulfide(pixelRange) = eBisulfide;
                     end
                     g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate(pixelRange) = uvIntensityRefNitrate;
                  else
                     fprintf('ERROR: TEST059: calibration information is missing for NITRATE in NetCDF meta file: %s\n', ncMetaFilePathName);
                  end
               else
                  fprintf('ERROR: TEST059: unable to retrieve PREDEPLOYMENT_CALIB_COEFFICIENT for NITRATE from NetCDF meta file: %s\n', ncMetaFilePathName);
               end
            else
               fprintf('ERROR: TEST059: NetCDF meta file not found: %s\n', ncMetaFilePathName);
            end
         end
      end
      
      if (test_to_perform('TEST063_CHLA', testToPerformList) == 1)
      
         % retrieve DARK_CHLA and SCALE_CHLA from json meta data file and
         % LAST_DARK_CHLA from scientific calibration information of the
         % previous profile file

         % json meta-data file for this float
         jsonInputFileName = [dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', floatNum)];
         
         if ~(exist(jsonInputFileName, 'file') == 2)
            fprintf('ERROR: TEST063: Json meta-data file not found: %s\n', jsonInputFileName);
         else
            % read meta-data file
            metaData = loadjson(jsonInputFileName);
            
            % fill the calibration coefficients
            if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
               if (~isempty(metaData.CALIBRATION_COEFFICIENT))
                  fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
                  idF = find((strcmp(fieldNames, 'ECO2') == 1) | ...
                     (strcmp(fieldNames, 'ECO3') == 1) | ...
                     (strcmp(fieldNames, 'FLBB') == 1));
                  if (length(idF) == 1)
                     ecoCalibStruct = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
                     fieldNames = fields(ecoCalibStruct);
                     idF = find(strcmp(fieldNames, 'DarkCountChloroA') == 1);
                     if (length(idF) == 1)
                        idVal = find(strcmp('TEST063_DARK_CHLA', testMetaData) == 1);
                        if (~isempty(idVal))
                           testMetaData{idVal+1} = ecoCalibStruct.(fieldNames{idF});
                        end
                     else
                        fprintf('ERROR: TEST063: Unable to find ''DarkCountChloroA'' in Json ECO2/ECO3/FLBB calibration information\n');
                     end
                     idF = find(strcmp(fieldNames, 'ScaleFactChloroA') == 1);
                     if (length(idF) == 1)
                        idVal = find(strcmp('TEST063_SCALE_CHLA', testMetaData) == 1);
                        if (~isempty(idVal))
                           testMetaData{idVal+1} = ecoCalibStruct.(fieldNames{idF});
                        end
                     else
                        fprintf('ERROR: TEST063: Unable to find ''ScaleFactChloroA'' in Json ECO2/ECO3/FLBB calibration information\n');
                     end
                  end
               end
            end
         end
      end
      
      % create output directory
      if (updateFiles == 0)
         ncOutputFileDir = [DIR_OUTPUT_NC_FILES '/' num2str(floatNum) '/'];
         if ~(exist(ncOutputFileDir, 'dir') == 7)
            mkdir(ncOutputFileDir);
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % PARTIAL RTQC ON TRAJECTORY FILE
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % store trajectory file path name
      ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Rtraj.nc', floatNum)];
      ncTrajOutputFilePathName = '';
      if (exist(ncTrajInputFilePathName, 'file') == 2)
         if (updateFiles == 0)
            ncTrajOutputFilePathName = [ncOutputFileDir sprintf('%d_Rtraj.nc', floatNum)];
         end
      else
         ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Dtraj.nc', floatNum)];
         if (exist(ncTrajInputFilePathName, 'file') == 2)
            if (updateFiles == 0)
               ncTrajOutputFilePathName = [ncOutputFileDir sprintf('%d_Dtraj.nc', floatNum)];
            end
         else
            fprintf('WARNING: Trajectory file not found\n');
            ncTrajInputFilePathName = '';
         end
      end
      
      % global variable to store temporary RTQC on traj data
      g_rtqc_trajData = [];
      if (~isempty(ncTrajInputFilePathName))
         
         % define the tests to perform on trajectory data
         testToPerformList2 = [ ...
            {'TEST002_IMPOSSIBLE_DATE'} {1} ...
            {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
            {'TEST004_POSITION_ON_LAND'} {1} ...
            {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {1} ...
            ];

         % perform RTQC on trajectory data (to fill JULD_QC, JULD_ADJUSTED_QC
         % and POSITION_QC)
         add_rtqc_to_trajectory_file(floatNum, ...
            ncTrajInputFilePathName, [], ...
            testToPerformList2, testMetaData, 1, 0, 0);
      else
         fprintf('WARNING: Trajectory file not found for float #%d\n', floatNum);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % RTQC ON PROFILE FILES
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % store multi profile file path name
      multiProfInputFilePathName = [ncInputFileDir sprintf('%d_prof.nc', floatNum)];
      multiProfOutputFilePathName = '';
      if (exist(multiProfInputFilePathName, 'file') == 2)
         if (updateFiles == 0)
            multiProfOutputFilePathName = [ncOutputFileDir sprintf('%d_prof.nc', floatNum)];
         end
      else
         fprintf('WARNING: No multi profile file\n');
         multiProfInputFilePathName = '';
      end
      
      % process mono-profile files
      ncInputFileDir = [ncInputFileDir '/profiles/'];
      
      if (exist(ncInputFileDir, 'dir') == 7)
         
         % create output directory
         if (updateFiles == 0)
            ncOutputFileDir = [ncOutputFileDir '/profiles/'];
            if ~(exist(ncOutputFileDir, 'dir') == 7)
               mkdir(ncOutputFileDir);
            end
         end
         
         ncInputFiles = dir([ncInputFileDir '*.nc']);
         % sort the file names so that descent profiles will be processed before
         % ascent associated one
         ncInputDescFiles = dir([ncInputFileDir '*D.nc']);
         for idFile = 1:length(ncInputDescFiles)
            descFileName = ncInputDescFiles(idFile).name;
            ascFileName = descFileName;
            ascFileName(end-3) = [];
            idFAsc = find(strcmp({ncInputFiles.name}, ascFileName) == 1);
            idFDesc = find(strcmp({ncInputFiles.name}, descFileName) == 1);
            if ((~isempty(idFAsc)) && (~isempty(idFDesc)))
               if (idFDesc > idFAsc)
                  tmp = ncInputFiles(idFAsc);
                  ncInputFiles(idFAsc) = ncInputFiles(idFDesc);
                  ncInputFiles(idFDesc) = tmp;
               end
            end
         end
         nbFiles = NB_FILES_TO_PROCESS;
         for idFile = 1:length(ncInputFiles)
            
            monoProfInputFileName = ncInputFiles(idFile).name;
            if (monoProfInputFileName(1) == 'B')
               continue
            end
            monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
            monoProfOutputFilePathName = '';
            if (updateFiles == 0)
               monoProfOutputFilePathName = [ncOutputFileDir '/' monoProfInputFileName];
            end
            
            fprintf('%s\n', monoProfInputFileName);
            
            % perform RTQC on profile data
            add_rtqc_to_profile_file(floatNum, ...
               monoProfInputFilePathName, monoProfOutputFilePathName, ...
               multiProfInputFilePathName, multiProfOutputFilePathName, ...
               testToPerformList, testMetaData, UPDATE_PROFILE_FILE_FLAG, 0);
            if (~isempty(multiProfOutputFilePathName))
               multiProfInputFilePathName = multiProfOutputFilePathName;
               multiProfOutputFilePathName = '';
            end
            fprintf('\n');
            nbFiles = nbFiles - 1;
            if (nbFiles == 0)
               break
            end
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % RTQC ON TRAJECTORY FILE
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
      if (~isempty(ncTrajInputFilePathName))
         
         [~, trajInputFileName, ~] = fileparts(ncTrajInputFilePathName);
         fprintf('%s\n', trajInputFileName);

         % perform RTQC on trajectory data
         add_rtqc_to_trajectory_file(floatNum, ...
            ncTrajInputFilePathName, ncTrajOutputFilePathName, ...
            testToPerformList, testMetaData, 0, UPDATE_TRAJECTORY_FILE_FLAG, 0);
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve from a list if a test has to be performed
%
% SYNTAX :
%  [o_testToPerform] = test_to_perform(a_testName, a_testToPerformList)
%
% INPUT PARAMETERS :
%   a_testName          : name of the test
%   a_testToPerformList : list of test to perform
%
% OUTPUT PARAMETERS :
%   o_testToPerform : test to perform flag (1 if the test has to be performed, 0
%                     otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_testToPerform] = test_to_perform(a_testName, a_testToPerformList)

% output parameters initialization
o_testToPerform = 0;


% check in the list if the test should be performed
testId = find(strcmp(a_testName, a_testToPerformList) == 1);
if (~isempty(testId))
   o_testToPerform = a_testToPerformList{testId+1};
end

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('RTQC_WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return