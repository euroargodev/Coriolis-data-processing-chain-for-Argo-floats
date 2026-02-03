% ------------------------------------------------------------------------------
% Add the real time QCs to NetCDF trajectory files.
%
% SYNTAX :
%  add_rtqc_to_trajectory_file(a_floatNum, ...
%    a_ncTrajInputFilePathName, a_ncTrajOutputFilePathName, ...
%    a_testToPerformList, a_testMetaData, ...
%    a_partialRtqcFlag, a_update_file_flag, a_justAfterDecodingFlag)
%
% INPUT PARAMETERS :
%   a_floatNum                 : float WMO number
%   a_ncTrajInputFilePathName  : input c trajectory file path name
%   a_ncTrajOutputFilePathName : output c trajectory file path name
%   a_testToPerformList        : list of tests to perform
%   a_testMetaData             : additionnal information associated to list of
%                                tests
%   a_partialRtqcFlag          : flag to perform only RTQC test on times and
%                                locations (and to store the results in a
%                                global variable)
%   a_update_file_flag         : file to update or not the file
%   a_justAfterDecodingFlag    : 1 if this function is called by
%                                add_rtqc_flags_to_netcdf_profile_and_trajectory_data
%                                (just after decoding), 0 otherwise
%                                (if set to 1, we keep Qc values set by the
%                                decoder)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/10/2016 - RNU - V 1.0: creation
%   03/14/2016 - RNU - V 1.1: - trajectory file should be retrieved fro storage
%                             directories, not from XML report.
%                             - incorrect initialization of testDoneList and
%                             testFailedList when no trajectory file is
%                             avaialable.
%   03/16/2016 - RNU - V 1.2: improved INFO, WARNING and ERROR messages (added
%                             float number (and cycle number when relevant))
%   04/13/2016 - RNU - V 1.3: update of the 'set_qc' function
%                             (g_decArgo_qcStrInterpolated QC value can be
%                             replaced by any QC value).
%   05/19/2016 - RNU - V 1.4: correction of the 'set_qc' function
%   06/17/2016 - RNU - V 1.5: don't initialize JULD_QC (or JULD_ADJUSTED_QC) to
%                             '0' if JULD_STATUS (or JULD_ADJUSTED_STATUS) is
%                             set to '9'.
%   07/04/2016 - RNU - V 1.6: apply test #22 on data sampled during "near
%                             surface" and "in air" phases (and stored with
%                             MC=g_MC_InAirSingleMeas).
%   09/15/2016 - RNU - V 1.7: - test #57 modified: PPOX_DOXY and PPOX_DOXY2
%                             refer to the same SENSOR (OPTODE_DOXY) - the
%                             first one to the Aanderaa, the second one to the
%                             SBE
%                             - when we link traj and prof data to retrieve prof
%                             QC in traj data, the comparaison can be done
%                             without PSAL (see "REPORT PROFILE QC IN TRAJECTORY
%                             DATA" in add_rtqc_to_profile_file.
%   10/05/2016 - RNU - V 1.8: when considering "in air" single measurements
%                             (MC=g_MC_InAirSingleMeas), consider also "in air"
%                             series of measurements (MC=g_MC_InAirSeriesOfMeas).
%   12/06/2016 - RNU - V 1.9: Test #57: new specific test defined for DOXY
%                             (if TEMP_QC=4 or PRES_QC=4, then DOXY_QC=4; if
%                              PSAL_QC=4, then DOXY_QC=3).
%   02/13/2017 - RNU - V 2.0: code update to manage CTS5 float data:
%                             - PRES2, TEMP2 and PSAL2 are present when a SUNA
%                               sensor is used
%   03/14/2017 - RNU - V 2.1: - code update to fix issues detected by the TRAJ
%                             checker: QC values are updated in 'c' and 'b'
%                             files according to the parameter values in each
%                             files (some QC values need to be set to ' ' when
%                             parameter values are set to FillValue in the
%                             appropriate file).
%                             - add RTQC test #62 for BBP
%   09/18/2018 - RNU - V 2.2: - to retrieve "Near Surface" and "In Air"
%                             measurements use:
%                             g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST
%                             g_MC_InAirSingleMeasRelativeToTST
%                             g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
%                             g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
%                             g_MC_InAirSingleMeasRelativeToTET
%                             instead of:
%                             g_MC_InAirSingleMeas
%                             g_MC_InAirSeriesOfMeas
%   11/06/2018 - RNU - V 2.3: TEST #6 (Global range test) updated for
%                             PH_IN_SITU_TOTAL parameter
%   02/12/2019 - RNU - V 2.4: TEST #20 (Questionable Argos position test)
%                             modified so that only 'good' locations (with QC =
%                             1) are used in the 'previous locations set' when
%                             processing the next cycle (see cycle #48 of float
%                             6903183).
%   03/26/2019 - RNU - V 2.5: Added RTQC tests for NITRATE parameter
%   07/15/2019 - RNU - V 2.6: In version 3.2 of the QC manual, for test #7, the
%                             minimal range for TEMP in the Read Sea has been
%                             set to 21°C (instead of 21.7°C).
%   09/23/2019 - RNU - V 2.7: Added "Global range test" for DOWN_IRRADIANCE380,
%                             DOWN_IRRADIANCE412, DOWN_IRRADIANCE443,
%                             DOWN_IRRADIANCE490 and DOWNWELLING_PAR.
%   02/25/2020 - RNU - V 2.8: Updated to cope with version 3.3 of core Argo
%                             Quality Control Manual:
%                              - Test 6: Global range test modified (for PRES).
%   02/25/2020 - RNU - V 2.8: Updated to cope with version 3.3 of core Argo
%                             Quality Control Manual:
%                              - Test 6: Global range test modified (for PRES).
%   06/19/2020 - RNU - V 2.9: TEST #57: set DOXY_QC = '3'
%   06/03/2021 - RNU - V 3.0: Updated to cope with version 3.5 of Argo Quality
%                             Control Manual For CTD and Trajectory Data
%                             - new test application order (tests 6 and 7 have
%                             moved)
%                             - a measurement with QC = '3' is tested by other
%                             quality control tests
%   06/21/2021 - RNU - V 3.1: JULD_QC and JULD_ADJUSTED_QC should not be
%                             initialized anymore (in APF11 DO profiles with the
%                             timestamp issue, JULD_QC is set to '2'
%   08/18/2021 - RNU - V 3.2: Minor modifications so that the same RTQC code can
%                             be used on C and B TRAJ 3.1 files or on the unique
%                             TRAJ 3.2 file
%   10/28/2021 - RNU - V 3.3: TEST 4 (position on land test) exclude Iridium
%                             locations
%                             TEST 7 (regional range test) don't use Iridium
%                             locations to determine region area
%   01/03/2022 - RNU - V 3.4: Exclude NaN values from get_gebco_elev_point
%                             output
%   12/02/2022 - RNU - V 3.5: Added "Global range test" for DOWN_IRRADIANCE665.
%   04/26/2023 - RNU - V 3.6: Implementation of new version of test #62 (BBP
%                             specific test)
%   09/22/2023 - RNU - V 3.7: Manage the case where no measurements are present
%                             in the TRAJ file
%   11/16/2023 - RNU - V 3.8: Added test #56 (PH specific test).
%   01/23/2024 - RNU - V 3.9: New global rule: if PRES_QC=4 then <PARAM>_QC=4
%                             for c, b, ic and ib parameters (tests #6 and #15
%                             are concerned).
%   02/12/2024 - RNU - V 4.0: - RTQC dedicated to TRAJ format 3.2 only.
%                             - update of TEST #56 "PH specific test" to be
%                             compliant with version 1.0 or Argo manual
%                             "BGC-Argo quality control manual for pH".
%                             - no difference between a PTSO float and a "true
%                             BGC" float.
%                             - generic data retrieving function
%                             (get_param_data) to be able to mix DATA_MODE.
%   05/15/2024 - RNU - V 4.1: Insert (PRES3, TEMP3, PSAL3) profile for Arvor
%                             Deep 3T prototype (decId 228)
%   12/13/2024 - RNU - V 4.2: TEST #60 PAR specific test added:
%                             Set DOWNWELLING_PAR_QC to '2'
%                             TEST #61 IRRADIANCE specific test added:
%                             Set DOWN_IRRADIANCExxx_QC to '2'
%   12/08/2025 - RNU - V 4.3: New management of N_HISTORY index.
%   01/28/2026 - RNU - V 4.4: HISTORY_INSTITUTION is set from DATA_CENTRE
%                             information stored in the META.json file (needed
%                             by the docker version).
% ------------------------------------------------------------------------------
function add_rtqc_to_trajectory_file(a_floatNum, ...
   a_ncTrajInputFilePathName, a_ncTrajOutputFilePathName, ...
   a_testToPerformList, a_testMetaData, ...
   a_partialRtqcFlag, a_update_file_flag, a_justAfterDecodingFlag)

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrChanged;       % '5'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'

% CHLA range min/max for RTQC test 6 (global range test)
global g_decArgo_rtqcTest6ChlaMin;
global g_decArgo_rtqcTest6ChlaMax;

% global measurement codes
global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTET;

% lists of managed decoders
global g_decArgo_decoderIdListAll;
global g_decArgo_decoderIdListDeepFloat;
global g_decArgo_decoderIdListBgcFloatAll;

% temporary trajectory data
global g_rtqc_trajData;

% global time status
global g_JULD_STATUS_9;

% program version
global g_decArgo_addRtqcToTrajVersion;
g_decArgo_addRtqcToTrajVersion = '4.4';

% Argo data start date
janFirst1997InJulD = gregorian_2_julian_dec_argo('1997/01/01 00:00:00');

% region definition for regional range test
RED_SEA_REGION = [[25 30 30 35]; ...
   [15 30 35 40]; ...
   [15 20 40 45]; ...
   [12.55 15 40 43]; ...
   [13 15 43 43.5]];

MEDITERRANEAN_SEA_REGION = [[30 40 -5 40]; ...
   [40 45 0 25]; ...
   [45 50 10 15]; ...
   [40 41 25 30]; ...
   [35.2 36.6 -5.4 -5]];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INFORMATION
% From version 4.0 this code is supposed to process TRAJ 3.2 only; moreover only
% RT TRAJ files are processed (no 'D' in DATA_MODE arrays).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check input trajectory file exists
if ~(exist(a_ncTrajInputFilePathName, 'file') == 2)
   fprintf('RTQC_ERROR: Float #%d: No input trajectory nc file to perform RTQC (%s)\n', ...
      a_floatNum, a_ncTrajInputFilePathName);
   return
end
ncTrajInputFilePathName = a_ncTrajInputFilePathName;

% check trajectory format version is 3.2
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'TRAJECTORY_PARAMETER_DATA_MODE'} ...
   ];
ncTrajData = get_data_from_nc_file(ncTrajInputFilePathName, wantedVars);
ncTrajInputFileFormatVersion = str2double(get_data_from_name('FORMAT_VERSION', ncTrajData));
if (ncTrajInputFileFormatVersion ~= 3.2)
   fprintf('RTQC_ERROR: Float #%d: Trajectory file is expected to be in format version 3.2 (while format version is %d for input file %s)\n', ...
      a_floatNum, ncTrajInputFileFormatVersion, ncTrajInputFilePathName);
   return
end
trajectoryParameterDataMode = get_data_from_name('TRAJECTORY_PARAMETER_DATA_MODE', ncTrajData);
if (any(trajectoryParameterDataMode == 'D'))
   fprintf('RTQC_ERROR: Float #%d: Trajectory file is expected to be in ''R'' or ''A'' DATA_MODE (some ''D'' are present in file %s)\n', ...
      a_floatNum, ncTrajInputFilePathName);
   return
end

% set trajectory output file name
ncTrajOutputFilePathName = a_ncTrajOutputFilePathName;
if (isempty(ncTrajOutputFilePathName))
   ncTrajOutputFilePathName = ncTrajInputFilePathName;
end

% list of possible tests
expectedTestList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} ...
   {'TEST002_IMPOSSIBLE_DATE'} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} ...
   {'TEST004_POSITION_ON_LAND'} ...
   {'TEST006_GLOBAL_RANGE'} ...
   {'TEST007_REGIONAL_RANGE'} ...
   {'TEST015_EXCLUSION_LIST'} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} ...
   {'TEST022_NS_MIXED_AIR_WATER'} ...
   {'TEST056_PH'} ...
   {'TEST057_DOXY'} ...
   {'TEST059_NITRATE'} ...
   {'TEST060_PAR'} ...
   {'TEST061_IRRADIANCE'} ...
   {'TEST062_BBP'} ...
   {'TEST063_CHLA'} ...
   ];

% retrieve the test to apply
lastTestNum = 63; % since profile tests can be reported in traj tests
testFlagList = zeros(lastTestNum, 1);
for idT = 1:length(expectedTestList)
   testName = expectedTestList{idT};
   testId = find(strcmp(testName, a_testToPerformList) == 1);
   if (~isempty(testId))
      testFlag = a_testToPerformList{testId+1};
      if (testFlag == 1)
         testFlagList(str2num(testName(5:7))) = 1;
      end
   end
end

% retrieve float decoder Id
floatDecoderId = '';
floatDecoderIdId = find(strcmp('TEST000_FLOAT_DECODER_ID', a_testMetaData) == 1);
if (~isempty(floatDecoderIdId))
   floatDecoderId = a_testMetaData{floatDecoderIdId+1};
end
if (~isempty(floatDecoderIdId))
   % check that the current float decoder Id is in the lists
   if (~ismember(floatDecoderId, g_decArgo_decoderIdListAll))
      fprintf('ERROR: Float #%d: decoderId=%d is not present in the check list of the add_rtqc_to_trajectory_file function\n', ...
         a_floatNum, floatDecoderId);
      return
   end
else
   fprintf('ERROR: Missing float decoder Id for float #%d\n', a_floatNum);
   return
end

% retrieve test additional information
parameterFlagOk = 0;
sensorFlagOk = 0;
parameterMeta = [];
parameterSensorMeta = [];
sensorMeta = [];
sensorModelMeta = [];

if (testFlagList(4) == 1)
   % for position on land test, we need the GEBCO file path name
   testMetaId = find(strcmp('TEST004_GEBCO_FILE', a_testMetaData) == 1);
   if (~isempty(testMetaId))
      gebcoPathFileName = a_testMetaData{testMetaId+1};
      if ~(exist(gebcoPathFileName, 'file') == 2)
         fprintf('RTQC_WARNING: TEST004: Float #%d: GEBCO file (%s) not found - test #4 not performed\n', ...
            a_floatNum, gebcoPathFileName);
         testFlagList(4) = 0;
      end
   else
      fprintf('RTQC_WARNING: TEST004: Float #%d: GEBCO file needed to perform test #4 - test #4 not performed\n', ...
         a_floatNum);
      testFlagList(4) = 0;
   end
end

if (testFlagList(15) == 1)
   % for supplemental sensor exclusion list test, we need the exclusion list file path name
   testMetaId = find(strcmp('TEST015_EXCLUSION_LIST_FILE', a_testMetaData) == 1);
   if (~isempty(testMetaId))
      exclusionListPathFileName = a_testMetaData{testMetaId+1};
      if ~(exist(exclusionListPathFileName, 'file') == 2)
         fprintf('RTQC_WARNING: TEST015: Float #%d: Exclusion list file (%s) not found - test #15 not performed\n', ...
            a_floatNum, exclusionListPathFileName);
         testFlagList(15) = 0;
      end
   else
      fprintf('RTQC_WARNING: TEST005: Float #%d: Exclusion list file needed to perform test #15 - test #15 not performed\n', ...
         a_floatNum);
      testFlagList(15) = 0;
   end
end

if (testFlagList(21) == 1)
   % for near-surface unpumped CTD salinity test, we need the Apex flag value
   % and the nc meta-data file path name
   if (~isempty(floatDecoderId))
      apexFloatFlag = ((floatDecoderId > 1000) && (floatDecoderId < 2000));
   else
      fprintf('RTQC_WARNING: TEST021: Float #%d: Apex float flag needed to perform test #21 - test #21 not performed\n', ...
         a_floatNum);
      testFlagList(21) = 0;
   end

   if (testFlagList(21) == 1)
      if (~parameterFlagOk || ~sensorFlagOk)

         testMetaId = find(strcmp('TEST021_METADA_DATA_FILE', a_testMetaData) == 1);
         if (~isempty(testMetaId))
            ncMetaPathFileName = a_testMetaData{testMetaId+1};
            if ~(exist(ncMetaPathFileName, 'file') == 2)
               fprintf('RTQC_WARNING: TEST021: Float #%d: Nc meta-data file (%s) not found - test #21 not performed\n', ...
                  a_floatNum, ncMetaPathFileName);
               testFlagList(21) = 0;
            end
         else
            fprintf('RTQC_WARNING: TEST021: Float #%d: Nc meta-data file needed to perform test #21 - test #21 not performed\n', ...
               a_floatNum);
            testFlagList(21) = 0;
         end

         if (testFlagList(21) == 1)

            parameterFlagOk = 1;
            sensorFlagOk = 1;

            % retrieve information from NetCDF meta file
            wantedVars = [ ...
               {'PARAMETER'} ...
               {'PARAMETER_SENSOR'} ...
               {'SENSOR'} ...
               {'SENSOR_MODEL'} ...
               ];

            % retrieve information from NetCDF meta file
            [ncMetaData] = get_data_from_nc_file(ncMetaPathFileName, wantedVars);

            if (isempty(parameterMeta))
               parameterMeta = [];
               idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
               if (~isempty(idVal))
                  parameterMetaTmp = ncMetaData{idVal+1}';

                  for id = 1:size(parameterMetaTmp, 1)
                     parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
                  end
               end
            end

            if (isempty(parameterSensorMeta))
               parameterSensorMeta = [];
               idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
               if (~isempty(idVal))
                  parameterSensorMetaTmp = ncMetaData{idVal+1}';

                  for id = 1:size(parameterSensorMetaTmp, 1)
                     parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
                  end
               end
            end

            if (isempty(sensorMeta))
               sensorMeta = [];
               idVal = find(strcmp('SENSOR', ncMetaData) == 1);
               if (~isempty(idVal))
                  sensorMetaTmp = ncMetaData{idVal+1}';

                  for id = 1:size(sensorMetaTmp, 1)
                     sensorMeta{end+1} = deblank(sensorMetaTmp(id, :));
                  end
               end
            end

            if (isempty(sensorModelMeta))
               sensorModelMeta = [];
               idVal = find(strcmp('SENSOR_MODEL', ncMetaData) == 1);
               if (~isempty(idVal))
                  sensorModelMetaTmp = ncMetaData{idVal+1}';

                  for id = 1:size(sensorModelMetaTmp, 1)
                     sensorModelMeta{end+1} = deblank(sensorModelMetaTmp(id, :));
                  end
               end
            end
         end
      end
   end
end

if (testFlagList(57) == 1)
   % for DOXY specific test, we need to identify BGC floats and the nc meta-data file path name
   if (~isempty(floatDecoderId) && ~isempty(g_decArgo_decoderIdListBgcFloatAll))
      if (ismember(floatDecoderId, g_decArgo_decoderIdListBgcFloatAll))
         bgcFloatFlag = 1;
      else
         bgcFloatFlag = 0;
      end
   elseif (isempty(floatDecoderId))
      fprintf('RTQC_WARNING: TEST057: Float #%d: Decoder Id needed to perform test #57 - test #57 not performed\n', ...
         a_floatNum);
      testFlagList(57) = 0;
   elseif (isempty(g_decArgo_decoderIdListDeepFloat))
      fprintf('RTQC_WARNING: TEST057: Float #%d: BGC float flag information needed to perform test #57 - test #57 not performed\n', ...
         a_floatNum);
      testFlagList(57) = 0;
   end

   if (testFlagList(57) == 1)
      if (~parameterFlagOk || ~sensorFlagOk)
         testMetaId = find(strcmp('TEST057_METADA_DATA_FILE', a_testMetaData) == 1);
         if (~isempty(testMetaId))
            ncMetaPathFileName = a_testMetaData{testMetaId+1};
            if ~(exist(ncMetaPathFileName, 'file') == 2)
               fprintf('RTQC_WARNING: TEST057: Float #%d: Nc meta-data file (%s) not found - test #57 not performed\n', ...
                  a_floatNum, ncMetaPathFileName);
               testFlagList(57) = 0;
            end
         else
            fprintf('RTQC_WARNING: TEST057: Float #%d: Nc meta-data file needed to perform test #57 - test #57 not performed\n', ...
               a_floatNum);
            testFlagList(57) = 0;
         end

         if (testFlagList(57) == 1)

            parameterFlagOk = 1;
            sensorFlagOk = 1;

            % retrieve information from NetCDF meta file
            wantedVars = [ ...
               {'PARAMETER'} ...
               {'PARAMETER_SENSOR'} ...
               {'SENSOR'} ...
               {'SENSOR_MODEL'} ...
               ];

            % retrieve information from NetCDF meta file
            [ncMetaData] = get_data_from_nc_file(ncMetaPathFileName, wantedVars);

            parameterMeta = [];
            idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
            if (~isempty(idVal))
               parameterMetaTmp = ncMetaData{idVal+1}';

               for id = 1:size(parameterMetaTmp, 1)
                  parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
               end
            end

            parameterSensorMeta = [];
            idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
            if (~isempty(idVal))
               parameterSensorMetaTmp = ncMetaData{idVal+1}';

               for id = 1:size(parameterSensorMetaTmp, 1)
                  parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
               end
            end

            sensorMeta = [];
            idVal = find(strcmp('SENSOR', ncMetaData) == 1);
            if (~isempty(idVal))
               sensorMetaTmp = ncMetaData{idVal+1}';

               for id = 1:size(sensorMetaTmp, 1)
                  sensorMeta{end+1} = deblank(sensorMetaTmp(id, :));
               end
            end

            sensorModelMeta = [];
            idVal = find(strcmp('SENSOR_MODEL', ncMetaData) == 1);
            if (~isempty(idVal))
               sensorModelMetaTmp = ncMetaData{idVal+1}';

               for id = 1:size(sensorModelMetaTmp, 1)
                  sensorModelMeta{end+1} = deblank(sensorModelMetaTmp(id, :));
               end
            end
         end
      end
   end
end

% check if any test has to be performed
if (isempty(find(testFlagList == 1, 1)))
   fprintf('RTQC_INFO: Float #%d: No RTQC test to perform\n', a_floatNum);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataStruct = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ TRAJECTORY DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve parameter fill values
paramJuld = get_netcdf_param_attributes('JULD');
paramLat = get_netcdf_param_attributes('LATITUDE');
paramLon = get_netcdf_param_attributes('LONGITUDE');

% retrieve the data from the core trajectory file
wantedVars = [ ...
   {'TRAJECTORY_PARAMETERS'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_ADJUSTED'} ...
   {'JULD_ADJUSTED_QC'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_ACCURACY'} ...
   {'POSITION_QC'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   {'AXES_ERROR_ELLIPSE_MAJOR'} ...
   ];
ncTrajData = get_data_from_nc_file(ncTrajInputFilePathName, wantedVars);

trajectoryParameters = get_data_from_name('TRAJECTORY_PARAMETERS', ncTrajData);
juld = get_data_from_name('JULD', ncTrajData);
juldQc = get_data_from_name('JULD_QC', ncTrajData)';
juldAdj = get_data_from_name('JULD_ADJUSTED', ncTrajData);
juldAdjQc = get_data_from_name('JULD_ADJUSTED_QC', ncTrajData)';
latitude = get_data_from_name('LATITUDE', ncTrajData);
longitude = get_data_from_name('LONGITUDE', ncTrajData);
positionAccuracy = get_data_from_name('POSITION_ACCURACY', ncTrajData)';
positionQc = get_data_from_name('POSITION_QC', ncTrajData)';
cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
axesErrorEllipseMajor = get_data_from_name('AXES_ERROR_ELLIPSE_MAJOR', ncTrajData);

% create the list of parameters
[~, nParam] = size(trajectoryParameters);
ncTrajParamNameList = [];
ncTrajParamAdjNameList = [];
for idParam = 1:nParam
   paramName = deblank(trajectoryParameters(:, idParam)');
   if (~isempty(paramName))
      if (~any(strcmp(paramName, ncTrajParamNameList)))
         ncTrajParamNameList{end+1} = paramName;
         paramInfo = get_netcdf_param_attributes(paramName);
         if (paramInfo.adjAllowed == 1)
            ncTrajParamAdjNameList = [ncTrajParamAdjNameList ...
               {[paramName '_ADJUSTED']} ...
               ];
         end
      end
   end
end

% retrieve the data
ncTrajParamNameQcList = [];
wantedVars = [];
for idParam = 1:length(ncTrajParamNameList)
   paramName = ncTrajParamNameList{idParam};
   paramNameQc = [paramName '_QC'];
   ncTrajParamNameQcList{end+1} = paramNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramName} ...
      {paramNameQc} ...
      ];
end
ncTrajParamAdjNameQcList = [];
for idParam = 1:length(ncTrajParamAdjNameList)
   paramAdjName = ncTrajParamAdjNameList{idParam};
   paramAdjNameQc = [paramAdjName '_QC'];
   ncTrajParamAdjNameQcList{end+1} = paramAdjNameQc;
   wantedVars = [ ...
      wantedVars ...
      {paramAdjName} ...
      {paramAdjNameQc} ...
      ];
end

ncTrajData = get_data_from_nc_file(ncTrajInputFilePathName, wantedVars);

ncTrajParamDataList = [];
ncTrajParamDataQcList = [];
ncTrajParamFillValueList = [];
for idParam = 1:length(ncTrajParamNameList)
   paramName = ncTrajParamNameList{idParam};
   paramNameData = lower(paramName);
   ncTrajParamDataList{end+1} = paramNameData;
   paramNameQc = ncTrajParamNameQcList{idParam};
   paramNameQcData = lower(paramNameQc);
   ncTrajParamDataQcList{end+1} = paramNameQcData;
   paramInfo = get_netcdf_param_attributes(paramName);
   ncTrajParamFillValueList{end+1} = paramInfo.fillValue;

   data = get_data_from_name(paramName, ncTrajData);
   if (size(data, 2) > 1)
      data = permute(data, ndims(data):-1:1);
   end
   dataQc = get_data_from_name(paramNameQc, ncTrajData)';

   dataStruct.(paramNameData) = data;
   dataStruct.(paramNameQcData) = dataQc;
end
ncTrajParamAdjDataList = [];
ncTrajParamAdjDataQcList = [];
ncTrajParamAdjFillValueList = [];
for idParam = 1:length(ncTrajParamAdjNameList)
   paramAdjName = ncTrajParamAdjNameList{idParam};
   paramAdjNameData = lower(paramAdjName);
   ncTrajParamAdjDataList{end+1} = paramAdjNameData;
   paramAdjNameQc = ncTrajParamAdjNameQcList{idParam};
   paramAdjNameQcData = lower(paramAdjNameQc);
   ncTrajParamAdjDataQcList{end+1} = paramAdjNameQcData;
   paramInfo = get_netcdf_param_attributes(paramAdjName(1:end-9));
   ncTrajParamAdjFillValueList{end+1} = paramInfo.fillValue;

   data = get_data_from_name(paramAdjName, ncTrajData);
   if (size(data, 2) > 1)
      data = permute(data, ndims(data):-1:1);
   end
   dataQc = get_data_from_name(paramAdjNameQc, ncTrajData)';

   dataStruct.(paramAdjNameData) = data;
   dataStruct.(paramAdjNameQcData) = dataQc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataStruct.cycleNumber = cycleNumber;
dataStruct.measurementCode = measurementCode;

dataStruct.ncTrajParamNameList = ncTrajParamNameList;
dataStruct.ncTrajParamNameQcList = ncTrajParamNameQcList;

dataStruct.ncTrajParamDataList = ncTrajParamDataList;
dataStruct.ncTrajParamDataQcList = ncTrajParamDataQcList;
dataStruct.ncTrajParamFillValueList = ncTrajParamFillValueList;

dataStruct.ncTrajParamAdjNameList = ncTrajParamAdjNameList;
dataStruct.ncTrajParamAdjNameQcList = ncTrajParamAdjNameQcList;

dataStruct.ncTrajParamAdjDataList = ncTrajParamAdjDataList;
dataStruct.ncTrajParamAdjDataQcList = ncTrajParamAdjDataQcList;
dataStruct.ncTrajParamAdjFillValueList = ncTrajParamAdjFillValueList;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APPLY RTQC TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% test lists initialization
testDoneList = zeros(lastTestNum, 1);
testFailedList = zeros(lastTestNum, 1);

% data QC initialization
% set QC = ' ' for unused values and QC = '0' for existing values

% JULD_QC

% JULD_QC and JULD_ADJUSTED_QC should not be initialized anymore (in APF11 DO
% profiles with the timestamp issue, JULD_QC is set to '2')

% % initialize JULD_QC (except when JULD_STATUS = '9')
% idUpdate = find(juldStatus ~= g_JULD_STATUS_9);
% if (~isempty(idUpdate))
%    juldQc(idUpdate) = g_decArgo_qcStrDef;
% end
% idNoDef = find(juld ~= paramJuld.fillValue);
% if (~isempty(idNoDef))
%    juldQc(idNoDef) = g_decArgo_qcStrNoQc;
% end
% % JULD_ADJUSTED_QC
% % initialize JULD_ADJUSTED_QC (except when JULD_ADJUSTED_STATUS = '9')
% idUpdate = find(juldAdjStatus ~= g_JULD_STATUS_9);
% if (~isempty(idUpdate))
%    juldAdjQc(idUpdate) = g_decArgo_qcStrDef;
% end
% idNoDef = find(juldAdj ~= paramJuld.fillValue);
% if (~isempty(idNoDef))
%    juldAdjQc(idNoDef) = g_decArgo_qcStrNoQc;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize POSITION_QC
positionQc = repmat(g_decArgo_qcStrDef, size(positionQc));

% initialize POSITION_QC to '0' when a location is set
idNoDef = find((juld ~= paramJuld.fillValue) & ...
   (latitude ~= paramLat.fillValue) & ...
   (longitude ~= paramLon.fillValue));
positionQc(idNoDef) = g_decArgo_qcStrNoQc;

% POSITION_QC of launch position should be set to g_decArgo_qcStrNoQc (see TRAJ
% cookbook)
% before being checked by tests #3 and #4

% set Iridium POSITION_QC according to CEP radius
% POSITION_QC = '1' if CEP radius < 5 km, POSITION_QC = '2' otherwise
idGood = find((juld ~= paramJuld.fillValue) & ...
   (latitude ~= paramLat.fillValue) & ...
   (longitude ~= paramLon.fillValue) & ...
   (positionAccuracy == 'I')' & ...
   (axesErrorEllipseMajor < 5000));
positionQc(idGood) = set_qc(positionQc(idGood), g_decArgo_qcStrGood);
idProbablyGood = find((juld ~= paramJuld.fillValue) & ...
   (latitude ~= paramLat.fillValue) & ...
   (longitude ~= paramLon.fillValue) & ...
   (positionAccuracy == 'I')' & ...
   (axesErrorEllipseMajor >= 5000));
positionQc(idProbablyGood) = set_qc(positionQc(idProbablyGood), g_decArgo_qcStrProbablyGood);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize <PARAM>_QC

% one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
for idD = 1:2
   if (idD == 1)
      % non adjusted data processing

      % set the name list
      ncTrajParamXNameList = ncTrajParamNameList;
      ncTrajParamXDataList = ncTrajParamDataList;
      ncTrajParamXDataQcList = ncTrajParamDataQcList;
      ncTrajParamXFillValueList = ncTrajParamFillValueList;
   else
      % adjusted data processing

      % set the name list
      ncTrajParamXNameList = ncTrajParamAdjNameList;
      ncTrajParamXDataList = ncTrajParamAdjDataList;
      ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
      ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
   end

   for idParam = 1:length(ncTrajParamXNameList)
      paramName = ncTrajParamXNameList{idParam};
      data = dataStruct.(ncTrajParamXDataList{idParam});
      dataQc = dataStruct.(ncTrajParamXDataQcList{idParam});
      paramFillValue = ncTrajParamXFillValueList{idParam};

      if (~isempty(data))
         if (size(data, 2) == 1)
            idNoDef = find(data ~= paramFillValue);
         else
            idNoDef = [];
            for idL = 1: size(data, 1)
               uDataL = unique(data(idL, :));
               if ~((length(uDataL) == 1) && (uDataL == paramFillValue))
                  idNoDef = [idNoDef idL];
               end
            end
         end

         % initialize Qc flags
         if (a_justAfterDecodingFlag == 1)
            % initialize Qc flags to g_decArgo_qcStrNoQc except for those which
            % have been set by the decoder (in
            % update_qc_from_sensor_state_ir_rudics_sbd2)
            dataQc(idNoDef) = set_qc(dataQc(idNoDef), g_decArgo_qcStrNoQc);

            % initialize NITRATE_QC to g_decArgo_qcStrCorrectable
            % initialize NITRATE_ADJUSTED_QC to g_decArgo_qcStrProbablyGood
            if (strcmp(paramName, 'NITRATE'))
               dataQc(idNoDef) = set_qc(dataQc(idNoDef), g_decArgo_qcStrCorrectable);
            elseif (strcmp(paramName, 'NITRATE_ADJUSTED'))
               dataQc(idNoDef) = set_qc(dataQc(idNoDef), g_decArgo_qcStrProbablyGood);
            end
         else
            % initialize Qc flags to g_decArgo_qcStrNoQc
            dataQc = repmat(g_decArgo_qcStrDef, size(dataQc));
            dataQc(idNoDef) = g_decArgo_qcStrNoQc;

            % initialize NITRATE_QC to g_decArgo_qcStrCorrectable
            % initialize NITRATE_ADJUSTED_QC to g_decArgo_qcStrProbablyGood
            if (strcmp(paramName, 'NITRATE'))
               dataQc(idNoDef) = g_decArgo_qcStrCorrectable;
            elseif (strcmp(paramName, 'NITRATE_ADJUSTED'))
               dataQc(idNoDef) = g_decArgo_qcStrProbablyGood;
            end
         end
         dataStruct.(ncTrajParamXDataQcList{idParam}) = dataQc;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REPORT RTQC PROFILE TEST RESULTS IN TRAJ DATA
%
if (~isempty(g_rtqc_trajData))

   % initialize parameter Qc with profile RTQC results

   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing

         % set the name list
         ncTrajParamXDataQcList = ncTrajParamDataQcList;
      else
         % adjusted data processing

         % set the name list
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
      end

      for idParam = 1:length(ncTrajParamXDataQcList)
         if (isfield(g_rtqc_trajData, ncTrajParamXDataQcList{idParam}))
            dataStruct.(ncTrajParamXDataQcList{idParam}) = g_rtqc_trajData.(ncTrajParamXDataQcList{idParam});
         end
      end
      if (isfield(g_rtqc_trajData, 'testDoneList'))
         testDoneList = g_rtqc_trajData.testDoneList;
         testFailedList = g_rtqc_trajData.testFailedList;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 1: platform identification test
%
if (testFlagList(1) == 1)
   % always Ok
   testDoneList(1) = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 2: impossible date test
%
if (testFlagList(2) == 1)

   % as JULD is a julian date we only need to check it is after 01/01/1997
   % and before the current date
   idNoDef = find(juld ~= paramJuld.fillValue);
   if (~isempty(idNoDef))
      % initialize Qc flag
      juldQc(idNoDef) = set_qc(juldQc(idNoDef), g_decArgo_qcStrGood);
      % apply the test
      idToFlag = find((juld(idNoDef) < janFirst1997InJulD) | ...
         ((juld(idNoDef)+g_decArgo_janFirst1950InMatlab) > now_utc));
      if (~isempty(idToFlag))
         juldQc(idNoDef(idToFlag)) = set_qc(juldQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);

         testFailedList(2) = 1;
      end
      testDoneList(2) = 1;
   end
   idNoDef = find(juldAdj ~= paramJuld.fillValue);
   if (~isempty(idNoDef))
      % initialize Qc flag
      juldAdjQc(idNoDef) = set_qc(juldAdjQc(idNoDef), g_decArgo_qcStrGood);
      % apply the test
      idToFlag = find((juldAdj(idNoDef) < janFirst1997InJulD) | ...
         ((juldAdj(idNoDef)+g_decArgo_janFirst1950InMatlab) > now_utc));
      if (~isempty(idToFlag))
         juldAdjQc(idNoDef(idToFlag)) = set_qc(juldAdjQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);

         testFailedList(2) = 1;
      end
      testDoneList(2) = 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 3: impossible location test
%
if (testFlagList(3) == 1)

   idNoDef = find((latitude ~= paramLat.fillValue) & (longitude ~= paramLon.fillValue));
   if (~isempty(idNoDef))
      % initialize Qc flag
      positionQc(idNoDef) = set_qc(positionQc(idNoDef), g_decArgo_qcStrGood);
      % apply the test
      idToFlag = find((latitude(idNoDef) > 90) | (latitude(idNoDef) < -90) | ...
         (longitude(idNoDef) > 180) | (longitude(idNoDef) <= -180));
      if (~isempty(idToFlag))
         positionQc(idNoDef(idToFlag)) = set_qc(positionQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);

         testFailedList(3) = 1;
      end
      testDoneList(3) = 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 4: position on land test
%
if (testFlagList(4) == 1)

   % we check that the mean value of the elevations provided by the GEBCO
   % bathymetric atlas is < 0
   idNoDef = find((latitude ~= paramLat.fillValue) & (longitude ~= paramLon.fillValue) & ...
      (positionAccuracy ~= 'I')'); % to exclude Iridium locations
   if (~isempty(idNoDef))

      testDoneList(4) = 1;

      % initialize Qc flag
      positionQc(idNoDef) = set_qc(positionQc(idNoDef), g_decArgo_qcStrGood);

      % ignore duplicated locations
      [uLonLat, ~, ic] = unique([longitude(idNoDef), latitude(idNoDef)], 'rows');

      % retrieve GEBCO elevations
      [elev] = get_gebco_elev_point(uLonLat(:, 1), uLonLat(:, 2), gebcoPathFileName);

      % apply the test
      idToFlag = [];
      for idP = 1:size(elev, 1)
         elevation = elev(idP, :);
         elevation(isnan(elevation)) = [];
         if (mean(elevation) >= 0)
            idF = find(ic == idP);
            idToFlag = [idToFlag idF'];
         end
      end

      if (~isempty(idToFlag))
         positionQc(idNoDef(idToFlag)) = set_qc(positionQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
         testFailedList(4) = 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 20: questionable Argos position test
%
if (testFlagList(20) == 1)

   uCycleNumber = unique(cycleNumber(cycleNumber >= 0));
   cyNumPrev = -1;
   for idCy = 1:length(uCycleNumber)
      cyNum = uCycleNumber(idCy);

      idMeasForCy = find(cycleNumber == cyNum);
      idNoDef = find((juld(idMeasForCy) ~= paramJuld.fillValue) & ...
         (latitude(idMeasForCy) ~= paramLat.fillValue) & ...
         (longitude(idMeasForCy) ~= paramLon.fillValue) & ...
         (juldQc(idMeasForCy) ~= g_decArgo_qcStrBad)' & ...
         (positionQc(idMeasForCy) ~= g_decArgo_qcStrBad)' & ...
         (positionAccuracy(idMeasForCy) ~= ' ')' & ... % to exclude launch location
         (positionAccuracy(idMeasForCy) ~= 'I')'); % to exclude Iridium locations
      if (~isempty(idNoDef))

         lastLocDateOfPrevCycle = g_decArgo_dateDef;
         lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
         lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
         if ((cyNumPrev ~= -1) && (cyNumPrev == cyNum-1))
            lastLocDateOfPrevCycle = lastLocDate;
            lastLocLonOfPrevCycle = lastLocLon;
            lastLocLatOfPrevCycle = lastLocLat;
         end

         [positionQc(idMeasForCy(idNoDef))] = compute_jamstec_qc( ...
            juld(idMeasForCy(idNoDef)), ...
            longitude(idMeasForCy(idNoDef)), ...
            latitude(idMeasForCy(idNoDef)), ...
            positionAccuracy(idMeasForCy(idNoDef)), ...
            lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);

         % keep only 'good' positions for the next cycle
         if (any(positionQc(idMeasForCy(idNoDef)) == g_decArgo_qcStrGood))
            cyNumPrev = cyNum;
            allPosDate = juld(idMeasForCy(idNoDef));
            allPosLon = longitude(idMeasForCy(idNoDef));
            allPosLat= latitude(idMeasForCy(idNoDef));
            allPosQc = positionQc(idMeasForCy(idNoDef));
            idKeep = find(allPosQc == g_decArgo_qcStrGood);
            keepPosDate = allPosDate(idKeep);
            keepPosLon = allPosLon(idKeep);
            keepPosLat= allPosLat(idKeep);
            [lastLocDate, idLast] = max(keepPosDate);
            lastLocLon = keepPosLon(idLast);
            lastLocLat = keepPosLat(idLast);
         end

         if (any((positionQc(idMeasForCy(idNoDef)) == g_decArgo_qcStrCorrectable) | ...
               (positionQc(idMeasForCy(idNoDef)) == g_decArgo_qcStrBad)))
            testFailedList(20) = 1;
         end
         testDoneList(20) = 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STORE PARTIAL RTQC IN GLOBAL VARIABLE
%

if (a_partialRtqcFlag == 1)

   % update the global variable to report traj data
   g_rtqc_trajData = [];

   % data for test 5/20 on profile location
   g_rtqc_trajData.juld = juld;
   g_rtqc_trajData.juldQc = juldQc;
   g_rtqc_trajData.juldAdj = juldAdj;
   g_rtqc_trajData.juldAdjQc = juldAdjQc;
   g_rtqc_trajData.latitude = latitude;
   g_rtqc_trajData.longitude = longitude;
   g_rtqc_trajData.positionAccuracy = positionAccuracy;
   g_rtqc_trajData.positionQc = positionQc;

   % data to report profile Qc in traj data
   g_rtqc_trajData.cycleNumber = cycleNumber;
   g_rtqc_trajData.measurementCode = measurementCode;

   % one loop for <PARAM> and one loop for <PARAM>_ADJUSTED
   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing

         % set the name list
         ncTrajParamXNameList = ncTrajParamNameList;
         ncTrajParamXDataList = ncTrajParamDataList;
         ncTrajParamXDataQcList = ncTrajParamDataQcList;

         g_rtqc_trajData.ncTrajParamNameList = ncTrajParamNameList;
         g_rtqc_trajData.ncTrajParamDataList = ncTrajParamDataList;
         g_rtqc_trajData.ncTrajParamDataQcList = ncTrajParamDataQcList;
         g_rtqc_trajData.ncTrajParamFillValueList = ncTrajParamFillValueList;
      else
         % adjusted data processing

         % set the name list
         ncTrajParamXNameList = ncTrajParamAdjNameList;
         ncTrajParamXDataList = ncTrajParamAdjDataList;
         ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;

         g_rtqc_trajData.ncTrajParamAdjNameList = ncTrajParamAdjNameList;
         g_rtqc_trajData.ncTrajParamAdjDataList = ncTrajParamAdjDataList;
         g_rtqc_trajData.ncTrajParamAdjDataQcList = ncTrajParamAdjDataQcList;
         g_rtqc_trajData.ncTrajParamAdjFillValueList = ncTrajParamAdjFillValueList;
      end

      for idParam = 1:length(ncTrajParamXNameList)
         g_rtqc_trajData.(ncTrajParamXDataList{idParam}) = dataStruct.(ncTrajParamXDataList{idParam});
         g_rtqc_trajData.(ncTrajParamXDataQcList{idParam}) = dataStruct.(ncTrajParamXDataQcList{idParam});
      end
   end

   clear variables;
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 15: supplemental sensor exclusion list test
%
if (testFlagList(15) == 1)

   % read exclusion list file
   fId = fopen(exclusionListPathFileName, 'r');
   if (fId == -1)
      fprintf('RTQC_WARNING: TEST015: Float #%d: Unable to open exclusion list file (%s) - test #15 not performed\n', ...
         a_floatNum, exclusionListPathFileName);
   else
      fileContents = textscan(fId, '%s', 'delimiter', ',');
      fclose(fId);
      fileContents = fileContents{:};
      if (rem(size(fileContents, 1), 7) ~= 0)
         fprintf('RTQC_WARNING: TEST015: Float #%d: Unable to parse exclusion list file (%s) - test #15 not performed\n', ...
            a_floatNum, exclusionListPathFileName);
      else

         exclusionListInfo = reshape(fileContents, 7, size(fileContents, 1)/7)';

         % retrieve information for the current float
         idF = find(strcmp(num2str(a_floatNum), exclusionListInfo(:, 1)) == 1);

         % apply the exclusion list information
         presQc4Flag = 0;
         for id = 1:length(idF)

            startDate = exclusionListInfo{idF(id), 3};
            endDate = exclusionListInfo{idF(id), 4};
            qcVal = exclusionListInfo{idF(id), 5};

            startDateJuld = datenum(startDate, 'yyyymmdd') - g_decArgo_janFirst1950InMatlab;
            endDateJuld = '';
            if (~isempty(endDate))
               endDateJuld = datenum(endDate, 'yyyymmdd') - g_decArgo_janFirst1950InMatlab;
            end

            for idD = 1:2
               if (idD == 1)
                  % non adjusted data processing

                  % set the name list
                  ncTrajParamXNameList = ncTrajParamNameList;
                  ncTrajParamXDataList = ncTrajParamDataList;
                  ncTrajParamXDataQcList = ncTrajParamDataQcList;
                  ncTrajParamXFillValueList = ncTrajParamFillValueList;
                  juldX = juld;
                  juldXQc = juldQc;

                  % retrieve exclusion listed parameter name
                  paramName = exclusionListInfo{idF(id), 2};
               else
                  % adjusted data processing

                  % set the name list
                  ncTrajParamXNameList = ncTrajParamAdjNameList;
                  ncTrajParamXDataList = ncTrajParamAdjDataList;
                  ncTrajParamXDataQcList = ncTrajParamAdjDataQcList;
                  ncTrajParamXFillValueList = ncTrajParamAdjFillValueList;
                  juldX = juldAdj;
                  juldXQc = juldAdjQc;

                  % retrieve exclusion listed parameter adjusted name
                  paramName = [exclusionListInfo{idF(id), 2} '_ADJUSTED'];
               end

               cyclelist = [];
               idFirstMeas = find( ...
                  ((juldXQc == g_decArgo_qcStrGood)' | ...
                  (juldXQc == g_decArgo_qcStrProbablyGood)') & ...
                  (juldX >= startDateJuld), 1, 'first');
               if (~isempty(idFirstMeas))
                  firstCycle = cycleNumber(idFirstMeas);

                  lastCycle = [];
                  if (~isempty(endDateJuld))
                     idLastMeas = find( ...
                        ((juldXQc == g_decArgo_qcStrGood)' | ...
                        (juldXQc == g_decArgo_qcStrProbablyGood)') & ...
                        (juldX <= endDateJuld), 1, 'last');
                     if (~isempty(idLastMeas))
                        lastCycle = cycleNumber(idLastMeas);
                     end
                  end

                  if (isempty(lastCycle))
                     cyclelist = [firstCycle:max(cycleNumber)];
                  else
                     cyclelist = [firstCycle:lastCycle];
                  end
               end
               if (~isempty(cyclelist))
                  idParam = find(strcmp(paramName, ncTrajParamXNameList), 1);
                  if (~isempty(idParam))
                     data = dataStruct.(ncTrajParamXDataList{idParam});
                     dataQc = dataStruct.(ncTrajParamXDataQcList{idParam});
                     paramFillValue = ncTrajParamXFillValueList{idParam};

                     idMeas = find( ...
                        (data ~= paramFillValue) & ...
                        ismember(cycleNumber, cyclelist));

                     % apply the test
                     dataQc(idMeas) = set_qc(dataQc(idMeas), qcVal);
                     dataStruct.(ncTrajParamXDataQcList{idParam}) = dataQc;

                     testDoneList(15) = 1;
                     testFailedList(15) = 1;

                     if (strncmp(paramName, 'PRES', length('PRES')) && (qcVal == g_decArgo_qcStrBad))
                        presQc4Flag = 1;
                     end
                  end
               end
            end
         end

         % apply general rule: if PRES_QC=4 then <PARAM>_QC=4 for c, b, ic and ib
         % parameters
         if (presQc4Flag)
            dataStruct = update_qc_for_bad_pres(dataStruct);
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 21: near-surface unpumped CTD salinity test
%
if (testFlagList(21) == 1)

   % in this adaptation of test 21 to trajectory data, near-surface measurements
   % are selected through the measurement codes:
   % g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST
   % g_MC_InAirSingleMeasRelativeToTST
   % g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
   % g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
   % g_MC_InAirSingleMeasRelativeToTET

   if (apexFloatFlag == 0)

      % list of parameters concerned by this test
      test21ParameterList = [ ...
         {'PSAL'} ...
         {'PSAL2'} ...
         {'PSAL_2'} ...
         % {'PSAL3'} ... % not involved in this test because assigned to RBR salinity (decId 228)
         {'DOXY'} ...
         {'DOXY2'} ...
         {'DOXY_2'} ...
         ];

      for idP = 1:length(test21ParameterList)
         paramName = test21ParameterList{idP};
         if (ismember(paramName, ncTrajParamNameList))

            for idDM = 1:2
               if (idDM == 1)
                  dataMode = 'R';
               else
                  dataMode = 'A';
               end

               % retrieve PARAM data
               [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
                  get_param_data(paramName, dataStruct, dataMode);
               if (~isempty(paramData))

                  idMeas = find( ...
                     (paramData ~= paramDataFillValue) & ...
                     ((measurementCode == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST) | ...
                     (measurementCode == g_MC_InAirSingleMeasRelativeToTST) | ...
                     (measurementCode == g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                     (measurementCode == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                     (measurementCode == g_MC_InAirSingleMeasRelativeToTET)));

                  if (~isempty(idMeas))

                     % for DOXY the test depends on sensor model (only for
                     % SBE63_OPTODE)
                     if (strncmp(paramName, 'DOXY', length('DOXY')))
                        % retrieve the sensor of this parameter
                        idF = find(strcmp(paramName, parameterMeta) == 1, 1);
                        if (~isempty(idF))
                           paramSensor = parameterSensorMeta{idF};
                           % retrieve the sensor model of this parameter
                           idF = find(strcmp(paramSensor, sensorMeta) == 1, 1);
                           if (~isempty(idF))
                              paramSensorModel = sensorModelMeta(idF);
                              if (~strcmp(paramSensorModel, 'SBE63_OPTODE'))
                                 continue
                              end
                           end
                        end
                     end

                     % apply the test
                     paramDataQc(idMeas) = set_qc(paramDataQc(idMeas), g_decArgo_qcStrCorrectable);
                     dataStruct.(paramDataQcName) = paramDataQc;

                     testDoneList(21) = 1;
                     testFailedList(21) = 1;
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 22: near-surface mixed air/water test
%
if (testFlagList(22) == 1)

   % in this adaptation of test 22 to trajectory data, near-surface measurements
   % are selected through the measurement codes:
   % g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST
   % g_MC_InAirSingleMeasRelativeToTST
   % g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
   % g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
   % g_MC_InAirSingleMeasRelativeToTET

   % the simplified version of the test implemented here consist in assigning a
   % QC 3 to near-surface mixed air/water tempertaures

   % list of parameters concerned by this test
   test22ParameterList = [ ...
      {'TEMP'} ...
      {'TEMP2'} ...
      {'TEMP_2'} ...
      % {'TEMP3'} ... % not involved in this test because assigned to RBR salinity (decId 228)
      {'TEMP_DOXY'} ...
      {'TEMP_DOXY2'} ...
      {'TEMP_DOXY_2'} ...
      ];

   for idP = 1:size(test22ParameterList, 1)
      paramName = test22ParameterList{idP};
      if (ismember(paramName, ncTrajParamNameList))

         for idDM = 1:2
            if (idDM == 1)
               dataMode = 'R';
            else
               dataMode = 'A';
            end

            % retrieve PARAM data
            [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
               get_param_data(paramName, dataStruct, dataMode);
            if (~isempty(paramData))

               idMeas = find( ...
                  (paramData ~= paramDataFillValue) & ...
                  ((measurementCode == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST) | ...
                  (measurementCode == g_MC_InAirSingleMeasRelativeToTST) | ...
                  (measurementCode == g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                  (measurementCode == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                  (measurementCode == g_MC_InAirSingleMeasRelativeToTET)));

               if (~isempty(idMeas))

                  % apply the test
                  paramDataQc(idMeas) = set_qc(paramDataQc(idMeas), g_decArgo_qcStrCorrectable);
                  dataStruct.(paramDataQcName) = paramDataQc;

                  testDoneList(22) = 1;
                  testFailedList(22) = 1;
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 6: global range test
%
if (testFlagList(6) == 1)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % SPECIFIC TO (PRES, TEMP, PSAL) AND (PRES2, TEMP2, PSAL2) AND (PRES3, TEMP3, PSAL3)
   % if PRES < –5dbar, then PRES_QC = '4', TEMP_QC = '4', PSAL_QC = '4'
   % elseif –5dbar <= PRES <= –2.4dbar, then PRES_QC = '3', TEMP_QC = '3', PSAL_QC = '3'.

   % should be applied to:
   % (PRES, TEMP, PSAL)
   % (PRES2, TEMP2, PSAL2)
   % (PRES_2, TEMP_2, PSAL_2)
   % (PRES3, TEMP3, PSAL3)
   % (PRES_3, TEMP_3, PSAL_3)
   % (PRES, TEMP_DOXY)
   % (PRES, TEMP_DOXY2)
   % (PRES, TEMP_DOXY_2)

   % list of parameters concerned by this test
   test6ParameterList1 = [ ...
      {'PRES'} {'TEMP'} {'PSAL'}; ...
      {'PRES2'} {'TEMP2'} {'PSAL2'}; ...
      {'PRES_2'} {'TEMP_2'} {'PSAL_2'}; ...
      {'PRES3'} {'TEMP3'} {'PSAL3'}; ...
      {'PRES_3'} {'TEMP_3'} {'PSAL_3'}; ...
      {'PRES'} {'TEMP_DOXY'} {''}; ...
      {'PRES'} {'TEMP_DOXY2'} {''}; ...
      {'PRES'} {'TEMP_DOXY_2'} {''}; ...
      ];

   presQc4Flag = 0;
   for idP = 1:size(test6ParameterList1, 1)
      presName = test6ParameterList1{idP, 1};
      tempName = test6ParameterList1{idP, 2};
      psalName = test6ParameterList1{idP, 3};

      for idDM = 1:2
         if (idDM == 1)
            dataMode = 'R';
         else
            dataMode = 'A';
         end

         %%%%%%%%%%%%%%%%%%%%
         % retrieve PRES data

         [presData, presDataQc, presDataFillValue, presDataQcName] = ...
            get_param_data(presName, dataStruct, dataMode);

         idNoDef = find(presData ~= presDataFillValue);
         if (~isempty(idNoDef))

            testDoneList(6) = 1;

            % initialize Qc flags (because the test directly depends on PRES)
            presDataQc(idNoDef) = set_qc(presDataQc(idNoDef), g_decArgo_qcStrGood);
            dataStruct.(presDataQcName) = presDataQc;

            % apply the test
            for idT = 1:2
               if (idT == 1)
                  idToFlag = find(presData(idNoDef) < -5);
                  flagValue = g_decArgo_qcStrBad;
               else
                  idToFlag = find((presData(idNoDef) >= -5) & (presData(idNoDef) <= -2.4));
                  flagValue = g_decArgo_qcStrCorrectable;
               end

               if (~isempty(idToFlag))
                  presDataQc(idNoDef(idToFlag)) = set_qc(presDataQc(idNoDef(idToFlag)), flagValue);
                  dataStruct.(presDataQcName) = presDataQc;

                  testFailedList(6) = 1;
                  if (flagValue == g_decArgo_qcStrBad)
                     presQc4Flag = 1;
                  end
               end
            end

            %%%%%%%%%%%%%%%%%%%%
            % retrieve TEMP data

            [tempData, tempDataQc, tempDataFillValue, tempDataQcName] = ...
               get_param_data(tempName, dataStruct, dataMode);
            if (~isempty(tempData))

               idNoDef = find((presData ~= presDataFillValue) & ...
                  (tempData ~= tempDataFillValue));
               if (~isempty(idNoDef))

                  % apply the test
                  for idT = 1:2
                     if (idT == 1)
                        idToFlag = find(presData(idNoDef) < -5);
                        flagValue = g_decArgo_qcStrBad;
                     else
                        idToFlag = find((presData(idNoDef) >= -5) & (presData(idNoDef) <= -2.4));
                        flagValue = g_decArgo_qcStrCorrectable;
                     end

                     if (~isempty(idToFlag))
                        tempDataQc(idNoDef(idToFlag)) = set_qc(tempDataQc(idNoDef(idToFlag)), flagValue);
                        dataStruct.(tempDataQcName) = tempDataQc;

                        testFailedList(6) = 1;
                     end
                  end
               end
            end

            %%%%%%%%%%%%%%%%%%%%
            % retrieve PSAL data

            if (~isempty(psalName))
               [psalData, psalDataQc, psalDataFillValue, psalDataQcName] = ...
                  get_param_data(psalName, dataStruct, dataMode);
               if (~isempty(psalData))

                  idNoDef = find((presData ~= presDataFillValue) & ...
                     (psalData ~= psalDataFillValue));
                  if (~isempty(idNoDef))

                     % apply the test
                     for idT = 1:2
                        if (idT == 1)
                           idToFlag = find(presData(idNoDef) < -5);
                           flagValue = g_decArgo_qcStrBad;
                        else
                           idToFlag = find((presData(idNoDef) >= -5) & (presData(idNoDef) <= -2.4));
                           flagValue = g_decArgo_qcStrCorrectable;
                        end

                        if (~isempty(idToFlag))
                           psalDataQc(idNoDef(idToFlag)) = set_qc(psalDataQc(idNoDef(idToFlag)), flagValue);
                           dataStruct.(psalDataQcName) = psalDataQc;

                           testFailedList(6) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end

   % apply general rule: if PRES_QC=4 then <PARAM>_QC=4 for c, b, ic and ib
   % parameters
   if (presQc4Flag)
      dataStruct = update_qc_for_bad_pres(dataStruct);
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % SPECIFIC TO OTHER PARAMETERS

   % list of parameters to test
   test6ParameterList2 = [ ...
      {'TEMP'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP2'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP_2'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP3'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP_3'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP_DOXY'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP_DOXY2'} {-2.5} {40} {-2.5} {40}; ...
      {'TEMP_DOXY_2'} {-2.5} {40} {-2.5} {40}; ...
      {'PSAL'} {2} {41} {2} {41}; ...
      {'PSAL2'} {2} {41} {2} {41}; ...
      {'PSAL_2'} {2} {41} {2} {41}; ...
      {'PSAL3'} {2} {41} {2} {41}; ...
      {'PSAL_3'} {2} {41} {2} {41}; ...
      {'DOXY'} {-5} {600} {-5} {600}; ...
      {'DOXY2'} {-5} {600} {-5} {600}; ...
      {'DOXY_2'} {-5} {600} {-5} {600}; ...
      {'CHLA'} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax}; ...
      {'CHLA2'} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax}; ...
      {'CHLA_2'} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax}; ...
      {'CHLA_FLUORESCENCE'} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax}; ...
      {'CHLA_FLUORESCENCE2'} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax}; ...
      {'CHLA_FLUORESCENCE_2'} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax} {g_decArgo_rtqcTest6ChlaMin} {g_decArgo_rtqcTest6ChlaMax}; ...
      {'PH_IN_SITU_TOTAL'} {7.0} {8.8} {7.3} {8.5}; ...
      {'NITRATE'} {-2} {50} {-2} {50}; ...
      {'DOWN_IRRADIANCE380'} {-1} {1.7} {-1} {1.7}; ...
      {'DOWN_IRRADIANCE412'} {-1} {2.9} {-1} {2.9}; ...
      {'DOWN_IRRADIANCE443'} {-1} {3.2} {-1} {3.2}; ...
      {'DOWN_IRRADIANCE490'} {-1} {3.4} {-1} {3.4}; ...
      {'DOWN_IRRADIANCE665'} {-1} {2.8} {-1} {2.8}; ...
      {'DOWNWELLING_PAR'} {-1} {4672} {-1} {4672}; ...
      ];

   for idP = 1:size(test6ParameterList2, 1)
      paramName = test6ParameterList2{idP, 1};
      if (ismember(paramName, ncTrajParamNameList))

         for idDM = 1:2
            if (idDM == 1)
               dataMode = 'R';
               paramTestMin = test6ParameterList2{idP, 2};
               paramTestMax = test6ParameterList2{idP, 3};
            else
               dataMode = 'A';
               paramTestMin = test6ParameterList2{idP, 2};
               paramTestMax = test6ParameterList2{idP, 3};
            end

            % retrieve PARAM data
            [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
               get_param_data(paramName, dataStruct, dataMode);

            idNoDef = find(paramData ~= paramDataFillValue);
            if (~isempty(idNoDef))

               testDoneList(6) = 1;

               % initialize Qc flags (because the test directly depends on PARAM)
               paramDataQc(idNoDef) = set_qc(paramDataQc(idNoDef), g_decArgo_qcStrGood);
               dataStruct.(paramDataQcName) = paramDataQc;

               % apply the test
               paramData = paramData(idNoDef);
               idToFlag = find((paramData < paramTestMin) | (paramData > paramTestMax));
               if (~isempty(idToFlag))
                  paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                  dataStruct.(paramDataQcName) = paramDataQc;

                  testFailedList(6) = 1;
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 7: regional range test
%
if (testFlagList(7) == 1)

   % list of parameters to test
   test7ParameterList = [ ...
      {'TEMP'} {21} {40} {10} {40}; ...
      {'TEMP2'} {21} {40} {10} {40}; ...
      {'TEMP_2'} {21} {40} {10} {40}; ...
      {'TEMP3'} {21} {40} {10} {40}; ...
      {'TEMP_3'} {21} {40} {10} {40}; ...
      {'TEMP_DOXY'} {21} {40} {10} {40}; ...
      {'TEMP_DOXY2'} {21} {40} {10} {40}; ...
      {'TEMP_DOXY_2'} {21} {40} {10} {40}; ...
      {'PSAL'} {2} {41} {2} {40}; ...
      {'PSAL2'} {2} {41} {2} {40}; ...
      {'PSAL_2'} {2} {41} {2} {40}; ...
      {'PSAL3'} {2} {41} {2} {40}; ...
      {'PSAL_3'} {2} {41} {2} {40}; ...
      ];

   % we determine a mean location for each cycle. This mean location is used to
   % define the region of all the measurements sampled during the cycle
   uCycleNumber = unique(cycleNumber(cycleNumber >= 0));
   for idCy = 1:length(uCycleNumber)
      cyNum = uCycleNumber(idCy);
      idMeasForCy = find(cycleNumber == cyNum);

      if (~isempty(idMeasForCy))
         juldForCy = juld(idMeasForCy);
         latForCy = latitude(idMeasForCy);
         lonForCy = longitude(idMeasForCy);
         posQcForCy = positionQc(idMeasForCy);
         posAccForCy = positionAccuracy(idMeasForCy);
         idOkForCy = find((juldForCy ~= paramJuld.fillValue) & ...
            (latForCy ~= paramLat.fillValue) & ...
            (lonForCy ~= paramLon.fillValue) & ...
            (posQcForCy ~= g_decArgo_qcStrCorrectable)' & ...
            (posQcForCy ~= g_decArgo_qcStrBad)' & ...
            (posAccForCy ~= 'I')'); % to exclude Iridium locations

         if (~isempty(idOkForCy))
            [~, idFirst] = min(juldForCy(idOkForCy));
            latOfCy = latForCy(idOkForCy(idFirst));
            lonOfCy = lonForCy(idOkForCy(idFirst));
            latOfCyPrev = [];
            lonOfCyPrev = [];

            % try to find a location for the begining of the cycle
            idMeasForCyPrev = find(cycleNumber == cyNum-1);

            if (~isempty(idMeasForCyPrev))
               juldForCyPrev = juld(idMeasForCyPrev);
               latForCyPrev = latitude(idMeasForCyPrev);
               lonForCyPrev = longitude(idMeasForCyPrev);
               posQcForCyPrev = positionQc(idMeasForCyPrev);
               posAccForCyPrev = positionAccuracy(idMeasForCyPrev);
               idOkForCyPrev = find((juldForCyPrev ~= paramJuld.fillValue) & ...
                  (latForCyPrev ~= paramLat.fillValue) & ...
                  (lonForCyPrev ~= paramLon.fillValue) & ...
                  (posQcForCyPrev ~= g_decArgo_qcStrCorrectable)' & ...
                  (posQcForCyPrev ~= g_decArgo_qcStrBad)' & ...
                  (posAccForCyPrev ~= 'I')'); % to exclude Iridium locations

               if (~isempty(idOkForCyPrev))
                  [~, idLast] = max(juldForCyPrev(idOkForCyPrev));
                  latOfCyPrev = latForCyPrev(idOkForCyPrev(idLast));
                  lonOfCyPrev = lonForCyPrev(idOkForCyPrev(idLast));
               end
            end

            % compute a mean location for the cycle measurements
            if (~isempty(latOfCyPrev))
               meanLatOfCy = mean([latOfCy latOfCyPrev]);
               meanLonOfCy = mean([lonOfCy lonOfCyPrev]);
            else
               meanLatOfCy = latOfCy;
               meanLonOfCy = lonOfCy;
            end

            if (location_in_region(meanLonOfCy, meanLatOfCy, RED_SEA_REGION) || ...
                  location_in_region(meanLonOfCy, meanLatOfCy, MEDITERRANEAN_SEA_REGION))

               for idP = 1:size(test7ParameterList, 1)
                  paramName = test7ParameterList{idP, 1};
                  if (ismember(paramName, ncTrajParamNameList))

                     paramTestMinRS = test7ParameterList{idP, 2};
                     paramTestMaxRS = test7ParameterList{idP, 3};
                     paramTestMinMS = test7ParameterList{idP, 4};
                     paramTestMaxMS = test7ParameterList{idP, 5};

                     for idT = 1:2
                        if (idT == 1)
                           region = RED_SEA_REGION;
                           paramTestMin = paramTestMinRS;
                           paramTestMax = paramTestMaxRS;
                        else
                           region = MEDITERRANEAN_SEA_REGION;
                           paramTestMin = paramTestMinMS;
                           paramTestMax = paramTestMaxMS;
                        end

                        if (location_in_region(meanLonOfCy, meanLatOfCy, region))

                           for idDM = 1:2
                              if (idDM == 1)
                                 dataMode = 'R';
                              else
                                 dataMode = 'A';
                              end

                              % retrieve PARAM data
                              [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
                                 get_param_data(paramName, dataStruct, dataMode);
                              if (~isempty(paramData))

                                 idNoDef = find(paramData(idMeasForCy) ~= paramDataFillValue);
                                 if (~isempty(idNoDef))

                                    testDoneList(7) = 1;

                                    % initialize Qc flags (because the test directly depends on PARAM)
                                    paramDataQc(idMeasForCy(idNoDef)) = set_qc(paramDataQc(idMeasForCy(idNoDef)), g_decArgo_qcStrGood);
                                    dataStruct.(paramDataQcName) = paramDataQc;

                                    % apply the test
                                    paramData = paramData(idMeasForCy(idNoDef));
                                    idToFlag = find((paramData < paramTestMin) | (paramData > paramTestMax));
                                    if (~isempty(idToFlag))
                                       paramDataQc(idMeasForCy(idNoDef(idToFlag))) = set_qc(paramDataQc(idMeasForCy(idNoDef(idToFlag))), g_decArgo_qcStrBad);
                                       dataStruct.(paramDataQcName) = paramDataQc;

                                       testFailedList(7) = 1;
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 56: PH specific test
%
if (testFlagList(56) == 1)

   if (ismember('PH_IN_SITU_TOTAL', ncTrajParamNameList))

      %%%%%%%%%%%%%%%%%%%%%%
      % First specific test:
      % set PH_IN_SITU_TOTAL_QC = '3'

      % retrieve PARAM data
      [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
         get_param_data('PH_IN_SITU_TOTAL', dataStruct, 'R');

      idNoDef = find(paramData ~= paramDataFillValue);
      if (~isempty(idNoDef))
         testDoneList(56) = 1;

         % initialize Qc flags (with QC = '3')
         paramDataQc(idNoDef) = set_qc(paramDataQc(idNoDef), g_decArgo_qcStrCorrectable);
         dataStruct.(paramDataQcName) = paramDataQc;

         testFailedList(56) = 1;
      end

      %%%%%%%%%%%%%%%%%%%%%%%
      % Second specific test:
      % if PRES_QC=4 and/or TEMP_QC=4 then PH_IN_SITU_TOTAL_QC=4; if PSAL_QC=4, then PH_IN_SITU_TOTAL_QC=3

      for idDM = 1:2
         if (idDM == 1)
            dataMode = 'R';
         else
            dataMode = 'A';
         end

         % retrieve PARAM data
         [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
            get_param_data('PH_IN_SITU_TOTAL', dataStruct, dataMode);
         idNoDefParam = find(paramData ~= paramDataFillValue);
         if (~isempty(idNoDefParam))
            testDoneList(56) = 1;

            % initialize Qc flags (because the test is specific to PH_IN_SITU_TOTAL)
            % useless for PH_IN_SITU_TOTAL_QC, which has been previously set to '3'
            paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrGood);
            dataStruct.(paramDataQcName) = paramDataQc;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % if PRES_QC=4 then PH_IN_SITU_TOTAL_QC=4

            % retrieve PRES data
            % if PARAMETER_DATA_MODE = ‘A’ then PH_IN_SITU_TOTAL_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
            [presData, presDataQc, presDataFillValue, ~] = ...
               get_param_data('PRES', dataStruct, 'R');
            if (~isempty(presData))

               idNoDef = find((presData ~= presDataFillValue) & ...
                  (paramData ~= paramDataFillValue));
               if (~isempty(idNoDef))

                  % apply the test
                  idToFlag = find(presDataQc(idNoDef) == g_decArgo_qcStrBad);
                  if (~isempty(idToFlag))
                     paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                     dataStruct.(paramDataQcName) = paramDataQc;

                     testFailedList(56) = 1;
                  end
               end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % if TEMP_QC=4 then PH_IN_SITU_TOTAL_QC=4

            % retrieve TEMP data
            % if PARAMETER_DATA_MODE = ‘A’ then PH_IN_SITU_TOTAL_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
            [tempData, tempDataQc, tempDataFillValue, ~] = ...
               get_param_data('TEMP', dataStruct, 'R');
            if (~isempty(tempData))

               idNoDef = find((tempData ~= tempDataFillValue) & ...
                  (paramData ~= paramDataFillValue));
               if (~isempty(idNoDef))

                  % apply the test
                  idToFlag = find(tempDataQc(idNoDef) == g_decArgo_qcStrBad);
                  if (~isempty(idToFlag))
                     paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                     dataStruct.(paramDataQcName) = paramDataQc;

                     testFailedList(56) = 1;
                  end
               end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % if PSAL_QC=4, then PH_IN_SITU_TOTAL_QC=3

            % retrieve PSAL data
            % if PARAMETER_DATA_MODE = ‘A’ then PH_IN_SITU_TOTAL_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
            [psalData, psalDataQc, psalDataFillValue, ~] = ...
               get_param_data('PSAL', dataStruct, 'R');
            if (~isempty(psalData))

               idNoDef = find((psalData ~= psalDataFillValue) & ...
                  (paramData ~= paramDataFillValue));
               if (~isempty(idNoDef))

                  % apply the test
                  idToFlag = find(psalDataQc(idNoDef) == g_decArgo_qcStrBad);
                  if (~isempty(idToFlag))
                     paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrCorrectable);
                     dataStruct.(paramDataQcName) = paramDataQc;

                     testFailedList(56) = 1;
                  end
               end
            end
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Sensor diagnostic checks:
      % if IB_PH or IK_PH is outside range [-100 100] nano amps then PH_IN_SITU_TOTAL_QC=3

      % list of parameters concerned by this test
      test56ParameterList = [ ...
         {'IB_PH'} {-100} {100}; ...
         {'IK_PH'} {-100} {100}; ...
         ];

      for idP = 1:size(test56ParameterList, 1)
         iParamName = test56ParameterList{idP, 1};
         if (ismember(iParamName, ncTrajParamNameList))

            iParamTestMin = test6ParameterList2{idP, 2};
            iParamTestMax = test6ParameterList2{idP, 3};

            for idDM = 1:2
               if (idDM == 1)
                  dataMode = 'R';
               else
                  dataMode = 'A';
               end

               % retrieve PARAM data
               [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
                  get_param_data('PH_IN_SITU_TOTAL', dataStruct, dataMode);
               idNoDefParam = find(paramData ~= paramDataFillValue);
               if (~isempty(idNoDefParam))
                  testDoneList(56) = 1;

                  % initialize Qc flags (because the test is specific to PH_IN_SITU_TOTAL)
                  % useless for PH_IN_SITU_TOTAL_QC, which has been previously set to '3'
                  paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrGood);
                  dataStruct.(paramDataQcName) = paramDataQc;

                  % retrieve I_PARAM data
                  [iParamData, ~, iParamDataFillValue, ~] = ...
                     get_param_data(iParamName, dataStruct, 'R');
                  if (~isempty(iParamData))
                     idNoDef = find((iParamData ~= iParamDataFillValue) & ...
                        (paramData ~= paramDataFillValue));
                     if (~isempty(idNoDef))

                        % apply the test
                        iParamData = iParamData(idNoDef);
                        idToFlag = find((iParamData < iParamTestMin) | (iParamData > iParamTestMax));
                        if (~isempty(idToFlag))
                           paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrCorrectable);
                           dataStruct.(paramDataQcName) = paramDataQc;

                           testFailedList(56) = 1;
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 57: DOXY specific test
%
if (testFlagList(57) == 1)

   %%%%%%%%%%%%%%%%%%%%%%
   % First specific test:
   % if (PARAMETER_SENSOR = OPTODE_DOXY) and (SENSOR_MODEL = SBE63_OPTODE) and
   % (MC = 1100 or any relative measurement) then PPOX_DOXY_QC = '4'

   if (ismember('PPOX_DOXY', ncTrajParamNameList))

      % initialize Qc flags (because the test is specific to PPOX_DOXY)
      for idDM = 1:2
         if (idDM == 1)
            dataMode = 'R';
         else
            dataMode = 'A';
         end

         % retrieve PARAM data
         [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
            get_param_data('PPOX_DOXY', dataStruct, dataMode);
         idNoDefParam = find(paramData ~= paramDataFillValue);
         if (~isempty(idNoDefParam))
            testDoneList(57) = 1;

            % initialize Qc flags (because the test is specific to PPOX_DOXY)
            paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrGood);
            dataStruct.(paramDataQcName) = paramDataQc;
         end
      end

      % check that this parameter is sampled by a SBE63 optode
      idF = find(strcmp('PPOX_DOXY', parameterMeta) == 1, 1);
      if (~isempty(idF))
         paramSensor = parameterSensorMeta{idF};
         % retrieve the sensor model of this parameter
         idF = find(strcmp(paramSensor, sensorMeta) == 1, 1);
         if (~isempty(idF))
            paramSensorModel = sensorModelMeta(idF);
            if (strcmp(paramSensorModel, 'SBE63_OPTODE'))

               for idDM = 1:2
                  if (idDM == 1)
                     dataMode = 'R';
                  else
                     dataMode = 'A';
                  end

                  % retrieve PARAM data
                  [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
                     get_param_data('PPOX_DOXY', dataStruct, dataMode);
                  if (~isempty(paramData))

                     idMeas = find( ...
                        (paramData ~= paramDataFillValue) & ...
                        ((measurementCode == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST) | ...
                        (measurementCode == g_MC_InAirSingleMeasRelativeToTST) | ...
                        (measurementCode == g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                        (measurementCode == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
                        (measurementCode == g_MC_InAirSingleMeasRelativeToTET)));

                     if (~isempty(idMeas))

                        % apply the test
                        paramDataQc(idMeas) = set_qc(paramDataQc(idMeas), g_decArgo_qcStrBad);
                        dataStruct.(paramDataQcName) = paramDataQc;

                        testFailedList(57) = 1;
                     end
                  end
               end
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%
   % Second specific test:
   % set DOXY_QC = '3'

   % list of parameters concerned by this test
   test57ParameterList = [ ...
      {'DOXY'} ...
      {'DOXY_2'} ...
      ];

   for idP = 1:length(test57ParameterList)
      paramName = test57ParameterList{idP};
      if (ismember(paramName, ncTrajParamNameList))

         % retrieve PARAM data
         [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
            get_param_data(paramName, dataStruct, 'R');
         idNoDefParam = find(paramData ~= paramDataFillValue);
         if (~isempty(idNoDefParam))
            testDoneList(57) = 1;

            % initialize Qc flags (with QC = '3')
            paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrCorrectable);
            dataStruct.(paramDataQcName) = paramDataQc;

            testFailedList(57) = 1;
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%
   % Third specific test:
   % if TEMP_QC=4 or PRES_QC=4, then DOXY_QC=4; if PSAL_QC=4, then DOXY_QC=3

   % list of parameters concerned by this test
   test57ParameterList2 = [ ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'DOXY_2'} ...
      ];

   for idP = 1:length(test57ParameterList2)
      paramName = test57ParameterList2{idP};
      if (ismember(paramName, ncTrajParamNameList))

         for idDM = 1:2
            if (idDM == 1)
               dataMode = 'R';
            else
               dataMode = 'A';
            end

            % retrieve PARAM data
            [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
               get_param_data(paramName, dataStruct, dataMode);
            idNoDefParam = find(paramData ~= paramDataFillValue);
            if (~isempty(idNoDefParam))
               testDoneList(57) = 1;

               % initialize Qc flags (because the test is specific to DOXY)
               % useless for DOXY_QC, which has been previously set to '3'
               paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrGood);
               dataStruct.(paramDataQcName) = paramDataQc;

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % if PRES_QC=4 then DOXY_QC=4

               % retrieve PRES data
               % if PARAMETER_DATA_MODE = ‘A’ then DOXY_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
               [presData, presDataQc, presDataFillValue, ~] = ...
                  get_param_data('PRES', dataStruct, 'R');
               if (~isempty(presData))

                  idNoDef = find((presData ~= presDataFillValue) & ...
                     (paramData ~= paramDataFillValue));
                  if (~isempty(idNoDef))

                     % apply the test
                     idToFlag = find(presDataQc(idNoDef) == g_decArgo_qcStrBad);
                     if (~isempty(idToFlag))
                        paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                        dataStruct.(paramDataQcName) = paramDataQc;

                        testFailedList(57) = 1;
                     end
                  end
               end

               if (bgcFloatFlag == 0)

                  % it is a PTSO float

                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % if TEMP_QC=4 then DOXY_QC=4

                  % retrieve TEMP data
                  % if PARAMETER_DATA_MODE = ‘A’ then DOXY_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
                  [tempData, tempDataQc, tempDataFillValue, ~] = ...
                     get_param_data('TEMP', dataStruct, 'R');
                  if (~isempty(tempData))

                     idNoDef = find((tempData ~= tempDataFillValue) & ...
                        (paramData ~= paramDataFillValue));
                     if (~isempty(idNoDef))

                        % apply the test
                        idToFlag = find(tempDataQc(idNoDef) == g_decArgo_qcStrBad);
                        if (~isempty(idToFlag))
                           paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                           dataStruct.(paramDataQcName) = paramDataQc;

                           testFailedList(57) = 1;
                        end
                     end
                  end

                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % if PSAL_QC=4, then DOXY_QC=3

                  % retrieve PSAL data
                  % if PARAMETER_DATA_MODE = ‘A’ then DOXY_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
                  [psalData, psalDataQc, psalDataFillValue, ~] = ...
                     get_param_data('PSAL', dataStruct, 'R');
                  if (~isempty(psalData))

                     idNoDef = find((psalData ~= psalDataFillValue) & ...
                        (paramData ~= paramDataFillValue));
                     if (~isempty(idNoDef))

                        % apply the test
                        idToFlag = find(psalDataQc(idNoDef) == g_decArgo_qcStrBad);
                        if (~isempty(idToFlag))
                           paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrCorrectable);
                           dataStruct.(paramDataQcName) = paramDataQc;

                           testFailedList(57) = 1;
                        end
                     end
                  end
               else

                  % it is a BGC float (each sensor has is own PRES axis)

                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % if TEMP_QC=4 then DOXY_QC=4
                  % if PSAL_QC=4, then DOXY_QC=3

                  % retrieve TEMP data
                  % if PARAMETER_DATA_MODE = ‘A’ then DOXY_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
                  [~, tempDataQc, ~, ~] = ...
                     get_param_data('TEMP', dataStruct, 'R');

                  % retrieve PSAL data
                  % if PARAMETER_DATA_MODE = ‘A’ then DOXY_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
                  [~, psalDataQc, ~, ~] = ...
                     get_param_data('PSAL', dataStruct, 'R');

                  if (any(tempDataQc == g_decArgo_qcStrBad) || ...
                        any(psalDataQc == g_decArgo_qcStrBad))

                     % we will process the sets of TEMP and PSAL data per cycle and
                     % per measurement code

                     idBad = find((tempDataQc == g_decArgo_qcStrBad) | ...
                        (psalDataQc == g_decArgo_qcStrBad));
                     uCyMc = unique([cycleNumber(idBad) measurementCode(idBad)], 'rows');
                     for idCM = 1:size(uCyMc, 1)
                        cyNum = uCyMc(idCM, 1);
                        measCode = uCyMc(idCM, 2);

                        idNoDefToCheck = find((presData ~= presDataFillValue) & ...
                           (paramData ~= paramDataFillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));
                        if (~isempty(idNoDefToCheck))

                           presDataForInt = presData(idNoDefToCheck);

                           % retrieve the PTS data
                           % if PARAMETER_DATA_MODE = ‘A’ then DOXY_ADJUSTED_QC should be defined from PSAL_QC, TEMP_QC and PRES_QC
                           [pres, ~, presFillValue, ...
                              temp, tempQc, tempFillValue, ...
                              psal, psalQc, psalFillValue] = ...
                              get_pts_data(dataStruct, cyNum, measCode, 'R');

                           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % if TEMP_QC=4 then DOXY_QC=4

                           % interpolate and extrapolate the CTD TEMP data at the pressures
                           % of the DOXY measurements
                           [~, tempIntQc] = compute_interpolated_PARAM_measurements( ...
                              pres, temp, tempQc, presDataForInt, ...
                              presFillValue, tempFillValue, presDataFillValue);

                           % apply the test
                           idToFlag = find(tempIntQc == g_decArgo_qcStrBad);
                           if (~isempty(idToFlag))
                              paramDataQc(idNoDefToCheck(idToFlag)) = set_qc(paramDataQc(idNoDefToCheck(idToFlag)), g_decArgo_qcStrBad);
                              dataStruct.(paramDataQcName) = paramDataQc;

                              testFailedList(57) = 1;
                           end

                           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % if PSAL_QC=4, then DOXY_QC=3

                           % interpolate and extrapolate the CTD PSAL data at the pressures
                           % of the DOXY measurements
                           [~, psalIntQc] = compute_interpolated_PARAM_measurements( ...
                              pres, psal, psalQc, presDataForInt, ...
                              presFillValue, psalFillValue, presDataFillValue);

                           % apply the test
                           idToFlag = find(psalIntQc == g_decArgo_qcStrBad);
                           if (~isempty(idToFlag))
                              paramDataQc(idNoDefToCheck(idToFlag)) = set_qc(paramDataQc(idNoDefToCheck(idToFlag)), g_decArgo_qcStrCorrectable);
                              dataStruct.(paramDataQcName) = paramDataQc;

                              testFailedList(57) = 1;
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 60: PAR specific test
%
if (testFlagList(60) == 1)

   if (ismember('DOWNWELLING_PAR', ncTrajParamNameList))

      %%%%%%%%%%%%%%%%%%%%%%
      % Specific test:
      % set DOWNWELLING_PAR_QC = '2'

      % retrieve PARAM data
      [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
         get_param_data('DOWNWELLING_PAR', dataStruct, 'R');

      idNoDef = find(paramData ~= paramDataFillValue);
      if (~isempty(idNoDef))

         % initialize Qc flags (with QC = '2')
         paramDataQc(idNoDef) = set_qc(paramDataQc(idNoDef), g_decArgo_qcStrProbablyGood);
         dataStruct.(paramDataQcName) = paramDataQc;

         testDoneList(60) = 1;
         testFailedList(60) = 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 61: IRRADIANCE specific test
%
if (testFlagList(61) == 1)

   %%%%%%%%%%%%%%%%%%%%%%
   % Specific test:
   % set DOWN_IRRADIANCExxx_QC = '2'

   % list of parameters concerned by this test
   test61ParameterList = [ ...
      {'DOWN_IRRADIANCE380'} ...
      {'DOWN_IRRADIANCE412'} ...
      {'DOWN_IRRADIANCE443'} ...
      {'DOWN_IRRADIANCE490'} ...
      {'DOWN_IRRADIANCE555'} ...
      {'DOWN_IRRADIANCE665'} ...
      {'DOWN_IRRADIANCE670'} ...
      ];

   for idP = 1:length(test61ParameterList)
      paramName = test61ParameterList{idP};
      if (ismember(paramName, ncTrajParamNameList))

         % retrieve PARAM data
         [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
            get_param_data(paramName, dataStruct, 'R');
         idNoDefParam = find(paramData ~= paramDataFillValue);
         if (~isempty(idNoDefParam))

            % initialize Qc flags (with QC = '2')
            paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrProbablyGood);
            dataStruct.(paramDataQcName) = paramDataQc;

            testDoneList(61) = 1;
            testFailedList(61) = 1;
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST 62: BBP specific test
%
if (testFlagList(62) == 1)

   if (ismember('BBP700', ncTrajParamNameList))

      % if PRES < 5 dbar and BBP700 < 0 the BBP700_QC = 4

      for idDM = 1:2
         if (idDM == 1)
            dataMode = 'R';
         else
            dataMode = 'A';
         end

         % retrieve PARAM data
         [paramData, paramDataQc, paramDataFillValue, paramDataQcName] = ...
            get_param_data('BBP700', dataStruct, dataMode);
         idNoDefParam = find(paramData ~= paramDataFillValue);
         if (~isempty(idNoDefParam))

            % initialize Qc flags (because the test is specific to BBP700)
            paramDataQc(idNoDefParam) = set_qc(paramDataQc(idNoDefParam), g_decArgo_qcStrGood);
            dataStruct.(paramDataQcName) = paramDataQc;

            % retrieve PRES data
            [presData, ~, presDataFillValue, ~] = ...
               get_param_data('PRES', dataStruct, dataMode);
            if (~isempty(presData))

               idNoDef = find((presData ~= presDataFillValue) & ...
                  (paramData ~= paramDataFillValue));
               if (~isempty(idNoDef))

                  testDoneList(62) = 1;

                  % apply the test
                  idToFlag = find((presData(idNoDef) < 5) & (paramData(idNoDef) < 0));
                  if (~isempty(idToFlag))
                     paramDataQc(idNoDef(idToFlag)) = set_qc(paramDataQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
                     dataStruct.(paramDataQcName) = paramDataQc;

                     testFailedList(62) = 1;
                  end
               end
            end
         end
      end
   end
end

if (a_update_file_flag == 0)
   clear variables;
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE THE REPORT HEX VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the report hex values
testDoneHex = compute_qctest_hex(find(testDoneList == 1));
testFailedHex = compute_qctest_hex(find(testFailedList == 1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE THE NETCDF FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory to store temporary files
[ncTrajInputPath, ~, ~] = fileparts(ncTrajInputFilePathName);
DIR_TMP_FILE = [ncTrajInputPath '/tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the input trajectory file to be updated
[~, fileName, fileExtension] = fileparts(ncTrajOutputFilePathName);
tmpNcTrajOutputPathFileName = [DIR_TMP_FILE '/' fileName fileExtension];
copy_file(ncTrajInputFilePathName, tmpNcTrajOutputPathFileName);

% create the list of data Qc to store in the NetCDF trajectory
dataQcList = [ ...
   {'JULD_QC'} {juldQc} ...
   {'JULD_ADJUSTED_QC'} {juldAdjQc} ...
   {'POSITION_QC'} {positionQc} ...
   ];
for idParam = 1:length(ncTrajParamNameList)
   dataQcList = [dataQcList ...
      {upper(ncTrajParamDataQcList{idParam})} {dataStruct.(ncTrajParamDataQcList{idParam})} ...
      ];
end
for idParam = 1:length(ncTrajParamAdjNameList)
   dataQcList = [dataQcList ...
      {upper(ncTrajParamAdjDataQcList{idParam})} {dataStruct.(ncTrajParamAdjDataQcList{idParam})} ...
      ];
end

% update the input file(s)
ok = nc_update_file(tmpNcTrajOutputPathFileName, dataQcList, testDoneHex, testFailedHex);

if (ok == 1)

   % if the update succeeded move the file in the output directory

   [ncTrajOutputPath, ~, ~] = fileparts(ncTrajOutputFilePathName);
   [~, fileName, fileExtension] = fileparts(tmpNcTrajOutputPathFileName);
   move_file(tmpNcTrajOutputPathFileName, [ncTrajOutputPath '/' fileName fileExtension]);
end

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% clear data from workspace
clear variables;

return

% ------------------------------------------------------------------------------
% Retrieve parameter data from the data structure according to its data mode.
%
% SYNTAX :
% [o_paramData, o_paramDataQc, o_paramDataFillValue, o_paramDataQcName] = ...
%   get_param_data(a_paramName, a_dataStruct, a_wantedDataMode)
%
% INPUT PARAMETERS :
%   a_paramName      : name of the parameter data
%   a_dataStruct     : data structure
%   a_wantedDataMode : data mode of the parameter to retrieve
%
% OUTPUT PARAMETERS :
%   o_paramData          : parameter data
%   o_paramDataQc        : parameter data QC
%   o_paramDataFillValue : parameter data Fill Value
%   o_paramDataQcName    : parameter data QC field name in the data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramData, o_paramDataQc, o_paramDataFillValue, o_paramDataQcName] = ...
   get_param_data(a_paramName, a_dataStruct, a_wantedDataMode)

% output parameters initialization
o_paramData = [];
o_paramDataQc = [];
o_paramDataFillValue = '';
o_paramDataQcName = '';


% retrieve PARAM data from the data structure
idParam = '';
if (a_wantedDataMode == 'R')
   idParam = find(strcmp(a_paramName, a_dataStruct.ncTrajParamNameList), 1);
   if (~isempty(idParam))
      ncTrajParamXDataList = a_dataStruct.ncTrajParamDataList;
      ncTrajParamXDataQcList = a_dataStruct.ncTrajParamDataQcList;
      ncTrajParamXFillValueList = a_dataStruct.ncTrajParamFillValueList;
   end
elseif (a_wantedDataMode == 'A')
   idParam = find(strcmp([a_paramName '_ADJUSTED'], a_dataStruct.ncTrajParamAdjNameList), 1);
   if (~isempty(idParam))
      ncTrajParamXDataList = a_dataStruct.ncTrajParamAdjDataList;
      ncTrajParamXDataQcList = a_dataStruct.ncTrajParamAdjDataQcList;
      ncTrajParamXFillValueList = a_dataStruct.ncTrajParamAdjFillValueList;
   end
end

if (~isempty(idParam))
   o_paramData = a_dataStruct.(ncTrajParamXDataList{idParam});
   o_paramDataQc = a_dataStruct.(ncTrajParamXDataQcList{idParam});
   o_paramDataFillValue = ncTrajParamXFillValueList{idParam};
   o_paramDataQcName = ncTrajParamXDataQcList{idParam};
end

return

% ------------------------------------------------------------------------------
% Apply general rule: if PRES_QC=4 then <PARAM>_QC=4 for c, b, ic and ib
% parameters.
%
% SYNTAX :
% [o_dataStruct] = update_qc_for_bad_pres(a_dataStruct)
%
% INPUT PARAMETERS :
%   a_dataStruct : input data structure
%
% OUTPUT PARAMETERS :
%   o_dataStruct : output data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = update_qc_for_bad_pres(a_dataStruct)

% output parameters initialization
o_dataStruct = a_dataStruct;

% QC flag values
global g_decArgo_qcStrBad;           % '4'


% list of possible PRES parameter names
presNameList = [ ...
   {'PRES'}; ...
   {'PRES2'}; ...
   {'PRES_2'}; ...
   {'PRES3'}; ...
   {'PRES_3'}; ...
   ];

for idParamPres = 1:length(presNameList)
   presName = presNameList{idParamPres};

   for idD = 1:2
      if (idD == 1)
         % non adjusted data processing

         % set the name list
         ncTrajParamXNameList = o_dataStruct.ncTrajParamNameList;
         ncTrajParamXDataList = o_dataStruct.ncTrajParamDataList;
         ncTrajParamXDataQcList = o_dataStruct.ncTrajParamDataQcList;
         ncTrajParamXFillValueList = o_dataStruct.ncTrajParamFillValueList;
      else
         % adjusted data processing

         % set the name list
         ncTrajParamXNameList = o_dataStruct.ncTrajParamAdjNameList;
         ncTrajParamXDataList = o_dataStruct.ncTrajParamAdjDataList;
         ncTrajParamXDataQcList = o_dataStruct.ncTrajParamAdjDataQcList;
         ncTrajParamXFillValueList = o_dataStruct.ncTrajParamAdjFillValueList;

         presName = [presName '_ADJUSTED'];
      end

      idPres = find(strcmp(presName, ncTrajParamXNameList), 1);
      if (~isempty(idPres))
         presDataQc = o_dataStruct.(ncTrajParamXDataQcList{idPres});

         idToFlag = find(presDataQc == g_decArgo_qcStrBad);
         if (~isempty(idToFlag))

            for idParam = 1:length(ncTrajParamXNameList)
               paramName = ncTrajParamXNameList{idParam};
               if (~strcmp(paramName, presName))

                  paramData = o_dataStruct.(ncTrajParamXDataList{idParam});
                  paramDataQc = o_dataStruct.(ncTrajParamXDataQcList{idParam});
                  paramFillValue = ncTrajParamXFillValueList{idParam};
                  idNoDef = find((paramData(idToFlag) ~= paramFillValue));
                  if (~isempty(idNoDef))
                     % set QC 4
                     paramDataQc(idToFlag(idNoDef)) = set_qc(paramDataQc(idToFlag(idNoDef)), g_decArgo_qcStrBad);
                     o_dataStruct.(ncTrajParamXDataQcList{idParam}) = paramDataQc;
                  end
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve PTS data from the data structure for a given cycle number,
% measurement code and data mode.
%
% SYNTAX :
% [o_presPts, o_presPtsQc, o_presPtsDataFillValue, ...
%   o_tempPts, o_tempPtsQc, o_tempPtsDataFillValue, ...
%   o_psalPts, o_psalPtsQc, o_psalPtsDataFillValue] = ...
%   get_pts_data(a_dataStruct, a_cyNum, a_measCode, a_dataMode)
%
% INPUT PARAMETERS :
%   a_dataStruct : data structure
%   a_cyNum      : cycle number of the data to retrieve
%   a_measCode   : measurement code of the data to retrieve
%   a_dataMode   : data mode of the data to retrieve
%
% OUTPUT PARAMETERS :
%   o_presPts              : PTS PRES data
%   o_presPtsQc            : PTS PRES QC data
%   o_presPtsDataFillValue : PTS PRES fill value
%   o_tempPts              : PTS TEMP data
%   o_tempPtsQc            : PTS TEMP QC data
%   o_tempPtsDataFillValue : PTS TEMP fill value
%   o_psalPts              : PTS PSAL data
%   o_psalPtsQc            : PTS PSAL QC data
%   o_psalPtsDataFillValue : PTS PSAL fill value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presPts, o_presPtsQc, o_presPtsDataFillValue, ...
   o_tempPts, o_tempPtsQc, o_tempPtsDataFillValue, ...
   o_psalPts, o_psalPtsQc, o_psalPtsDataFillValue] = ...
   get_pts_data(a_dataStruct, a_cyNum, a_measCode, a_dataMode)

% output parameters initialization
o_presPts = [];
o_presPtsQc = [];
o_presPtsDataFillValue = '';
o_tempPts = [];
o_tempPtsQc = [];
o_tempPtsDataFillValue = '';
o_psalPts = [];
o_psalPtsQc = [];
o_psalPtsDataFillValue = '';


% retrieve PRES data
[presData, presDataQc, presDataFillValue, ~] = ...
   get_param_data('PRES', a_dataStruct, a_dataMode);

% retrieve TEMP data
[tempData, tempDataQc, tempDataFillValue, ~] = ...
   get_param_data('TEMP', a_dataStruct, a_dataMode);

% retrieve PSAL data
[psalData, psalDataQc, psalDataFillValue, ~] = ...
   get_param_data('PSAL', a_dataStruct, a_dataMode);

if (~isempty(presData) && ~isempty(tempData) && ~isempty(psalData))

   % retrieve PTS data
   idNoDef = find(((presData ~= presDataFillValue) | ...
      (tempData ~= tempDataFillValue) | ...
      (psalData ~= psalDataFillValue)) & ...
      (a_dataStruct.cycleNumber == a_cyNum) & ...
      (a_dataStruct.measurementCode == a_measCode));
   if (~isempty(idNoDef))

      o_presPts = presData(idNoDef);
      o_presPtsQc = presDataQc(idNoDef);
      o_presPtsDataFillValue = presDataFillValue;
      o_tempPts = tempData(idNoDef);
      o_tempPtsQc = tempDataQc(idNoDef);
      o_tempPtsDataFillValue = tempDataFillValue;
      o_psalPts = psalData(idNoDef);
      o_psalPtsQc = psalDataQc(idNoDef);
      o_psalPtsDataFillValue = psalDataFillValue;
   end
end

return

% ------------------------------------------------------------------------------
% Interpolate the PARAM (TEMP or PSAL) measurements of a PTS profile at given P
% levels.
%
% SYNTAX :
%  [o_paramInt, o_paramIntQc] = compute_interpolated_PARAM_measurements( ...
%    a_ptsPres, a_ptsParam, a_ptsParamQc, a_presInt, ...
%    a_ptsPresFv, a_ptsParamFv, a_presIntFv)
%
% INPUT PARAMETERS :
%   a_ptsPres    : CTD PRES profile measurements
%   a_ptsParam   : CTD PARAM profile measurements
%   a_ptsParam   : CTD PARAM profile QCs
%   a_presInt    : P levels of PARAM measurement interpolation
%   a_ptsPresFv  : fill value of CTD PRES profile measurements
%   a_ptsParamFv : fill value of CTD PARAM profile measurements
%   a_presIntFv  : fill value of P levels of PARAM measurement interpolation
%
% OUTPUT PARAMETERS :
%   o_paramInt   : CTD PARAM interpolated data
%   o_paramIntQc : CTD PARAM interpolated data QCs
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramInt, o_paramIntQc] = compute_interpolated_PARAM_measurements( ...
   a_ptsPres, a_ptsParam, a_ptsParamQc, a_presInt, ...
   a_ptsPresFv, a_ptsParamFv, a_presIntFv)

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrBad;           % '4'

% output parameters initialization
o_paramInt = ones(size(a_presInt))*a_ptsParamFv;
o_paramIntQc = repmat(g_decArgo_qcStrDef, size(a_presInt));


% get the measurement levels of output data
idNoDefOutput = find((a_presInt ~= a_presIntFv));

% interpolate the PARAM measurements at the output P levels
idNoDefInput = find((a_ptsPres ~= a_ptsPresFv) & (a_ptsParam ~= a_ptsParamFv));

if (~isempty(idNoDefOutput) && ~isempty(idNoDefInput))

   % get PRES and PARAM measurements
   ctdPres = a_ptsPres(idNoDefInput);
   ctdParam = a_ptsParam(idNoDefInput);
   ctdParamQc = a_ptsParamQc(idNoDefInput);

   if (length(ctdPres) > 1)

      % % sort data
      % [~, idSort] = sort(ctdPres);
      % ctdPres = ctdPres(idSort);
      % ctdParam = ctdParam(idSort);
      % ctdParam = ctdParam(idSort);

      % duplicate PARAM values 10 dbar above the shallowest level
      [~, idMin] = min(ctdPres);
      ctdPres = [ctdPres(idMin)-10; ctdPres];
      ctdParam = [ctdParam(idMin); ctdParam];
      ctdParamQc = [ctdParamQc(idMin) ctdParamQc];

      % duplicate PARAM values 50 dbar below the deepest level
      [~, idMax] = max(ctdPres);
      ctdPres = [ctdPres; ctdPres(idMax)+50];
      ctdParam = [ctdParam; ctdParam(idMax)];
      ctdParamQc = [ctdParamQc ctdParamQc(idMax)];

      % manage duplicated pressures
      if (length(ctdPres) ~= length(unique(ctdPres)))
         [uCtdPres, ~, ic] = unique(ctdPres);
         for idL = 1:length(uCtdPres)
            idM = find(ic == idL);
            if (length(idM) > 1)
               for id = 2:length(idM)
                  cpt = 1;
                  while (any((ctdPres(idM(id)) + cpt*1e-4) == ctdPres))
                     cpt = cpt + 1;
                  end
                  ctdPres(idM(id)) = ctdPres(idM(id)) + cpt*1e-4;
               end
            end
         end
      end

      % interpolate PARAM values
      paramInt = interp1(ctdPres, ctdParam, a_presInt(idNoDefOutput), 'linear');
      paramInt(isnan(paramInt)) = a_ptsParamFv;

      % interpolate PARAM QC values
      ctdParamQcNum = zeros(size(ctdParam));
      ctdParamQcNum(find(ctdParamQc == g_decArgo_qcStrBad)) = 1;

      paramIntQcNum = interp1(ctdPres, ctdParamQcNum, a_presInt(idNoDefOutput), 'linear');
      paramIntQcNum(isnan(paramIntQcNum)) = 0;

      paramIntQc = repmat(g_decArgo_qcStrDef, size(paramIntQcNum));
      paramIntQc(find(paramIntQcNum ~= 0)) = g_decArgo_qcStrBad;

      o_paramInt(idNoDefOutput) = paramInt;
      o_paramIntQc(idNoDefOutput) = paramIntQc;
   end
end

return

% ------------------------------------------------------------------------------
% Check if a location is in a given region (defined by a list of rectangles).
%
% SYNTAX :
%  [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)
%
% INPUT PARAMETERS :
%   a_lon    : location longitude
%   a_lat    : location latitude
%   a_region : region
%
% OUTPUT PARAMETERS :
%   o_inRegionFlag : in region flag (1 if in region, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inRegionFlag] = location_in_region(a_lon, a_lat, a_region)

% output parameters initialization
o_inRegionFlag = -1;

for idR = 1:length(a_region)
   region = a_region(idR, :);
   if ((a_lat >= region(1)) && (a_lat <= region(2)) && (a_lon >= region(3)) && (a_lon <= region(4)))
      o_inRegionFlag = 1;
      return
   end
end

o_inRegionFlag = 0;

return

% ------------------------------------------------------------------------------
% Update NetCDF files after RTQC has been performed.
%
% SYNTAX :
% [o_ok] = nc_update_file(a_trajFileName, a_dataQc, a_testDoneHex, a_testFailedHex)
%
% INPUT PARAMETERS :
%   a_trajFileName  : trajectory file path name to update
%   a_dataQc        : QC data to store in the trajectory file
%   a_testDoneHex   : HEX code of test performed
%   a_testFailedHex : HEX code of test failed
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/10/2016 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function [o_ok] = nc_update_file(a_trajFileName, a_dataQc, a_testDoneHex, a_testFailedHex)

% output parameters initialization
o_ok = 0;

% program version
global g_decArgo_addRtqcToTrajVersion;

% QC flag values
global g_decArgo_qcStrDef;           % ' '

% global time status
global g_JULD_STATUS_fill_value;

% list of parameters that have an extra dimension (N_VALUESx)
global g_decArgo_paramWithExtraDimList;

% json meta-data
global g_decArgo_jsonMetaData;


% retrieve histoy institution from META.json file
histoInstitutionMeta = '';
if (~isempty(g_decArgo_jsonMetaData))
   if (isfield(g_decArgo_jsonMetaData, 'DATA_CENTRE'))
      if (~isempty(g_decArgo_jsonMetaData.DATA_CENTRE))
         histoInstitutionMeta = strtrim(g_decArgo_jsonMetaData.DATA_CENTRE); % case of a RTQC after a decoding session
      end
   end
end
if (isempty(histoInstitutionMeta))
   histoInstitutionMeta = 'IF';
end

% retrieve data from trajectory file
wantedVars = [ ...
   {'DATE_CREATION'} ...
   {'MEASUREMENT_CODE'} ...
   {'HISTORY_INSTITUTION'} ...
   ];

% retrieve parameter data to decide wich QC value should be set
for idParamQc = 1:2:length(a_dataQc)
   paramQcName = a_dataQc{idParamQc};
   paramName = paramQcName(1:end-3);
   if (strncmp(paramName, 'JULD', length('JULD')))
      wantedVars = [wantedVars ...
         {paramName} ...
         {[paramName '_STATUS']} ...
         ];
   elseif (strcmp(paramName, 'POSITION'))
      wantedVars = [wantedVars ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         ];
   else
      wantedVars = [wantedVars ...
         {paramName} ...
         ];
   end
end

ncTrajData = get_data_from_nc_file(a_trajFileName, wantedVars);

% check that 2 additionnal N_HISTORY set of arrays are available
need = 0;
historyInstitution = get_data_from_name('HISTORY_INSTITUTION', ncTrajData);
if (isempty(historyInstitution))
   need = 2;
elseif (size(historyInstitution, 2) == 1)
   if (~isempty(strtrim(historyInstitution(:, end))))
      need = 2;
   else
      need = 1;
   end
elseif (size(historyInstitution, 2) >= 2)
   if (~isempty(strtrim(historyInstitution(:, end-1))) && ~isempty(strtrim(historyInstitution(:, end))))
      need = 2;
   elseif (~isempty(strtrim(historyInstitution(:, end-1))))
      need = 1;
   end
end

% modify the N_HISTORY dimension of the traj file
if (need ~= 0)
   ok = update_n_history_dim_in_traj_file(a_trajFileName, need);
   if (ok == 0)
      fprintf('RTQC_ERROR: Unable to update the N_HISTORY dimension of the NetCDF file: %s\n', a_trajFileName);
      return
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update the trajectory file

% retrieve the N_MEASUREMENT dimension
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
nMeasurement = size(measurementCode, 1);

% open the file to update
fCdf = netcdf.open(a_trajFileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('RTQC_ERROR: Unable to open NetCDF file: %s\n', a_trajFileName);
   return
end

try

   % update <PARAM>_QC values
   for idParamQc = 1:2:length(a_dataQc)
      paramQcName = a_dataQc{idParamQc};
      paramName = paramQcName(1:end-3);

      if (var_is_present_dec_argo(fCdf, paramQcName))

         dataQc = a_dataQc{idParamQc+1};
         if (size(dataQc, 2) > nMeasurement)
            dataQc = dataQc(:, 1:nMeasurement);
         elseif (size(dataQc, 2) < nMeasurement)
            nbColToAdd = nMeasurement - size(dataQc, 2);
            dataQc = cat(2, dataQc, repmat(g_decArgo_qcStrDef, 1, nbColToAdd));
         end

         if (strncmp(paramName, 'JULD', length('JULD')))

            paramInfo = get_netcdf_param_attributes('JULD');
            paramJuld = get_data_from_name(paramName, ncTrajData);
            paramJuldStatus = get_data_from_name([paramName '_STATUS'], ncTrajData);

            idF = find((paramJuld == paramInfo.fillValue) & (paramJuldStatus == g_JULD_STATUS_fill_value));
            dataQc(idF) = g_decArgo_qcStrDef;

         elseif (strcmp(paramName, 'POSITION'))

            paramLatInfo = get_netcdf_param_attributes('LATITUDE');
            paramLonInfo = get_netcdf_param_attributes('LONGITUDE');
            paramLat = get_data_from_name('LATITUDE', ncTrajData);
            paramLon = get_data_from_name('LONGITUDE', ncTrajData);

            idF = find((paramLat == paramLatInfo.fillValue) & (paramLon == paramLonInfo.fillValue));
            dataQc(idF) = g_decArgo_qcStrDef;

         else

            paramName2 = paramName;
            idF = strfind(paramName2, '_ADJUSTED');
            if (~isempty(idF))
               paramName2 = paramName2(1:idF-1);
            end
            paramInfo = get_netcdf_param_attributes(paramName2);
            paramData = get_data_from_name(paramName, ncTrajData);

            if (~ismember(paramName2, g_decArgo_paramWithExtraDimList))
               idF = find(paramData == paramInfo.fillValue);
               dataQc(idF) = g_decArgo_qcStrDef;
            else
               idF = [];
               for idLev = 1:size(paramData, 2)
                  if (~any(paramData(:, idLev) ~= paramInfo.fillValue))
                     idF = [idF idLev];
                  end
               end
               dataQc(idF) = g_decArgo_qcStrDef;
            end

         end

         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), dataQc');
      end
   end

   % update miscellaneous information

   % date of the file update
   dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');

   % retrieve the creation date of the file
   dateCreation = get_data_from_name('DATE_CREATION', ncTrajData)';
   if (isempty(deblank(dateCreation)))
      dateCreation = dateUpdate;
   end

   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COQC software)'];
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);

   % upate date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);

   % data state indicator
   dataStateIndicator = '2B';
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_STATE_INDICATOR'), 0, length(dataStateIndicator), dataStateIndicator);

   % update history information
   historyInstitution = get_data_from_name('HISTORY_INSTITUTION', ncTrajData);
   [~, nHistory] = size(historyInstitution); % original dimension
   nHistory = nHistory + need; % if the dimension has been modified (but not already in size(historyInstitution))
   nHistoryId = nHistory - 2;
   histoInstitution = histoInstitutionMeta;
   histoStep = 'ARGQ';
   histoSoftware = 'COQC';
   histoSoftwareRelease = g_decArgo_addRtqcToTrajVersion;

   for idHisto = 1:2
      if (idHisto == 1)
         histoAction = 'QCP$';
         histoQcTest = a_testDoneHex;
      else
         nHistoryId = nHistoryId + 1;
         histoAction = 'QCF$';
         histoQcTest = a_testFailedHex;
      end
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(histoInstitution)]), histoInstitution');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(histoStep)]), histoStep');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(histoSoftware)]), histoSoftware');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(histoSoftwareRelease)]), histoSoftwareRelease');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(dateUpdate)]), dateUpdate');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(dateUpdate)]), dateUpdate');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(histoAction)]), histoAction');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_QCTEST'), ...
         fliplr([nHistoryId 0]), ...
         fliplr([1 length(histoQcTest)]), histoQcTest');
   end

   netcdf.close(fCdf);

catch MException
   netcdf.close(fCdf);
   rethrow(MException)
end

o_ok = 1;

return
