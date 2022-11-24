% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in
% individual json files.
%
% SYNTAX :
%  generate_json_float_meta_argos_nke_old_versions()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_argos_nke_old_versions()

% meta-data file exported from Coriolis data base
floatMetaFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\meta_PRV_from_VB_REFERENCE_20150217_nke_old_versions.txt';

fprintf('Generating json meta-data files from input file: %s\n', floatMetaFileName);

% list of concerned floats
floatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all_argos.txt';

fprintf('Generating json meta-data files for floats of the list: %s\n', floatListFileName);

% directory of individual json float meta-data files
outputDirName = ['C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\generate_json_float_meta_argos_nke_old_versions_' datestr(now, 'yyyymmddTHHMMSS')];

% list of floats which profile during descent
descProfFloatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\descent_profiling_floats.txt';

% to check consistency with ANDRO meta-data
surfSliceThickFile = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\cut_off_pres\surf_slice_thick.txt';
ctdCutOffFile = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\cut_off_pres\ctd_cut_off.txt';
standardFormatIdFile = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\andro_standard_format_id\andro_standard_format_id.txt';
metaDataFile = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\andro_meta_data\CorrectedMetadata_20140813.txt';
prvFloatInfoFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\andro_prv_float_info\_provor_floats_information_all.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

global g_decArgo_janFirst1950InMatlab;

init_default_values;


% create and start log file recording
[~, name, ~] = fileparts(floatListFileName);
logFile = [DIR_LOG_FILE '/' 'generate_json_float_meta_argos_nke_old_versions_' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

mandatoryList1 = [ ...
   {'BATTERY_TYPE'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} ...
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} ...
   {'DAC_FORMAT_ID'} ...
   {'FIRMWARE_VERSION'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'MANUAL_VERSION'} ...
   {'PI_NAME'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PTT'} ...
   {'SENSOR_SERIAL_NO'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_SENSOR'} ...
   {'STANDARD_FORMAT_ID'} ...
   {'TRANS_FREQUENCY'} ...
   {'TRANS_SYSTEM_ID'} ...
   {'WMO_INST_TYPE'} ...
   ];
mandatoryList2 = [ ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   ];

% list of floats which profile during descent
profDuringDescFloatList = load(descProfFloatListFileName);

if ~(exist(floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', floatMetaFileName);
   return;
end

% read meta file
fId = fopen(floatMetaFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', floatMetaFileName);
   return;
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';

% get the mapping structure
metaBddStruct = get_meta_bdd_struct();
metaBddStructNames = fieldnames(metaBddStruct);

% process the meta-data to fill the structure
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the sme number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the sme number of digits
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('%s is not a valid WMO number\n', wmoList{id});
      return;
   end
end
S = sprintf('%s*', wmoList{:});
wmoList = sscanf(S, '%f*');
dimLevlist = metaData(:, 3);
S = sprintf('%s*', dimLevlist{:});
dimLevlist = sscanf(S, '%f*');
floatList = unique(wmoList);

if ~(exist(floatListFileName, 'file') == 2)
   fprintf('File not found: %s\n', floatListFileName);
   return;
end
refFloatList = load(floatListFileName);

floatList = sort(intersect(floatList, refFloatList));
% floatList = [2900268];

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('Meta-data not found for float: %d\n', notFoundFloat);
end

% ANDRO: surface slice thickness
data = load(surfSliceThickFile);
tabWmoSurfSliceThick = data(:, 1);
tabSurfSliceThick = data(:, 2);

% ANDRO: CTD cut-off pressure
data = load(ctdCutOffFile);
tabWmoCtdcutOff = data(:, 1);
tabCtdcutOff = data(:, 2);

% ANDRO: standard format Id
data = load(standardFormatIdFile);
tabWmoStandardFormatId = data(:, 1);
tabStandardFormatId = data(:, 2);

% ANDRO: PRV float info
[listWmoNum, listDecId, listArgosId, listFrameLen, listCycleTime, ...
   listDriftSamplingPeriod, listDelay, listLaunchDate, listRefDay] = ...
   get_floats_info_for_dep2(prvFloatInfoFileName);

for idFloat = 1:length(floatList)
   
   floatNum = floatList(idFloat);
   fprintf('%3d/%3d %d\n', idFloat, length(floatList), floatNum);
   
   % initialize the structure to be filled
   metaStruct = get_meta_init_struct();
   
   metaStruct.PLATFORM_NUMBER = num2str(floatNum);
   metaStruct.ARGO_USER_MANUAL_VERSION = '3.1';
   
   % direct conversion data
   idForWmo = find(wmoList == floatNum);
   for idBSN = 1:length(metaBddStructNames)
      metaBddStructField = metaBddStructNames{idBSN};
      metaBddStructValue = metaBddStruct.(metaBddStructField);
      if (~isempty(metaBddStructValue))
         idF = find(strcmp(metaData(idForWmo, 5), metaBddStructValue) == 1, 1);
         if (~isempty(idF))
            metaStruct.(metaBddStructField) = metaData{idForWmo(idF), 4};
         else
            if (~isempty(find(strcmp(mandatoryList1, metaBddStructField) == 1, 1)))
               metaStruct.(metaBddStructField) = 'n/a';
               %                fprintf('Empty mandatory meta-data ''%s'' set to ''n/a''\n', metaBddStructValue);
            elseif (~isempty(find(strcmp(mandatoryList2, metaBddStructField) == 1, 1)))
               metaStruct.(metaBddStructField) = 'UNKNOWN';
            end
         end
      end
   end
   
   % PTT / IMEI specific processing
   if (~isempty(metaStruct.IMEI))
      metaStruct.PTT = metaStruct.IMEI;
   end
   
   %    idF = find(strcmp(metaData(idForWmo, 5), 'PTT') == 1, 1);
   %    if (~isempty(idF))
   %       if (strcmp(metaStruct.TRANS_SYSTEM, 'IRIDIUM'))
   %          if (isempty(metaStruct.PTT))
   %             metaStruct.PTT = metaStruct.IMEI;
   %          end
   %       end
   %    end
   
   % multi dim data
   itemList = [ ...
      {'TRANS_SYSTEM'} ...
      {'TRANS_SYSTEM_ID'} ...
      {'TRANS_FREQUENCY'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   [metaStruct] = add_multi_dim_data( ...
      {'POSITIONING_SYSTEM'}, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   itemList = [ ...
      {'SENSOR'} ...
      {'SENSOR_MAKER'} ...
      {'SENSOR_MODEL'} ...
      {'SENSOR_SERIAL_NO'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   itemList = [ ...
      {'PARAMETER'} ...
      {'PARAMETER_SENSOR'} ...
      {'PARAMETER_UNITS'} ...
      {'PARAMETER_ACCURACY'} ...
      {'PARAMETER_RESOLUTION'} ...
      {'PREDEPLOYMENT_CALIB_EQUATION'} ...
      {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
      {'PREDEPLOYMENT_CALIB_COMMENT'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   itemList = [ ...
      {'CALIB_RT_PARAMETER'} ...
      {'CALIB_RT_EQUATION'} ...
      {'CALIB_RT_COEFFICIENT'} ...
      {'CALIB_RT_COMMENT'} ...
      {'CALIB_RT_DATE'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   % configuration parameters
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = metaStruct.DAC_FORMAT_ID;
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d => no json file generated\n', ...
         floatNum);
      continue;
   end
   
   
   % CONFIG_PARAMETER_NAME
   configStruct = get_config_bdd_struct(dacFormatId);
   configStructNames = fieldnames(configStruct);
   metaStruct.CONFIG_PARAMETER_NAME = configStructNames;
   
   % CONFIG_PARAMETER_VALUE
   
   % older versions don't transmit configuration.
   % we create all configuration from data base information
   idFRepRate = find(strcmp(metaData(idForWmo, 5), 'REPETITION_RATE') == 1);
   if (isempty(idFRepRate))
      fprintf('ERROR: REPETITION_RATE is missing for float %d => no json file generated\n', ...
         floatNum);
      continue;
   end
   
   configBddStruct = get_config_bdd_struct(dacFormatId);
   configBddStructNames = fieldnames(configBddStruct);
   
   nbConfig = length(idFRepRate);
   if (nbConfig > 1)
      fprintf('Multi conf: %d\n', floatNum);
   end
   configParamVal = cell(length(configStructNames), nbConfig);
   configRepRate = cell(1, nbConfig);
   cutOffPres = [];
   for idConf = 1:nbConfig
      configRepRate{1, idConf} = metaData{idForWmo(idFRepRate(idConf)), 4};
      for idBSN = 1:length(configBddStructNames)
         configBddStructName = configBddStructNames{idBSN};
         if ((strcmp(configBddStructName, 'CONFIG_FloatReferenceDay_FloatDay') == 0) && ...
               (strcmp(configBddStructName, 'CONFIG_ClockAscentStart_HH') == 0) && ...
               (strcmp(configBddStructName, 'CONFIG_CTDPumpStopPressure_dbar') == 0) && ...
               (strcmp(configBddStructName, 'CONFIG_CTDPumpStopPressurePlusThreshold_dbar') == 0))
            configBddStructValue = configBddStruct.(configBddStructName);
            if (~isempty(configBddStructValue))
               idF = find(strcmp(metaData(idForWmo, 5), configBddStructValue) == 1);
               if (~isempty(idF))
                  dimLev = dimLevlist(idForWmo(idF));
                  idDim = find(dimLev == idConf, 1);
                  if ((isempty(idDim)) && (idConf > 1))
                     idDim = 1;
                  elseif ((isempty(idDim)) && (idConf == 1))
                     fprintf('ERROR\n');
                  end
                  
                  if ((strcmp(configBddStructValue, 'DIRECTION') == 0) && ...
                        (strcmp(configBddStructValue, 'PR_IMMERSION_DRIFT_PERIOD') == 0))
                     configParamVal{idBSN, idConf} = metaData{idForWmo(idF(idDim)), 4};
                  else
                     if (strcmp(configBddStructValue, 'DIRECTION') == 1)
                        if (ismember(floatNum, profDuringDescFloatList))
                           configParamVal{idBSN, idConf} = '3';
                        else
                           configParamVal{idBSN, idConf} = '1';
                        end
                     elseif (strcmp(configBddStructValue, 'PR_IMMERSION_DRIFT_PERIOD') == 1)
                        configParamVal{idBSN, idConf} = num2str(str2num(metaData{idForWmo(idF(idDim)), 4})/60);
                     end
                  end
               end
            else
               % if we want to use default values if the information is
               % missing in the database
               %                      configParamVal{idBSN, idConf} = configStruct.(configBddStructName);
            end
         else
            if (strcmp(configBddStructName, 'CONFIG_FloatReferenceDay_FloatDay') == 1)
               idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_Reference_day') == 1);
               if (~isempty(idF0))
                  configParamVal{idBSN, idConf} = metaData{idForWmo(idF0), 4};
               else
                  idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                  idF2 = find(strcmp(metaData(idForWmo, 5), 'PR_LAUNCH_DATETIME') == 1);
                  if ~(isempty(idF1) || isempty(idF2))
                     refDate = datenum(metaData{idForWmo(idF1), 4}, 'dd/mm/yyyy HH:MM');
                     launchDate = datenum(metaData{idForWmo(idF2), 4}, 'dd/mm/yyyy HH:MM');
                     configParamVal{idBSN, idConf} = num2str(fix(refDate) - fix(launchDate));
                  end
               end
            elseif (strcmp(configBddStructName, 'CONFIG_ClockAscentStart_HH') == 1)
               idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_Start_time') == 1);
               if (~isempty(idF0))
                  configParamVal{idBSN, idConf} = sprintf('%02d', str2num(metaData{idForWmo(idF0), 4}));
               else
                  idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                  if (~isempty(idF1))
                     refDate = datenum(metaData{idForWmo(idF1), 4}, 'dd/mm/yyyy HH:MM');
                     configParamVal{idBSN, idConf} = datestr(refDate, 'HH');
                  end
               end
            elseif ((strcmp(configBddStructName, 'CONFIG_CTDPumpStopPressure_dbar') == 1))
               
               stopCtdPumpBdd = [];
               idF0 = find(strcmp(metaData(idForWmo, 5), 'PRES_SBE_PUMP_SWITCH_OFF') == 1);
               if (~isempty(idF0))
                  stopCtdPumpBdd = str2num(metaData{idForWmo(idF0), 4});
               end

               stopCtdPumpAndro = [];
               idF1 = find(tabWmoCtdcutOff == floatNum);
               if (~isempty(idF1))
                  stopCtdPumpAndro = tabCtdcutOff(idF1);
               end
               
               stopCtdPump = 5;
               if (~isempty(stopCtdPumpBdd) && ~isempty(stopCtdPumpAndro))
                  if (stopCtdPumpBdd ~= stopCtdPumpAndro)
                     fprintf('INFO: float %d: CTD pump cut-off PRES differ (BDD = %g, ANDRO = %g)\n', ...
                        floatNum, stopCtdPumpBdd, stopCtdPumpAndro);
                  end
                  stopCtdPump = stopCtdPumpBdd;
               elseif (~isempty(stopCtdPumpBdd))
                  stopCtdPump = stopCtdPumpBdd;
               elseif (~isempty(stopCtdPumpAndro))
                  fprintf('INFO: float %d: CTD pump cut-off PRES retrieved from ANDRO (ANDRO = %g)\n', ...
                     floatNum, stopCtdPumpAndro);
                  stopCtdPump = stopCtdPumpAndro;
               end
               configParamVal{idBSN, idConf} = num2str(stopCtdPump);

               surfSliceThickBdd = [];
               idF0 = find(strcmp(metaData(idForWmo, 5), 'SURF_SLICE_THICKNESS') == 1);
               if (~isempty(idF0))
                  surfSliceThickBdd = str2num(metaData{idForWmo(idF0), 4});
               end
               
               surfSliceThickAndro = [];
               idF1 = find(tabWmoSurfSliceThick == floatNum);
               if (~isempty(idF1))
                  surfSliceThickAndro = tabSurfSliceThick(idF1);
               end
   
               surfSliceThick = 10;
               if (~isempty(surfSliceThickBdd) && ~isempty(surfSliceThickAndro))
                  %                   if (surfSliceThickBdd ~= surfSliceThickAndro)
                  %                      fprintf('INFO: float %d: surf slice thickness differ (BDD = %g, ANDRO = %g)\n', ...
                  %                         floatNum, surfSliceThickBdd, surfSliceThickAndro);
                  %                   end
                  surfSliceThick = surfSliceThickBdd;
               elseif (~isempty(surfSliceThickBdd))
                  surfSliceThick = surfSliceThickBdd;
               elseif (~isempty(surfSliceThickAndro))
                  fprintf('INFO: float %d: surf slice thickness retrieved from ANDRO (ANDRO = %g)\n', ...
                     floatNum, surfSliceThickAndro);
                  surfSliceThick = surfSliceThickAndro;
               end
                  
               cutOffPres = stopCtdPump + surfSliceThick/2;
               
            elseif ((strcmp(configBddStructName, 'CONFIG_CTDPumpStopPressurePlusThreshold_dbar') == 1))
               if (~isempty(cutOffPres))
                  configParamVal{idBSN, idConf} = num2str(cutOffPres);
               end
            end
         end
      end
   end
   
   % PLATFORM_MAKER
   switch (dacFormatId)
      % flotteurs MARTEC
      case {'1', '2.2', '2.6', '2.7', '3.21', '3.5', '3.61', '3.8', '3.81', '4.0', '4.1', '4.11', '5.0', '5.1', '5.2', '5.5'}
         metaStruct.PLATFORM_MAKER = 'MARTEC';
         % flotteurs NKE
      case {'4.6', '4.61'}
         metaStruct.PLATFORM_MAKER = 'NKE';
      otherwise
         fprintf('WARNING: Nothing done yet to retrieve PLATFORM_MAKER for dacFormatId %s\n', dacFormatId);
   end
   
   % the configuration with idConf=1 SHOULD be the configuration of the
   % float for the cycle #1 (not for the first cycle which is #0)
   
   % add a first configuration, specific to float version (with or
   % without a prelude phase)
   
   % all without prelude phase ?
   
   % floats without a prelude phase: cycle #0 is the first deep
   % cycle; it has a shorter duration and the float profiles during
   % descent
   
   % the configuration is based on the last one
   configParamVal0 = configParamVal(:, end);
   
   % set the descending sampling period
   idDescSampPeriod = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_DescentToParkPresSamplingTime_seconds') == 1);
   idAscSampPeriod = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_AscentSamplingPeriod_seconds') == 1);
   if (~isempty(idDescSampPeriod))
      if  (isempty(configParamVal0{idDescSampPeriod}) || ...
            (~isempty(configParamVal0{idDescSampPeriod}) && ...
            (str2num(configParamVal0{idDescSampPeriod}) == 0)))
         % the descending sampling period is empty or set to 0
         
         if (~isempty(idAscSampPeriod) && ...
               ~isempty(configParamVal0{idAscSampPeriod}))
            % copy the ascending sampling period to the descending
            % sampling period
            configParamVal0{idDescSampPeriod} = configParamVal0{idAscSampPeriod};
         else
            % set the descending sampling period to the default
            % value (10 sec)
            configParamVal0{idDescSampPeriod} = num2str(10);
         end
      end
   end
   
   % compute the duration of the cycle #0
   idCycleTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_CycleTime_hours') == 1);
   if ~(isempty(idCycleTime))
      configParamVal0{idCycleTime} = '';
   end
   
   idCycleTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_CycleTime_hours') == 1);
   idRefDay = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_FloatReferenceDay_FloatDay') == 1);
   idAscentStartTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_ClockAscentStart_HH') == 1);
   idProfileDepth = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_ProfilePressure_dbar') == 1);
   idArgosTransmissionDuration = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_TransmissionMinTime_hours') == 1);
   if ~(isempty(idCycleTime) || isempty(idRefDay) || ...
         isempty(idAscentStartTime) || isempty(idProfileDepth) || ...
         isempty(idArgosTransmissionDuration))
      
      refDay = configParamVal0{idRefDay};
      ascentStartTime = configParamVal0{idAscentStartTime};
      profileDepth = configParamVal0{idProfileDepth};
      argosTransmissionDuration = configParamVal0{idArgosTransmissionDuration};
      
      if ~(isempty(refDay) || isempty(ascentStartTime) || ...
            isempty(profileDepth) || isempty(argosTransmissionDuration))
         
         firstDeepCycleDuration = str2num(refDay) + ...
            str2num(ascentStartTime)/24 + ...
            str2num(profileDepth)/8640 + ...
            str2num(argosTransmissionDuration)/24;
         
         configParamVal0{idCycleTime} = num2str(firstDeepCycleDuration);
      end
   end
   
   idDir = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_Direction_NUMBER') == 1);
   if (~isempty(idDir))
      configParamVal0{idDir} = '3';
   end
   
   configParamVal = [configParamVal0 configParamVal];
   
   metaStruct.CONFIG_REPETITION_RATE = configRepRate;
   metaStruct.CONFIG_PARAMETER_VALUE = configParamVal;
   
   % RT_OFFSET
   idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_PARAMETER') == 1);
   if (~isempty(idF))
      rtOffsetData = [];
      
      rtOffsetParam = [];
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['PARAM_' num2str(dimLevel)];
         rtOffsetParam.(fieldName) = metaData{idForWmo(idF(id)), 4};
      end
      rtOffsetSlope = [];
      rtOffsetValue = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_COEFFICIENT') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldNameValue = ['VALUE_' num2str(dimLevel)];
         fieldNameSlope = ['SLOPE_' num2str(dimLevel)];
         coefStrOri = metaData{idForWmo(idF(id)), 4};
         coefStr = regexprep(coefStrOri, ' ', '');
         idPos1 = strfind(coefStr, 'a1=');
         idPos2 = strfind(coefStr, ',a0=');
         if (~isempty(idPos1) && ~isempty(idPos2))
            rtOffsetSlope.(fieldNameSlope) = coefStr(idPos1+3:idPos2-1);
            rtOffsetValue.(fieldNameValue) = coefStr(idPos2+4:end);
            [~, statusSlope] = str2num(rtOffsetSlope.(fieldNameSlope));
            [~, statusValue] = str2num(rtOffsetValue.(fieldNameValue));
            if ((statusSlope == 0) || (statusValue == 0))
               fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') => exit\n', ...
                  floatList(idFloat), coefStrOri);
               return;
            end
         else
            fprintf('ERROR: while parsing CALIB_RT_COEFFICIENT for float %d (found: ''%s'') => exit\n', ...
               floatList(idFloat), coefStrOri);
            return;
         end
      end
      rtOffsetDate = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_DATE') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['DATE_' num2str(dimLevel)];
         rtOffsetDate.(fieldName) = metaData{idForWmo(idF(id)), 4};
      end
      rtOffsetData.PARAM = rtOffsetParam;
      rtOffsetData.SLOPE = rtOffsetSlope;
      rtOffsetData.VALUE = rtOffsetValue;
      rtOffsetData.DATE = rtOffsetDate;
      
      metaStruct.RT_OFFSET = rtOffsetData;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % check consistency with ANDRO meta-data
   
   % ANDRO: standard format Id
   idF1 = find(tabWmoStandardFormatId == floatNum);
   if (~isempty(idF1))
      if (~isempty(metaStruct.STANDARD_FORMAT_ID))
         if (str2num(metaStruct.STANDARD_FORMAT_ID) ~= tabStandardFormatId(idF1))
            fprintf('INFO: float %d: STANDARD_FORMAT_ID differ (BDD = %d, ANDRO = %d)\n', ...
               floatNum, metaStruct.STANDARD_FORMAT_ID, tabStandardFormatId(idF1));
         end
      else
         fprintf('INFO: float %d: STANDARD_FORMAT_ID retrieved from ANDRO (ANDRO = %d)\n', ...
            floatNum, tabStandardFormatId(idF1));
         metaStruct.STANDARD_FORMAT_ID = sprintf('%06d', tabStandardFormatId(idF1));
      end
   end

   % ANDRO: meta-data
   [ptt, missionNum, repRate, downTime, upTime, ...
      cycleTime, parkPres, profPres, ...
      launchDate, launchLon, launchLat, startUpDate] = ...
      get_dep_meta_for_dep2(floatNum, metaDataFile);

   if (~isempty(ptt))
      if (str2num(metaStruct.PTT) ~= ptt)
         fprintf('INFO: float %d: PTT differ (BDD = %d, ANDRO = %d)\n', ...
            floatNum, str2num(metaStruct.PTT), ptt);
      end
      launchDateAndro = datestr(launchDate+g_decArgo_janFirst1950InMatlab, 'dd/mm/yyyy HH:MM:SS');
      if (~strcmp(metaStruct.LAUNCH_DATE, launchDateAndro))
         fprintf('INFO: float %d: LAUNCH_DATE differ (BDD = %s, ANDRO = %s)\n', ...
            floatNum, metaStruct.LAUNCH_DATE, launchDateAndro);
      end
      launchLatBdd = round(str2num(metaStruct.LAUNCH_LATITUDE)*1000)/1000;
      if (launchLatBdd ~= launchLat)
         fprintf('INFO: float %d: LAUNCH_LATITUDE differ (BDD = %g, ANDRO = %g)\n', ...
            floatNum, launchLatBdd, launchLat);
      end
      launchLonBdd = round(str2num(metaStruct.LAUNCH_LONGITUDE)*1000)/1000;
      if (launchLonBdd ~= launchLon)
         fprintf('INFO: float %d: LAUNCH_LONGITUDE differ (BDD = %g, ANDRO = %g)\n', ...
            floatNum, launchLonBdd, launchLon);
      end
      
      confParamName = metaStruct.CONFIG_PARAMETER_NAME;
      confParamVal = metaStruct.CONFIG_PARAMETER_VALUE;
      confRepRate = metaStruct.CONFIG_REPETITION_RATE;
      for idR = 1:length(confRepRate)
         if (str2num(confRepRate{idR}) ~= repRate(idR))
            fprintf('INFO: float %d: REPETITION_RATE differ (BDD = %d, ANDRO = %d)\n', ...
               floatNum, str2num(confRepRate{idR}), repRate(idR));
         end
      end
      if (size(confParamVal, 2) ~= length(missionNum)+1)
         fprintf('INFO: float %d: number of config differ (BDD = %d, ANDRO = %d)\n', ...
            floatNum, size(confParamVal, 1), length(missionNum)+1);
      else
         for idM = 1:length(missionNum)
            cycleDuration = cycleTime(idM);
            parkingPres = parkPres(idM);
            profilePres = profPres(idM);
            if (idM == 1)
               idF0 = find(strcmp(confParamName, 'CONFIG_CycleTime_hours'));
               if (str2num(confParamVal{idF0, idM+1}) ~= cycleDuration)
                  fprintf('INFO: float %d: CONFIG_CycleTime_hours differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, idM+1}), cycleDuration);
               end
               idF0 = find(strcmp(confParamName, 'CONFIG_ParkPressure_dbar'));
               if (str2num(confParamVal{idF0, idM+1}) ~= parkingPres)
                  fprintf('INFO: float %d: CONFIG_ParkPressure_dbar differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, idM+1}), parkingPres);
               end
               idF0 = find(strcmp(confParamName, 'CONFIG_ProfilePressure_dbar'));
               if (str2num(confParamVal{idF0, idM+1}) ~= profilePres)
                  fprintf('INFO: float %d: CONFIG_ProfilePressure_dbar differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, idM+1}), profilePres);
               end
            else
               idF0 = find(strcmp(confParamName, 'CONFIG_ParkPressure_dbar'));
               if (str2num(confParamVal{idF0, 1}) ~= parkingPres)
                  fprintf('INFO: float %d: CONFIG_ParkPressure_dbar differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, 1}), parkingPres);
               end
               if (str2num(confParamVal{idF0, idM+1}) ~= parkingPres)
                  fprintf('INFO: float %d: CONFIG_ParkPressure_dbar differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, idM+1}), parkingPres);
               end
               idF0 = find(strcmp(confParamName, 'CONFIG_ProfilePressure_dbar'));
               if (str2num(confParamVal{idF0, 1}) ~= profilePres)
                  fprintf('INFO: float %d: CONFIG_ProfilePressure_dbar differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, 1}), profilePres);
               end
               idF0 = find(strcmp(confParamName, 'CONFIG_ProfilePressure_dbar'));
               if (str2num(confParamVal{idF0, idM+1}) ~= profilePres)
                  fprintf('INFO: float %d: CONFIG_ProfilePressure_dbar differ (BDD = %d, ANDRO = %d)\n', ...
                     floatNum, str2num(confParamVal{idF0, idM+1}), profilePres);
               end
            end
         end
      end
   end
   
   % ANDRO: PRV float info
   idF1 = find(listWmoNum == floatNum);
   if (~isempty(idF1))
      
      confParamName = metaStruct.CONFIG_PARAMETER_NAME;
      confParamVal = metaStruct.CONFIG_PARAMETER_VALUE;

      % drift sampling period
      idF0 = find(strcmp(confParamName, 'CONFIG_ParkSamplingPeriod_hours'));
      for idC = 1:size(confParamVal, 2)
         if (isempty(confParamVal{idF0, idC}))
            fprintf('INFO: float %d: CONFIG_ParkSamplingPeriod_hours empty in BDD (ANDRO = %d)\n', ...
               floatNum, listDriftSamplingPeriod(idF1));
         else
            if (str2num(confParamVal{idF0, idC}) ~= listDriftSamplingPeriod(idF1))
               fprintf('INFO: float %d: CONFIG_ParkSamplingPeriod_hours differ (BDD = %d, ANDRO = %d) => ANDRO value used\n', ...
                  floatNum, str2num(confParamVal{idF0, idC}), listDriftSamplingPeriod(idF1));
               metaStruct.CONFIG_PARAMETER_VALUE{idF0, idC} = num2str(listDriftSamplingPeriod(idF1));
            end
         end
      end
      
      % DELAI parameter
      switch (dacFormatId)
         % flotteurs avec DELAI
         case {'1', '2.2', '2.6', '2.7', '3.21', '3.5', '3.61', '3.8', '3.81', '4.0', '4.1', '4.11'}
            if (listDelay(idF1) ~= -1)
               idF0 = find(strcmp(confParamName, 'CONFIG_DescentToProfTimeOut_hours'));
               for idC = 1:size(confParamVal, 2)
                  if (isempty(confParamVal{idF0, idC}))
                     %                      fprintf('INFO: float %d: CONFIG_DescentToProfTimeOut_hours empty in BDD (ANDRO = %d)\n', ...
                     %                         floatNum, listDelay(idF1));
                     metaStruct.CONFIG_PARAMETER_VALUE{idF0, idC} = num2str(listDelay(idF1));
                  else
                     if (str2num(confParamVal{idF0, idC}) ~= listDelay(idF1))
                        fprintf('INFO: float %d: CONFIG_DescentToProfTimeOut_hours differ (BDD = %d, ANDRO = %d)\n', ...
                           floatNum, str2num(confParamVal{idF0, idC}), listDelay(idF1));
                     end
                  end
               end
            end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % create the directory of json output files
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
   
   % create the json output files
   outputFileName = [outputDirName '/' sprintf('%d_meta.json', floatNum)];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
      return;
   end
   
   fprintf(fidOut, '{\n');
   
   metaStructNames = fieldnames(metaStruct);
   for idBSN = 1:length(metaStructNames)
      fprintf(fidOut, '   "%s" : ', metaStructNames{idBSN});
      if (strcmp(metaStructNames{idBSN}, 'CALIBRATION_COEFFICIENT') == 1)
         fieldVal = metaStruct.(metaStructNames{idBSN});
         if (isempty(fieldVal) || (isa(fieldVal, 'struct')))
            fprintf(fidOut, '[ \n');
            if (~isempty(fieldVal))
               fprintf(fidOut, '      {\n');
               fieldSubVal = fieldnames(fieldVal);
               for idDim1 = 1:size(fieldSubVal, 1)
                  fprintf(fidOut, '      "%s" :\n', ...
                     fieldSubVal{idDim1});
                  fprintf(fidOut, '         {\n');
                  fieldSubVal2 = fieldnames(fieldVal.(fieldSubVal{idDim1}));
                  for idDim2 = 1:size(fieldSubVal2, 1)
                     fprintf(fidOut, '            "%s" : %s', ...
                        fieldSubVal2{idDim2}, ...
                        fieldVal.(fieldSubVal{idDim1}).(fieldSubVal2{idDim2}));
                     if (idDim2 < size(fieldSubVal2, 1))
                        fprintf(fidOut, ',\n');
                     else
                        fprintf(fidOut, '\n');
                     end
                  end
                  if (idDim1 < size(fieldSubVal, 1))
                     fprintf(fidOut, '         },\n');
                  else
                     fprintf(fidOut, '         }\n');
                  end
               end
               fprintf(fidOut, '      }\n');
            end
            if (idBSN < length(metaStructNames))
               fprintf(fidOut, '   ],\n');
            else
               fprintf(fidOut, '   ]\n');
            end
         end
      elseif (strcmp(metaStructNames{idBSN}, 'RT_OFFSET') == 1)
         fieldVal = metaStruct.(metaStructNames{idBSN});
         if (isempty(fieldVal) || (isa(fieldVal, 'struct')))
            fprintf(fidOut, '[ \n');
            if (~isempty(fieldVal))
               fprintf(fidOut, '      {\n');
               fieldSubVal = fieldnames(fieldVal);
               for idDim1 = 1:size(fieldSubVal, 1)
                  fprintf(fidOut, '      "%s" :\n', ...
                     fieldSubVal{idDim1});
                  fprintf(fidOut, '         {\n');
                  fieldSubVal2 = fieldnames(fieldVal.(fieldSubVal{idDim1}));
                  for idDim2 = 1:size(fieldSubVal2, 1)
                     fprintf(fidOut, '            "%s" : "%s"', ...
                        fieldSubVal2{idDim2}, ...
                        fieldVal.(fieldSubVal{idDim1}).(fieldSubVal2{idDim2}));
                     if (idDim2 < size(fieldSubVal2, 1))
                        fprintf(fidOut, ',\n');
                     else
                        fprintf(fidOut, '\n');
                     end
                  end
                  if (idDim1 < size(fieldSubVal, 1))
                     fprintf(fidOut, '         },\n');
                  else
                     fprintf(fidOut, '         }\n');
                  end
               end
               fprintf(fidOut, '      }\n');
            end
            if (idBSN < length(metaStructNames))
               fprintf(fidOut, '   ],\n');
            else
               fprintf(fidOut, '   ]\n');
            end
         end
      else
         fieldVal = metaStruct.(metaStructNames{idBSN});
         if (isa(fieldVal, 'char'))
            if (idBSN < length(metaStructNames))
               fprintf(fidOut, '"%s", \n', char(fieldVal));
            else
               fprintf(fidOut, '"%s" \n', char(fieldVal));
            end
         else
            if (isempty(fieldVal) || (isa(fieldVal, 'cell')))
               fprintf(fidOut, '[ \n');
               for idDim2 = 1:size(fieldVal, 2)
                  fprintf(fidOut, '      {\n');
                  for idDim1 = 1:size(fieldVal, 1)
                     fieldSubVal = char(fieldVal{idDim1, idDim2});
                     if (size(fieldVal, 2) == 1)
                        fprintf(fidOut, '      "%s_%d" : "%s"', ...
                           metaStructNames{idBSN}, ...
                           idDim1, ...
                           fieldSubVal);
                     else
                        fprintf(fidOut, '      "%s_%d_%d" : "%s"', ...
                           metaStructNames{idBSN}, ...
                           idDim1, ...
                           idDim2, ...
                           fieldSubVal);
                     end
                     if (idDim1 < size(fieldVal, 1))
                        fprintf(fidOut, ',\n');
                     else
                        fprintf(fidOut, '\n');
                     end
                  end
                  if (idDim2 < size(fieldVal, 2))
                     fprintf(fidOut, '      },\n');
                  else
                     fprintf(fidOut, '      }\n');
                  end
               end
               if (idBSN < length(metaStructNames))
                  fprintf(fidOut, '   ],\n');
               else
                  fprintf(fidOut, '   ]\n');
               end
            else
               fprintf('ERROR\n');
            end
         end
      end
   end
   
   fprintf(fidOut, '}\n');
   
   fclose(fidOut);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
function [o_metaStruct] = add_multi_dim_data( ...
   a_itemList, ...
   a_metaData, a_idForWmo, a_dimLevlist, ...
   a_metaStruct, a_mandatoryList1, a_mandatoryList2)

o_metaStruct = a_metaStruct;

dimLevListAll = [];
for idItem = 1:length(a_itemList)
   idF = find(strcmp(a_metaData(a_idForWmo, 5), a_itemList{idItem}) == 1);
   if (~isempty(idF))
      dimLevListAll = [dimLevListAll a_dimLevlist(a_idForWmo(idF))'];
   end
end
dimLevListAll = sort(unique(dimLevListAll));

for idItem = 1:length(a_itemList)
   idF = find(strcmp(a_metaData(a_idForWmo, 5), a_itemList{idItem}) == 1);
   if (~isempty(idF))
      val = cell(length(dimLevListAll), 1);
      dimLevList = a_dimLevlist(a_idForWmo(idF));
      for idL = 1:length(dimLevList)
         idLev = find(dimLevListAll == dimLevList(idL));
         val{idLev, 1} = a_metaData{a_idForWmo(idF(idL)), 4};
      end
      for idL = 1:length(dimLevListAll)
         if (isempty(val{idL, 1}))
            if (~isempty(find(strcmp(a_mandatoryList1, a_itemList{idItem}) == 1, 1)))
               val{idL, 1} = 'n/a';
            elseif (~isempty(find(strcmp(a_mandatoryList2, a_itemList{idItem}) == 1, 1)))
               val{idL, 1} = 'UNKNOWN';
            end
         end
      end
      o_metaStruct.(a_itemList{idItem}) = val;
   else
      if (~isempty(find(strcmp(a_mandatoryList1, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'n/a';
         end
         o_metaStruct.(a_itemList{idItem}) = val;
      elseif (~isempty(find(strcmp(a_mandatoryList2, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'UNKNOWN';
         end
         o_metaStruct.(a_itemList{idItem}) = val;
      end
   end
end

% idF = find(strcmp(a_metaData(a_idForWmo, 5), a_item) == 1);
% if (~isempty(idF))
%    dimLev = a_dimLevlist(a_idForWmo(idF));
%    [unused idSort] = sort(dimLev);
%    val = cell(length(dimLev), 1);
%    for id = 1:length(dimLev)
%       val{id, 1} = char(a_metaData(a_idForWmo(idF(idSort(id))), 4));
%    end
%    o_metaStruct = setfield(o_metaStruct, a_item, val);
% end

return;

% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_bdd_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   
   % old versions are all with a DELAI parameter
   % (CONFIG_DescentToProfTimeOut_hours)
   case {'1', '2.2', '2.6', '2.7', '3.21', '3.5', '3.61', '3.8', '3.81', '4.1', '4.11'}
      o_configStruct = struct( ...
         'CONFIG_MaxCycles_NUMBER', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_CycleTime_hours', 'CYCLE_TIME', ...
         'CONFIG_FloatReferenceDay_FloatDay', 'PRCFG_Reference_day', ...
         'CONFIG_ClockAscentStart_HH', 'PRCFG_Start_time', ...
         'CONFIG_DelayBeforeMissionStart_minutes', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_DescentToProfTimeOut_hours', '', ...
         'CONFIG_DescentToParkPresSamplingTime_seconds', 'DESC_PROFILE_PERIOD', ...
         'CONFIG_ParkSamplingPeriod_hours', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_AscentSamplingPeriod_seconds', 'ASC_PROFILE_PERIOD', ...
         'CONFIG_ParkPressure_dbar', 'PARKING_PRESSURE', ...
         'CONFIG_ProfilePressure_dbar', 'DEEPEST_PRESSURE', ...
         'CONFIG_PressureThresholdDataReduction_dbar', 'SHALLOW_DEEP_THRESHOLD', ...
         'CONFIG_ProfileSurfaceSlicesThickness_dbar', 'SURF_SLICE_THICKNESS', ...
         'CONFIG_ProfileBottomSlicesThickness_dbar', 'DEPTH_SLICE_THICKNESS', ...
         'CONFIG_TransmissionRepetitionPeriod_seconds', 'TRANS_REPETITION', ...
         'CONFIG_TransmissionMinTime_hours', 'CONFIG_TransMinTime_HOURS', ...
         'CONFIG_CTDPumpStopPressure_dbar', 'PRES_SBE_PUMP_SWITCH_OFF', ...
         'CONFIG_CTDPumpStopPressurePlusThreshold_dbar', '', ...
         'CONFIG_Direction_NUMBER', 'DIRECTION');
      
      % new version
   case {'4.0', '4.6', '4.61', '5.0', '5.1', '5.2', '5.5'}
      o_configStruct = struct( ...
         'CONFIG_MaxCycles_NUMBER', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_CycleTime_hours', 'CYCLE_TIME', ...
         'CONFIG_FloatReferenceDay_FloatDay', 'PRCFG_Reference_day', ...
         'CONFIG_ClockAscentStart_HH', 'PRCFG_Start_time', ...
         'CONFIG_DelayBeforeMissionStart_minutes', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_DescentToParkPresSamplingTime_seconds', 'DESC_PROFILE_PERIOD', ...
         'CONFIG_ParkSamplingPeriod_hours', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_AscentSamplingPeriod_seconds', 'ASC_PROFILE_PERIOD', ...
         'CONFIG_ParkPressure_dbar', 'PARKING_PRESSURE', ...
         'CONFIG_ProfilePressure_dbar', 'DEEPEST_PRESSURE', ...
         'CONFIG_PressureThresholdDataReductionShallowToIntermediate_dbar', 'INT_SURF_THRESHOLD', ...
         'CONFIG_PressureThresholdDataReductionIntermediateToDeep_dbar', 'DEPTH_INT_THRESHOLD', ...
         'CONFIG_ProfileSurfaceSlicesThickness_dbar', 'SURF_SLICE_THICKNESS', ...
         'CONFIG_ProfileIntermediateSlicesThickness_dbar', 'INT_SLICE_THICKNESS', ...
         'CONFIG_ProfileBottomSlicesThickness_dbar', 'DEPTH_SLICE_THICKNESS', ...
         'CONFIG_TransmissionRepetitionPeriod_seconds', 'TRANS_REPETITION', ...
         'CONFIG_TransmissionMinTime_hours', 'CONFIG_TransMinTime_HOURS', ...
         'CONFIG_InternalPressureCalibrationCoef1_NUMBER', 'PRCFG_Pressure_coefficient_A', ...
         'CONFIG_InternalPressureCalibrationCoef2_NUMBER', 'PRCFG_Pressure_coefficient_B', ...
         'CONFIG_CTDPumpStopPressure_dbar', 'PRES_SBE_PUMP_SWITCH_OFF', ...
         'CONFIG_CTDPumpStopPressurePlusThreshold_dbar', '', ...
         'CONFIG_Direction_NUMBER', 'DIRECTION');
      
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_argos_nke_old_versions for dacFormatId %s\n', a_dacFormatId);
end

return;

% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_bdd_struct()

% output parameters initialization
o_metaStruct = struct( ...
   'ARGO_USER_MANUAL_VERSION', '', ...
   'PLATFORM_NUMBER', '', ...
   'PTT', 'PTT', ...
   'IMEI', 'IMEI', ...
   'TRANS_SYSTEM', 'TRANS_SYSTEM', ...
   'TRANS_SYSTEM_ID', 'TRANS_SYSTEM_ID', ...
   'TRANS_FREQUENCY', 'TRANS_FREQUENCY', ...
   'POSITIONING_SYSTEM', 'POSITIONING_SYSTEM', ...
   'PLATFORM_FAMILY', 'PLATFORM_FAMILY', ...
   'PLATFORM_TYPE', 'PLATFORM_TYPE', ...
   'PLATFORM_MAKER', 'PLATFORM_MAKER', ...
   'FIRMWARE_VERSION', 'FIRMWARE_VERSION', ...
   'MANUAL_VERSION', 'MANUAL_VERSION', ...
   'FLOAT_SERIAL_NO', 'INST_REFERENCE', ...
   'STANDARD_FORMAT_ID', 'STANDARD_FORMAT_ID', ...
   'DAC_FORMAT_ID', 'PR_VERSION', ...
   'WMO_INST_TYPE', 'PR_PROBE_CODE', ...
   'PROJECT_NAME', 'PR_EXPERIMENT_ID', ...
   'DATA_CENTRE', 'DATA_CENTRE', ...
   'PI_NAME', 'PI_NAME', ...
   'ANOMALY', 'ANOMALY', ...
   'BATTERY_TYPE', 'BATTERY_TYPE', ...
   'BATTERY_PACKS', 'BATTERY_PACKS', ...
   'CONTROLLER_BOARD_TYPE_PRIMARY', 'CONTROLLER_BOARD_TYPE_PRIMARY', ...
   'CONTROLLER_BOARD_TYPE_SECONDARY', 'CONTROLLER_BOARD_TYPE_SECONDARY', ...
   'CONTROLLER_BOARD_SERIAL_NO_PRIMARY', 'CONTROLLER_BOARD_SERIAL_NO_PRIMA', ...
   'CONTROLLER_BOARD_SERIAL_NO_SECONDARY', 'CONTROLLER_BOARD_SERIAL_NO_SECON', ...
   'SPECIAL_FEATURES', 'SPECIAL_FEATURES', ...
   'FLOAT_OWNER', 'FLOAT_OWNER', ...
   'OPERATING_INSTITUTION', 'OPERATING_INSTITUTION', ...
   'CUSTOMISATION', 'CUSTOMISATION', ...
   'LAUNCH_DATE', 'PR_LAUNCH_DATETIME', ...
   'LAUNCH_LATITUDE', 'PR_LAUNCH_LATITUDE', ...
   'LAUNCH_LONGITUDE', 'PR_LAUNCH_LONGITUDE', ...
   'LAUNCH_QC', 'LAUNCH_QC', ...
   'START_DATE', 'START_DATE', ...
   'START_DATE_QC', 'START_DATE_QC', ...
   'STARTUP_DATE', '', ...
   'STARTUP_DATE_QC', '', ...
   'DEPLOYMENT_PLATFORM', 'DEPLOY_PLATFORM', ...
   'DEPLOYMENT_CRUISE_ID', 'DEPLOY_MISSION', ...
   'DEPLOYMENT_REFERENCE_STATION_ID', 'DEPLOY_AVAILABLE_PROFILE_ID', ...
   'END_MISSION_DATE', 'END_MISSION_DATE', ...
   'END_MISSION_STATUS', 'END_MISSION_STATUS', ...
   'PREDEPLOYMENT_CALIB_EQUATION', 'PREDEPLOYMENT_CALIB_EQUATION', ...
   'PREDEPLOYMENT_CALIB_COEFFICIENT', 'PREDEPLOYMENT_CALIB_COEFFICIENT', ...
   'PREDEPLOYMENT_CALIB_COMMENT', 'PREDEPLOYMENT_CALIB_COMMENT', ...
   'CALIB_RT_PARAMETER', 'CALIB_RT_PARAMETER', ...
   'CALIB_RT_EQUATION', 'CALIB_RT_EQUATION', ...
   'CALIB_RT_COEFFICIENT', 'CALIB_RT_COEFFICIENT', ...
   'CALIB_RT_COMMENT', 'CALIB_RT_COMMENT', ...
   'CALIB_RT_DATE', 'CALIB_RT_DATE');

return;

% ------------------------------------------------------------------------------
% Lecture des méta-données corrigées d'un flotteur.
%
% SYNTAX :
%  [o_ptt, o_missionNum, o_repRate, o_downTime, o_upTime, ...
%    o_cycleTime, o_parkPres, o_profPres, ...
%    o_launchDate, o_launchLon, o_launchLat, o_startUpDate] = ...
%    get_dep_meta_for_dep2(a_wmo, a_metaFileName)
%
% INPUT PARAMETERS :
%   a_wmo          : numéro WMO du flotteur concerné
%   a_metaFileName : fichier des méta-données
%
% OUTPUT PARAMETERS :
%   o_ptt         : Argos ou Iridium Id
%   o_missionNum  : numéro de mission
%   o_repRate     : repetition rate de la mission
%   o_downTime    : down time
%   o_upTime      : up time
%   o_cycleTime   : durée du cycle
%   o_parkPres    : pression de parking
%   o_profPres    : pression de profil
%   o_launchDate  : date de lâcher
%   o_launchLon   : longitude de lâcher
%   o_launchLat   : latitude de lâcher
%   o_startUpDate : date de descente pour le premier cycle
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   25/08/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ptt, o_missionNum, o_repRate, o_downTime, o_upTime, ...
   o_cycleTime, o_parkPres, o_profPres, ...
   o_launchDate, o_launchLon, o_launchLat, o_startUpDate] = ...
   get_dep_meta_for_dep2(a_wmo, a_metaFileName)

% output parameters initialization
o_ptt = [];
o_missionNum = [];
o_repRate = [];
o_downTime = [];
o_upTime = [];
o_cycleTime = [];
o_parkPres = [];
o_profPres = [];
o_launchDate = [];
o_launchLon = [];
o_launchLat = [];
o_startUpDate = [];


% ouverture du de méta données
fId = fopen(a_metaFileName, 'r');
if (fId == -1)
   fprintf('Erreur ouverture fichier : %s\n', a_metaFileName);
   return;
end

% lecture et stockage des données du fichier DEP
metaData = textscan(fId, '%u %d64 %u %u %d %d %f %u %u %s %s %f %f %s %s');

wmoTab = metaData{1}(:);
idF = find(wmoTab == a_wmo);
if (~isempty(idF))
   o_ptt = metaData{2}(idF);
   o_ptt(find(o_ptt == -1)) = [];
   if (isempty(o_ptt))
      o_ptt = -1;
   end
   o_ptt = unique(o_ptt);
   o_missionNum = metaData{3}(idF);
   o_repRate = metaData{4}(idF);
   o_downTime = metaData{5}(idF);
   o_upTime = metaData{6}(idF);
   o_cycleTime = metaData{7}(idF);
   o_parkPres = metaData{8}(idF);
   o_profPres = metaData{9}(idF);
   launchDateGregDay = metaData{10}(idF);
   launchDateGregHour = metaData{11}(idF);
   o_launchDate = compute_juld(launchDateGregDay, launchDateGregHour, 1);
   o_launchLon = metaData{12}(idF);
   o_launchLat = metaData{13}(idF);
   o_launchLon = o_launchLon(1);
   o_launchLat = o_launchLat(1);
   startUpDateGregDay = metaData{14}(idF);
   startUpDateGregHour = metaData{15}(idF);
   o_startUpDate = compute_juld(startUpDateGregDay, startUpDateGregHour, 0);
else
   fprintf('ERROR: float #%d is not in file %s\n', a_wmo, a_metaFileName);
end

fclose(fId);

return;

% ------------------------------------------------------------------------------
% Calcul des dates juliennes à partir des dates grégoriennes.
%
% SYNTAX :
% [o_julD] = compute_juld(a_dayStr, a_hourStr, , a_reOrder)
%
% INPUT PARAMETERS :
%   a_dayStr  : partie jour de la date grégorienne (yyyy/mm/jj)
%   a_hourStr : partie heure de la date grégorienne (hh:mm:ss)
%   a_reOrder : 1 si les jour sont au format (jj/mm/yyyy)
%
% OUTPUT PARAMETERS :
%   o_julD : date julienne calculée
%
% EXAMPLES :
%
% SEE ALSO : init_valdef, gregorian_2_julian
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   13/05/2008 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julD] = compute_juld(a_dayStr, a_hourStr, a_reOrder)

o_julD = '';

dateGregStr = '9999/99/99 99:99:99';

nbDates = length(a_dayStr);
for idDate = 1:nbDates
   day = a_dayStr{idDate};
   hour = a_hourStr{idDate};
   if (a_reOrder == 1)
      idF = findstr(day, '/');
      day = [day(idF(end)+1:end) '/' day(idF(1)+1:idF(2)-1) '/' day(1:idF(1)-1)];
   end
   if (strcmp([day ' ' hour], dateGregStr) == 0)
      o_julD = gregorian_2_julian_dec_argo([day ' ' hour]);
      break;
   end
end

% ------------------------------------------------------------------------------
% Get floats information from floats information file.
%
% SYNTAX :
%  [o_listWmoNum o_listDecId o_listArgosId o_listFrameLen ...
%    o_listCycleTime o_listDriftSamplingPeriod o_listRefDay] = ...
%    get_floats_info_for_dep2(a_floatInfoFileName)
%
% INPUT PARAMETERS :
%   a_floatInfoFileName : Excel float information file name
%
% OUTPUT PARAMETERS :
%   o_listWmoNum          : floats WMO number
%   o_listDecId           : floats decoder Id
%   o_listArgosId         : floats PTT number
%   o_listFrameLen        : floats data frame length
%   o_listCycleTime       : floats cycle duration
%   o_driftSamplingPeriod : sampling period during drift phase (in hours)
%   o_listDelay           : DELAI parameter (in hours)
%   o_listLaunchDate      : floats launch date
%   o_listRefDay          : floats reference day (day of the first descent)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_listWmoNum, o_listDecId, o_listArgosId, o_listFrameLen, ...
   o_listCycleTime, o_listDriftSamplingPeriod, o_listDelay, o_listLaunchDate, ...
   o_listRefDay] = ...
   get_floats_info_for_dep2(a_floatInfoFileName)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_listWmoNum = [];
o_listDecId = [];
o_listArgosId = [];
o_listFrameLen = [];
o_listCycleTime = [];
o_listDriftSamplingPeriod = [];
o_listDelay = [];
o_listLaunchDate = [];
o_listRefDay = [];

if ~(~exist(a_floatInfoFileName, 'dir') && exist(a_floatInfoFileName, 'file'))
   fprintf('Float information file not found: %s\n', a_floatInfoFileName);
   return;
end

fId = fopen(a_floatInfoFileName, 'r');
if (fId == -1)
   fprintf('Error in opening file : %s\n', a_floatInfoFileName);
end

data = textscan(fId, '%d %d %s %d %d %d %d %s %s');

o_listWmoNum = data{1}(:);
o_listDecId = data{2}(:);
o_listArgosId = data{3}(:);
o_listFrameLen = data{4}(:);
o_listCycleTime = data{5}(:);
o_listDriftSamplingPeriod = data{6}(:);
o_listDelay = data{7}(:);
listLaunchDate = data{8}(:);
listRefDay = data{9}(:);

fclose(fId);

% data = load(a_floatInfoFileName);
% 
% o_listWmoNum = data(:, 1);
% o_listDecId = data(:, 2);
% o_listArgosId = uint64(data(:, 3));
% o_listFrameLen = data(:, 4);
% o_listCycleTime = data(:, 5);
% o_listDriftSamplingPeriod = data(:, 6);
% o_listDelay = data(:, 7);
% listLaunchDate = data(:, 8);
% listRefDay = data(:, 9);

o_listLaunchDate = ones(length(listRefDay), 1)*g_decArgo_dateDef;
o_listRefDay = ones(length(listRefDay), 1)*g_decArgo_dateDef;
for id = 1:length(listRefDay)
   launchDate = char(listLaunchDate(id));
   refDay = char(listRefDay(id));
   if (length(launchDate) == 14)
      o_listLaunchDate(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
         launchDate(1:4), launchDate(5:6), launchDate(7:8), ...
         launchDate(9:10), launchDate(11:12), launchDate(13:14)));
      o_listRefDay(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s 00:00:00', ...
         refDay(1:4), refDay(5:6), refDay(7:8)));
   end
end

return;
