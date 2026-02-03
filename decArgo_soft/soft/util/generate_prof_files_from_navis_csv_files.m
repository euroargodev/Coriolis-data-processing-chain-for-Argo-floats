% ------------------------------------------------------------------------------
% Generate profile files from Navis and Apex US CSV data files.
%
% SYNTAX :
%  generate_prof_files_from_navis_csv_files()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2025 - RNU - creation
% ------------------------------------------------------------------------------
function generate_prof_files_from_navis_csv_files

% directory input CSV files
INPUT_CSV_DIR_NAME = 'C:\Users\jprannou\_DATA\NAVIS_US_BGC\DATA\NAVIS_US_BGC_DATA\L2_ori\';

% directory input NetCDF files
INPUT_NC_DIR_NAME = 'C:\Users\jprannou\_DATA\NAVIS_US_BGC\DATA\NAVIS_US_BGC_DATA\GDAC\';

% directory input mat files
INPUT_MAT_DIR_NAME = 'C:\Users\jprannou\_DATA\NAVIS_US_BGC\DATA\NAVIS_US_BGC_DATA\mat\';

% directory input json files
INPUT_JSON_DIR_NAME = 'C:\Users\jprannou\_DATA\NAVIS_US_BGC\DATA\NAVIS_US_BGC_DATA\param\';

% directory putput NetCDF files
OUTPUT_NC_DIR_NAME = 'C:\Users\jprannou\_DATA\NAVIS_US_BGC\DATA\NAVIS_US_BGC_DATA\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% list of concerned floats
floatList = [
   % {5902460} {'n0572'}; ...
   {5902461} {'n0573'}; ...
   {5902462} {'n0574'}; ...
   {5903100} {'n0646'}; ...
   {5903101} {'n0647'}; ...
   {5903102} {'n0648'}; ...
   {5903103} {'n0846'}; ...
   {5903104} {'n0847'}; ...
   {5903105} {'n0848'}; ...
   {5903106} {'n0849'}; ...
   {5903107} {'n0850'}; ...
   {5903108} {'n0851'}; ...
   {5903109} {'n0852'} ...
   ];

global g_decArgo_floatNum;
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_realtimeFlag;
global g_decArgo_applyRtqc;
global g_decArgo_decoderVersion;

% tool version
g_decArgo_decoderVersion = 1.0;

% default values initialization
init_default_values;


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_prof_files_from_navis_csv_files_' currentTime '.log'];
diary(logFileName);

% process float data
for idFloat = 1:size(floatList, 1)
   % for idFloat = 1:1

   floatWmo = floatList{idFloat, 1};
   floatId = floatList{idFloat, 2};

   fprintf('Processing float #%d (%s):\n', floatWmo, floatId);

   ncDirPathName = [INPUT_NC_DIR_NAME '\' num2str(floatWmo)];
   csvDirPathName = [INPUT_CSV_DIR_NAME '\' floatId];
   if (exist(ncDirPathName, 'dir') == 7)
      if (exist(csvDirPathName, 'dir') == 7)

         % process input CSV files
         tabProfiles = [];
         paramListAll = [];
         csvFiles = dir([csvDirPathName '/*.csv']);
         for idFile = 1:length(csvFiles)

            csvFileName = csvFiles(idFile).name;
            fprintf('%d/%d: processing file: %s\n', idFile, length(csvFiles), csvFileName);

            % retrieve cycle number
            idDot = strfind(csvFileName, '.');
            cycleNumber = str2double(csvFileName(idDot(1)+1:idDot(2)-1));

            ncFileName = sprintf('D%d_%03d.nc', floatWmo, cycleNumber);
            ncFilePathName = [ncDirPathName '/profiles/' ncFileName];
            if ~(exist(ncFilePathName, 'file') == 2)
               ncFileName = sprintf('R%d_%03d.nc', floatWmo, cycleNumber);
               ncFilePathName = [ncDirPathName '/profiles/' ncFileName];
            end

            if (exist(ncFilePathName, 'file') == 2)

               ncDataStruct = get_nc_data(ncFilePathName);

               csvFilePathName = [csvDirPathName '/' csvFileName];

               csvDataStruct = get_csv_data(csvFilePathName);
               csvDataStruct.cycleNumber = cycleNumber;

               if (idFile == 1)
                  % additionalMetaDataNames = [ ...
                  %    {'PROJECT_NAME'} ...
                  %    {'PI_NAME'} ...
                  %    {'DATA_CENTRE'} ...
                  %    {'DC_REFERENCE'} ...
                  %    {'DATA_STATE_INDICATOR'} ...
                  %    {'FLOAT_SERIAL_NO'} ...
                  %    {'FIRMWARE_VERSION'} ...
                  %    ];
                  additionalMetaDataNames = [ ...
                     {'PROJECT_NAME'} ...
                     {'PI_NAME'} ...
                     {'DATA_CENTRE'} ...
                     {'DC_REFERENCE'} ...
                     {'FLOAT_SERIAL_NO'} ...
                     {'FIRMWARE_VERSION'} ...
                     ];
                  additionalMetaData = get_data_from_nc_file(ncFilePathName, additionalMetaDataNames);
                  for id = 2:2:length(additionalMetaData)
                     additionalMetaData{id} = strtrim(additionalMetaData{id}');
                  end
               end

               % compute DOXY from MOLAR_DOXY
               csvDataStruct = compute_doxy_data(csvDataStruct, ncDataStruct);

               profStruct = create_prof_struct(csvDataStruct, ncDataStruct);
               tabProfiles = [tabProfiles profStruct];

               paramListAll = unique([paramListAll {profStruct.paramList.name}], 'stable');
            else
               fprintf('ERROR: File not found: %s:\n', ncFilePathName);
            end
         end

         % generate profile files

         g_decArgo_floatNum = floatWmo;
         g_decArgo_dirOutputNetcdfFile = OUTPUT_NC_DIR_NAME;
         g_decArgo_realtimeFlag = 0;
         g_decArgo_applyRtqc = 0;

         create_nc_mono_prof_files_3_1(1201, ...
            tabProfiles, additionalMetaData);

         % update meta file
         ncFileName = sprintf('%d_meta.nc', floatWmo);
         ncFilePathName = [ncDirPathName '/' ncFileName];
         if (exist(ncFilePathName, 'file') == 2)

            ncMetaFilePathName = [OUTPUT_NC_DIR_NAME '/' num2str(floatWmo) '/' ncFileName];
            copy_file(ncFilePathName, ncMetaFilePathName);

            matFile = dir([INPUT_MAT_DIR_NAME '/' floatId '*.mat']);
            sensorMeta = [];
            if (~isempty(matFile))
               matData = load([INPUT_MAT_DIR_NAME '/' matFile(1).name]);
               sensorMeta = matData.f.param.sensors;
            end

            jsonFile = dir([INPUT_JSON_DIR_NAME '/' floatId '*.json']);
            sensorMeta = [];
            if (~isempty(jsonFile))
               jsonData = loadjson([INPUT_JSON_DIR_NAME '/' jsonFile(1).name]);
               sensorMeta = jsonData.sensors;
            end

            ok = update_meta_file(ncMetaFilePathName, paramListAll, sensorMeta);

         end

      else
         fprintf('ERROR: Directory not found: %s:\n', csvDirPathName);
      end
   else
      fprintf('ERROR: Directory not found: %s:\n', ncDirPathName);
   end
end

diary off;

return

% ------------------------------------------------------------------------------
% Update META.nc file (sensor information, parameter information and
% predeployment calibration information.
%
% SYNTAX :
%    [o_ok] = update_meta_file(a_metaFileName, a_paramList, a_sensorMetaData)
%
% INPUT PARAMETERS :
%   a_metaFileName   : meta file path name
%   a_paramList      : list of parameters
%   a_sensorMetaData : additional information on sensors and parameters
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
%   11/17/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_meta_file(a_metaFileName, a_paramList, a_sensorMetaData)

% output parameters initialization
o_ok = 0;


% update sensor and parameter information
[sensorInfo, paramInfo] = update_sensor_and_param_info(a_metaFileName, a_paramList, a_sensorMetaData);

% directory to store temporary files
[filePath, fileName, fileExtension] = fileparts(a_metaFileName);
DIR_TMP_FILE = [filePath '/tmp/'];

% create the temp directory
if (exist(DIR_TMP_FILE, 'dir') == 7)
   rmdir(DIR_TMP_FILE, 's');
end
mkdir(DIR_TMP_FILE);

% make a copy of the file in the temp directory
metaFileName = [DIR_TMP_FILE '/' fileName fileExtension];
tmpMetaFileName = [DIR_TMP_FILE '/' fileName '_tmp' fileExtension];
copy_file(a_metaFileName, tmpMetaFileName);

% retrieve the file schema
outputFileSchema = ncinfo(tmpMetaFileName);

% retrieve the N_SENSOR dimension length
idF = find(strcmp({outputFileSchema.Dimensions.Name}, 'N_SENSOR'), 1);
nSensor = outputFileSchema.Dimensions(idF).Length;

if (nSensor ~= size(sensorInfo, 1))
   % update the file schema with the correct N_SENSOR dimension
   [outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
      'N_SENSOR', size(sensorInfo, 1));
end

% retrieve the N_SENSOR dimension length
idF = find(strcmp({outputFileSchema.Dimensions.Name}, 'N_PARAM'), 1);
nParam = outputFileSchema.Dimensions(idF).Length;

if (nParam ~= size(paramInfo, 1))
   % update the file schema with the correct N_PARAM dimension
   [outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
      'N_PARAM', size(paramInfo, 1));
end

% create updated file
ncwriteschema(metaFileName, outputFileSchema);

% list of varaiables to be updated
varList1 = [ ...
   {'SENSOR'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'}];
varList2 = [ ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_ACCURACY'} ...
   {'PARAMETER_RESOLUTION'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_COMMENT'}];

% copy data in updated file
fCdfIn = netcdf.open(tmpMetaFileName, 'NC_NOWRITE');
if (isempty(fCdfIn))
   fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', tmpMetaFileName);
   return
end

try

   fCdfOut = netcdf.open(metaFileName, 'NC_WRITE');
   if (isempty(fCdfOut))
      fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', metaFileName);
      return
   end

   try

      for idVar = 1:length(outputFileSchema.Variables)
         varName = outputFileSchema.Variables(idVar).Name;

         if (ismember(varName, varList1) || ismember(varName, varList2))
            continue
         end

         varData = netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName));
         if (~isempty(varData))
            if (~isempty(outputFileSchema.Variables(idVar).Dimensions))
               dimList = {outputFileSchema.Variables(idVar).Dimensions.Name};
               if (length(dimList) == 1)
                  netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), 0, length(varData), varData);
               else
                  startList = zeros(1, length(dimList));
                  countList = size(varData);
                  if (length(countList) < length(dimList))
                     countList = [countList ones(1, length(dimList)-length(countList))];
                  end
                  netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), startList, countList, varData);
               end
            else
               netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), varData);
            end
         end
      end

      for idV = 1:length(varList1)
         varName = varList1{idV};
         for id = 1:size(sensorInfo, 1)
            switch (varName)
               case {'SENSOR'}
                  varData = sensorInfo{id, 1};
               case {'SENSOR_MAKER'}
                  varData = sensorInfo{id, 2};
               case {'SENSOR_MODEL'}
                  varData = sensorInfo{id, 3};
               case {'SENSOR_SERIAL_NO'}
                  varData = sensorInfo{id, 4};
            end
            if (~isempty(varData))
               netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), ...
                  fliplr([id-1  0]), fliplr([1 length(varData)]), varData');
            end
         end
      end

      for idV = 1:length(varList2)
         varName = varList2{idV};
         for id = 1:size(paramInfo, 1)
            switch (varName)
               case {'PARAMETER'}
                  varData = paramInfo{id, 1};
               case {'PARAMETER_SENSOR'}
                  varData = paramInfo{id, 2};
               case {'PARAMETER_UNITS'}
                  varData = paramInfo{id, 3};
               case {'PARAMETER_ACCURACY'}
                  varData = paramInfo{id, 4};
               case {'PARAMETER_RESOLUTION'}
                  varData = paramInfo{id, 5};
               case {'PREDEPLOYMENT_CALIB_EQUATION'}
                  varData = paramInfo{id, 6};
               case {'PREDEPLOYMENT_CALIB_COEFFICIENT'}
                  varData = paramInfo{id, 7};
               case {'PREDEPLOYMENT_CALIB_COMMENT'}
                  varData = paramInfo{id, 8};
            end
            if (~isempty(varData))
               netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), ...
                  fliplr([id-1  0]), fliplr([1 length(varData)]), varData');
            end
         end
      end

      netcdf.close(fCdfOut);

   catch MException
      netcdf.close(fCdfOut);
      rethrow(MException)
   end

   netcdf.close(fCdfIn);

catch MException
   netcdf.close(fCdfIn);
   rethrow(MException)
end

% update input file
move_file(metaFileName, a_metaFileName);

% delete the temp directory
remove_directory(DIR_TMP_FILE);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Update sensor information, parameter information and predeployment calibration
% information.
%
% SYNTAX :
%   [o_sensorInfo, o_paramInfo] = update_sensor_and_param_info( ...
%   a_metaFileName, a_paramList, a_sensorMetaData)
%
% INPUT PARAMETERS :
%   a_metaFileName   : meta file path name
%   a_paramList      : list of parameters
%   a_sensorMetaData : additional information on sensors and parameters
%
% OUTPUT PARAMETERS :
%   o_sensorInfo : updated sensor information
%   o_paramInfo  : updated parameter information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/17/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorInfo, o_paramInfo] = update_sensor_and_param_info( ...
   a_metaFileName, a_paramList, a_sensorMetaData)

% output parameters initialization
o_sensorInfo = [];
o_paramInfo = [];

% retrieve global coefficient default values
global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;


% check the N_CALiB_PARAM dimension
wantedVars = [ ...
   {'SENSOR'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_ACCURACY'} ...
   {'PARAMETER_RESOLUTION'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_COMMENT'} ...
   ];

ncData = get_data_from_nc_file(a_metaFileName, wantedVars);

sensor = get_data_from_name('SENSOR', ncData);
sensorMaker = get_data_from_name('SENSOR_MAKER', ncData);
sensorModel = get_data_from_name('SENSOR_MODEL', ncData);
sensorSerialNo = get_data_from_name('SENSOR_SERIAL_NO', ncData);

[~, nSensor] = size(sensor);
sensorInfo = repmat({{} {} {} {}}, nSensor, 1);
for idS = 1:nSensor
   sensorInfo{idS, 1} = deblank(sensor(:, idS)');
   sensorInfo{idS, 2}  = deblank(sensorMaker(:, idS)');
   sensorInfo{idS, 3}  = deblank(sensorModel(:, idS)');
   sensorInfo{idS, 4}  = deblank(sensorSerialNo(:, idS)');
end

param = get_data_from_name('PARAMETER', ncData);
paramSensor = get_data_from_name('PARAMETER_SENSOR', ncData);
paramUnits = get_data_from_name('PARAMETER_UNITS', ncData);
paramAccuracy = get_data_from_name('PARAMETER_ACCURACY', ncData);
paramResolution = get_data_from_name('PARAMETER_RESOLUTION', ncData);
preCalibEquation = get_data_from_name('PREDEPLOYMENT_CALIB_EQUATION', ncData);
preCalibCoefficient = get_data_from_name('PREDEPLOYMENT_CALIB_COEFFICIENT', ncData);
preCalibComment = get_data_from_name('PREDEPLOYMENT_CALIB_COMMENT', ncData);

[~, nParam] = size(param);
paramInfo = repmat({{} {} {} {} {} {} {} {}}, nParam, 1);
for idP = 1:nParam
   paramInfo{idP, 1} = deblank(param(:, idP)');
   paramInfo{idP, 2}  = deblank(paramSensor(:, idP)');
   paramInfo{idP, 3}  = deblank(paramUnits(:, idP)');
   paramInfo{idP, 4}  = deblank(paramAccuracy(:, idP)');
   paramInfo{idP, 5}  = deblank(paramResolution(:, idP)');
   paramInfo{idP, 6}  = deblank(preCalibEquation(:, idP)');
   paramInfo{idP, 7}  = deblank(preCalibCoefficient(:, idP)');
   paramInfo{idP, 8}  = deblank(preCalibComment(:, idP)');
end

% check sensors from parameter list
if (~ismember('CTD_PRES', sensorInfo(:, 1)))
   fprintf('ERROR: ''CTD_PRES'' sensor is missing\n');
end
if (~ismember('CTD_TEMP', sensorInfo(:, 1)))
   fprintf('ERROR: ''CTD_TEMP'' sensor is missing\n');
end
if (~ismember('CTD_CNDC', sensorInfo(:, 1)))
   fprintf('ERROR: ''CTD_CNDC'' sensor is missing\n');
end
if (ismember('MOLAR_DOXY', a_paramList))
   if (~ismember('OPTODE_DOXY', sensorInfo(:, 1)))
      fprintf('ERROR: ''OPTODE_DOXY'' sensor is missing\n');
   end
end
if (ismember('CHLA', a_paramList))
   if (~ismember('FLUOROMETER_CHLA', sensorInfo(:, 1)))
      fprintf('ERROR: ''FLUOROMETER_CHLA'' sensor is missing\n');
   end
end
if (ismember('BBP700', a_paramList))
   if (~ismember('BACKSCATTERINGMETER_BBP700', sensorInfo(:, 1)))
      fprintf('ERROR: ''BACKSCATTERINGMETER_BBP700'' sensor is missing\n');
   end
end
if (ismember('CDOM', a_paramList))
   if (~ismember('FLUOROMETER_CDOM', sensorInfo(:, 1)))
      fprintf('ERROR: ''FLUOROMETER_CDOM'' sensor is missing\n');
   end
end
if (ismember('DOWNWELLING_PAR', a_paramList))
   if (~ismember('RADIOMETER_PAR', sensorInfo(:, 1)))
      fprintf('ERROR: ''RADIOMETER_PAR'' sensor is missing\n');
   end
end
if (ismember('CP660', a_paramList))
   if (~ismember('TRANSMISSOMETER_CP650', sensorInfo(:, 1)))
      fprintf('ERROR: ''TRANSMISSOMETER_CP650'' sensor is missing\n');
   end
end

% check parameters from parameter list
if (~ismember('PRES', paramInfo(:, 1)))
   fprintf('ERROR: ''PRES'' parameter is missing\n');
end
if (ismember('PRES', a_paramList))
   idS = find(strcmp('CTD_PRES', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.CTD.model, 'SBE41CP'))
      if (~strcmp(sensorInfo{idS, 2}, 'DRUCK') && ~strcmp(sensorInfo{idS, 2}, 'KISTLER'))
         fprintf('ERROR: ''DRUCK'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'SBE41N'))
         fprintf('ERROR: ''SBE41N'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.CTD.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''CTD_PRES'' sn inconsistent\n');
   end
end

if (~ismember('TEMP', paramInfo(:, 1)))
   fprintf('ERROR: ''TEMP'' parameter is missing\n');
end
if (ismember('TEMP', a_paramList))
   idS = find(strcmp('CTD_TEMP', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.CTD.model, 'SBE41CP'))
      if (~strcmp(sensorInfo{idS, 2}, 'SBE'))
         fprintf('ERROR: ''SBE'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'SBE41N'))
         fprintf('ERROR: ''SBE41N'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.CTD.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''CTD_TEMP'' sn inconsistent\n');
   end
end

if (~ismember('PSAL', paramInfo(:, 1)))
   fprintf('ERROR: ''PSAL'' parameter is missing\n');
end
if (ismember('TEMP', a_paramList))
   idS = find(strcmp('CTD_CNDC', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.CTD.model, 'SBE41CP'))
      if (~strcmp(sensorInfo{idS, 2}, 'SBE'))
         fprintf('ERROR: ''SBE'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'SBE41N'))
         fprintf('ERROR: ''SBE41N'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.CTD.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''CTD_CNDC'' sn inconsistent\n');
   end
end

if (ismember('TEMP_DOXY', a_paramList))
   if (~ismember('TEMP_DOXY', paramInfo(:, 1)))
      fprintf('ERROR: ''TEMP_DOXY'' parameter is missing\n');
   end
end
if (ismember('MOLAR_DOXY', a_paramList))
   if (~ismember('MOLAR_DOXY', paramInfo(:, 1)))
      paramInfo = [paramInfo; ...
         [{'MOLAR_DOXY'} {'OPTODE_DOXY'} {'micromole/L'} {'n/a'} {'n/a'} {'n/a'} {'n/a'} {'n/a'}]];

      fprintf('INFO: ''MOLAR_DOXY'' parameter is missing - added\n');
   end
end
if (ismember('DOXY', a_paramList))
   if (~ismember('DOXY', paramInfo(:, 1)))
      fprintf('ERROR: ''DOXY'' parameter is missing\n');
   end
end

if (ismember('TEMP_DOXY', a_paramList) || ismember('MOLAR_DOXY', a_paramList))
   idS = find(strcmp('OPTODE_DOXY', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.O2.model, 'SBE63'))
      if (~strcmp(sensorInfo{idS, 2}, 'SBE'))
         fprintf('ERROR: ''SBE'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'SBE63_OPTODE'))
         fprintf('ERROR: ''SBE63_OPTODE'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.O2.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''OPTODE_DOXY'' sn inconsistent\n');
   end
end

if (ismember('TEMP_DOXY', a_paramList))
   idP = find(strcmp('TEMP_DOXY', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      eq = a_sensorMetaData.O2.o2_t.eq;
      a = a_sensorMetaData.O2.o2_t.a;
      if (strcmp(eq, '1 / (a[0] + a[1] * rt + a[2] * rt ** 2 + a[3] * rt ** 3 - 273.15)'))
         preCalibEq = 'TEMP_DOXY=1/(TA0+TA1*L+TA2*L^2+TA3*L^3)-273.15; L=ln(100000*TEMP_VOLTAGE_DOXY/(3.3-TEMP_VOLTAGE_DOXY)); TEMP_VOLTAGE_DOXY is the thermistor voltage in volts';
         preCalibCoef = sprintf('TA0=%g; TA1=%g; TA2=%g; TA3=%g', a);
         preCalibComment = 'optode temperature, see SBE63 User’s Manual (manual version #007, 10/28/13)';

         paramInfo{idP, 6} = preCalibEq;
         paramInfo{idP, 7} = preCalibCoef;
         paramInfo{idP, 8} = preCalibComment;
      else
         fprintf('ERROR: ''eq'' not expected\n');
      end
   end
end

if (ismember('MOLAR_DOXY', a_paramList))
   idP = find(strcmp('MOLAR_DOXY', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      eq = a_sensorMetaData.O2.o2_ph.eq;
      a = a_sensorMetaData.O2.o2_ph.a;
      b = a_sensorMetaData.O2.o2_ph.b;
      c = a_sensorMetaData.O2.o2_ph.c;
      preCalibEq = ['MOLAR_DOXY = ' eq];
      preCalibEq = regexprep(preCalibEq, 'a[0]', 'ao');
      preCalibEq = regexprep(preCalibEq, 'a[1]', 'a1');
      preCalibEq = regexprep(preCalibEq, 'a[2]', 'a2');
      preCalibEq = regexprep(preCalibEq, 'b[0]', 'b0');
      preCalibEq = regexprep(preCalibEq, 'b[1]', 'b1');
      preCalibEq = regexprep(preCalibEq, 'c[0]', 'c0');
      preCalibEq = regexprep(preCalibEq, 'c[1]', 'c1');
      preCalibEq = regexprep(preCalibEq, 'c[2]', 'c2');
      preCalibEq = regexprep(preCalibEq, 'o2_t', 'TEMP_DOXY');
      preCalibEq = regexprep(preCalibEq, 'phase', 'PHASE_DELAY_DOXY');
      preCalibCoef = sprintf('a0=%g, a1=%g, a2=%g; b0=%g, b1=%g; c0=%g, c1=%g, c2=%g', a, b, c);
      preCalibComment = 'see SBE63 User’s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';

      paramInfo{idP, 6} = preCalibEq;
      paramInfo{idP, 7} = preCalibCoef;
      paramInfo{idP, 8} = preCalibComment;
   end
end

if (ismember('DOXY', a_paramList))
   idP = find(strcmp('DOXY', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      preCalibEq = 'O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[(PSAL-Sref)*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*(PSAL^2-Sref^2)]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho; where rho is the potential density [kg/L] calculated from CTD data';
      preCalibCoef = sprintf('Sref=%e; Spreset=%e; Pcoef2=%e, Pcoef3=%e; B0=%e, B1=%e, B2=%e, B3=%e; C0=%e; D0=%e, D1=%e, D2=%e, D3=%e', ...
         0, ...
         g_decArgo_doxy_201and202_201_301_sPreset, ...
         g_decArgo_doxy_201and202_201_301_pCoef2, ...
         g_decArgo_doxy_201and202_201_301_pCoef3, ...
         g_decArgo_doxy_201and202_201_301_b0, ...
         g_decArgo_doxy_201and202_201_301_b1, ...
         g_decArgo_doxy_201and202_201_301_b2, ...
         g_decArgo_doxy_201and202_201_301_b3, ...
         g_decArgo_doxy_201and202_201_301_c0, ...
         g_decArgo_doxy_201and202_201_301_d0, ...
         g_decArgo_doxy_201and202_201_301_d1, ...
         g_decArgo_doxy_201and202_201_301_d2, ...
         g_decArgo_doxy_201and202_201_301_d3 ...
         );
      preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';

      paramInfo{idP, 6} = preCalibEq;
      paramInfo{idP, 7} = preCalibCoef;
      paramInfo{idP, 8} = preCalibComment;
   end
end

if (ismember('CHLA', a_paramList))
   if (~ismember('CHLA', paramInfo(:, 1)))
      fprintf('ERROR: ''CHLA'' parameter is missing\n');
   end
end
if (ismember('CHLA', a_paramList))
   idS = find(strcmp('FLUOROMETER_CHLA', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.ECO.model, 'MCOM'))
      if (~strcmp(sensorInfo{idS, 2}, 'WETLABS'))
         fprintf('ERROR: ''WETLABS'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'MCOMS_FLBBCD'))
         fprintf('ERROR: ''MCOMS_FLBBCD'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.ECO.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''FLUOROMETER_CHLA'' sn inconsistent\n');
   end

   idP = find(strcmp('CHLA', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      eq = a_sensorMetaData.ECO.fchl.eq;
      scaleFactor = a_sensorMetaData.ECO.fchl.scale_factor;
      darkCount = a_sensorMetaData.ECO.fchl.dark_count;
      if (strcmp(eq, 'scale_factor * (count - dark_count)'))
         preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
         preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
            scaleFactor, darkCount);
         preCalibComment = '';

         paramInfo{idP, 6} = preCalibEq;
         paramInfo{idP, 7} = preCalibCoef;
         paramInfo{idP, 8} = preCalibComment;
      else
         fprintf('ERROR: ''eq'' not expected\n');
      end
   end
end

if (ismember('BBP700', a_paramList))
   if (~ismember('BBP700', paramInfo(:, 1)))
      fprintf('ERROR: ''BBP700'' parameter is missing\n');
   end
end
if (ismember('BBP700', a_paramList))
   idS = find(strcmp('BACKSCATTERINGMETER_BBP700', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.ECO.model, 'MCOM'))
      if (~strcmp(sensorInfo{idS, 2}, 'WETLABS'))
         fprintf('ERROR: ''WETLABS'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'MCOMS_FLBBCD'))
         fprintf('ERROR: ''MCOMS_FLBBCD'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.ECO.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''BACKSCATTERINGMETER_BBP700'' sn inconsistent\n');
   end

   idP = find(strcmp('BBP700', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      eq = a_sensorMetaData.ECO.beta.eq;
      scaleFactor = a_sensorMetaData.ECO.beta.scale_factor;
      darkCount = a_sensorMetaData.ECO.beta.dark_count;
      if (strcmp(eq, 'scale_factor * (count - dark_count)'))
         preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
         preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at %d angularDeg', ...
            darkCount, scaleFactor, nan, nan);
         preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';

         paramInfo{idP, 6} = preCalibEq;
         paramInfo{idP, 7} = preCalibCoef;
         paramInfo{idP, 8} = preCalibComment;
      else
         fprintf('ERROR: ''eq'' not expected\n');
      end
   end
end

if (ismember('CDOM', a_paramList))
   if (~ismember('CDOM', paramInfo(:, 1)))
      fprintf('ERROR: ''CDOM'' parameter is missing\n');
   end
end
if (ismember('CDOM', a_paramList))
   idS = find(strcmp('FLUOROMETER_CDOM', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.ECO.model, 'MCOM'))
      if (~strcmp(sensorInfo{idS, 2}, 'WETLABS'))
         fprintf('ERROR: ''WETLABS'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'MCOMS_FLBBCD'))
         fprintf('ERROR: ''MCOMS_FLBBCD'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.ECO.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''FLUOROMETER_CDOM'' sn inconsistent\n');
   end

   idP = find(strcmp('CDOM', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      eq = a_sensorMetaData.ECO.fdom.eq;
      scaleFactor = a_sensorMetaData.ECO.fdom.scale_factor;
      darkCount = a_sensorMetaData.ECO.fdom.dark_count;
      if (strcmp(eq, 'scale_factor * (count - dark_count)'))
         preCalibEq = 'CDOM=(FLUORESCENCE_CDOM-DARK_CDOM)*SCALE_CDOM';
         preCalibCoef = sprintf('SCALE_CDOM=%g, DARK_CDOM=%g', ...
            scaleFactor, darkCount);
         preCalibComment = '';

         paramInfo{idP, 6} = preCalibEq;
         paramInfo{idP, 7} = preCalibCoef;
         paramInfo{idP, 8} = preCalibComment;
      else
         fprintf('ERROR: ''eq'' not expected\n');
      end
   end
end

if (ismember('DOWNWELLING_PAR', a_paramList))
   if (~ismember('DOWNWELLING_PAR', paramInfo(:, 1)))
      idP = find(strcmp('DOWN_IRRADIANCE', paramInfo(:, 1)));
      paramInfo{idP, 1} = 'DOWNWELLING_PAR';

      fprintf('INFO: ''DOWNWELLING_PAR'' parameter is missing - ''DOWN_IRRADIANCE'' renamed\n');
   end
end
if (ismember('DOWNWELLING_PAR', a_paramList))
   idS = find(strcmp('RADIOMETER_PAR', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.Radiometer.model, 'Satlantic PAR'))
      if (~strcmp(sensorInfo{idS, 2}, 'SATLANTIC'))
         fprintf('ERROR: ''SATLANTIC'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'SATLANTIC_PAR'))
         fprintf('ERROR: ''SATLANTIC_PAR'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.Radiometer.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''RADIOMETER_PAR'' sn inconsistent\n');
   end

   idP = find(strcmp('DOWNWELLING_PAR', paramInfo(:, 1)));
   if (strcmp(paramInfo{idP, 6}, 'n/a') && ...
         strcmp(paramInfo{idP, 7}, 'n/a') && ...
         strcmp(paramInfo{idP, 8}, 'n/a'))

      eq = a_sensorMetaData.Radiometer.par.eq;
      a = a_sensorMetaData.Radiometer.par.a;
      im = a_sensorMetaData.Radiometer.par.im;
      if (strcmp(eq, 'a[1] * (count - a[0]) * im') || ...
            strcmp(eq, 'par=a[1] * (count - a[0]) * im'))
         preCalibEq = 'DOWNWELLING_PAR=A1_PAR*(RAW_DOWNWELLING_PAR-A0_PAR)*lm_PAR';
         preCalibCoef = sprintf('A1_PAR=%g, A0_PAR=%g, lm_PAR=%g', ...
            a(2), a(1), im);
         preCalibComment = '';

         paramInfo{idP, 6} = preCalibEq;
         paramInfo{idP, 7} = preCalibCoef;
         paramInfo{idP, 8} = preCalibComment;
      else
         fprintf('ERROR: ''eq'' not expected\n');
      end
   end
end

if (ismember('CP660', a_paramList))
   if (~ismember('CP660', paramInfo(:, 1)))

      idP = find(strcmp('TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION', paramInfo(:, 1)));
      paramInfo{idP, 1} = 'CP650';
      paramInfo{idP, 2} = 'TRANSMISSOMETER_CP650';
      paramInfo{idP, 3} = 'm-1';

      fprintf('INFO: ''CP660'' parameter is missing - ''TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION'' renamed\n');
   end
end
if (ismember('CP660', a_paramList))
   idS = find(strcmp('TRANSMISSOMETER_CP650', sensorInfo(:, 1)));
   if (strcmp(a_sensorMetaData.BeamC.model, 'CRV2K'))
      if (~strcmp(sensorInfo{idS, 2}, 'WETLABS'))
         fprintf('ERROR: ''WETLABS'' expected\n');
      end
      if (~strcmp(sensorInfo{idS, 3}, 'C_ROVER'))
         fprintf('ERROR: ''C_ROVER'' expected\n');
      end
   else
      fprintf('ERROR: not managed yet\n');
   end
   if (str2double(a_sensorMetaData.BeamC.sn) ~= str2double(sensorInfo{idS, 4}))
      fprintf('ERROR: ''TRANSMISSOMETER_CP650'' sn inconsistent\n');
   end
end

% sort sensors according to a given list
sensorSortedList = [ ...
   {'CTD_PRES'} ...
   {'CTD_TEMP'} ...
   {'CTD_CNDC'} ...
   {'OPTODE_DOXY'} ...
   {'FLUOROMETER_CHLA'} ...
   {'BACKSCATTERINGMETER_BBP700'} ...
   {'FLUOROMETER_CDOM'} ...
   {'RADIOMETER_PAR'} ...
   {'TRANSMISSOMETER_CP650'} ...
   ];

for idS = 1:size(sensorInfo, 1)
   if (~ismember(sensorInfo{idS, 1}, sensorSortedList))
      fprintf('ERROR: ''%s'' missing in sensorSortedList\n', sensorInfo{idS, 1});
   end
end

o_sensorInfo = cell(size(sensorInfo));
cpt = 1;
for idS = 1:length(sensorSortedList)
   idF = find(strcmp(sensorSortedList{idS}, sensorInfo(:, 1)));
   if (~isempty(idF))
      o_sensorInfo(cpt, :) = sensorInfo(idF,:);
      cpt = cpt + 1;
   end
end

% sort parameters according to a given list
parameterSortedList = [ ...
   {'PRES'} ...
   {'TEMP'} ...
   {'PSAL'} ...
   {'MOLAR_DOXY'} ...
   {'TEMP_DOXY'} ...
   {'DOXY'} ...
   {'CHLA'} ...
   {'BBP700'} ...
   {'CDOM'} ...
   {'DOWNWELLING_PAR'} ...
   {'CP650'} ...
   ];

for idP = 1:size(paramInfo, 1)
   if (~ismember(paramInfo{idP, 1}, parameterSortedList))
      fprintf('ERROR: ''%s'' missing in parameterSortedList\n', paramInfo{idP, 1});
   end
end

o_paramInfo = cell(size(paramInfo));
cpt = 1;
for idP = 1:length(parameterSortedList)
   idF = find(strcmp(parameterSortedList{idP}, paramInfo(:, 1)));
   if (~isempty(idF))
      o_paramInfo(cpt, :) = paramInfo(idF,:);
      cpt = cpt + 1;
   end
end

return

% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}), 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;

   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      if (~isempty(var.Dimensions))
         idDims = find(strcmp(a_dimName, {var.Dimensions.Name}));
         if (~isempty(idDims))
            a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
            for idDim = 1:length(idDims)
               a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
            end
         end
      end
   end
end

o_outputSchema = a_inputSchema;

return

% ------------------------------------------------------------------------------
% Create and fill profile data structure.
%
% SYNTAX :
%  [o_profStruct] = create_prof_struct(a_csvDataStruct, a_ncDataStruct)
%
% INPUT PARAMETERS :
%   a_csvDataStruct : input CSV data structure
%   a_ncDataStruct  : input NetCDF data structure
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = create_prof_struct(a_csvDataStruct, a_ncDataStruct)

% output parameters initialization
o_profStruct = [];


% initialize a NetCDF profile structure and fill it with decoded profile data
o_profStruct = get_profile_init_struct(a_csvDataStruct.cycleNumber, -1, -1, -1);

o_profStruct.cycleNumber = a_csvDataStruct.cycleNumber;
o_profStruct.outputCycleNumber = a_csvDataStruct.cycleNumber;
o_profStruct.primarySamplingProfileFlag = 1;
o_profStruct.direction = 'A';
o_profStruct.date = a_ncDataStruct.JULD;
o_profStruct.dateQc = a_ncDataStruct.JULD_QC;
o_profStruct.locationDate = a_ncDataStruct.JULD_LOCATION;
o_profStruct.locationLon = a_ncDataStruct.LONGITUDE;
o_profStruct.locationLat = a_ncDataStruct.LATITUDE;
o_profStruct.locationQc = a_ncDataStruct.POSITION_QC;
o_profStruct.posSystem = a_ncDataStruct.POSITIONING_SYSTEM;
o_profStruct.vertSamplingScheme = a_ncDataStruct.VERTICAL_SAMPLING_SCHEME;

paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');

paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramMolarDoxy = get_netcdf_param_attributes('MOLAR_DOXY');
paramDoxy = get_netcdf_param_attributes('DOXY');
paramChla = get_netcdf_param_attributes('CHLA');
paramBbp700 = get_netcdf_param_attributes('BBP700');
paramCdom = get_netcdf_param_attributes('CDOM');
paramDownwellingPar = get_netcdf_param_attributes('DOWNWELLING_PAR');
paramCp660 = get_netcdf_param_attributes('CP660');

paramList = [];
paramData = [];
paramDataQc = [];
if (~isempty(a_csvDataStruct.pres))
   paramList = [paramList paramPres];
   pres = a_csvDataStruct.pres;
   presQc = repmat('1', size(pres));
   presQc(isnan(pres)) = '9';
   pres(isnan(pres)) = paramPres.fillValue;
   paramData = [paramData pres];
   paramDataQc = [paramDataQc presQc];
end
if (~isempty(a_csvDataStruct.temp))
   paramList = [paramList paramTemp];
   temp = a_csvDataStruct.temp;
   tempQc = repmat('1', size(temp));
   tempQc(isnan(temp)) = '9';
   temp(isnan(temp)) = paramTemp.fillValue;
   paramData = [paramData temp];
   paramDataQc = [paramDataQc tempQc];
end
if (~isempty(a_csvDataStruct.psal))
   paramList = [paramList paramPsal];
   psal = a_csvDataStruct.psal;
   psalQc = repmat('1', size(psal));
   psalQc(isnan(psal)) = '9';
   psal(isnan(psal)) = paramPsal.fillValue;
   paramData = [paramData psal];
   paramDataQc = [paramDataQc psalQc];
end
if (~isempty(a_csvDataStruct.tempDoxy))
   paramList = [paramList paramTempDoxy];
   tempDoxy = a_csvDataStruct.tempDoxy;
   tempDoxyQc = repmat('1', size(tempDoxy));
   tempDoxyQc(isnan(tempDoxy)) = '9';
   tempDoxy(isnan(tempDoxy)) = paramTempDoxy.fillValue;
   paramData = [paramData tempDoxy];
   paramDataQc = [paramDataQc tempDoxyQc];
end
if (~isempty(a_csvDataStruct.molarDoxy))
   paramList = [paramList paramMolarDoxy];
   molarDoxy = a_csvDataStruct.molarDoxy;
   molarDoxyQc = repmat('1', size(molarDoxy));
   molarDoxyQc(isnan(molarDoxy)) = '9';
   molarDoxy(isnan(molarDoxy)) = paramMolarDoxy.fillValue;
   paramData = [paramData molarDoxy];
   paramDataQc = [paramDataQc molarDoxyQc];
end
if (~isempty(a_csvDataStruct.doxy))
   paramList = [paramList paramDoxy];
   doxy = a_csvDataStruct.doxy;
   doxyQc = repmat('1', size(doxy));
   doxyQc(isnan(doxy)) = '9';
   doxy(isnan(doxy)) = paramDoxy.fillValue;
   paramData = [paramData doxy];
   paramDataQc = [paramDataQc doxyQc];
end
if (~isempty(a_csvDataStruct.chlaRt))
   paramList = [paramList paramChla];
   chla = a_csvDataStruct.chlaRt;
   chlaQc = repmat('1', size(chla));
   chlaQc(isnan(chla)) = '9';
   chla(isnan(chla)) = paramChla.fillValue;
   paramData = [paramData chla];
   paramDataQc = [paramDataQc chlaQc];
end
if (~isempty(a_csvDataStruct.bbp700))
   paramList = [paramList paramBbp700];
   bbp700 = a_csvDataStruct.bbp700;
   bbp700Qc = repmat('1', size(bbp700));
   bbp700Qc(isnan(bbp700)) = '9';
   bbp700(isnan(bbp700)) = paramBbp700.fillValue;
   paramData = [paramData bbp700];
   paramDataQc = [paramDataQc bbp700Qc];
end
if (~isempty(a_csvDataStruct.cdom))
   paramList = [paramList paramCdom];
   cdom = a_csvDataStruct.cdom;
   cdomQc = repmat('1', size(cdom));
   cdomQc(isnan(cdom)) = '9';
   cdom(isnan(cdom)) = paramCdom.fillValue;
   paramData = [paramData cdom];
   paramDataQc = [paramDataQc cdomQc];
end
if (~isempty(a_csvDataStruct.downwellingPar))
   paramList = [paramList paramDownwellingPar];
   downwellingPar = a_csvDataStruct.downwellingPar;
   downwellingParQc = repmat('1', size(downwellingPar));
   downwellingParQc(isnan(downwellingPar)) = '9';
   downwellingPar(isnan(downwellingPar)) = paramDownwellingPar.fillValue;
   paramData = [paramData downwellingPar];
   paramDataQc = [paramDataQc downwellingParQc];
end
if (~isempty(a_csvDataStruct.cp660))
   paramList = [paramList paramCp660];
   cp660 = a_csvDataStruct.cp660;
   cp660Qc = repmat('1', size(downwellingPar));
   cp660Qc(isnan(cp660)) = '9';
   cp660(isnan(cp660)) = paramCp660.fillValue;
   paramData = [paramData cp660];
   paramDataQc = [paramDataQc cp660Qc];
end

if (any(any(isnan(paramData))))
   fprintf('ERROR: Nan values in input data\n');
end

o_profStruct.paramList = paramList;
o_profStruct.paramDataMode = repmat('A', 1, length(paramList));
o_profStruct.data = paramData;
o_profStruct.dataQc = paramDataQc;
o_profStruct.dataAdj = paramData;
o_profStruct.dataAdjQc = paramDataQc;

% set PRES_ADJUSTED
if (~isnan(a_ncDataStruct.SURFACE_PRESSURE_OFFSET))

   pres = o_profStruct.data(:, 1);
   presAdj = pres - a_ncDataStruct.SURFACE_PRESSURE_OFFSET;

   o_profStruct.dataAdj(:, 1) = presAdj;
end


% set CHLA_ADJUSTED
if (~isempty(a_csvDataStruct.chlaAdj))
   idChla = find(strcmp({o_profStruct.paramList.name}, 'CHLA'), 1);
   if (~isempty(idChla))

      chlaQc = paramDataQc(:, idChla);
      chlaAdj = a_csvDataStruct.chlaAdj;
      chlaAdjQc = repmat('1', size(chlaAdj));
      chlaQc(isnan(chlaAdj)) = '4';
      chlaAdjQc(isnan(chlaAdj)) = '9';
      chlaAdj(isnan(chlaAdj)) = paramChla.fillValue;

      o_profStruct.dataQc(:, idChla) = chlaQc;
      o_profStruct.dataAdj(:, idChla) = chlaAdj;
      o_profStruct.dataAdjQc(:, idChla) = chlaAdjQc;
   end
end

o_profStruct.configMissionNumber = a_ncDataStruct.CONFIG_MISSION_NUMBER;

return

% ------------------------------------------------------------------------------
% Read data from CSV file.
%
% SYNTAX :
%  [o_dataStruct] = get_csv_data(a_csvFilePathName)
%
% INPUT PARAMETERS :
%   a_csvFilePathName : CSV file path name
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
%   07/09/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_csv_data(a_csvFilePathName)

% output parameters initialization
o_dataStruct = [];

% default values
global g_decArgo_janFirst1950InMatlab;

global g_decArgo_floatTransType;
g_decArgo_floatTransType = 2;


% mapping of CSV file columns
% datetime => JULD
% lat => LATITUDE
% lon => LONGITUDE
% p => PRES
% t => TEMP
% s => PSAL
% o2_t => TEMP_DOXY
% fchl => CHLA (RT)
% fdom => CDOM
% par => DOWNWELLING_PAR
% tilt => UNUSED
% rilt_std => UNUSED
% c_su => CP660
% o2_c => MOLAR_DOXY
% bbp => BBP700
% chla_adj => CHLA_ADJUSTED
% sigma => UNUSED
% poc => UNUSED
% cphyto => UNUSED

% open and read input CSV file
fId = fopen(a_csvFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening CSV file: %s\n', a_csvFilePathName);
   return
end

% read the CSV file
dataAll = textscan(fId, '%s', 'delimiter', '\n');

fclose(fId);

dataAll = dataAll{:};
dataHeader = textscan(dataAll{1}, '%s', 'delimiter', ',');
dataHeader = dataHeader{:};

NB_MEAS = size(dataAll, 1) - 1;
juld = nan(NB_MEAS, 1);
lat = nan(NB_MEAS, 1);
lon = nan(NB_MEAS, 1);
pres = nan(NB_MEAS, 1);
temp = nan(NB_MEAS, 1);
psal = nan(NB_MEAS, 1);
tempDoxy = nan(NB_MEAS, 1);
chlaRt = nan(NB_MEAS, 1);
cdom = nan(NB_MEAS, 1);
downwellingPar = nan(NB_MEAS, 1);
cp660 = nan(NB_MEAS, 1);
molarDoxy = nan(NB_MEAS, 1);
bbp700 = nan(NB_MEAS, 1);
chlaAdj = nan(NB_MEAS, 1);
doxy = nan(NB_MEAS, 1);

timeId = find(strcmp(dataHeader, 'datetime'));
if (isempty(timeId))
   fprintf('ERROR: Cannot find ''datetime'' in CSV file: %s\n', a_csvFilePathName);
   return
end
latId = find(strcmp(dataHeader, 'lat'));
if (isempty(latId))
   fprintf('ERROR: Cannot find ''lat'' in CSV file: %s\n', a_csvFilePathName);
   return
end
lonId = find(strcmp(dataHeader, 'lon'));
if (isempty(lonId))
   fprintf('ERROR: Cannot find ''lon'' in CSV file: %s\n', a_csvFilePathName);
   return
end
presId = find(strcmp(dataHeader, 'p'));
if (isempty(presId))
   fprintf('ERROR: Cannot find ''p'' in CSV file: %s\n', a_csvFilePathName);
   return
end
tempId = find(strcmp(dataHeader, 't'));
if (isempty(tempId))
   fprintf('ERROR: Cannot find ''t'' in CSV file: %s\n', a_csvFilePathName);
   return
end
psalId = find(strcmp(dataHeader, 's'));
if (isempty(psalId))
   fprintf('ERROR: Cannot find ''s'' in CSV file: %s\n', a_csvFilePathName);
   return
end
tempDoxyId = find(strcmp(dataHeader, 'o2_t'));
chlaRtId = find(strcmp(dataHeader, 'fchl'));
cdomId = find(strcmp(dataHeader, 'fdom'));
downwellingParId = find(strcmp(dataHeader, 'par'));
cp660Id = find(strcmp(dataHeader, 'c_su'));
molarDoxyId = find(strcmp(dataHeader, 'o2_c'));
bbp700Id = find(strcmp(dataHeader, 'bbp'));
chlaAdjId = find(strcmp(dataHeader, 'chla_adj'));
doxyId = '';

for idL = 2:size(dataAll, 1)
   dataL = textscan(dataAll{idL}, '%s', 'delimiter', ',');
   dataL = dataL{:};

   juld(idL-1) = datenum(dataL{timeId}, 'yyyy-mm-dd HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   lat(idL-1) = str2double(dataL{latId});
   lon(idL-1) = str2double(dataL{lonId});
   pres(idL-1) = str2double(dataL{presId});
   temp(idL-1) = str2double(dataL{tempId});
   psal(idL-1) = str2double(dataL{psalId});
   if (~isempty(tempDoxyId))
      tempDoxy(idL-1) = str2double(dataL{tempDoxyId});
   end
   if (~isempty(chlaRtId))
      chlaRt(idL-1) = str2double(dataL{chlaRtId});
   end
   if (~isempty(cdomId))
      cdom(idL-1) = str2double(dataL{cdomId});
   end
   if (~isempty(downwellingParId))
      downwellingPar(idL-1) = str2double(dataL{downwellingParId});
   end
   if (~isempty(cp660Id))
      cp660(idL-1) = str2double(dataL{cp660Id});
   end
   if (~isempty(molarDoxyId))
      molarDoxy(idL-1) = str2double(dataL{molarDoxyId});
   end
   if (~isempty(bbp700Id))
      bbp700(idL-1) = str2double(dataL{bbp700Id});
   end
   if (~isempty(chlaAdjId))
      chlaAdj(idL-1) = str2double(dataL{chlaAdjId});
   end
end

o_dataStruct.cycleNumber = '';
o_dataStruct.juld = flipud(juld);
o_dataStruct.lat = flipud(lat);
o_dataStruct.lon = flipud(lon);
o_dataStruct.pres = flipud(pres);
o_dataStruct.temp = flipud(temp);
o_dataStruct.psal = flipud(psal);
if (~isempty(tempDoxyId))
   o_dataStruct.tempDoxy = flipud(tempDoxy);
else
   o_dataStruct.tempDoxy = [];
end
if (~isempty(chlaRtId))
   o_dataStruct.chlaRt = flipud(chlaRt);
else
   o_dataStruct.chlaRt = [];
end
if (~isempty(cdomId))
   o_dataStruct.cdom = flipud(cdom);
else
   o_dataStruct.cdom = [];
end
if (~isempty(downwellingParId))
   o_dataStruct.downwellingPar = flipud(downwellingPar);
else
   o_dataStruct.downwellingPar = [];
end
if (~isempty(cp660Id))
   o_dataStruct.cp660 = flipud(cp660);
else
   o_dataStruct.cp660 = [];
end
if (~isempty(molarDoxyId))
   o_dataStruct.molarDoxy = flipud(molarDoxy);
else
   o_dataStruct.molarDoxy = [];
end
if (~isempty(bbp700Id))
   o_dataStruct.bbp700 = flipud(bbp700);
else
   o_dataStruct.bbp700 = [];
end
if (~isempty(chlaAdjId))
   o_dataStruct.chlaAdj = flipud(chlaAdj);
else
   o_dataStruct.chlaAdj = [];
end
if (~isempty(doxyId))
   o_dataStruct.doxy = flipud(doxy);
else
   o_dataStruct.doxy = [];
end

return

% ------------------------------------------------------------------------------
% Compute DOXY from MOLAR_DOXY.
%
% SYNTAX :
%  [o_dataStruct] = compute_doxy_data(a_dataStruct, a_ncDataStruct)
%
% INPUT PARAMETERS :
%   a_dataStruct   : input data structure
%   a_ncDataStruct : input additional information from NetCDF profile
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
%   11/14/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = compute_doxy_data(a_dataStruct, a_ncDataStruct)

% output parameters initialization
o_dataStruct = a_dataStruct;

% retrieve global coefficient default values
global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;


if (isempty(a_dataStruct.pres) || isempty(a_dataStruct.temp) || ...
      isempty(a_dataStruct.psal) || isempty(a_dataStruct.molarDoxy))
   return
end

pres = a_dataStruct.pres;
temp = a_dataStruct.temp;
psal = a_dataStruct.psal;
molarDoxy = a_dataStruct.molarDoxy;

doxy = nan(size(molarDoxy));
idDef = find( ...
   isnan(molarDoxy) | ...
   isnan(pres) | ...
   isnan(temp) | ...
   isnan(psal));
idNoDef = setdiff(1:length(doxy), idDef);

if (~isempty(idNoDef))

   molarDoxyValues = molarDoxy(idNoDef);
   presValues = pres(idNoDef);
   tempValues = temp(idNoDef);
   psalValues = psal(idNoDef);
   latitude = repmat(a_ncDataStruct.LATITUDE, size(molarDoxyValues));
   longitude = repmat(a_ncDataStruct.LONGITUDE, size(molarDoxyValues));

   % salinity effect correction
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, 0, ...
      g_decArgo_doxy_201and202_201_301_d0, ...
      g_decArgo_doxy_201and202_201_301_d1, ...
      g_decArgo_doxy_201and202_201_301_d2, ...
      g_decArgo_doxy_201and202_201_301_d3, ...
      g_decArgo_doxy_201and202_201_301_sPreset, ...
      g_decArgo_doxy_201and202_201_301_b0, ...
      g_decArgo_doxy_201and202_201_301_b1, ...
      g_decArgo_doxy_201and202_201_301_b2, ...
      g_decArgo_doxy_201and202_201_301_b3, ...
      g_decArgo_doxy_201and202_201_301_c0 ...
      );

   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decArgo_doxy_201and202_201_301_pCoef2, ...
      g_decArgo_doxy_201and202_201_301_pCoef3 ...
      );

   % units convertion (micromol/L to micromol/kg)
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, longitude, latitude);
   rho = rho/1000;

   oxyValues = oxygenPresComp ./ rho;
   idNoNan = find(~isnan(oxyValues));

   doxy(idNoDef(idNoNan)) = oxyValues(idNoNan);
   o_dataStruct.doxy = doxy;
end

return

% ------------------------------------------------------------------------------
% Read data from PROF NetCDF file.
%
% SYNTAX :
%  [o_dataStruct] = get_nc_data(a_ncFilePathName)
%
% INPUT PARAMETERS :
%   a_ncFilePathName : NetCDF file path name
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
%   07/09/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_nc_data(a_ncFilePathName)

% output parameters initialization
o_dataStruct = [];
o_metaData = [];


wantedVars = [ ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'POSITIONING_SYSTEM'} ...
   {'VERTICAL_SAMPLING_SCHEME'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'PARAMETER'} ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'SCIENTIFIC_CALIB_DATE'} ...
   {'PRES'} ...
   {'PRES_ADJUSTED'} ...
   ];

ncData = get_data_from_nc_file(a_ncFilePathName, wantedVars);

pres = get_data_from_name('PRES', ncData);
presAdj = get_data_from_name('PRES_ADJUSTED', ncData);
if (isscalar(unique(round((pres-presAdj)*10000)/10000)))
   surfPresOffset = unique(round((pres-presAdj)*10000)/10000);
else
   surfPresOffset = nan;
end

% parameter = get_data_from_name('PARAMETER', ncData);
% sciCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', ncData);
% sciCalibCoefficient = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', ncData);
% sciCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', ncData);
% sciCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', ncData);
%
% [~, nParam, nCalib, nProf] = size(parameter);
% calibCoef = nan;
% calibDate = nan;
% for idProf = 1:nProf
%    for idCalib = 1:nCalib
%       for idParam = 1:nParam
%          param = deblank(parameter(:, idParam, idCalib, idProf)');
%          if (strcmp(param, 'PRES'))
%             coefStr = deblank(sciCalibCoefficient(:, idParam, idCalib, idProf)');
%             dateStr =  deblank(sciCalibDate(:, idParam, idCalib, idProf)');
%             idF1 = strfind(coefStr, '=');
%             idF2 = strfind(coefStr, 'dbar');
%             if (~isempty(idF1) && ~isempty(idF2))
%                calibCoefTmp = str2double(coefStr(idF1+1:idF2-1));
%                calibDateTmp = gregorian_2_julian_dec_argo([dateStr(1:4) '/' ...
%                   dateStr(5:6) '/' dateStr(7:8) ' ' dateStr(9:10) ':' ...
%                   dateStr(11:12) ':' dateStr(13:14)]);
%                if (isnan(calibCoef))
%                   calibCoef = calibCoefTmp;
%                   calibDate = calibDateTmp;
%                else
%                   if (calibDateTmp > calibDate)
%                      calibCoef = calibCoefTmp;
%                      calibDate = calibDateTmp;
%                   end
%                end
%             end
%          end
%       end
%    end
% end

o_dataStruct.JULD = get_data_from_name('JULD', ncData);
o_dataStruct.JULD_QC = get_data_from_name('JULD_QC', ncData);
o_dataStruct.JULD_LOCATION = get_data_from_name('JULD_LOCATION', ncData);
o_dataStruct.LATITUDE = get_data_from_name('LATITUDE', ncData);
o_dataStruct.LONGITUDE = get_data_from_name('LONGITUDE', ncData);
o_dataStruct.POSITION_QC = get_data_from_name('POSITION_QC', ncData);
o_dataStruct.POSITIONING_SYSTEM = strtrim(get_data_from_name('POSITIONING_SYSTEM', ncData)');
o_dataStruct.VERTICAL_SAMPLING_SCHEME = strtrim(get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncData)');
o_dataStruct.CONFIG_MISSION_NUMBER = get_data_from_name('CONFIG_MISSION_NUMBER', ncData);
o_dataStruct.SURFACE_PRESSURE_OFFSET = surfPresOffset;

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE c and b files.
%
% SYNTAX :
%  create_nc_mono_prof_files_3_1( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_mono_prof_files_3_1( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson)

% create the c files
[cFileInfo] = create_nc_mono_prof_c_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, []);

% create the b files
[bFileInfo] = create_nc_mono_prof_b_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, cFileInfo);

% the C-PROF file of each new or updated B-PROF file should be also created or updated
cFileToCreate = [];
if (~isempty(cFileInfo) && ~isempty(bFileInfo))
   cFileInfoNum = cFileInfo(:, 1)*10 + cFileInfo(:, 2);
   bFileInfoNum = bFileInfo(:, 1)*10 + bFileInfo(:, 2);
   [~, id] = setdiff(bFileInfoNum, cFileInfoNum);
   if (~isempty(id))
      cFileToCreate = bFileInfo(id, :);
   end
elseif (~isempty(bFileInfo))
   cFileToCreate = bFileInfo;
end
if (~isempty(cFileToCreate))
   create_nc_mono_prof_c_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, cFileToCreate);
end

fprintf('... NetCDF MONO-PROFILE files created\n');

return

% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE c files.
%
% SYNTAX :
%  [o_cFileInfo] = create_nc_mono_prof_c_files_3_1( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson, a_cFileToCreate)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%   a_cFileToCreate    : information on C-PROF files that should be generated
%
% OUTPUT PARAMETERS :
%   o_cFileInfo : information on generated C-PROF files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cFileInfo] = create_nc_mono_prof_c_files_3_1( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson, a_cFileToCreate)

% output parameters initialization
o_cFileInfo = [];

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% configuration values
global g_decArgo_generateNcMonoProf;
global g_decArgo_applyRtqc;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% global input parameter information
global g_decArgo_processModeAll;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrMissing;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% global default values
global g_decArgo_dateDef;
global g_decArgo_qcDef;

% decoder version
global g_decArgo_decoderVersion;

% report information structure
global g_decArgo_reportStruct;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% to store information on PARAM adjustment
global g_decArgo_paramProfAdjInfo;

% max length allowed for VERTICAL_SAMPLING_SCHEME
global g_decArgo_vssMaxLength;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabProfiles))
   return
end

% select Auxiliary profiles
idProfAux = find([a_tabProfiles.sensorNumber] > 100);
a_tabAuxProfiles = a_tabProfiles(idProfAux);
a_tabProfiles(idProfAux) = [];

% no data to save
if (isempty(a_tabProfiles))
   return
end

% assign time resolution for each float transmission type
if (a_decoderId == 2003)
   profJulDLocRes = double(6/1440); % 6 minutes
else
   profJulDLocRes = double(1/86400); % 1 second
end
[profJulDRes, profJulDComment] = get_prof_juld_resolution(g_decArgo_floatTransType, a_decoderId);

% 03/24/2015: the GDAC checker cannot check 'empty' profiles, we will add a
% default profile with fillValue measurements

% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag]];
end

% add 'default' primary profiles
tabProfiles = a_tabProfiles;
cyNumList = unique(profInfo(:, 1));
dirList = unique(profInfo(:, 2));
for idCy = 1:length(cyNumList)
   cyNum = cyNumList(idCy);
   for idDir = 1:length(dirList)
      direction = dirList(idDir);

      if (~isempty(find( ...
            (profInfo(:, 1) == cyNum) & ...
            (profInfo(:, 2) == direction), 1)))

         idProfInFile = find( ...
            (profInfo(:, 1) == cyNum) & ...
            (profInfo(:, 2) == direction));
         idPrimary = find(profInfo(idProfInFile, 3) == 1, 1);

         if (isempty(idPrimary))

            % create a 'default' primary c profile
            defaultPrimaryProfile = create_default_primary_profile( ...
               cyNum, direction, ...
               tabProfiles, a_decoderId);

            fprintf('DEC_INFO: Float #%d Output Cycle #%d ''%c'': no primary sampling profile - adding a ''default'' one\n', ...
               g_decArgo_floatNum, cyNum, defaultPrimaryProfile.direction);

            % add it to the profiles to process
            tabProfiles(end+1) = defaultPrimaryProfile;
         end
      end
   end
end

% collect information on profiles
profInfo = [];
for idProf = 1:length(tabProfiles)
   profile = tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag 0]];
end

generatedProfList = [];
for idProf = 1:length(tabProfiles)
   if (profInfo(idProf, 4) == 0)
      profile = tabProfiles(idProf);
      cycleNumber = profile.cycleNumber;
      profileNumber = profile.profileNumber;
      outputCycleNumber = profile.outputCycleNumber;

      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end

      % list of profiles to store in the current profile file
      idProfInFile = find( ...
         (profInfo(:, 1) == outputCycleNumber) & ...
         (profInfo(:, 2) == direction) & ...
         (profInfo(:, 4) == 0));
      profInfo(idProfInFile, 4) = 1;
      nbProfToStore = length(idProfInFile);

      % put the primary sampling profile on top of the list
      idPrimary = find(profInfo(idProfInFile, 3) == 1);
      profShiftIfNoPrimary = 0;
      if (length(idPrimary) == 1)
         idProfInFile = [idProfInFile(idPrimary); idProfInFile];
         idProfInFile(idPrimary+1) = [];
      else
         if (isempty(idPrimary))
            % should never append since 03/24/2015 (see above)
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no primary sampling profile\n', ...
               g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
            profShiftIfNoPrimary = 1;
         else
            fprintf('ERROR: Float #%d Cycle #%d Profile #%d Output Cycle #%d: multiple (%d) primary sampling profiles\n', ...
               g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, length(idPrimary));
         end
      end
      nbProfInFile = nbProfToStore + profShiftIfNoPrimary;

      % create the profile parameters list and compute the number of levels
      profParamName = [];
      nbProfParam = 0;
      nbProfLevels = 0;
      for idP = 1:nbProfToStore
         paramNameOfProf = [];
         prof = tabProfiles(idProfInFile(idP));
         parameterList = prof.paramList;
         profileData = prof.data;
         for idParam = 1:length(parameterList)
            if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))
               profParamName = [profParamName; {parameterList(idParam).name}];
               paramNameOfProf = [paramNameOfProf; {parameterList(idParam).name}];
               nbProfLevels = max(nbProfLevels, size(profileData, 1));
            end
         end
         nbProfParam = max(nbProfParam, length(unique(paramNameOfProf)));
      end
      profUniqueParamName = unique(profParamName, 'stable');

      if (nbProfParam > 0)

         % create output file pathname
         floatNumStr = num2str(g_decArgo_floatNum);
         outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end
         outputDirName = [outputDirName '/profiles/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end

         if (direction == 1)
            ncFileName = sprintf('R%d_%03dD.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         else
            ncFileName = sprintf('R%d_%03d.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         end
         ncPathFileName = [outputDirName  ncFileName];

         % check if the file need to be created
         generate = 1;
         if (g_decArgo_floatTransType == 1)

            % Argos floats

            if (g_decArgo_generateNcMonoProf == 2)

               if ((g_decArgo_realtimeFlag == 1) && (g_decArgo_processModeAll == 0))

                  % in this configuration, only new profile files are created
                  % (never updated)
                  if (exist(ncPathFileName, 'file') == 2)
                     generate = 0;
                  end
               end
            end

         elseif ((g_decArgo_floatTransType == 2) || ...
               (g_decArgo_floatTransType == 4))

            % Iridium RUDICS floats
            % Iridium SBD ProvBioII floats

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  % - it exists but the profile structure has been updated
                  if ((exist(ncPathFileName, 'file') == 2) && ...
                        (isempty(find([tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               elseif (g_decArgo_delayedModeFlag == 1)

                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  if (exist(ncPathFileName, 'file') == 2)
                     generate = 0;
                  end
               end
            end

         elseif (g_decArgo_floatTransType == 3)

            % Iridium SBD floats

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  % - it exists but the profile structure has been updated
                  if ((exist(ncPathFileName, 'file') == 2) && ...
                        (isempty(find([tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               end
            end

         else

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no strategy to generate or not profile NetCDF files - generating all profile files\n', ...
                     g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
               end
            end
         end

         % some files should be generated from input parameter list
         if (generate == 0)
            if (~isempty(a_cFileToCreate))
               if (any((a_cFileToCreate(:, 1) == outputCycleNumber) & (a_cFileToCreate(:, 2) == direction)))
                  generate = 1;
               end
            end
         end

         % some profile positions may have been updated
         if (generate == 0)
            if (exist(ncPathFileName, 'file') == 2)

               % retrieve profile location of the nc file
               [ncJuldLoc, ncLat, ncLon, ncPosQc, ncPosSystem] = get_nc_profile_location(ncPathFileName);

               if (length(ncJuldLoc) == nbProfToStore + profShiftIfNoPrimary)

                  for idP = 1:nbProfToStore

                     % get nc profile location
                     profPos = idP+profShiftIfNoPrimary;
                     if (profPos <= length(ncJuldLoc))
                        juldLoc = ncJuldLoc(profPos);
                        latitude = ncLat(profPos);
                        longitude = ncLon(profPos);
                        positionQc = ncPosQc(profPos);
                        positioningSystem = ncPosSystem{profPos};

                        ncProfLocStr = sprintf('%s %.3f %.3f %s', ...
                           julian_2_gregorian_dec_argo(juldLoc), ...
                           latitude, longitude, positioningSystem);

                        % compare profile location
                        prof = tabProfiles(idProfInFile(idP));
                        profLocStr = sprintf('%s %.3f %.3f %s', ...
                           julian_2_gregorian_dec_argo(prof.locationDate), ...
                           prof.locationLat, prof.locationLon, prof.posSystem);

                        if ((((positionQc == '9') && (prof.locationQc ~= ' ')) || ...
                              ((positionQc == '8') && (prof.locationQc ~= '8')) || ...
                              ((positionQc ~= '8') && (prof.locationQc == '8'))))
                           generate = 1;
                           break
                        elseif ((positionQc ~= '9') && (prof.locationQc ~= ' ') && ...
                              ~strcmp(profLocStr, ncProfLocStr))
                           generate = 1;
                           break
                        end
                     end
                  end
               else
                  generate = 1;
               end
            end
         end

         % 1 - the data of one cycle can be in consecutive rsync log files
         % to check if the file need to be created we should then compare profile
         % levels
         % 2 - a new RT adjustment has been set we should compared profile
         % levels of adjusted data
         if (generate == 0)
            if ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_realtimeFlag == 1))
               if (exist(ncPathFileName, 'file') == 2)

                  % retrieve profile levels of the nc file
                  ncProfLev = get_nc_profile_level(ncPathFileName);

                  % compare profile levels
                  differ = 0;
                  for idP = 1:nbProfToStore
                     profPos = idP-1+profShiftIfNoPrimary;
                     if (profPos+1 > length(ncProfLev))
                        % new pofiles should be added in the file
                        differ = 1;
                        break
                     end

                     prof = tabProfiles(idProfInFile(idP));

                     % profile parameter data
                     parameterList = prof.paramList;
                     for idLoop = 1:2
                        nLevelsParam = 0;
                        idNoDefAll = [];
                        for idParam = 1:length(parameterList)
                           if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))
                              profParam = parameterList(idParam);
                              profParamName = profParam.name;
                              paramInfo = get_netcdf_param_attributes(profParamName);
                              if (idLoop == 1)
                                 profData = prof.data;
                              else
                                 profData = prof.dataAdj;
                              end
                              % prof.data is empty in 'default' primary profiles
                              if (~isempty(profData))
                                 % parameter data
                                 paramData = profData(:, idParam);
                                 idNoDef = find(paramData ~= paramInfo.fillValue);
                                 idNoDefAll = [idNoDefAll idNoDef'];
                              end
                           end
                        end
                        if (~isempty(idNoDefAll))
                           nLevelsParam = max(idNoDefAll) - min(idNoDefAll) + 1;
                        end
                        if (idLoop == 1)
                           ncProfLevRef = ncProfLev(1, profPos+1);
                        else
                           ncProfLevRef = ncProfLev(2, profPos+1);
                        end
                        if (nLevelsParam ~= ncProfLevRef)
                           differ = 1;
                           break
                        end
                     end
                     if (differ == 1)
                        break
                     end
                  end
                  if (differ == 1)
                     generate = 1;
                  end

                  if (generate == 0)
                     if ((a_decoderId > 2000) && (a_decoderId < 3000))

                        % NOVA/DOVA float
                        % the clock offset is not defined for the last cycle
                        % (needed information for cycle N is transmitted during
                        % cycle N+1) => profile JULD (and JULD_LOCATION since
                        % it is in float time) can be adjusted during the
                        % following cycles
                        % => the file should be updated if it was the last one
                        % of the previous run and we received a new one

                        fileCycleNum = [];
                        floatFiles = [dir([outputDirName '/' sprintf('R%d_*.nc', g_decArgo_floatNum)]); ...
                           dir([outputDirName '/' sprintf('D%d_*.nc', g_decArgo_floatNum)])];
                        for idFile = 1:length(floatFiles)
                           floatFileName = floatFiles(idFile).name;
                           idFUs = strfind(floatFileName, '_');
                           fileCycleNum = [fileCycleNum str2num(floatFileName(idFUs+1:idFUs+3))];
                        end

                        if (~isempty(fileCycleNum))
                           if ((outputCycleNumber == max(fileCycleNum)) && ...
                                 (any(profInfo(:, 1) == outputCycleNumber+1)))
                              generate = 1;
                           end
                        end
                     end
                  end
               end
            end
         end

         % the RT adjustment coefficients have been modified
         if (generate == 0)
            if ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_realtimeFlag == 1))
               if (exist(ncPathFileName, 'file') == 2)

                  % retrieve RT adjustment information
                  sciCalibInfo = get_nc_profile_sci_calib_info(ncPathFileName);

                  % compare RT adjustment coefficients
                  differ = 0;
                  for idP = 1:nbProfToStore

                     prof = tabProfiles(idProfInFile(idP));

                     % check PRES surface offset adjustment information
                     if (any(strcmp({prof.paramList.name}, 'PRES')))
                        if (~isempty(prof.presOffset))

                           paramCoefficient = {['Surface Pressure = ' num2str(prof.presOffset) ' dbar']};

                           presAdjList = find(strcmp('PRES', sciCalibInfo(:, 4)));
                           found = 0;
                           for idAdj = 1:length(presAdjList)
                              if (strcmp(paramCoefficient, sciCalibInfo(presAdjList(idAdj), 6)))
                                 found = 1;
                                 break
                              end
                           end
                           if (~found)
                              differ = 1;
                              break
                           end
                        end
                     end

                     % check misc adjustment information (from data base)
                     if (~isempty(prof.rtParamAdjIdList))
                        for idProfAdj = prof.rtParamAdjIdList

                           % retrieve information on PARAM adjustment
                           idF = find([g_decArgo_paramProfAdjInfo{:, 1}] == idProfAdj);
                           paramAdjInfo = g_decArgo_paramProfAdjInfo(idF, :);
                           paramName = paramAdjInfo{4};
                           paramInfo = get_netcdf_param_attributes(paramName);
                           if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'j'))
                              paramCoefficient = paramAdjInfo{6};

                              paramAdjList = find(strcmp(paramName, sciCalibInfo(:, 4)));
                              found = 0;
                              for idAdj = 1:length(paramAdjList)
                                 if (strcmp(paramCoefficient, sciCalibInfo(paramAdjList(idAdj), 6)))
                                    found = 1;
                                    break
                                 end
                              end
                              if (~found)
                                 differ = 1;
                                 break
                              end
                           end
                        end
                        if (differ == 1)
                           break
                        end
                     end
                  end
                  if (differ == 1)
                     generate = 1;
                  end
               end
            end
         end

         if (generate == 0)
            continue
         end

         generatedProfList = [generatedProfList; outputCycleNumber direction];

         % information to retrieve from a possible existing mono-profile file
         ncCreationDate = '';
         histoInstitution = '';
         histoStep = '';
         histoSoftware = '';
         histoSoftwareRelease = '';
         histoDate = '';

         if (exist(ncPathFileName, 'file') == 2)

            % retrieve information from existing file
            wantedProfVars = [ ...
               {'DATE_CREATION'} ...
               {'HISTORY_INSTITUTION'} ...
               {'HISTORY_STEP'} ...
               {'HISTORY_SOFTWARE'} ...
               {'HISTORY_SOFTWARE_RELEASE'} ...
               {'HISTORY_DATE'} ...
               ];

            % retrieve information from PROF netCDF file
            [profData] = get_data_from_nc_file(ncPathFileName, wantedProfVars);

            idVal = find(strcmp('DATE_CREATION', profData) == 1);
            if (~isempty(idVal))
               ncCreationDate = profData{idVal+1}';
            end
            idVal = find(strcmp('HISTORY_INSTITUTION', profData) == 1);
            if (~isempty(idVal))
               histoInstitution = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_STEP', profData) == 1);
            if (~isempty(idVal))
               histoStep = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_SOFTWARE', profData) == 1);
            if (~isempty(idVal))
               histoSoftware = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_SOFTWARE_RELEASE', profData) == 1);
            if (~isempty(idVal))
               histoSoftwareRelease = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_DATE', profData) == 1);
            if (~isempty(idVal))
               histoDate = profData{idVal+1};
            end

            if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
               fprintf('Updating NetCDF MONO-PROFILE file (%s) ...\n', ncFileName);
            end

         else
            if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
               fprintf('Creating NetCDF MONO-PROFILE file (%s) ...\n', ncFileName);
            end
         end

         if (g_decArgo_floatTransType == 1)

            % Argos floats

            if (g_decArgo_generateNcMonoProf == 2)
               if (~isempty(profile.profileCompleted) && (profile.profileCompleted > 0))
                  fprintf('INFO: Float #%d cycle #%d: missing levels in transmitted profile (%d levels are missing)\n', ...
                     g_decArgo_floatNum, outputCycleNumber, profile.profileCompleted);
               end
            end
         end

         currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

         % create and open NetCDF file
         fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
         if (isempty(fCdf))
            fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
            return
         end

         try

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % DEFINE MODE BEGIN
            if (VERBOSE_MODE == 2)
               fprintf('START DEFINE MODE\n');
               fprintf('float cycle # = %d\n', cycleNumber);
               fprintf('float profile # = %d\n', profileNumber);
               fprintf('output cycle # = %d\n', outputCycleNumber);
            end

            % create dimensions
            dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
            string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
            string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
            paramNameLength = 16;
            string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
            string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
            string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
            string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
            string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

            nProfDimId = netcdf.defDim(fCdf, 'N_PROF', nbProfInFile);
            nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbProfParam);
            nLevelsDimId = netcdf.defDim(fCdf, 'N_LEVELS', nbProfLevels);
            % N_CALIB dimension is processed and created later
            nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', netcdf.getConstant('NC_UNLIMITED'));

            if (VERBOSE_MODE == 2)
               fprintf('N_PROF = %d\n', nbProfInFile);
               fprintf('N_PARAM = %d\n', nbProfParam);
               fprintf('N_LEVELS = %d\n', nbProfLevels);
            end

            % create global attributes
            globalVarId = netcdf.getConstant('NC_GLOBAL');
            netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
            institution = 'CORIOLIS';
            idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               dataCentre = char(a_metaDataFromJson{idVal+1});
               [institution] = get_institution_from_data_centre(dataCentre, 1);
            end
            netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
            netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
            if (isempty(ncCreationDate))
               globalHistoryText = [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
            else
               globalHistoryText = [datestr(datenum(ncCreationDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
            end
            % modif 20250709
            % globalHistoryText = [globalHistoryText ...
            %    datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis float real time data processing)'];
            globalHistoryText = globalHistoryText(1:end-1);
            netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
            netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
            netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.1');
            netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
            netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');
            % modif 20250709
            % netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));
            netcdf.putAtt(fCdf, globalVarId, 'id', 'https://doi.org/10.17882/42182');

            % create misc variables
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

            % create profile variables
            platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
            netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
            netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
            netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');

            projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Name of the project');
            netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');

            piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
            netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');

            stationParametersVarId = netcdf.defVar(fCdf, 'STATION_PARAMETERS', 'NC_CHAR', fliplr([nProfDimId nParamDimId string16DimId]));
            netcdf.putAtt(fCdf, stationParametersVarId, 'long_name', 'List of available parameters for the station');
            netcdf.putAtt(fCdf, stationParametersVarId, 'conventions', 'Argo reference table 3');
            netcdf.putAtt(fCdf, stationParametersVarId, '_FillValue', ' ');

            cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nProfDimId);
            netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number');
            netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle (if exists), 1 : first complete cycle');
            netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));

            directionVarId = netcdf.defVar(fCdf, 'DIRECTION', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, directionVarId, 'long_name', 'Direction of the station profiles');
            netcdf.putAtt(fCdf, directionVarId, 'conventions', 'A: ascending profiles, D: descending profiles');
            netcdf.putAtt(fCdf, directionVarId, '_FillValue', ' ');

            dataCenterVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', fliplr([nProfDimId string2DimId]));
            netcdf.putAtt(fCdf, dataCenterVarId, 'long_name', 'Data centre in charge of float data processing');
            netcdf.putAtt(fCdf, dataCenterVarId, 'conventions', 'Argo reference table 4');
            netcdf.putAtt(fCdf, dataCenterVarId, '_FillValue', ' ');

            dcReferenceVarId = netcdf.defVar(fCdf, 'DC_REFERENCE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, dcReferenceVarId, 'long_name', 'Station unique identifier in data centre');
            netcdf.putAtt(fCdf, dcReferenceVarId, 'conventions', 'Data centre convention');
            netcdf.putAtt(fCdf, dcReferenceVarId, '_FillValue', ' ');

            dataStateIndicatorVarId = netcdf.defVar(fCdf, 'DATA_STATE_INDICATOR', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'long_name', 'Degree of processing the data have passed through');
            netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'conventions', 'Argo reference table 6');
            netcdf.putAtt(fCdf, dataStateIndicatorVarId, '_FillValue', ' ');

            dataModeVarId = netcdf.defVar(fCdf, 'DATA_MODE', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, dataModeVarId, 'long_name', 'Delayed mode or real time data');
            netcdf.putAtt(fCdf, dataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
            netcdf.putAtt(fCdf, dataModeVarId, '_FillValue', ' ');

            platformTypeVarId = netcdf.defVar(fCdf, 'PLATFORM_TYPE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, platformTypeVarId, 'long_name', 'Type of float');
            netcdf.putAtt(fCdf, platformTypeVarId, 'conventions', 'Argo reference table 23');
            netcdf.putAtt(fCdf, platformTypeVarId, '_FillValue', ' ');

            floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
            netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');

            firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Instrument firmware version');
            netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');

            wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
            netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
            netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');

            juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of the station relative to REFERENCE_DATE_TIME');
            netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
            netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
            netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
            netcdf.putAtt(fCdf, juldVarId, 'resolution', profJulDRes);
            netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
            netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');
            if (~isempty(profJulDComment))
               netcdf.putAtt(fCdf, juldVarId, 'comment_on_resolution', profJulDComment);
            end

            juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
            netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
            netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');

            juldLocationVarId = netcdf.defVar(fCdf, 'JULD_LOCATION', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, juldLocationVarId, 'long_name', 'Julian day (UTC) of the location relative to REFERENCE_DATE_TIME');
            netcdf.putAtt(fCdf, juldLocationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
            netcdf.putAtt(fCdf, juldLocationVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
            netcdf.putAtt(fCdf, juldLocationVarId, 'resolution', profJulDLocRes);
            netcdf.putAtt(fCdf, juldLocationVarId, '_FillValue', double(999999));

            latitudeVarId = netcdf.defVar(fCdf, 'LATITUDE', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, latitudeVarId, 'long_name', 'Latitude of the station, best estimate');
            netcdf.putAtt(fCdf, latitudeVarId, 'standard_name', 'latitude');
            netcdf.putAtt(fCdf, latitudeVarId, 'units', 'degree_north');
            netcdf.putAtt(fCdf, latitudeVarId, '_FillValue', double(99999));
            netcdf.putAtt(fCdf, latitudeVarId, 'valid_min', double(-90));
            netcdf.putAtt(fCdf, latitudeVarId, 'valid_max', double(90));
            netcdf.putAtt(fCdf, latitudeVarId, 'axis', 'Y');

            longitudeVarId = netcdf.defVar(fCdf, 'LONGITUDE', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, longitudeVarId, 'long_name', 'Longitude of the station, best estimate');
            netcdf.putAtt(fCdf, longitudeVarId, 'standard_name', 'longitude');
            netcdf.putAtt(fCdf, longitudeVarId, 'units', 'degree_east');
            netcdf.putAtt(fCdf, longitudeVarId, '_FillValue', double(99999));
            netcdf.putAtt(fCdf, longitudeVarId, 'valid_min', double(-180));
            netcdf.putAtt(fCdf, longitudeVarId, 'valid_max', double(180));
            netcdf.putAtt(fCdf, longitudeVarId, 'axis', 'X');

            positionQcVarId = netcdf.defVar(fCdf, 'POSITION_QC', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, positionQcVarId, 'long_name', 'Quality on position (latitude and longitude)');
            netcdf.putAtt(fCdf, positionQcVarId, 'conventions', 'Argo reference table 2');
            netcdf.putAtt(fCdf, positionQcVarId, '_FillValue', ' ');

            positioningSystemVarId = netcdf.defVar(fCdf, 'POSITIONING_SYSTEM', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
            netcdf.putAtt(fCdf, positioningSystemVarId, 'long_name', 'Positioning system');
            netcdf.putAtt(fCdf, positioningSystemVarId, '_FillValue', ' ');

            % global quality of PARAM profile
            for idParam = 1:length(profUniqueParamName)
               profParamName = profUniqueParamName{idParam};
               ncParamName = sprintf('PROFILE_%s_QC', profParamName);

               profileParamQcVarId = netcdf.defVar(fCdf, ncParamName, 'NC_CHAR', nProfDimId);
               netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', profParamName));
               netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
               netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
            end

            verticalSamplingSchemeVarId = netcdf.defVar(fCdf, 'VERTICAL_SAMPLING_SCHEME', 'NC_CHAR', fliplr([nProfDimId string256DimId]));
            netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'long_name', 'Vertical sampling scheme');
            netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'conventions', 'Argo reference table 16');
            netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, '_FillValue', ' ');

            configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nProfDimId);
            netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
            netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
            netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));

            % add profile data
            calibInfo = [];
            for idP = 1:nbProfToStore

               prof = tabProfiles(idProfInFile(idP));

               % profile parameter data
               parameterList = prof.paramList;
               for idParam = 1:length(parameterList)

                  if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                     profParam = parameterList(idParam);
                     profParamName = profParam.name;
                     profParamNcType = profParam.paramNcType;

                     % parameter variable and attributes
                     if (~var_is_present_dec_argo(fCdf, profParamName))

                        profParamVarId = netcdf.defVar(fCdf, profParamName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));

                        if (~isempty(profParam.longName))
                           netcdf.putAtt(fCdf, profParamVarId, 'long_name', profParam.longName);
                        end
                        if (~isempty(profParam.standardName))
                           netcdf.putAtt(fCdf, profParamVarId, 'standard_name', profParam.standardName);
                        end
                        if (~isempty(profParam.fillValue))
                           netcdf.putAtt(fCdf, profParamVarId, '_FillValue', profParam.fillValue);
                        end
                        if (~isempty(profParam.units))
                           netcdf.putAtt(fCdf, profParamVarId, 'units', profParam.units);
                        end
                        if (~isempty(profParam.validMin))
                           netcdf.putAtt(fCdf, profParamVarId, 'valid_min', profParam.validMin);
                        end
                        if (~isempty(profParam.validMax))
                           netcdf.putAtt(fCdf, profParamVarId, 'valid_max', profParam.validMax);
                        end
                        if (~isempty(profParam.cFormat))
                           netcdf.putAtt(fCdf, profParamVarId, 'C_format', profParam.cFormat);
                        end
                        if (~isempty(profParam.fortranFormat))
                           netcdf.putAtt(fCdf, profParamVarId, 'FORTRAN_format', profParam.fortranFormat);
                        end
                        if (~isempty(profParam.resolution))
                           netcdf.putAtt(fCdf, profParamVarId, 'resolution', profParam.resolution);
                        end
                        if (~isempty(profParam.axis))
                           netcdf.putAtt(fCdf, profParamVarId, 'axis', profParam.axis);
                        end
                     end

                     % parameter QC variable and attributes
                     profParamQcName = sprintf('%s_QC', profParam.name);
                     if (~var_is_present_dec_argo(fCdf, profParamQcName))

                        profParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));

                        netcdf.putAtt(fCdf, profParamQcVarId, 'long_name', 'quality flag');
                        netcdf.putAtt(fCdf, profParamQcVarId, 'conventions', 'Argo reference table 2');
                        netcdf.putAtt(fCdf, profParamQcVarId, '_FillValue', ' ');
                     end

                     % parameter adjusted variable and attributes
                     if (profParam.adjAllowed == 1)

                        profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamAdjName))

                           profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));

                           if (~isempty(profParam.longName))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'long_name', profParam.longName);
                           end
                           if (~isempty(profParam.standardName))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'standard_name', profParam.standardName);
                           end
                           if (~isempty(profParam.fillValue))
                              netcdf.putAtt(fCdf, profParamAdjVarId, '_FillValue', profParam.fillValue);
                           end
                           if (~isempty(profParam.units))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'units', profParam.units);
                           end
                           if (~isempty(profParam.validMin))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_min', profParam.validMin);
                           end
                           if (~isempty(profParam.validMax))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_max', profParam.validMax);
                           end
                           if (~isempty(profParam.cFormat))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'C_format', profParam.cFormat);
                           end
                           if (~isempty(profParam.fortranFormat))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'FORTRAN_format', profParam.fortranFormat);
                           end
                           if (~isempty(profParam.resolution))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'resolution', profParam.resolution);
                           end
                           if (~isempty(profParam.axis))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'axis', profParam.axis);
                           end
                        end

                        % parameter adjusted QC variable and attributes
                        profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamAdjQcName))

                           profParamAdjQcVarId = netcdf.defVar(fCdf, profParamAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));

                           netcdf.putAtt(fCdf, profParamAdjQcVarId, 'long_name', 'quality flag');
                           netcdf.putAtt(fCdf, profParamAdjQcVarId, 'conventions', 'Argo reference table 2');
                           netcdf.putAtt(fCdf, profParamAdjQcVarId, '_FillValue', ' ');
                        end

                        % parameter adjusted error variable and attributes
                        profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamAdjErrName))

                           profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));

                           netcdf.putAtt(fCdf, profParamAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
                           if (~isempty(profParam.fillValue))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, '_FillValue', profParam.fillValue);
                           end
                           if (~isempty(profParam.units))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'units', profParam.units);
                           end
                           if (~isempty(profParam.cFormat))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'C_format', profParam.cFormat);
                           end
                           if (~isempty(profParam.fortranFormat))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'FORTRAN_format', profParam.fortranFormat);
                           end
                           if (~isempty(profParam.resolution))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'resolution', profParam.resolution);
                           end
                        end
                     end
                  end
               end
            end

            % history information
            historyInstitutionVarId = netcdf.defVar(fCdf, 'HISTORY_INSTITUTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historyInstitutionVarId, 'long_name', 'Institution which performed action');
            netcdf.putAtt(fCdf, historyInstitutionVarId, 'conventions', 'Argo reference table 4');
            netcdf.putAtt(fCdf, historyInstitutionVarId, '_FillValue', ' ');

            historyStepVarId = netcdf.defVar(fCdf, 'HISTORY_STEP', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historyStepVarId, 'long_name', 'Step in data processing');
            netcdf.putAtt(fCdf, historyStepVarId, 'conventions', 'Argo reference table 12');
            netcdf.putAtt(fCdf, historyStepVarId, '_FillValue', ' ');

            historySoftwareVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historySoftwareVarId, 'long_name', 'Name of software which performed action');
            netcdf.putAtt(fCdf, historySoftwareVarId, 'conventions', 'Institution dependent');
            netcdf.putAtt(fCdf, historySoftwareVarId, '_FillValue', ' ');

            historySoftwareReleaseVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE_RELEASE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'long_name', 'Version/release of software which performed action');
            netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'conventions', 'Institution dependent');
            netcdf.putAtt(fCdf, historySoftwareReleaseVarId, '_FillValue', ' ');

            historyReferenceVarId = netcdf.defVar(fCdf, 'HISTORY_REFERENCE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, historyReferenceVarId, 'long_name', 'Reference of database');
            netcdf.putAtt(fCdf, historyReferenceVarId, 'conventions', 'Institution dependent');
            netcdf.putAtt(fCdf, historyReferenceVarId, '_FillValue', ' ');

            historyDateVarId = netcdf.defVar(fCdf, 'HISTORY_DATE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId dateTimeDimId]));
            netcdf.putAtt(fCdf, historyDateVarId, 'long_name', 'Date the history record was created');
            netcdf.putAtt(fCdf, historyDateVarId, 'conventions', 'YYYYMMDDHHMISS');
            netcdf.putAtt(fCdf, historyDateVarId, '_FillValue', ' ');

            historyActionVarId = netcdf.defVar(fCdf, 'HISTORY_ACTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historyActionVarId, 'long_name', 'Action performed on data');
            netcdf.putAtt(fCdf, historyActionVarId, 'conventions', 'Argo reference table 7');
            netcdf.putAtt(fCdf, historyActionVarId, '_FillValue', ' ');

            historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
            netcdf.putAtt(fCdf, historyParameterVarId, 'long_name', 'Station parameter action is performed on');
            netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Argo reference table 3');
            netcdf.putAtt(fCdf, historyParameterVarId, '_FillValue', ' ');

            historyStartPresVarId = netcdf.defVar(fCdf, 'HISTORY_START_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
            netcdf.putAtt(fCdf, historyStartPresVarId, 'long_name', 'Start pressure action applied on');
            netcdf.putAtt(fCdf, historyStartPresVarId, '_FillValue', single(99999));
            netcdf.putAtt(fCdf, historyStartPresVarId, 'units', 'decibar');

            historyStopPresVarId = netcdf.defVar(fCdf, 'HISTORY_STOP_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
            netcdf.putAtt(fCdf, historyStopPresVarId, 'long_name', 'Stop pressure action applied on');
            netcdf.putAtt(fCdf, historyStopPresVarId, '_FillValue', single(99999));
            netcdf.putAtt(fCdf, historyStopPresVarId, 'units', 'decibar');

            historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
            netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
            netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));

            historyQcTestVarId = netcdf.defVar(fCdf, 'HISTORY_QCTEST', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
            netcdf.putAtt(fCdf, historyQcTestVarId, 'long_name', 'Documentation of tests performed, tests failed (in hex form)');
            netcdf.putAtt(fCdf, historyQcTestVarId, 'conventions', 'Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
            netcdf.putAtt(fCdf, historyQcTestVarId, '_FillValue', ' ');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % DEFINE MODE END
            if (VERBOSE_MODE == 2)
               fprintf('STOP DEFINE MODE\n');
            end

            netcdf.endDef(fCdf);

            valueStr = 'Argo profile';
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

            % create profile variables
            valueStr = sprintf('%d', g_decArgo_floatNum);
            valueStr = [valueStr blanks(8-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, platformNumberVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = ' ';
            idVal = find(strcmp('PROJECT_NAME', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(64-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, projectNameVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = ' ';
            idVal = find(strcmp('PI_NAME', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(64-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, piNameVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            for idP = 1:nbProfToStore
               prof = tabProfiles(idProfInFile(idP));
               parameterList = prof.paramList;
               profPos = idP-1+profShiftIfNoPrimary;
               paramPos = 0;
               for idParam = 1:length(parameterList)

                  if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                     valueStr = parameterList(idParam).name;
                     if (length(valueStr) > paramNameLength)
                        fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) - name truncated\n', ...
                           g_decArgo_floatNum, valueStr, paramNameLength);
                        valueStr = valueStr(1:paramNameLength);
                     end

                     netcdf.putVar(fCdf, stationParametersVarId, ...
                        fliplr([profPos paramPos 0]), fliplr([1 1 length(valueStr)]), valueStr');
                     paramPos = paramPos + 1;
                  end
               end
            end

            netcdf.putVar(fCdf, cycleNumberVarId, profShiftIfNoPrimary, nbProfToStore, ones(1, nbProfToStore)*outputCycleNumber);

            valueStr = ' ';
            idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(2-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, dataCenterVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = ' ';
            idVal = find(strcmp('DC_REFERENCE', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(32-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, dcReferenceVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = '1A';
            idVal = find(strcmp('DATA_STATE_INDICATOR', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(4-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, dataStateIndicatorVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            netcdf.putVar(fCdf, dataModeVarId, profShiftIfNoPrimary, nbProfToStore, repmat('R', 1, nbProfToStore));

            valueStr = get_platform_type(a_decoderId);
            valueStr = [valueStr blanks(32-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, platformTypeVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = ' ';
            idVal = find(strcmp('FLOAT_SERIAL_NO', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(32-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, floatSerialNoVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = ' ';
            idVal = find(strcmp('FIRMWARE_VERSION', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               valueStr = char(a_metaDataFromJson{idVal+1});
            end
            valueStr = [valueStr blanks(32-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, firmwareVersionVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            valueStr = get_wmo_instrument_type(a_decoderId);
            valueStr = [valueStr blanks(4-length(valueStr))];
            tabValue = repmat(valueStr, nbProfToStore, 1);
            netcdf.putVar(fCdf, wmoInstTypeVarId, ...
               fliplr([profShiftIfNoPrimary 0]), ...
               fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

            % copy existing history information
            if (~isempty(histoInstitution))
               if (size(histoInstitution, 2) <= nbProfInFile)
                  netcdf.putVar(fCdf, historyInstitutionVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoInstitution, 3) size(histoInstitution, 2) size(histoInstitution, 1)]), histoInstitution);
                  netcdf.putVar(fCdf, historyStepVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoStep, 3) size(histoStep, 2) size(histoStep, 1)]), histoStep);
                  netcdf.putVar(fCdf, historySoftwareVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoSoftware, 3) size(histoSoftware, 2) size(histoSoftware, 1)]), histoSoftware);
                  netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoSoftwareRelease, 3) size(histoSoftwareRelease, 2) size(histoSoftwareRelease, 1)]), histoSoftwareRelease);
                  netcdf.putVar(fCdf, historyDateVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoDate, 3) size(histoDate, 2) size(histoDate, 1)]), histoDate);
               else
                  fprintf('WARNING: Float #%d : N_PROF=%d in existing file, N_PROF=%d in updated file - history information not copied when updating file %s\n', ...
                     g_decArgo_floatNum, size(histoInstitution, 2), nbProfInFile, ncPathFileName);
               end
            end

            % add profile data
            for idP = 1:nbProfToStore
               if (VERBOSE_MODE == 2)
                  fprintf('Add profile #%d/%d data\n', ...
                     idP+profShiftIfNoPrimary, nbProfInFile);
               end

               profPos = idP-1+profShiftIfNoPrimary;
               prof = tabProfiles(idProfInFile(idP));

               % profile direction
               netcdf.putVar(fCdf, directionVarId, profPos, 1, prof.direction);

               % profile date
               profDate = prof.date;
               if (profDate ~= g_decArgo_dateDef)
                  netcdf.putVar(fCdf, juldVarId, profPos, 1, profDate);
                  if (~isempty(prof.dateQc))
                     netcdf.putVar(fCdf, juldQcVarId, profPos, 1, prof.dateQc);
                  else
                     netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
                  end
               else
                  netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrMissing);
               end

               % profile location
               profLocationDate = prof.locationDate;
               profLocationLon = prof.locationLon;
               profLocationLat = prof.locationLat;
               profLocationQc = prof.locationQc;
               profPosSystem = prof.posSystem;
               if (profLocationDate ~= g_decArgo_dateDef)
                  netcdf.putVar(fCdf, juldLocationVarId, profPos, 1, profLocationDate);
                  netcdf.putVar(fCdf, latitudeVarId, profPos, 1, profLocationLat);
                  netcdf.putVar(fCdf, longitudeVarId, profPos, 1, profLocationLon);
                  if (~isempty(profLocationQc))
                     netcdf.putVar(fCdf, positionQcVarId, profPos, 1, profLocationQc);
                  else
                     netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
                  end
               else
                  netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrMissing);
               end
               netcdf.putVar(fCdf, positioningSystemVarId, fliplr([profPos 0]), fliplr([1 length(profPosSystem)]), profPosSystem');

               % vertical sampling scheme
               vertSampScheme = prof.vertSamplingScheme;
               if (length(vertSampScheme) > g_decArgo_vssMaxLength)
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: vertical sampling scheme too long (length = %d > %d) - vertical sampling scheme ''%s'' not set\n', ...
                     g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, ...
                     length(vertSampScheme), g_decArgo_vssMaxLength, ...
                     vertSampScheme);
                  idF1 = strfind(vertSampScheme, '[');
                  idF2 = strfind(vertSampScheme, ']');
                  vertSampScheme = [vertSampScheme(1:idF1(1)) 'detailed description too long for available space' vertSampScheme(idF2(end):end)];
               end
               netcdf.putVar(fCdf, verticalSamplingSchemeVarId, fliplr([profPos 0]), fliplr([1 length(vertSampScheme)]), vertSampScheme');

               % configuration mission number
               if (~isempty(prof.configMissionNumber))
                  netcdf.putVar(fCdf, configMissionNumberVarId, profPos, 1, prof.configMissionNumber);
               end

               % profile parameter data
               parameterList = prof.paramList;
               parameterDataMode = prof.paramDataMode;
               adjInCoreFlag = 0;
               if (~isempty(parameterDataMode))
                  if (any(parameterDataMode([parameterList.paramType] == 'c') == 'A') || any(parameterDataMode([parameterList.paramType] == 'j') == 'A'))
                     adjInCoreFlag = 1;
                     netcdf.putVar(fCdf, dataModeVarId, profPos, 1, 'A');
                  end
               end
               for idParam = 1:length(parameterList)

                  if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                     profParam = parameterList(idParam);

                     % parameter variable and attributes

                     profParamName = profParam.name;
                     profParamVarId = netcdf.inqVarID(fCdf, profParamName);

                     % parameter QC variable and attributes
                     profParamQcName = sprintf('%s_QC', profParam.name);
                     profParamQcVarId = netcdf.inqVarID(fCdf, profParamQcName);

                     if (profParam.adjAllowed == 1)
                        % parameter adjusted variable and attributes
                        profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                        profParamAdjVarId = netcdf.inqVarID(fCdf, profParamAdjName);

                        % parameter adjusted QC variable and attributes
                        profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
                        profParamAdjQcVarId = netcdf.inqVarID(fCdf, profParamAdjQcName);

                        % parameter adjusted error variable and attributes
                        profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
                        profParamAdjErrVarId = netcdf.inqVarID(fCdf, profParamAdjErrName);
                     end

                     % prof.data is empty in 'default' primary profiles
                     if (~isempty(prof.data))

                        % parameter data
                        paramData = prof.data(:, idParam);
                        if (isempty(prof.dataQc))
                           paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                           paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                        else
                           paramDataQc = prof.dataQc(:, idParam);
                           if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                              paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           else
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                              idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                              paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));

                              profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                              profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                              netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                           end
                        end

                        if (prof.direction == 'A')
                           measIds = fliplr([1:length(paramData)]);
                        else
                           measIds = [1:length(paramData)];
                        end
                        netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));

                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramDataQcStr(measIds));

                        if ((profParam.adjAllowed == 1) && (adjInCoreFlag))

                           % parameter adjusted data
                           if (parameterDataMode(idParam) == ' ')
                              paramAdjData = paramData;
                              paramAdjDataQcStr = paramDataQcStr;
                           else
                              paramAdjData = prof.dataAdj(:, idParam);
                              if (isempty(prof.dataAdjQc))
                                 paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                 paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                              else
                                 paramAdjDataQc = prof.dataAdjQc(:, idParam);
                                 if (all(paramAdjDataQc == g_decArgo_qcDef))
                                    paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                    paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                                 else
                                    paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, length(paramAdjData), 1);
                                    idNoDef = find(paramAdjDataQc ~= g_decArgo_qcDef);
                                    paramAdjDataQcStr(idNoDef) = num2str(paramAdjDataQc(idNoDef));

                                    profQualityFlag = compute_profile_quality_flag(paramAdjDataQcStr);
                                    profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                                 end
                              end
                           end

                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjData(measIds));

                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));

                           if (~isempty(prof.dataAdjError))
                              paramAdjDataError = prof.dataAdjError(:, idParam);
                              if (any(paramAdjDataError ~= profParam.fillValue))
                                 netcdf.putVar(fCdf, profParamAdjErrVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjDataError)]), paramAdjDataError(measIds));
                              end
                           end
                        end
                     end
                  end
               end

               % add PRES adjustment information
               if (any(strcmp({prof.paramList.name}, 'PRES')))
                  if (~isempty(prof.presOffset))

                     tabParam = {'PRES'};
                     tabEquation = {'PRES_ADJUSTED = PRES - Surface Pressure'};
                     tabCoefficient = {['Surface Pressure = ' num2str(prof.presOffset) ' dbar']};
                     tabComment = {'Pressure adjusted in real time by using pressure offset at the sea surface'};
                     if (isempty(ncCreationDate))
                        date = currentDate;
                     else
                        date = ncCreationDate;
                     end
                     tabDate = {date};

                     % store calibration information for this profile
                     profCalibInfo = [];
                     profCalibInfo.profId = idP;
                     profCalibInfo.param = tabParam;
                     profCalibInfo.equation = tabEquation;
                     profCalibInfo.coefficient = tabCoefficient;
                     profCalibInfo.comment = tabComment;
                     profCalibInfo.date = tabDate;
                     calibInfo{end+1} = profCalibInfo;
                  end
               end

               % for decoder RT adjustments:
               % retrieve SCIENTIFIC_CALIB_* from decoder g_decArgo_paramProfAdjInfo
               % global variable
               if (~isempty(prof.rtParamAdjIdList))
                  for idAdj = prof.rtParamAdjIdList

                     % retrieve information on PARAM adjustment
                     idF = find([g_decArgo_paramProfAdjInfo{:, 1}] == idAdj);
                     paramAdjInfo = g_decArgo_paramProfAdjInfo(idF, :);
                     paramName = paramAdjInfo{4};

                     paramInfo = get_netcdf_param_attributes(paramName);
                     if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'j'))
                        paramEquation = paramAdjInfo{5};
                        paramCoefficient = paramAdjInfo{6};
                        paramComment = paramAdjInfo{7};
                        paramDate = paramAdjInfo{8};

                        if (isempty(paramDate))
                           if (isempty(ncCreationDate))
                              paramDate = currentDate;
                           else
                              paramDate = ncCreationDate;
                           end
                        end
                        tabParam = {paramName};
                        tabEquation = {paramEquation};
                        tabCoefficient = {paramCoefficient};
                        tabComment = {paramComment};
                        tabDate = {paramDate};

                        % store calibration information for this profile
                        profCalibInfo = [];
                        profCalibInfo.profId = idP;
                        profCalibInfo.param = tabParam;
                        profCalibInfo.equation = tabEquation;
                        profCalibInfo.coefficient = tabCoefficient;
                        profCalibInfo.comment = tabComment;
                        profCalibInfo.date = tabDate;
                        calibInfo{end+1} = profCalibInfo;
                     end
                  end
               end

               % add a SCIENTIFIC_CALIB_COMMENT for duplicated data
               if (~isempty(calibInfo))
                  calibList = [calibInfo{:}];
                  idF = find([calibList.profId] == idP);
                  if (~isempty(idF))
                     calibListForProf = [calibInfo{idF}];
                     newList = setdiff({prof.paramList.name}, [calibListForProf.param]);
                     for idParam = 1:length(newList)
                        paramName = newList{idParam};
                        paramInfo = get_netcdf_param_attributes(paramName);
                        if (paramInfo.paramType == 'c')

                           tabParam = {paramName};
                           tabEquation = {[paramName '_ADJUSTED = ' paramName]};
                           tabCoefficient = {'Not applicable'};
                           tabComment = {'No adjustment performed (values duplicated)'};
                           if (isempty(ncCreationDate))
                              date = currentDate;
                           else
                              date = ncCreationDate;
                           end
                           tabDate = {date};

                           % store calibration information for this profile
                           profCalibInfo = [];
                           profCalibInfo.profId = idP;
                           profCalibInfo.param = tabParam;
                           profCalibInfo.equation = tabEquation;
                           profCalibInfo.coefficient = tabCoefficient;
                           profCalibInfo.comment = tabComment;
                           profCalibInfo.date = tabDate;
                           calibInfo{end+1} = profCalibInfo;
                        elseif (paramInfo.paramType == 'j')

                           tabParam = {paramName};
                           tabEquation = {'Not applicable'};
                           tabCoefficient = {'Not applicable'};
                           tabComment = {'Not applicable'};
                           if (isempty(ncCreationDate))
                              date = currentDate;
                           else
                              date = ncCreationDate;
                           end
                           tabDate = {date};

                           % store calibration information for this profile
                           profCalibInfo = [];
                           profCalibInfo.profId = idP;
                           profCalibInfo.param = tabParam;
                           profCalibInfo.equation = tabEquation;
                           profCalibInfo.coefficient = tabCoefficient;
                           profCalibInfo.comment = tabComment;
                           profCalibInfo.date = tabDate;
                           calibInfo{end+1} = profCalibInfo;
                        end
                     end
                  end
               end

               % history information
               currentHistoId = 0;
               if (~isempty(histoInstitution))
                  if (size(histoInstitution, 2) <= nbProfInFile)
                     currentHistoId = size(histoInstitution, 3);
                  end
               end
               value = 'IF';
               netcdf.putVar(fCdf, historyInstitutionVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               % modif 20250709
               % value = 'ARFM';
               % netcdf.putVar(fCdf, historyStepVarId, ...
               %    fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               % modif 20250709
               % value = 'CODA';
               value = 'COGP';
               netcdf.putVar(fCdf, historySoftwareVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               value = g_decArgo_decoderVersion;
               netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               value = currentDate;
               netcdf.putVar(fCdf, historyDateVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');

            end

            % process calibration information

            % compute the N_CALIB dimension
            nbCalib = 1;
            if (~isempty(calibInfo))
               tabCalibInfo1 = [];
               for idC = 1:length(calibInfo)
                  if (isempty(tabCalibInfo1))
                     tabCalibInfo1 = [tabCalibInfo1; calibInfo{idC}.profId calibInfo{idC}.param 1];
                  else
                     idF = find(([tabCalibInfo1{:, 1}] == calibInfo{idC}.profId)' & ...
                        strcmp(tabCalibInfo1(:, 2), calibInfo{idC}.param{:}));
                     if (isempty(idF))
                        tabCalibInfo1 = [tabCalibInfo1; calibInfo{idC}.profId calibInfo{idC}.param 1];
                     else
                        tabCalibInfo1{idF, end} = tabCalibInfo1{idF, end} + 1;
                     end
                  end
               end
               nbCalib = max([tabCalibInfo1{:, end}]);
            end

            netcdf.reDef(fCdf);

            nCalibDimId = netcdf.defDim(fCdf, 'N_CALIB', nbCalib);

            % calibration information
            parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string16DimId]));
            netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'List of parameters with calibration information');
            netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Argo reference table 3');
            netcdf.putAtt(fCdf, parameterVarId, '_FillValue', ' ');

            scientificCalibEquationVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_EQUATION', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
            netcdf.putAtt(fCdf, scientificCalibEquationVarId, 'long_name', 'Calibration equation for this parameter');
            netcdf.putAtt(fCdf, scientificCalibEquationVarId, '_FillValue', ' ');

            scientificCalibCoefficientVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
            netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, 'long_name', 'Calibration coefficients for this equation');
            netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, '_FillValue', ' ');

            scientificCalibCommentVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COMMENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
            netcdf.putAtt(fCdf, scientificCalibCommentVarId, 'long_name', 'Comment applying to this parameter calibration');
            netcdf.putAtt(fCdf, scientificCalibCommentVarId, '_FillValue', ' ');

            scientificCalibDateVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_DATE', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId dateTimeDimId]));
            netcdf.putAtt(fCdf, scientificCalibDateVarId, 'long_name', 'Date of calibration');
            netcdf.putAtt(fCdf, scientificCalibDateVarId, 'conventions', 'YYYYMMDDHHMISS');
            netcdf.putAtt(fCdf, scientificCalibDateVarId, '_FillValue', ' ');

            netcdf.endDef(fCdf);

            % fill PARAMETER variable (even if there is no RT adjustments)
            ncParamlist = repmat({''}, nbProfToStore, nbProfParam);
            for idP = 1:nbProfToStore
               prof = tabProfiles(idProfInFile(idP));
               parameterList = prof.paramList;
               profPos = idP-1+profShiftIfNoPrimary;
               paramPos = 0;
               for idParam = 1:length(parameterList)
                  if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                     valueStr = parameterList(idParam).name;

                     for idCalib = 1:nbCalib
                        netcdf.putVar(fCdf, parameterVarId, ...
                           fliplr([profPos idCalib-1 paramPos 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
                     end
                     paramPos = paramPos + 1;
                     ncParamlist(idP, paramPos) = {valueStr};
                  end
               end
            end

            tabCalibInfo2 = [];
            for idC = 1:length(calibInfo)
               profId = calibInfo{idC}.profId;
               profPos = profId-1+profShiftIfNoPrimary;
               param = calibInfo{idC}.param{:};
               idPosParam = find(strcmp(ncParamlist(profId, :), param) == 1);
               equation = calibInfo{idC}.equation{:};
               coef = calibInfo{idC}.coefficient{:};
               comment = calibInfo{idC}.comment{:};
               date = calibInfo{idC}.date{:};

               % compute start calibId
               if (isempty(tabCalibInfo2))
                  tabCalibInfo2 = [tabCalibInfo2; calibInfo{idC}.profId calibInfo{idC}.param 1];
                  idCalibStart = 1;
               else
                  idF = find(([tabCalibInfo2{:, 1}] == calibInfo{idC}.profId)' & ...
                     strcmp(tabCalibInfo2(:, 2), calibInfo{idC}.param{:}));
                  if (isempty(idF))
                     tabCalibInfo2 = [tabCalibInfo2; calibInfo{idC}.profId calibInfo{idC}.param 1];
                     idCalibStart = 1;
                  else
                     tabCalibInfo2{idF, end} = tabCalibInfo2{idF, end} + 1;
                     idCalibStart = idCalibStart + 1;
                  end
               end

               idF = find(([tabCalibInfo1{:, 1}] == profId)' & strcmp(tabCalibInfo1(:, 2), param));
               idCalibStop = idCalibStart + (nbCalib-tabCalibInfo1{idF, end});

               for id = idCalibStart:idCalibStop
                  value = param;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, parameterVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = equation;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibEquationVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = coef;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibCoefficientVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = comment;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibCommentVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = date;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibDateVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
               end
            end

            netcdf.close(fCdf);

         catch MException
            netcdf.close(fCdf);
            rethrow(MException)
         end

         if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_applyRtqc == 1))
            % store information for the XML report
            g_decArgo_reportStruct.outputMonoProfFiles = [g_decArgo_reportStruct.outputMonoProfFiles ...
               {ncPathFileName}];
         end
      end
   end
end

fprintf('... NetCDF MONO-PROFILE c files created\n');

% process Auxiliary profiles
if (~isempty(a_tabAuxProfiles))
   create_nc_mono_prof_aux_files( ...
      a_decoderId, a_tabAuxProfiles, a_metaDataFromJson, generatedProfList);
end

o_cFileInfo = generatedProfList;

return

% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE b files.
%
% SYNTAX :
%  [o_bFileInfo] = create_nc_mono_prof_b_files_3_1( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%   a_bFileToCreate    : information on B-PROF files that should be generated
%
% OUTPUT PARAMETERS :
%   o_bFileInfo : information on generated B-PROF files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bFileInfo] = create_nc_mono_prof_b_files_3_1( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson, a_bFileToCreate)

% output parameters initialization
o_bFileInfo = [];

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% configuration values
global g_decArgo_generateNcMonoProf;
global g_decArgo_applyRtqc;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% global input parameter information
global g_decArgo_processModeAll;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrMissing;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% global default values
global g_decArgo_dateDef;
global g_decArgo_qcDef;

% decoder version
global g_decArgo_decoderVersion;

% report information structure
global g_decArgo_reportStruct;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% to store information on PARAM adjustment
global g_decArgo_paramProfAdjInfo;

% max length allowed for VERTICAL_SAMPLING_SCHEME
global g_decArgo_vssMaxLength;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabProfiles))
   return
end

% remove Auxiliary profiles (they are process in create_nc_mono_prof_aux_files)
sensorNumList = [a_tabProfiles.sensorNumber];
idProfAux = find(sensorNumList > 100);
a_tabProfiles(idProfAux) = [];

% no data to save
if (isempty(a_tabProfiles))
   return
end

% check if there is at least one B file to create
bFileNeeded = 0;
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   if (~is_core_profile(profile))
      bFileNeeded = 1;
      break
   end
end
if (bFileNeeded == 0)
   return
end

% assign time resolution for each float transmission type
if (a_decoderId == 2003)
   profJulDLocRes = double(6/1440); % 6 minutes
else
   profJulDLocRes = double(1/86400); % 1 second
end
[profJulDRes, profJulDComment] = get_prof_juld_resolution(g_decArgo_floatTransType, a_decoderId);

% 03/24/2015: the GDAC checker cannot check 'empty' profiles, we will add a
% default profile with fillValue measurements

% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag]];
end

% add 'default' primary profiles
tabProfiles = a_tabProfiles;
cyNumList = unique(profInfo(:, 1));
dirList = unique(profInfo(:, 2));
for idCy = 1:length(cyNumList)
   cyNum = cyNumList(idCy);
   for idDir = 1:length(dirList)
      direction = dirList(idDir);

      if (~isempty(find( ...
            (profInfo(:, 1) == cyNum) & ...
            (profInfo(:, 2) == direction), 1)))

         idProfInFile = find( ...
            (profInfo(:, 1) == cyNum) & ...
            (profInfo(:, 2) == direction));
         idPrimary = find(profInfo(idProfInFile, 3) == 1);

         if (isempty(idPrimary))

            % create a 'default' primary b profile
            defaultPrimaryProfile = create_default_primary_profile( ...
               cyNum, direction, ...
               tabProfiles, a_decoderId);

            fprintf('DEC_INFO: Float #%d Output Cycle #%d ''%c'': no primary sampling profile - adding a ''default'' one\n', ...
               g_decArgo_floatNum, cyNum, defaultPrimaryProfile.direction);

            % add it to the profiles to process
            tabProfiles(end+1) = defaultPrimaryProfile;
         end
      end
   end
end

% collect information on profiles
profInfo = [];
for idProf = 1:length(tabProfiles)
   profile = tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag 0]];
end

generatedProfList = [];
for idProf = 1:length(tabProfiles)
   if (profInfo(idProf, 4) == 0)
      profile = tabProfiles(idProf);
      cycleNumber = profile.cycleNumber;
      profileNumber = profile.profileNumber;
      outputCycleNumber = profile.outputCycleNumber;

      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end

      % list of profiles to store in the current profile file
      idProfInFile = find( ...
         (profInfo(:, 1) == outputCycleNumber) & ...
         (profInfo(:, 2) == direction) & ...
         (profInfo(:, 4) == 0));
      profInfo(idProfInFile, 4) = 1;
      nbProfToStore = length(idProfInFile);

      % put the primary sampling profile on top of the list
      idPrimary = find(profInfo(idProfInFile, 3) == 1);
      profShiftIfNoPrimary = 0;
      if (length(idPrimary) == 1)
         idProfInFile = [idProfInFile(idPrimary); idProfInFile];
         idProfInFile(idPrimary+1) = [];
      else
         if (isempty(idPrimary))
            % should never append since 03/24/2015 (see above)
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no primary sampling profile\n', ...
               g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
            profShiftIfNoPrimary = 1;
         else
            fprintf('ERROR: Float #%d Cycle #%d Profile #%d Output Cycle #%d: multiple (%d) primary sampling profiles\n', ...
               g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, length(idPrimary));
         end
      end
      nbProfInFile = nbProfToStore + profShiftIfNoPrimary;

      % check if all the profiles to be stored are core profiles
      bFileNeeded = 0;
      for idP = 1:nbProfToStore
         prof = tabProfiles(idProfInFile(idP));
         if (~is_core_profile(prof))
            bFileNeeded = 1;
            break
         end
      end
      if (bFileNeeded == 0)
         continue
      end

      % create the profile parameters list and compute the number of levels
      % and sublevels
      profParamName = [];
      nbProfParam = 0;
      nbProfLevels = 0;
      profSubLevels = [];
      paramNameSubLevels = [];
      for idP = 1:nbProfToStore
         paramNameOfProf = [];
         prof = tabProfiles(idProfInFile(idP));
         parameterList = prof.paramList;
         profileData = prof.data;
         for idParam = 1:length(parameterList)
            if ((((parameterList(idParam).paramType ~= 'c') && (parameterList(idParam).paramType ~= 'j')) || ...
                  strcmp(parameterList(idParam).name, 'PRES')))

               profParamName = [profParamName; {parameterList(idParam).name}];
               paramNameOfProf = [paramNameOfProf; {parameterList(idParam).name}];
               nbProfLevels = max(nbProfLevels, size(profileData, 1));

               if (~isempty(prof.paramNumberWithSubLevels))
                  idF = find(prof.paramNumberWithSubLevels == idParam);
                  if (~isempty(idF))
                     profSubLevels = [profSubLevels prof.paramNumberOfSubLevels(idF)];
                     paramNameSubLevels = [paramNameSubLevels {parameterList(idParam).name}];
                  end
               end
            end
         end
         nbProfParam = max(nbProfParam, length(unique(paramNameOfProf)));
      end
      profUniqueParamName = unique(profParamName, 'stable');

      % due to erroneous received data, the number of sublevels can vary for a
      % same parameter
      paramSubLevels = unique(paramNameSubLevels, 'stable');
      dimSubLevels = [];
      for idParamSL = 1:length(paramSubLevels)
         dimSubLevels = [dimSubLevels ...
            max(profSubLevels(find(strcmp(paramNameSubLevels, paramSubLevels{idParamSL}))))];
      end
      profSubLevels = sort(unique(dimSubLevels), 'descend');

      if (nbProfParam > 0)

         % create output file pathname
         floatNumStr = num2str(g_decArgo_floatNum);
         outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end
         outputDirName = [outputDirName '/profiles/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end

         if (direction == 1)
            ncFileName = sprintf('BR%d_%03dD.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         else
            ncFileName = sprintf('BR%d_%03d.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         end
         ncPathFileName = [outputDirName  ncFileName];

         % check if the file need to be created
         generate = 1;
         if (g_decArgo_floatTransType == 1)

            % Argos floats

            if (g_decArgo_generateNcMonoProf == 2)

               if ((g_decArgo_realtimeFlag == 1) && (g_decArgo_processModeAll == 0))

                  % in this configuration, only new profile files are created
                  % (never updated)
                  if (exist(ncPathFileName, 'file') == 2)
                     generate = 0;
                  end
               end
            end

         elseif ((g_decArgo_floatTransType == 2) || ...
               (g_decArgo_floatTransType == 4))

            % Iridium RUDICS floats
            % Iridium SBD ProvBioII floats

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  % - it exists but the profile structure has been updated
                  if ((exist(ncPathFileName, 'file') == 2) && ...
                        (isempty(find([tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               elseif (g_decArgo_delayedModeFlag == 1)

                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  if (exist(ncPathFileName, 'file') == 2)
                     generate = 0;
                  end
               end
            end

         elseif (g_decArgo_floatTransType == 3)

            % Iridium SBD floats

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  % - it exists but the profile structure has been updated
                  if ((exist(ncPathFileName, 'file') == 2) && ...
                        (isempty(find([tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               end
            end

         else

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no strategy to generate or not profile NetCDF files - generating all profile fles\n', ...
                     g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
               end
            end
         end

         % some files should be generated from input parameter list
         if (generate == 0)
            if (~isempty(a_bFileToCreate))
               if (any((a_bFileToCreate(:, 1) == outputCycleNumber) & (a_bFileToCreate(:, 2) == direction)))
                  generate = 1;
               end
            end
         end

         % some profile positions may have been updated
         if (generate == 0)
            if (exist(ncPathFileName, 'file') == 2)

               % retrieve profile location of the nc file
               [ncJuldLoc, ncLat, ncLon, ncPosQc, ncPosSystem] = get_nc_profile_location(ncPathFileName);

               if (length(ncJuldLoc) == nbProfToStore + profShiftIfNoPrimary)

                  for idP = 1:nbProfToStore

                     % get nc profile location
                     profPos = idP+profShiftIfNoPrimary;
                     if (profPos <= length(ncJuldLoc))
                        juldLoc = ncJuldLoc(profPos);
                        latitude = ncLat(profPos);
                        longitude = ncLon(profPos);
                        positionQc = ncPosQc(profPos);
                        positioningSystem = ncPosSystem{profPos};

                        ncProfLocStr = sprintf('%s %.3f %.3f %s', ...
                           julian_2_gregorian_dec_argo(juldLoc), ...
                           latitude, longitude, positioningSystem);

                        % compare profile location
                        prof = tabProfiles(idProfInFile(idP));
                        profLocStr = sprintf('%s %.3f %.3f %s', ...
                           julian_2_gregorian_dec_argo(prof.locationDate), ...
                           prof.locationLat, prof.locationLon, prof.posSystem);

                        if ((((positionQc == '9') && (prof.locationQc ~= ' ')) || ...
                              ((positionQc == '8') && (prof.locationQc ~= '8')) || ...
                              ((positionQc ~= '8') && (prof.locationQc == '8'))))
                           generate = 1;
                           break
                        elseif ((positionQc ~= '9') && (prof.locationQc ~= ' ') && ...
                              ~strcmp(profLocStr, ncProfLocStr))
                           generate = 1;
                           break
                        end
                     end
                  end
               else
                  generate = 1;
               end
            end
         end

         % 1 - the data of one cycle can be in consecutive rsync log files
         % to check if the file need to be created we should then compare profile
         % levels
         % 2 - a new RT adjustment has been set we should compared profile
         % levels of adjusted data
         if (generate == 0)
            if ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_realtimeFlag == 1))
               if (exist(ncPathFileName, 'file') == 2)

                  % retrieve profile levels of the nc file
                  ncProfLev = get_nc_profile_level(ncPathFileName);

                  % compare profile levels
                  differ = 0;

                  for idP = 1:nbProfToStore
                     prof = tabProfiles(idProfInFile(idP));
                     profPos = idP-1+profShiftIfNoPrimary;

                     % profile parameter data
                     parameterList = prof.paramList;
                     for idLoop = 1:2
                        nLevelsParam = 0;
                        idNoDefAll = [];
                        for idParam = 1:length(parameterList)
                           if (((parameterList(idParam).paramType ~= 'c') && (parameterList(idParam).paramType ~= 'j')) || ...
                                 strcmp(parameterList(idParam).name, 'PRES'))
                              if ~(strcmp(parameterList(idParam).name, 'PRES') && (idLoop == 2)) % PRES_ADJUSTED is not in B-PROF
                                 profParam = parameterList(idParam);
                                 profParamName = profParam.name;
                                 paramInfo = get_netcdf_param_attributes(profParamName);
                                 if (idLoop == 1)
                                    profData = prof.data;
                                 else
                                    profData = prof.dataAdj;
                                 end
                                 % prof.data is empty in 'default' primary profiles
                                 if (~isempty(profData))
                                    % parameter data
                                    if (isempty(prof.paramNumberWithSubLevels))
                                       % none of the profile parameters has sublevels
                                       paramData = profData(:, idParam);
                                       idNoDef = find(paramData ~= paramInfo.fillValue);
                                       idNoDefAll = [idNoDefAll idNoDef'];
                                    else
                                       % some profile parameters have sublevels
                                       % retrieve the column(s) associated with the parameter data
                                       idF = find(prof.paramNumberWithSubLevels < idParam);
                                       if (isempty(idF))
                                          firstCol = idParam;
                                       else
                                          firstCol = idParam + sum(prof.paramNumberOfSubLevels(idF)) - length(idF);
                                       end

                                       idF = find(prof.paramNumberWithSubLevels == idParam);
                                       if (isempty(idF))
                                          lastCol = firstCol;
                                       else
                                          lastCol = firstCol + prof.paramNumberOfSubLevels(idF) - 1;
                                       end

                                       paramData = profData(:, firstCol:lastCol);
                                       if (size(paramData, 2) == 1)
                                          idNoDef = find(paramData ~= paramInfo.fillValue);
                                          idNoDefAll = [idNoDefAll idNoDef'];
                                       else
                                          idNoDef = [];
                                          for id = 1:size(paramData, 1)
                                             if (any(paramData(id, :) ~= paramInfo.fillValue))
                                                idNoDef = [idNoDef id];
                                             end
                                          end
                                          idNoDefAll = [idNoDefAll idNoDef];
                                       end
                                    end
                                 end
                              end
                           end
                        end
                        if (~isempty(idNoDefAll))
                           nLevelsParam = max(idNoDefAll) - min(idNoDefAll) + 1;
                        end
                        if (idLoop == 1)
                           ncProfLevRef = ncProfLev(1, profPos+1);
                        else
                           ncProfLevRef = ncProfLev(2, profPos+1);
                        end
                        if (nLevelsParam ~= ncProfLevRef)
                           differ = 1;
                           break
                        end
                     end
                     if (differ == 1)
                        break
                     end
                  end
                  if (differ == 1)
                     generate = 1;
                  end

                  if (generate == 0)
                     if ((a_decoderId > 2000) && (a_decoderId < 3000))

                        % NOVA/DOVA float
                        % the clock offset is not defined for the last cycle
                        % (needed information for cycle N is transmitted during
                        % cycle N+1) => profile JULD (and JULD_LOCATION since
                        % it is in float time) can be adjusted during the
                        % following cycles
                        % => the file should be updated if it was the last one
                        % of the previous run and we received a new one

                        fileCycleNum = [];
                        floatFiles = [dir([outputDirName '/' sprintf('BR%d_*.nc', g_decArgo_floatNum)]); ...
                           dir([outputDirName '/' sprintf('BD%d_*.nc', g_decArgo_floatNum)])];
                        for idFile = 1:length(floatFiles)
                           floatFileName = floatFiles(idFile).name;
                           idFUs = strfind(floatFileName, '_');
                           fileCycleNum = [fileCycleNum str2num(floatFileName(idFUs+1:idFUs+3))];
                        end

                        if (~isempty(fileCycleNum))
                           if ((outputCycleNumber == max(fileCycleNum)) && ...
                                 (any(profInfo(:, 1) == outputCycleNumber+1)))
                              generate = 1;
                           end
                        end
                     end
                  end
               end
            end
         end

         % the RT adjustment coefficients have been modified
         if (generate == 0)
            if ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_realtimeFlag == 1))
               if (exist(ncPathFileName, 'file') == 2)

                  % retrieve RT adjustment information
                  sciCalibInfo = get_nc_profile_sci_calib_info(ncPathFileName);

                  % compare RT adjustment coefficients
                  differ = 0;
                  for idP = 1:nbProfToStore

                     prof = tabProfiles(idProfInFile(idP));

                     % check misc adjustment information (from data base)
                     if (~isempty(prof.rtParamAdjIdList))
                        for idProfAdj = prof.rtParamAdjIdList

                           % retrieve information on PARAM adjustment
                           idF = find([g_decArgo_paramProfAdjInfo{:, 1}] == idProfAdj);
                           paramAdjInfo = g_decArgo_paramProfAdjInfo(idF, :);
                           paramName = paramAdjInfo{4};
                           % we cannot apply the same rule to CHLA parameter
                           % because it is adjusted during the RTQC process,
                           % thus the adjustment coefficients are not available
                           % yet
                           if (~strcmp(paramName, 'CHLA'))
                              paramInfo = get_netcdf_param_attributes(paramName);
                              if ((paramInfo.paramType ~= 'c') && (paramInfo.paramType ~= 'j'))
                                 paramCoefficient = paramAdjInfo{6};

                                 paramAdjList = find(strcmp(paramName, sciCalibInfo(:, 4)));
                                 found = 0;
                                 for idAdj = 1:length(paramAdjList)
                                    if (strcmp(paramCoefficient, sciCalibInfo(paramAdjList(idAdj), 6)))
                                       found = 1;
                                       break
                                    end
                                 end
                                 if (~found)
                                    differ = 1;
                                    break
                                 end
                              end
                           end
                        end
                        if (differ == 1)
                           break
                        end
                     end
                  end
                  if (differ == 1)
                     generate = 1;
                  end
               end
            end
         end

         if (generate == 0)
            continue
         end

         generatedProfList = [generatedProfList; outputCycleNumber direction];

         % information to retrieve from a possible existing mono-profile file
         ncCreationDate = '';
         histoInstitution = '';
         histoStep = '';
         histoSoftware = '';
         histoSoftwareRelease = '';
         histoDate = '';

         if (exist(ncPathFileName, 'file') == 2)

            % retrieve information from existing file
            wantedProfVars = [ ...
               {'DATE_CREATION'} ...
               {'HISTORY_INSTITUTION'} ...
               {'HISTORY_STEP'} ...
               {'HISTORY_SOFTWARE'} ...
               {'HISTORY_SOFTWARE_RELEASE'} ...
               {'HISTORY_DATE'} ...
               ];

            % retrieve information from PROF netCDF file
            [profData] = get_data_from_nc_file(ncPathFileName, wantedProfVars);

            idVal = find(strcmp('DATE_CREATION', profData) == 1);
            if (~isempty(idVal))
               ncCreationDate = profData{idVal+1}';
            end
            idVal = find(strcmp('HISTORY_INSTITUTION', profData) == 1);
            if (~isempty(idVal))
               histoInstitution = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_STEP', profData) == 1);
            if (~isempty(idVal))
               histoStep = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_SOFTWARE', profData) == 1);
            if (~isempty(idVal))
               histoSoftware = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_SOFTWARE_RELEASE', profData) == 1);
            if (~isempty(idVal))
               histoSoftwareRelease = profData{idVal+1};
            end
            idVal = find(strcmp('HISTORY_DATE', profData) == 1);
            if (~isempty(idVal))
               histoDate = profData{idVal+1};
            end

            if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
               fprintf('Updating NetCDF MONO-PROFILE b file (%s) ...\n', ncFileName);
            end

         else
            if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
               fprintf('Creating NetCDF MONO-PROFILE b file (%s) ...\n', ncFileName);
            end
         end

         if (g_decArgo_floatTransType == 1)

            % Argos floats

            if (g_decArgo_generateNcMonoProf == 2)
               if (~isempty(profile.profileCompleted) && (profile.profileCompleted > 0))
                  fprintf('INFO: Float #%d cycle #%d: missing levels in transmitted profile (%d levels are missing)\n', ...
                     g_decArgo_floatNum, outputCycleNumber, profile.profileCompleted);
               end
            end
         end

         currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

         % create and open NetCDF file
         fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
         if (isempty(fCdf))
            fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
            return
         end

         try

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % DEFINE MODE BEGIN
            if (VERBOSE_MODE == 2)
               fprintf('START DEFINE MODE\n');
               fprintf('float cycle # = %d\n', cycleNumber);
               fprintf('float profile # = %d\n', profileNumber);
               fprintf('output cycle # = %d\n', outputCycleNumber);
            end

            % create dimensions
            dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
            string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
            string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
            paramNameLength = 64;
            string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
            string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
            string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
            string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
            string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

            nProfDimId = netcdf.defDim(fCdf, 'N_PROF', nbProfInFile);
            nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbProfParam);
            nLevelsDimId = netcdf.defDim(fCdf, 'N_LEVELS', nbProfLevels);
            for idSL = 1:length(profSubLevels)
               netcdf.defDim(fCdf, sprintf('N_VALUES%d', profSubLevels(idSL)), profSubLevels(idSL));
            end
            % N_CALIB dimension is processed and created later
            nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', netcdf.getConstant('NC_UNLIMITED'));

            if (VERBOSE_MODE == 2)
               fprintf('N_PROF = %d\n', nbProfInFile);
               fprintf('N_PARAM = %d\n', nbProfParam);
               fprintf('N_LEVELS = %d\n', nbProfLevels);
               for idSL = 1:length(profSubLevels)
                  fprintf('N_SUBLEVELS%d = %d\n', profSubLevels(idSL), profSubLevels(idSL));
               end
            end

            % create global attributes
            globalVarId = netcdf.getConstant('NC_GLOBAL');
            netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
            institution = 'CORIOLIS';
            idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               dataCentre = char(a_metaDataFromJson{idVal+1});
               [institution] = get_institution_from_data_centre(dataCentre, 1);
            end
            netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
            netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
            if (isempty(ncCreationDate))
               globalHistoryText = [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
            else
               globalHistoryText = [datestr(datenum(ncCreationDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
            end
            % modif 20250709
            % globalHistoryText = [globalHistoryText ...
            %    datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis float real time data processing)'];
            netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
            netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
            netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.1');
            netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
            netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');
            % modif 20250709
            % netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));
            netcdf.putAtt(fCdf, globalVarId, 'id', 'https://doi.org/10.17882/42182');

            % create misc variables
            dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string32DimId);
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

            % create profile variables
            platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
            netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
            netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
            netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');

            projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Name of the project');
            netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');

            piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
            netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');

            stationParametersVarId = netcdf.defVar(fCdf, 'STATION_PARAMETERS', 'NC_CHAR', fliplr([nProfDimId nParamDimId string64DimId]));
            netcdf.putAtt(fCdf, stationParametersVarId, 'long_name', 'List of available parameters for the station');
            netcdf.putAtt(fCdf, stationParametersVarId, 'conventions', 'Argo reference table 3');
            netcdf.putAtt(fCdf, stationParametersVarId, '_FillValue', ' ');

            cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nProfDimId);
            netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number');
            netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle (if exists), 1 : first complete cycle');
            netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));

            directionVarId = netcdf.defVar(fCdf, 'DIRECTION', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, directionVarId, 'long_name', 'Direction of the station profiles');
            netcdf.putAtt(fCdf, directionVarId, 'conventions', 'A: ascending profiles, D: descending profiles');
            netcdf.putAtt(fCdf, directionVarId, '_FillValue', ' ');

            dataCenterVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', fliplr([nProfDimId string2DimId]));
            netcdf.putAtt(fCdf, dataCenterVarId, 'long_name', 'Data centre in charge of float data processing');
            netcdf.putAtt(fCdf, dataCenterVarId, 'conventions', 'Argo reference table 4');
            netcdf.putAtt(fCdf, dataCenterVarId, '_FillValue', ' ');

            dcReferenceVarId = netcdf.defVar(fCdf, 'DC_REFERENCE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, dcReferenceVarId, 'long_name', 'Station unique identifier in data centre');
            netcdf.putAtt(fCdf, dcReferenceVarId, 'conventions', 'Data centre convention');
            netcdf.putAtt(fCdf, dcReferenceVarId, '_FillValue', ' ');

            dataStateIndicatorVarId = netcdf.defVar(fCdf, 'DATA_STATE_INDICATOR', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'long_name', 'Degree of processing the data have passed through');
            netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'conventions', 'Argo reference table 6');
            netcdf.putAtt(fCdf, dataStateIndicatorVarId, '_FillValue', ' ');

            dataModeVarId = netcdf.defVar(fCdf, 'DATA_MODE', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, dataModeVarId, 'long_name', 'Delayed mode or real time data');
            netcdf.putAtt(fCdf, dataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
            netcdf.putAtt(fCdf, dataModeVarId, '_FillValue', ' ');

            parameterDataModeVarId = netcdf.defVar(fCdf, 'PARAMETER_DATA_MODE', 'NC_CHAR', fliplr([nProfDimId nParamDimId]));
            netcdf.putAtt(fCdf, parameterDataModeVarId, 'long_name', 'Delayed mode or real time data');
            netcdf.putAtt(fCdf, parameterDataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
            netcdf.putAtt(fCdf, parameterDataModeVarId, '_FillValue', ' ');

            platformTypeVarId = netcdf.defVar(fCdf, 'PLATFORM_TYPE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, platformTypeVarId, 'long_name', 'Type of float');
            netcdf.putAtt(fCdf, platformTypeVarId, 'conventions', 'Argo reference table 23');
            netcdf.putAtt(fCdf, platformTypeVarId, '_FillValue', ' ');

            floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
            netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');

            firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
            netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Instrument firmware version');
            netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');

            wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
            netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
            netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');

            juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of the station relative to REFERENCE_DATE_TIME');
            netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
            netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
            netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
            netcdf.putAtt(fCdf, juldVarId, 'resolution', profJulDRes);
            netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
            netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');
            if (~isempty(profJulDComment))
               netcdf.putAtt(fCdf, juldVarId, 'comment_on_resolution', profJulDComment);
            end

            juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
            netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
            netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');

            juldLocationVarId = netcdf.defVar(fCdf, 'JULD_LOCATION', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, juldLocationVarId, 'long_name', 'Julian day (UTC) of the location relative to REFERENCE_DATE_TIME');
            netcdf.putAtt(fCdf, juldLocationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
            netcdf.putAtt(fCdf, juldLocationVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
            netcdf.putAtt(fCdf, juldLocationVarId, 'resolution', profJulDLocRes);
            netcdf.putAtt(fCdf, juldLocationVarId, '_FillValue', double(999999));

            latitudeVarId = netcdf.defVar(fCdf, 'LATITUDE', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, latitudeVarId, 'long_name', 'Latitude of the station, best estimate');
            netcdf.putAtt(fCdf, latitudeVarId, 'standard_name', 'latitude');
            netcdf.putAtt(fCdf, latitudeVarId, 'units', 'degree_north');
            netcdf.putAtt(fCdf, latitudeVarId, '_FillValue', double(99999));
            netcdf.putAtt(fCdf, latitudeVarId, 'valid_min', double(-90));
            netcdf.putAtt(fCdf, latitudeVarId, 'valid_max', double(90));
            netcdf.putAtt(fCdf, latitudeVarId, 'axis', 'Y');

            longitudeVarId = netcdf.defVar(fCdf, 'LONGITUDE', 'NC_DOUBLE', nProfDimId);
            netcdf.putAtt(fCdf, longitudeVarId, 'long_name', 'Longitude of the station, best estimate');
            netcdf.putAtt(fCdf, longitudeVarId, 'standard_name', 'longitude');
            netcdf.putAtt(fCdf, longitudeVarId, 'units', 'degree_east');
            netcdf.putAtt(fCdf, longitudeVarId, '_FillValue', double(99999));
            netcdf.putAtt(fCdf, longitudeVarId, 'valid_min', double(-180));
            netcdf.putAtt(fCdf, longitudeVarId, 'valid_max', double(180));
            netcdf.putAtt(fCdf, longitudeVarId, 'axis', 'X');

            positionQcVarId = netcdf.defVar(fCdf, 'POSITION_QC', 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, positionQcVarId, 'long_name', 'Quality on position (latitude and longitude)');
            netcdf.putAtt(fCdf, positionQcVarId, 'conventions', 'Argo reference table 2');
            netcdf.putAtt(fCdf, positionQcVarId, '_FillValue', ' ');

            positioningSystemVarId = netcdf.defVar(fCdf, 'POSITIONING_SYSTEM', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
            netcdf.putAtt(fCdf, positioningSystemVarId, 'long_name', 'Positioning system');
            netcdf.putAtt(fCdf, positioningSystemVarId, '_FillValue', ' ');

            % global quality of PARAM profile
            for idParam = 1:length(profUniqueParamName)
               profParamName = profUniqueParamName{idParam};
               if (~strcmp(profParamName, 'PRES'))
                  ncParamName = sprintf('PROFILE_%s_QC', profParamName);

                  profileParamQcVarId = netcdf.defVar(fCdf, ncParamName, 'NC_CHAR', nProfDimId);
                  netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', profParamName));
                  netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
                  netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
               end
            end

            verticalSamplingSchemeVarId = netcdf.defVar(fCdf, 'VERTICAL_SAMPLING_SCHEME', 'NC_CHAR', fliplr([nProfDimId string256DimId]));
            netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'long_name', 'Vertical sampling scheme');
            netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'conventions', 'Argo reference table 16');
            netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, '_FillValue', ' ');

            configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nProfDimId);
            netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
            netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
            netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));

            % add profile data
            calibInfo = [];
            doubleTypeInFile = 0;
            for idP = 1:nbProfToStore

               prof = tabProfiles(idProfInFile(idP));

               % profile parameter data
               parameterList = prof.paramList;
               for idParam = 1:length(parameterList)

                  if (((parameterList(idParam).paramType ~= 'c') && (parameterList(idParam).paramType ~= 'j')) || ...
                        strcmp(parameterList(idParam).name, 'PRES'))

                     profParam = parameterList(idParam);
                     profParamName = profParam.name;
                     profParamNcType = profParam.paramNcType;

                     % find if this parameter has sublevels
                     paramWithSubLevels = 0;
                     if (~isempty(prof.paramNumberWithSubLevels))
                        idF = find(prof.paramNumberWithSubLevels == idParam);
                        if (~isempty(idF))
                           paramWithSubLevels = 1;
                           paramSubLevelsDim = dimSubLevels(find(strcmp(profParamName, paramSubLevels), 1));
                           %                            nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', prof.paramNumberOfSubLevels(idF)));
                           nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', paramSubLevelsDim));
                        end
                     end

                     % parameter variable and attributes
                     if (~var_is_present_dec_argo(fCdf, profParamName))

                        if (strcmp(profParamNcType, 'NC_DOUBLE'))
                           doubleTypeInFile = 1;
                        end
                        if (paramWithSubLevels == 0)
                           profParamVarId = netcdf.defVar(fCdf, profParamName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));
                        else
                           profParamVarId = netcdf.defVar(fCdf, profParamName, profParamNcType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
                        end

                        if (~isempty(profParam.longName))
                           netcdf.putAtt(fCdf, profParamVarId, 'long_name', profParam.longName);
                        end
                        if (~isempty(profParam.standardName))
                           netcdf.putAtt(fCdf, profParamVarId, 'standard_name', profParam.standardName);
                        end
                        if (~isempty(profParam.fillValue))
                           netcdf.putAtt(fCdf, profParamVarId, '_FillValue', profParam.fillValue);
                        end
                        if (~isempty(profParam.units))
                           netcdf.putAtt(fCdf, profParamVarId, 'units', profParam.units);
                        end
                        if (~isempty(profParam.validMin))
                           netcdf.putAtt(fCdf, profParamVarId, 'valid_min', profParam.validMin);
                        end
                        if (~isempty(profParam.validMax))
                           netcdf.putAtt(fCdf, profParamVarId, 'valid_max', profParam.validMax);
                        end
                        if (~isempty(profParam.cFormat))
                           netcdf.putAtt(fCdf, profParamVarId, 'C_format', profParam.cFormat);
                        end
                        if (~isempty(profParam.fortranFormat))
                           netcdf.putAtt(fCdf, profParamVarId, 'FORTRAN_format', profParam.fortranFormat);
                        end
                        if (~isempty(profParam.resolution))
                           netcdf.putAtt(fCdf, profParamVarId, 'resolution', profParam.resolution);
                        end
                        if (~isempty(profParam.axis))
                           netcdf.putAtt(fCdf, profParamVarId, 'axis', profParam.axis);
                        end
                     end

                     % parameter QC variable and attributes
                     if ((profParam.paramType ~= 'c') && (profParam.paramType ~= 'j'))

                        profParamQcName = sprintf('%s_QC', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamQcName))

                           profParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));

                           netcdf.putAtt(fCdf, profParamQcVarId, 'long_name', 'quality flag');
                           netcdf.putAtt(fCdf, profParamQcVarId, 'conventions', 'Argo reference table 2');
                           netcdf.putAtt(fCdf, profParamQcVarId, '_FillValue', ' ');
                        end
                     end

                     % parameter adjusted variable and attributes
                     if ((profParam.adjAllowed == 1) && (profParam.paramType ~= 'c') && (profParam.paramType ~= 'j'))

                        profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamAdjName))

                           if (paramWithSubLevels == 0)
                              profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));
                           else
                              profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, profParamNcType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
                           end

                           if (~isempty(profParam.longName))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'long_name', profParam.longName);
                           end
                           if (~isempty(profParam.standardName))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'standard_name', profParam.standardName);
                           end
                           if (~isempty(profParam.fillValue))
                              netcdf.putAtt(fCdf, profParamAdjVarId, '_FillValue', profParam.fillValue);
                           end
                           if (~isempty(profParam.units))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'units', profParam.units);
                           end
                           if (~isempty(profParam.validMin))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_min', profParam.validMin);
                           end
                           if (~isempty(profParam.validMax))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_max', profParam.validMax);
                           end
                           if (~isempty(profParam.cFormat))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'C_format', profParam.cFormat);
                           end
                           if (~isempty(profParam.fortranFormat))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'FORTRAN_format', profParam.fortranFormat);
                           end
                           if (~isempty(profParam.resolution))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'resolution', profParam.resolution);
                           end
                           if (~isempty(profParam.axis))
                              netcdf.putAtt(fCdf, profParamAdjVarId, 'axis', profParam.axis);
                           end
                        end

                        % parameter adjusted QC variable and attributes
                        profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamAdjQcName))

                           profParamAdjQcVarId = netcdf.defVar(fCdf, profParamAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));

                           netcdf.putAtt(fCdf, profParamAdjQcVarId, 'long_name', 'quality flag');
                           netcdf.putAtt(fCdf, profParamAdjQcVarId, 'conventions', 'Argo reference table 2');
                           netcdf.putAtt(fCdf, profParamAdjQcVarId, '_FillValue', ' ');
                        end

                        % parameter adjusted error variable and attributes
                        profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
                        if (~var_is_present_dec_argo(fCdf, profParamAdjErrName))

                           if (paramWithSubLevels == 0)
                              profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));
                           else
                              profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, profParamNcType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
                           end

                           netcdf.putAtt(fCdf, profParamAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
                           if (~isempty(profParam.fillValue))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, '_FillValue', profParam.fillValue);
                           end
                           if (~isempty(profParam.units))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'units', profParam.units);
                           end
                           if (~isempty(profParam.cFormat))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'C_format', profParam.cFormat);
                           end
                           if (~isempty(profParam.fortranFormat))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'FORTRAN_format', profParam.fortranFormat);
                           end
                           if (~isempty(profParam.resolution))
                              netcdf.putAtt(fCdf, profParamAdjErrVarId, 'resolution', profParam.resolution);
                           end
                        end
                     end
                  end
               end
            end

            % history information
            historyInstitutionVarId = netcdf.defVar(fCdf, 'HISTORY_INSTITUTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historyInstitutionVarId, 'long_name', 'Institution which performed action');
            netcdf.putAtt(fCdf, historyInstitutionVarId, 'conventions', 'Argo reference table 4');
            netcdf.putAtt(fCdf, historyInstitutionVarId, '_FillValue', ' ');

            historyStepVarId = netcdf.defVar(fCdf, 'HISTORY_STEP', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historyStepVarId, 'long_name', 'Step in data processing');
            netcdf.putAtt(fCdf, historyStepVarId, 'conventions', 'Argo reference table 12');
            netcdf.putAtt(fCdf, historyStepVarId, '_FillValue', ' ');

            historySoftwareVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historySoftwareVarId, 'long_name', 'Name of software which performed action');
            netcdf.putAtt(fCdf, historySoftwareVarId, 'conventions', 'Institution dependent');
            netcdf.putAtt(fCdf, historySoftwareVarId, '_FillValue', ' ');

            historySoftwareReleaseVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE_RELEASE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'long_name', 'Version/release of software which performed action');
            netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'conventions', 'Institution dependent');
            netcdf.putAtt(fCdf, historySoftwareReleaseVarId, '_FillValue', ' ');

            historyReferenceVarId = netcdf.defVar(fCdf, 'HISTORY_REFERENCE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, historyReferenceVarId, 'long_name', 'Reference of database');
            netcdf.putAtt(fCdf, historyReferenceVarId, 'conventions', 'Institution dependent');
            netcdf.putAtt(fCdf, historyReferenceVarId, '_FillValue', ' ');

            historyDateVarId = netcdf.defVar(fCdf, 'HISTORY_DATE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId dateTimeDimId]));
            netcdf.putAtt(fCdf, historyDateVarId, 'long_name', 'Date the history record was created');
            netcdf.putAtt(fCdf, historyDateVarId, 'conventions', 'YYYYMMDDHHMISS');
            netcdf.putAtt(fCdf, historyDateVarId, '_FillValue', ' ');

            historyActionVarId = netcdf.defVar(fCdf, 'HISTORY_ACTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
            netcdf.putAtt(fCdf, historyActionVarId, 'long_name', 'Action performed on data');
            netcdf.putAtt(fCdf, historyActionVarId, 'conventions', 'Argo reference table 7');
            netcdf.putAtt(fCdf, historyActionVarId, '_FillValue', ' ');

            historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string64DimId]));
            netcdf.putAtt(fCdf, historyParameterVarId, 'long_name', 'Station parameter action is performed on');
            netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Argo reference table 3');
            netcdf.putAtt(fCdf, historyParameterVarId, '_FillValue', ' ');

            historyStartPresVarId = netcdf.defVar(fCdf, 'HISTORY_START_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
            netcdf.putAtt(fCdf, historyStartPresVarId, 'long_name', 'Start pressure action applied on');
            netcdf.putAtt(fCdf, historyStartPresVarId, '_FillValue', single(99999));
            netcdf.putAtt(fCdf, historyStartPresVarId, 'units', 'decibar');

            historyStopPresVarId = netcdf.defVar(fCdf, 'HISTORY_STOP_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
            netcdf.putAtt(fCdf, historyStopPresVarId, 'long_name', 'Stop pressure action applied on');
            netcdf.putAtt(fCdf, historyStopPresVarId, '_FillValue', single(99999));
            netcdf.putAtt(fCdf, historyStopPresVarId, 'units', 'decibar');

            if (doubleTypeInFile == 0)
               historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
               netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
               netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));
            else
               historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_DOUBLE', fliplr([nHistoryDimId nProfDimId]));
               netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
               netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', double(99999));
            end

            historyQcTestVarId = netcdf.defVar(fCdf, 'HISTORY_QCTEST', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
            netcdf.putAtt(fCdf, historyQcTestVarId, 'long_name', 'Documentation of tests performed, tests failed (in hex form)');
            netcdf.putAtt(fCdf, historyQcTestVarId, 'conventions', 'Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
            netcdf.putAtt(fCdf, historyQcTestVarId, '_FillValue', ' ');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % DEFINE MODE END
            if (VERBOSE_MODE == 2)
               fprintf('STOP DEFINE MODE\n');
            end

            netcdf.endDef(fCdf);

            valueStr = 'B-Argo profile';
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

            % create profile variables

            for idP = 1:nbProfToStore
               prof = tabProfiles(idProfInFile(idP));

               profPos = idP-1+profShiftIfNoPrimary;

               valueStr = sprintf('%d', g_decArgo_floatNum);
               netcdf.putVar(fCdf, platformNumberVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = ' ';
               idVal = find(strcmp('PROJECT_NAME', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               netcdf.putVar(fCdf, projectNameVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = ' ';
               idVal = find(strcmp('PI_NAME', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               netcdf.putVar(fCdf, piNameVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               netcdf.putVar(fCdf, dataModeVarId, profPos, 1, 'R');

               parameterList = prof.paramList;
               parameterDataMode = prof.paramDataMode;
               paramPos = 0;
               for idParam = 1:length(parameterList)

                  if ((((parameterList(idParam).paramType ~= 'c') && (parameterList(idParam).paramType ~= 'j')) || ...
                        strcmp(parameterList(idParam).name, 'PRES')))

                     valueStr = parameterList(idParam).name;

                     if (length(valueStr) > paramNameLength)
                        fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) - name truncated\n', ...
                           g_decArgo_floatNum, valueStr, paramNameLength);
                        valueStr = valueStr(1:paramNameLength);
                     end

                     netcdf.putVar(fCdf, stationParametersVarId, ...
                        fliplr([profPos paramPos 0]), fliplr([1 1 length(valueStr)]), valueStr');

                     if (isempty(parameterDataMode))
                        netcdf.putVar(fCdf, parameterDataModeVarId, fliplr([profPos paramPos]), fliplr([1 1]), 'R');
                     elseif ((parameterDataMode(idParam) == 'A') && (~strcmp(parameterList(idParam).name, 'PRES')))
                        netcdf.putVar(fCdf, parameterDataModeVarId, fliplr([profPos paramPos]), fliplr([1 1]), 'A');
                        netcdf.putVar(fCdf, dataModeVarId, profPos, 1, 'A');
                     else
                        netcdf.putVar(fCdf, parameterDataModeVarId, fliplr([profPos paramPos]), fliplr([1 1]), 'R');
                     end

                     paramPos = paramPos + 1;
                  end
               end

               netcdf.putVar(fCdf, cycleNumberVarId, profPos, 1, outputCycleNumber);

               valueStr = ' ';
               idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               netcdf.putVar(fCdf, dataCenterVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = ' ';
               idVal = find(strcmp('DC_REFERENCE', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               valueStr = [valueStr blanks(32-length(valueStr))];
               tabValue = repmat(valueStr, nbProfToStore, 1);
               netcdf.putVar(fCdf, dcReferenceVarId, ...
                  fliplr([profShiftIfNoPrimary 0]), ...
                  fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

               valueStr = '1A';
               idVal = find(strcmp('DATA_STATE_INDICATOR', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               netcdf.putVar(fCdf, dataStateIndicatorVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = get_platform_type(a_decoderId);
               netcdf.putVar(fCdf, platformTypeVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = ' ';
               idVal = find(strcmp('FLOAT_SERIAL_NO', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               netcdf.putVar(fCdf, floatSerialNoVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = ' ';
               idVal = find(strcmp('FIRMWARE_VERSION', a_metaDataFromJson) == 1);
               if (~isempty(idVal))
                  valueStr = char(a_metaDataFromJson{idVal+1});
               end
               netcdf.putVar(fCdf, firmwareVersionVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');

               valueStr = get_wmo_instrument_type(a_decoderId);
               netcdf.putVar(fCdf, wmoInstTypeVarId, ...
                  fliplr([profPos 0]), ...
                  fliplr([1 length(valueStr)]), valueStr');
            end

            % copy existing history information
            if (~isempty(histoInstitution))
               if (size(histoInstitution, 2) <= nbProfInFile)
                  netcdf.putVar(fCdf, historyInstitutionVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoInstitution, 3) size(histoInstitution, 2) size(histoInstitution, 1)]), histoInstitution);
                  netcdf.putVar(fCdf, historyStepVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoStep, 3) size(histoStep, 2) size(histoStep, 1)]), histoStep);
                  netcdf.putVar(fCdf, historySoftwareVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoSoftware, 3) size(histoSoftware, 2) size(histoSoftware, 1)]), histoSoftware);
                  netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoSoftwareRelease, 3) size(histoSoftwareRelease, 2) size(histoSoftwareRelease, 1)]), histoSoftwareRelease);
                  netcdf.putVar(fCdf, historyDateVarId, ...
                     fliplr([0 0 0]), fliplr([size(histoDate, 3) size(histoDate, 2) size(histoDate, 1)]), histoDate);
               else
                  fprintf('WARNING: Float #%d : N_PROF=%d in existing file, N_PROF=%d in updated file - history information not copied when updating file %s\n', ...
                     g_decArgo_floatNum, size(histoInstitution, 2), nbProfInFile, ncPathFileName);
               end
            end

            % CONCERNING RT ADJUSTMENT
            % there are 2 kinds of RT adjustments that are managed by the decoder:
            % 1- adjustments performed during the decoding process
            % 2- adjustments stored in the DB (stored in the meta.json files)
            % Concerning adjustments performed during the decoding process:
            % - the PRES RT adjustment of Apex floats should not be involve other
            % derived parameters (see "Minutes of the 6th BGC-Argo meeting 27, 28
            % November 2017, Hamburg")
            % - some parameters (CHLA, NITRATE, ...) may have their own RT
            % adjustment
            % Concerning adjustments stored in the DB:
            % - there is no reprocessing of associated derived parameters (i.e. for
            % example if PSAL should be adjusted, associated DOXY data is not
            % reprocessed to DOXY_ADJUSTED)

            % add profile data
            for idP = 1:nbProfToStore

               prof = tabProfiles(idProfInFile(idP));

               profPos = idP-1+profShiftIfNoPrimary;

               if (VERBOSE_MODE == 2)
                  fprintf('Add profile #%d/%d data\n', ...
                     profPos, nbProfInFile);
               end

               % profile direction
               netcdf.putVar(fCdf, directionVarId, profPos, 1, prof.direction);

               % profile date
               profDate = prof.date;
               if (profDate ~= g_decArgo_dateDef)
                  netcdf.putVar(fCdf, juldVarId, profPos, 1, profDate);
                  if (~isempty(prof.dateQc))
                     netcdf.putVar(fCdf, juldQcVarId, profPos, 1, prof.dateQc);
                  else
                     netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
                  end
               else
                  netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrMissing);
               end

               % profile location
               profLocationDate = prof.locationDate;
               profLocationLon = prof.locationLon;
               profLocationLat = prof.locationLat;
               profLocationQc = prof.locationQc;
               profPosSystem = prof.posSystem;
               if (profLocationDate ~= g_decArgo_dateDef)
                  netcdf.putVar(fCdf, juldLocationVarId, profPos, 1, profLocationDate);
                  netcdf.putVar(fCdf, latitudeVarId, profPos, 1, profLocationLat);
                  netcdf.putVar(fCdf, longitudeVarId, profPos, 1, profLocationLon);
                  if (~isempty(profLocationQc))
                     netcdf.putVar(fCdf, positionQcVarId, profPos, 1, profLocationQc);
                  else
                     netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
                  end
               else
                  netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrMissing);
               end
               netcdf.putVar(fCdf, positioningSystemVarId, fliplr([profPos 0]), fliplr([1 length(profPosSystem)]), profPosSystem');

               % vertical sampling scheme
               vertSampScheme = prof.vertSamplingScheme;
               if (length(vertSampScheme) > g_decArgo_vssMaxLength)
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: vertical sampling scheme too long (length = %d > %d) - vertical sampling scheme ''%s'' not set\n', ...
                     g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, ...
                     length(vertSampScheme), g_decArgo_vssMaxLength, ...
                     vertSampScheme);
                  idF1 = strfind(vertSampScheme, '[');
                  idF2 = strfind(vertSampScheme, ']');
                  vertSampScheme = [vertSampScheme(1:idF1(1)) 'detailed description too long for available space' vertSampScheme(idF2(end):end)];
               end
               netcdf.putVar(fCdf, verticalSamplingSchemeVarId, fliplr([profPos 0]), fliplr([1 length(vertSampScheme)]), vertSampScheme');

               % configuration mission number
               if (~isempty(prof.configMissionNumber))
                  netcdf.putVar(fCdf, configMissionNumberVarId, profPos, 1, prof.configMissionNumber);
               end

               % profile parameter data
               parameterList = prof.paramList;
               parameterDataMode = prof.paramDataMode;
               for idParam = 1:length(parameterList)

                  if (((parameterList(idParam).paramType ~= 'c') && (parameterList(idParam).paramType ~= 'j')) || ...
                        strcmp(parameterList(idParam).name, 'PRES'))

                     profParam = parameterList(idParam);

                     % parameter variable and attributes
                     profParamName = profParam.name;
                     profParamVarId = netcdf.inqVarID(fCdf, profParamName);

                     % parameter QC variable and attributes
                     profParamQcVarId = '';
                     if (~strcmp(profParam.name, 'PRES'))
                        profParamQcName = sprintf('%s_QC', profParam.name);
                        profParamQcVarId = netcdf.inqVarID(fCdf, profParamQcName);
                     end

                     if ((profParam.adjAllowed == 1) && (profParam.paramType ~= 'c') && (profParam.paramType ~= 'j'))
                        % parameter adjusted variable and attributes
                        profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                        profParamAdjVarId = netcdf.inqVarID(fCdf, profParamAdjName);

                        % parameter adjusted QC variable and attributes
                        profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
                        profParamAdjQcVarId = netcdf.inqVarID(fCdf, profParamAdjQcName);

                        % parameter adjusted error variable and attributes
                        profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
                        profParamAdjErrVarId = netcdf.inqVarID(fCdf, profParamAdjErrName);
                     end

                     % prof.data is empty in 'default' primary profiles
                     if (~isempty(prof.data))

                        % parameter data
                        if (isempty(prof.paramNumberWithSubLevels))

                           % none of the profile parameters has sublevels
                           paramData = prof.data(:, idParam);
                           if (isempty(prof.dataQc))
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                              paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           else
                              paramDataQc = prof.dataQc(:, idParam);
                              if (all(paramDataQc == g_decArgo_qcDef))
                                 paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                                 paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                              else
                                 paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                                 idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                                 paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));

                                 if (~strcmp(profParam.name, 'PRES'))
                                    profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                                    profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                                 end
                              end
                           end

                           if (prof.direction == 'A')
                              measIds = fliplr([1:length(paramData)]);
                           else
                              measIds = [1:length(paramData)];
                           end
                           netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));

                           if (~isempty(profParamQcVarId))
                              netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramDataQcStr(measIds));
                           end

                           if (~isempty(parameterDataMode) && (parameterDataMode(idParam) == 'A') && ...
                                 (profParam.adjAllowed == 1) && (profParam.paramType ~= 'c') && (profParam.paramType ~= 'j'))

                              % parameter adjusted data
                              paramAdjData = prof.dataAdj(:, idParam);
                              if (isempty(prof.dataAdjQc))
                                 paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                 paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                              else
                                 paramAdjDataQc = prof.dataAdjQc(:, idParam);
                                 if (all(paramAdjDataQc == g_decArgo_qcDef))
                                    paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                    paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                                 else
                                    paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, length(paramAdjData), 1);
                                    idNoDef = find(paramAdjDataQc ~= g_decArgo_qcDef);
                                    paramAdjDataQcStr(idNoDef) = num2str(paramAdjDataQc(idNoDef));

                                    profQualityFlag = compute_profile_quality_flag(paramAdjDataQcStr);
                                    profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                                 end
                              end

                              netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjData(measIds));

                              netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));

                              if (~isempty(prof.dataAdjError))
                                 paramAdjDataError = prof.dataAdjError(:, idParam);
                                 if (any(paramAdjDataError ~= profParam.fillValue))
                                    netcdf.putVar(fCdf, profParamAdjErrVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjDataError)]), paramAdjDataError(measIds));
                                 end
                              end
                           end

                        else % of if (isempty(prof.paramNumberWithSubLevels))

                           % some profile parameters have sublevels

                           % retrieve the column(s) associated with the parameter data
                           idF = find(prof.paramNumberWithSubLevels < idParam);
                           if (isempty(idF))
                              firstCol = idParam;
                           else
                              firstCol = idParam + sum(prof.paramNumberOfSubLevels(idF)) - length(idF);
                           end

                           idF = find(prof.paramNumberWithSubLevels == idParam);
                           if (isempty(idF))
                              lastCol = firstCol;
                           else
                              lastCol = firstCol + prof.paramNumberOfSubLevels(idF) - 1;
                           end

                           paramData = prof.data(:, firstCol:lastCol);
                           if (isempty(prof.dataQc))
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                              if (size(paramData, 2) == 1)
                                 paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                              else
                                 for idL = 1: size(paramData, 1)
                                    if (any(paramData(idL, :) ~= profParam.fillValue))
                                       paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                    end
                                 end
                              end
                           else
                              paramDataQc = prof.dataQc(:, idParam);
                              if (all(paramDataQc == g_decArgo_qcDef))
                                 paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                                 if (size(paramData, 2) == 1)
                                    paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                                 else
                                    for idL = 1: size(paramData, 1)
                                       if (any(paramData(idL, :) ~= profParam.fillValue))
                                          paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                       end
                                    end
                                 end
                              else
                                 paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                                 idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                                 paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));

                                 if (~strcmp(profParam.name, 'PRES'))
                                    profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                                    profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                                 end
                              end
                           end

                           if (prof.direction == 'A')
                              measIds = fliplr([1:size(paramData, 1)]);
                           else
                              measIds = [1:size(paramData, 1)];
                           end
                           if (size(paramData, 2) == 1)

                              netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));

                              if (~isempty(profParamQcVarId))
                                 netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQcStr)]), paramDataQcStr(measIds));
                              end

                              if (~isempty(parameterDataMode) && (parameterDataMode(idParam) == 'A') && ...
                                    (profParam.adjAllowed == 1) && (profParam.paramType ~= 'c') && (profParam.paramType ~= 'j'))

                                 % parameter adjusted data
                                 paramAdjData = prof.dataAdj(:, firstCol:lastCol);
                                 if (isempty(prof.dataAdjQc))
                                    paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                    paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                                 else
                                    paramAdjDataQc = prof.dataAdjQc(:, idParam);
                                    if (all(paramAdjDataQc == g_decArgo_qcDef))
                                       paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                       paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                                    else
                                       paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                       idNoDef = find(paramAdjDataQc ~= g_decArgo_qcDef);
                                       paramAdjDataQcStr(idNoDef) = num2str(paramAdjDataQc(idNoDef));

                                       if (~strcmp(profParam.name, 'PRES'))
                                          profQualityFlag = compute_profile_quality_flag(paramAdjDataQcStr);
                                          profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                          netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                                       end
                                    end
                                 end

                                 netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjData(measIds));

                                 netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));

                                 if (~isempty(prof.dataAdjError))
                                    paramAdjDataError = prof.dataAdjError(:, firstCol:lastCol);
                                    if (any(paramAdjDataError ~= profParam.fillValue))
                                       netcdf.putVar(fCdf, profParamAdjErrVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjDataError)]), paramAdjDataError(measIds));
                                    end
                                 end
                              end

                           else % of if (size(paramData, 2) == 1)

                              netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0 0]), fliplr([1 size(paramData)]), paramData(measIds, :)');

                              if (~isempty(profParamQcVarId))
                                 netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQcStr)]), paramDataQcStr(measIds));
                              end

                              if (~isempty(parameterDataMode) && (parameterDataMode(idParam) == 'A') && ...
                                    (profParam.adjAllowed == 1) && (profParam.paramType ~= 'c') && (profParam.paramType ~= 'j'))

                                 % parameter adjusted data
                                 paramAdjData = prof.dataAdj(:, firstCol:lastCol);
                                 if (isempty(prof.dataAdjQc))
                                    paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                    for idL = 1: size(paramAdjData, 1)
                                       if (any(paramAdjData(idL, :) ~= profParam.fillValue))
                                          paramAdjDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                       end
                                    end
                                 else
                                    paramAdjDataQc = prof.dataAdjQc(:, idParam);
                                    if (all(paramAdjDataQc == g_decArgo_qcDef))
                                       paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                       for idL = 1: size(paramAdjData, 1)
                                          if (any(paramAdjData(idL, :) ~= profParam.fillValue))
                                             paramAdjDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                          end
                                       end
                                    else
                                       paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                       idNoDef = find(paramAdjDataQc ~= g_decArgo_qcDef);
                                       paramAdjDataQcStr(idNoDef) = num2str(paramAdjDataQc(idNoDef));

                                       if (~strcmp(profParam.name, 'PRES'))
                                          profQualityFlag = compute_profile_quality_flag(paramAdjDataQcStr);
                                          profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                          netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                                       end
                                    end
                                 end

                                 netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 size(paramAdjData)]), paramAdjData(measIds, :)');

                                 netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));

                                 if (~isempty(prof.dataAdjError))
                                    paramAdjDataError = prof.dataAdjError(:, firstCol:lastCol);
                                    if (any(paramAdjDataError ~= profParam.fillValue))
                                       netcdf.putVar(fCdf, profParamAdjErrVarId, fliplr([profPos 0 0]), fliplr([1 size(paramAdjDataError)]), paramAdjDataError(measIds, :)');
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
               end

               % add specific comment for PRES parameter
               if (any(strcmp({prof.paramList.name}, 'PRES')))

                  comment = '';
                  paramDate = '';
                  if (any(prof.paramDataMode == 'A'))
                     comment = 'Not applicable';
                     if (isempty(ncCreationDate))
                        paramDate = currentDate;
                     else
                        paramDate = ncCreationDate;
                     end
                  end
                  tabParam = {'PRES'};
                  tabEquation = {comment};
                  tabCoefficient = {comment};
                  tabComment = {'Adjusted values are provided in the core profile file'};
                  tabDate = {paramDate};

                  % store calibration information for this profile
                  profCalibInfo = [];
                  profCalibInfo.profId = idP;
                  profCalibInfo.param = tabParam;
                  profCalibInfo.equation = tabEquation;
                  profCalibInfo.coefficient = tabCoefficient;
                  profCalibInfo.comment = tabComment;
                  profCalibInfo.date = tabDate;
                  calibInfo{end+1} = profCalibInfo;
               end

               % for decoder RT adjustments:
               % retrieve SCIENTIFIC_CALIB_* from decoder g_decArgo_paramProfAdjInfo
               % global variable
               if (~isempty(prof.rtParamAdjIdList))
                  for idAdj = prof.rtParamAdjIdList

                     % retrieve information on PARAM adjustment
                     idF = find([g_decArgo_paramProfAdjInfo{:, 1}] == idAdj);
                     paramAdjInfo = g_decArgo_paramProfAdjInfo(idF, :);
                     paramName = paramAdjInfo{4};

                     paramInfo = get_netcdf_param_attributes(paramName);
                     if ((paramInfo.paramType ~= 'c') && (paramInfo.paramType ~= 'j'))
                        paramEquation = paramAdjInfo{5};
                        paramCoefficient = paramAdjInfo{6};
                        paramComment = paramAdjInfo{7};
                        paramDate = paramAdjInfo{8};

                        if (isempty(paramDate))
                           if (isempty(ncCreationDate))
                              paramDate = currentDate;
                           else
                              paramDate = ncCreationDate;
                           end
                        end
                        tabParam = {paramName};
                        tabEquation = {paramEquation};
                        tabCoefficient = {paramCoefficient};
                        tabComment = {paramComment};
                        tabDate = {paramDate};

                        % store calibration information for this profile
                        profCalibInfo = [];
                        profCalibInfo.profId = idP;
                        profCalibInfo.param = tabParam;
                        profCalibInfo.equation = tabEquation;
                        profCalibInfo.coefficient = tabCoefficient;
                        profCalibInfo.comment = tabComment;
                        profCalibInfo.date = tabDate;
                        calibInfo{end+1} = profCalibInfo;
                     end
                  end
               end

               % history information
               currentHistoId = 0;
               if (~isempty(histoInstitution))
                  if (size(histoInstitution, 2) <= nbProfInFile)
                     currentHistoId = size(histoInstitution, 3);
                  end
               end
               value = 'IF';
               netcdf.putVar(fCdf, historyInstitutionVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               % modif 20250709
               % value = 'ARFM';
               % netcdf.putVar(fCdf, historyStepVarId, ...
               %    fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               % modif 20250709
               % value = 'CODA';
               value = 'COGP';
               netcdf.putVar(fCdf, historySoftwareVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               value = g_decArgo_decoderVersion;
               netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
               value = currentDate;
               netcdf.putVar(fCdf, historyDateVarId, ...
                  fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
            end

            % process calibration information

            % compute the N_CALIB dimension
            nbCalib = 1;
            if (~isempty(calibInfo))
               tabCalibInfo1 = [];
               for idC = 1:length(calibInfo)
                  if (isempty(tabCalibInfo1))
                     tabCalibInfo1 = [tabCalibInfo1; calibInfo{idC}.profId calibInfo{idC}.param 1];
                  else
                     idF = find(([tabCalibInfo1{:, 1}] == calibInfo{idC}.profId)' & ...
                        strcmp(tabCalibInfo1(:, 2), calibInfo{idC}.param{:}));
                     if (isempty(idF))
                        tabCalibInfo1 = [tabCalibInfo1; calibInfo{idC}.profId calibInfo{idC}.param 1];
                     else
                        tabCalibInfo1{idF, end} = tabCalibInfo1{idF, end} + 1;
                     end
                  end
               end
               nbCalib = max([tabCalibInfo1{:, end}]);
            end

            netcdf.reDef(fCdf);

            nCalibDimId = netcdf.defDim(fCdf, 'N_CALIB', nbCalib);

            % calibration information
            parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string64DimId]));
            netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'List of parameters with calibration information');
            netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Argo reference table 3');
            netcdf.putAtt(fCdf, parameterVarId, '_FillValue', ' ');

            scientificCalibEquationVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_EQUATION', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
            netcdf.putAtt(fCdf, scientificCalibEquationVarId, 'long_name', 'Calibration equation for this parameter');
            netcdf.putAtt(fCdf, scientificCalibEquationVarId, '_FillValue', ' ');

            scientificCalibCoefficientVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
            netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, 'long_name', 'Calibration coefficients for this equation');
            netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, '_FillValue', ' ');

            scientificCalibCommentVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COMMENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
            netcdf.putAtt(fCdf, scientificCalibCommentVarId, 'long_name', 'Comment applying to this parameter calibration');
            netcdf.putAtt(fCdf, scientificCalibCommentVarId, '_FillValue', ' ');

            scientificCalibDateVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_DATE', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId dateTimeDimId]));
            netcdf.putAtt(fCdf, scientificCalibDateVarId, 'long_name', 'Date of calibration');
            netcdf.putAtt(fCdf, scientificCalibDateVarId, 'conventions', 'YYYYMMDDHHMISS');
            netcdf.putAtt(fCdf, scientificCalibDateVarId, '_FillValue', ' ');

            netcdf.endDef(fCdf);

            % fill PARAMETER variable (event if there is no RT adjustments)
            ncParamlist = repmat({''}, nbProfToStore, nbProfParam);
            for idP = 1:nbProfToStore
               prof = tabProfiles(idProfInFile(idP));
               parameterList = prof.paramList;
               profPos = idP-1+profShiftIfNoPrimary;
               paramPos = 0;
               for idParam = 1:length(parameterList)

                  if ((((parameterList(idParam).paramType ~= 'c') && (parameterList(idParam).paramType ~= 'j')) || ...
                        strcmp(parameterList(idParam).name, 'PRES')))

                     valueStr = parameterList(idParam).name;

                     for idCalib = 1:nbCalib
                        netcdf.putVar(fCdf, parameterVarId, ...
                           fliplr([profPos idCalib-1 paramPos 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
                     end
                     paramPos = paramPos + 1;
                     ncParamlist(idP, paramPos) = {valueStr};
                  end
               end
            end

            tabCalibInfo2 = [];
            for idC = 1:length(calibInfo)
               profId = calibInfo{idC}.profId;
               profPos = profId-1+profShiftIfNoPrimary;
               param = calibInfo{idC}.param{:};
               idPosParam = find(strcmp(ncParamlist(profId, :), param) == 1);
               equation = calibInfo{idC}.equation{:};
               coef = calibInfo{idC}.coefficient{:};
               comment = calibInfo{idC}.comment{:};
               date = calibInfo{idC}.date{:};

               % compute start calibId
               if (isempty(tabCalibInfo2))
                  tabCalibInfo2 = [tabCalibInfo2; calibInfo{idC}.profId calibInfo{idC}.param 1];
                  idCalibStart = 1;
               else
                  idF = find(([tabCalibInfo2{:, 1}] == calibInfo{idC}.profId)' & ...
                     strcmp(tabCalibInfo2(:, 2), calibInfo{idC}.param{:}));
                  if (isempty(idF))
                     tabCalibInfo2 = [tabCalibInfo2; calibInfo{idC}.profId calibInfo{idC}.param 1];
                     idCalibStart = 1;
                  else
                     tabCalibInfo2{idF, end} = tabCalibInfo2{idF, end} + 1;
                     idCalibStart = idCalibStart + 1;
                  end
               end

               idF = find(([tabCalibInfo1{:, 1}] == profId)' & strcmp(tabCalibInfo1(:, 2), param));
               idCalibStop = idCalibStart + (nbCalib-tabCalibInfo1{idF, end});

               for id = idCalibStart:idCalibStop
                  value = param;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, parameterVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = equation;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibEquationVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = coef;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibCoefficientVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = comment;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibCommentVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
                  value = date;
                  if (~isempty(value))
                     netcdf.putVar(fCdf, scientificCalibDateVarId, ...
                        fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
                  end
               end
            end

            netcdf.close(fCdf);

         catch MException
            netcdf.close(fCdf);
            rethrow(MException)
         end

         if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_applyRtqc == 1))
            % store information for the XML report
            g_decArgo_reportStruct.outputMonoProfFiles = [g_decArgo_reportStruct.outputMonoProfFiles ...
               {ncPathFileName}];
         end
      end
   end
end

o_bFileInfo = generatedProfList;

fprintf('... NetCDF MONO-PROFILE b files created\n');

return

