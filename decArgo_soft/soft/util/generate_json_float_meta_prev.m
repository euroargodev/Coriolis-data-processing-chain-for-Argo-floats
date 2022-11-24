% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in
% individual json files.
%
% SYNTAX :
%  generate_json_float_meta()
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
%   04/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta()

% meta-data file exported from Coriolis data base
floatMetaFileName = 'C:\users\RNU\Argo\Aco\12833_update_decPrv_pour_RT_TRAJ3\configParamNames\meta_PRV_REFERENCE_20140716.txt';
floatMetaFileName = 'C:\users\RNU\Argo\Aco\12833_update_decPrv_pour_RT_TRAJ3\configParamNames\meta_PRV_from_VB_REFERENCE_20140924.txt';
floatMetaFileName = 'C:\users\RNU\Argo\Aco\12833_update_decPrv_pour_RT_TRAJ3\configParamNames\meta_PRV_from_VB_REFERENCE_20141001.txt';
floatMetaFileName = 'C:\users\RNU\Argo\Aco\12833_update_decPrv_pour_RT_TRAJ3\configParamNames\meta_PRV_from_VB_REFERENCE_20141205.txt';

fprintf('Generating json meta-data files from input file: %s\n', floatMetaFileName);

% list of concerned floats
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/nke_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.5_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.42_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.44_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.45_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.43_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.23_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.51_all.txt';
floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.2_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.21_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.22_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.4_all.txt';
% floatListFileName = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/coriolis_prv_4.41_all.txt';

fprintf('Generating json meta-data files for floats of the list: %s\n', floatListFileName);

% directory of individual json float meta-data files
outputDirName = ['C:\users\RNU\Argo\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];


% list of floats which profile during descent
profDuringDescFloatList = [69000	69001	69002	69003	69004	69005	69030	69031	69032	69034	69035	69036	69037	69038	69039	69040	69041	69042	69043	69044	1900341	1900342	3900999	3901000	6900045	6900046	6900047	6900048	6900383	6900384	6900385	6900386	6900677	6900680	6900681	6900682	6900683];

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
% floatList = [3901000];
% floatList = [6901881];
% floatList = [6900708];

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('Meta-data not found for float: %d\n', notFoundFloat);
end

for idFloat = 1:length(floatList)
   
   fprintf('%3d/%3d %d\n', idFloat, length(floatList), floatList(idFloat));
      
   % initialize the structure to be filled
   metaStruct = get_meta_init_struct();

   metaStruct.PLATFORM_NUMBER = num2str(floatList(idFloat));
   metaStruct.ARGO_USER_MANUAL_VERSION = '3.1';
   
   % direct conversion data
   idForWmo = find(wmoList == floatList(idFloat));
   for idBSN = 1:length(metaBddStructNames)
      metaBddStructValue = getfield(metaBddStruct, char(metaBddStructNames(idBSN)));
      if (~isempty(metaBddStructValue))
         idF = find(strcmp(metaData(idForWmo, 5), metaBddStructValue) == 1, 1);
         if (~isempty(idF))
            metaStruct = setfield(metaStruct, char(metaBddStructNames(idBSN)), char(metaData(idForWmo(idF), 4)));
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
      metaStruct);

   [metaStruct] = add_multi_dim_data( ...
      {'POSITIONING_SYSTEM'}, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct);
   
   itemList = [ ...
      {'SENSOR'} ...
      {'SENSOR_MAKER'} ...
      {'SENSOR_MODEL'} ...
      {'SENSOR_SERIAL_NO'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct);

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
      metaStruct);
   
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
      metaStruct);
   
   % configuration parameters
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = getfield(metaStruct, 'DAC_FORMAT_ID');
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d => no json file generated\n', ...
         floatList(idFloat));
      continue;
   end
   
   % CONFIG_PARAMETER_NAME
   configStruct = get_config_init_struct(dacFormatId);
   configStructNames = fieldnames(configStruct);
   metaStruct.CONFIG_PARAMETER_NAME = configStructNames;
   
   % CONFIG_PARAMETER_VALUE
   idFRepRate = find(strcmp(metaData(idForWmo, 5), 'REPETITION_RATE') == 1);
   if (~isempty(idFRepRate))
      
      configBddStruct = get_config_bdd_struct(dacFormatId);
      configBddStructNames = fieldnames(configBddStruct);
      
      nbConfig = length(idFRepRate);
      if (nbConfig > 1)
         fprintf('Multi conf: %d\n', floatList(idFloat));
      end
      configParamVal = cell(length(configStructNames), nbConfig);
      configRepRate = cell(1, nbConfig);
      for idConf = 1:nbConfig
         configRepRate{1, idConf} = char(metaData(idForWmo(idFRepRate(idConf)), 4));
         for idBSN = 1:length(configBddStructNames)
            configBddStructName = char(configBddStructNames(idBSN));
            if ((strcmp(configBddStructName, 'CONFIG_PM2_ReferenceDay') == 0) && ...
                  (strcmp(configBddStructName, 'CONFIG_PM3_AscentStartTime') == 0) && ...
                  (strcmp(configBddStructName, 'CONFIG_PM3_EstimatedSurfaceTime') == 0))
               configBddStructValue = getfield(configBddStruct, configBddStructName);
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
                           (strcmp(configBddStructValue, 'CYCLE_TIME') == 0) && ...
                           (strcmp(configBddStructValue, 'PR_IMMERSION_DRIFT_PERIOD') == 0) && ...
                           (strncmp(configBddStructValue, 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 0))
                        configParamVal{idBSN, idConf} = char(metaData(idForWmo(idF(idDim)), 4));
                     else
                        if (strcmp(configBddStructValue, 'DIRECTION') == 1)
                           if (ismember(floatList(idFloat), profDuringDescFloatList))
                              configParamVal{idBSN, idConf} = '3';
                           else
                              configParamVal{idBSN, idConf} = '1';
                           end
                           %                               % change convention for 'DIRECTION' parameter
                           %                               if (char(metaData(idForWmo(idF(idDim)), 4)) == 'A')
                           %                                  configParamVal{idBSN, idConf} = '1';
                           %                               elseif (char(metaData(idForWmo(idF(idDim)), 4)) == 'B')
                           %                                  configParamVal{idBSN, idConf} = '2';
                           %                               end
                        elseif (strcmp(configBddStructValue, 'CYCLE_TIME') == 1)
                           configParamVal{idBSN, idConf} = num2str(str2num(char(metaData(idForWmo(idF(idDim)), 4)))/24);
                        elseif (strcmp(configBddStructValue, 'PR_IMMERSION_DRIFT_PERIOD') == 1)
                           configParamVal{idBSN, idConf} = num2str(str2num(char(metaData(idForWmo(idF(idDim)), 4)))/60);
                        elseif (strncmp(configBddStructValue, 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1)
                           % processed below
                        end
                     end
                  end
               else
                  % if we want to use default values if the information is
                  % missing in the database
                  %                      configParamVal{idBSN, idConf} = getfield(configStruct, configBddStructName);
               end
            else
               if (strcmp(configBddStructName, 'CONFIG_PM2_ReferenceDay') == 1)
                  idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_Reference_day') == 1);
                  if (~isempty(idF0))
                     configParamVal{idBSN, idConf} = char(metaData(idForWmo(idF0), 4));
                  else
                     idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                     idF2 = find(strcmp(metaData(idForWmo, 5), 'PR_LAUNCH_DATETIME') == 1);
                     if ~(isempty(idF1) || isempty(idF2))
                        refDate = datenum(char(metaData(idForWmo(idF1), 4)), 'dd/mm/yyyy HH:MM');
                        launchDate = datenum(char(metaData(idForWmo(idF2), 4)), 'dd/mm/yyyy HH:MM');
                        configParamVal{idBSN, idConf} = num2str(fix(refDate) - fix(launchDate));
                     end
                  end
               elseif (strcmp(configBddStructName, 'CONFIG_PM3_AscentStartTime') == 1)
                  idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_Start_time') == 1);
                  if (~isempty(idF0))
                     configParamVal{idBSN, idConf} = sprintf('%02d', str2num(metaData{idForWmo(idF0), 4}));
                  else
                     idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                     if (~isempty(idF1))
                        refDate = datenum(char(metaData(idForWmo(idF1), 4)), 'dd/mm/yyyy HH:MM');
                        configParamVal{idBSN, idConf} = datestr(refDate, 'HH');
                     end
                  end
               elseif (strcmp(configBddStructName, 'CONFIG_PM3_EstimatedSurfaceTime') == 1)
                  idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_End_time') == 1);
                  if (~isempty(idF0))
                     configParamVal{idBSN, idConf} = sprintf('%02d', str2num(metaData{idForWmo(idF0), 4}));
                  else
                     idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                     if (~isempty(idF1))
                        refDate = datenum(char(metaData(idForWmo(idF1), 4)), 'dd/mm/yyyy HH:MM');
                        configParamVal{idBSN, idConf} = datestr(refDate, 'HH');
                     end
                  end
               end
            end
         end
      end
      
      % the configuration with idConf=1 SHOULD be the configuration of the
      % float for the cycle #1 (not for the first cycle which is #0)
            
      % add a first configuration, specific to float version (with or
      % without a prelude phase)
      switch (dacFormatId)
         case {'4.2', '4.21', '4.22', '4.4', '4.41', '4.5'}
            % floats without a prelude phase: cycle #0 is the first deep
            % cycle; it has a shorter duration and the float profiles during
            % descent
            
            % the configuration is based on the last one
            configParamVal0 = configParamVal(:, end);
            
            % set the descending sampling period
            idDescSampPeriod = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM5_DescentSamplingPeriod') == 1);
            idAscSampPeriod = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM7_AscentSamplingPeriod') == 1);
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
            idCycleTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM1_CyclePeriod') == 1);
            if ~(isempty(idCycleTime))
               configParamVal0{idCycleTime} = '';
            end
            
            idCycleTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM1_CyclePeriod') == 1);
            idRefDay = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM2_ReferenceDay') == 1);
            idAscentStartTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM3_AscentStartTime') == 1);
            idProfileDepth = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM9_ProfileDepth') == 1);
            if (strcmp(dacFormatId, '4.5') == 1)
               idArgosTransmissionDuration = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PA3_ArgosTransmissionDuration') == 1);
            else
               idArgosTransmissionDuration = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PA2_ArgosTransmissionDuration') == 1);
            end
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
         case {'4.23', '4.42', '4.43', '4.44', '4.45', '4.51'}
            % floats with a prelude phase: cycle #0 is a surface cycle,
            % cycle #0 is a deep cycle 
            % (shorter duration and profile during descent)
            
            % floats with a prelude phase: cycle #0 is a surface cycle,
            % cycle #1 is the first deep cycle; it has a shorter duration and
            % the float profiles during descent

            % the configuration is based on the first one
            configParamVal0 = configParamVal(:, 1);
            
            % set the descending sampling period
            idDescSampPeriod = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM5_DescentSamplingPeriod') == 1);
            idAscSampPeriod = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM7_AscentSamplingPeriod') == 1);
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
            
            % compute the duration of the cycle #1
            idCycleTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM1_CyclePeriod') == 1);
            if ~(isempty(idCycleTime))
               configParamVal0{idCycleTime} = '';
            end
            
            idCycleTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM1_CyclePeriod') == 1);
            idRefDay = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM2_ReferenceDay') == 1);
            idEstimatedSurfaceTime = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PM3_EstimatedSurfaceTime') == 1);
            idArgosTransmissionDuration = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PA3_ArgosTransmissionDuration') == 1);
            if ~(isempty(idCycleTime) || isempty(idRefDay) || ...
                  isempty(idEstimatedSurfaceTime) || ...
                  isempty(idArgosTransmissionDuration))

               refDay = configParamVal0{idRefDay};
               estimatedSurfaceTime = configParamVal0{idEstimatedSurfaceTime};
               argosTransmissionDuration = configParamVal0{idArgosTransmissionDuration};
               
               if ~(isempty(refDay) || isempty(estimatedSurfaceTime) || ...
                     isempty(argosTransmissionDuration))
                  
                  firstDeepCycleDuration = str2num(refDay) + ...
                     str2num(estimatedSurfaceTime)/24 + ...
                     str2num(argosTransmissionDuration)/24;

                  configParamVal0{idCycleTime} = num2str(firstDeepCycleDuration);
               end
            end
         otherwise
            fprintf('WARNING: Nothing done yet in generate_json_float_meta for dacFormatId %s\n', dacFormatId);
      end
      
      idDir = find(strcmp(metaStruct.CONFIG_PARAMETER_NAME, 'CONFIG_PX0_Direction') == 1);
      if (~isempty(idDir))
         configParamVal0{idDir} = '3';
      end
      
      configParamVal = [configParamVal0 configParamVal];
      
      metaStruct.CONFIG_REPETITION_RATE = configRepRate;
      metaStruct.CONFIG_PARAMETER_VALUE = configParamVal;
   end
   
   % CALIBRATION_COEFFICIENT
   switch (dacFormatId)
      case {'4.4', '4.41', '4.43'}
         idF = find(strcmp(metaData(idForWmo, 5), 'DOXY_CALIB_REF_SALINITY') == 1);
         if (~isempty(idF))
            calibrationCoefficient = [];
            calibrationCoefficient.OPTODE.DoxyCalibRefSalinity = char(metaData(idForWmo(idF(1)), 4));
            
            metaStruct.CALIBRATION_COEFFICIENT = calibrationCoefficient;
         end
      case {'4.42'}
         idF = find(strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1);
         calibData = [];
         for id = 1:length(idF)
            calibName = char(metaData(idForWmo(idF(id)), 5));
            fieldName = ['SVUFoilCoef' num2str(str2num(calibName(end)))];
            calibData.(fieldName) = char(metaData(idForWmo(idF(id)), 4));
         end
         if (~isempty(calibData))
            calibrationCoefficient = [];
            calibrationCoefficient.OPTODE = calibData;
            
            metaStruct.CALIBRATION_COEFFICIENT = calibrationCoefficient;
         end
      case {'4.44'}
         idF = find((strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_COEFF_A', length('AANDERAA_OPTODE_FOIL_COEFF_A')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_COEFF_B', length('AANDERAA_OPTODE_FOIL_COEFF_B')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_POLYDEG_T', length('AANDERAA_OPTODE_FOIL_POLYDEG_T')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_POLYDEG_O', length('AANDERAA_OPTODE_FOIL_POLYDEG_O')) == 1));
         calibData = [];
         for id = 1:length(idF)
            calibName = char(metaData(idForWmo(idF(id)), 5));
            if (strncmp(calibName, 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1)
               fieldName = ['TempCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1)
               fieldName = ['PhaseCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_COEFF_A', length('AANDERAA_OPTODE_FOIL_COEFF_A')) == 1)
               fieldName = ['FoilCoefA' calibName(length('AANDERAA_OPTODE_FOIL_COEFF_A')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_COEFF_B', length('AANDERAA_OPTODE_FOIL_COEFF_B')) == 1)
               fieldName = ['FoilCoefB' calibName(length('AANDERAA_OPTODE_FOIL_COEFF_B')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_POLYDEG_T', length('AANDERAA_OPTODE_FOIL_POLYDEG_T')) == 1)
               fieldName = ['FoilPolyDegT' calibName(length('AANDERAA_OPTODE_FOIL_POLYDEG_T')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_POLYDEG_O', length('AANDERAA_OPTODE_FOIL_POLYDEG_O')) == 1)
               fieldName = ['FoilPolyDegO' calibName(length('AANDERAA_OPTODE_FOIL_POLYDEG_O')+1:end)];
            end
            calibData.(fieldName) = char(metaData(idForWmo(idF(id)), 4));
         end
         if (~isempty(calibData))
            calibrationCoefficient = [];
            calibrationCoefficient.OPTODE = calibData;
            
            metaStruct.CALIBRATION_COEFFICIENT = calibrationCoefficient;
         end
      case {'4.45'}
         idF = find((strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_CONC_COEF_', length('AANDERAA_OPTODE_CONC_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_COEFF_A', length('AANDERAA_OPTODE_FOIL_COEFF_A')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_COEFF_B', length('AANDERAA_OPTODE_FOIL_COEFF_B')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_POLYDEG_T', length('AANDERAA_OPTODE_FOIL_POLYDEG_T')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_POLYDEG_O', length('AANDERAA_OPTODE_FOIL_POLYDEG_O')) == 1));
         calibData = [];
         for id = 1:length(idF)
            calibName = char(metaData(idForWmo(idF(id)), 5));
            if (strncmp(calibName, 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1)
               fieldName = ['TempCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1)
               fieldName = ['PhaseCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_CONC_COEF_', length('AANDERAA_OPTODE_CONC_COEF_')) == 1)
               fieldName = ['ConcCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_COEFF_A', length('AANDERAA_OPTODE_FOIL_COEFF_A')) == 1)
               fieldName = ['FoilCoefA' calibName(length('AANDERAA_OPTODE_FOIL_COEFF_A')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_COEFF_B', length('AANDERAA_OPTODE_FOIL_COEFF_B')) == 1)
               fieldName = ['FoilCoefB' calibName(length('AANDERAA_OPTODE_FOIL_COEFF_B')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_POLYDEG_T', length('AANDERAA_OPTODE_FOIL_POLYDEG_T')) == 1)
               fieldName = ['FoilPolyDegT' calibName(length('AANDERAA_OPTODE_FOIL_POLYDEG_T')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_POLYDEG_O', length('AANDERAA_OPTODE_FOIL_POLYDEG_O')) == 1)
               fieldName = ['FoilPolyDegO' calibName(length('AANDERAA_OPTODE_FOIL_POLYDEG_O')+1:end)];
            end
            calibData.(fieldName) = char(metaData(idForWmo(idF(id)), 4));
         end
         if (~isempty(calibData))
            calibrationCoefficient = [];
            calibrationCoefficient.OPTODE = calibData;
            
            metaStruct.CALIBRATION_COEFFICIENT = calibrationCoefficient;
         end
   end
   
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
      rtOffsetValue = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_COEFFICIENT') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['VALUE_' num2str(dimLevel)];
         value = metaData{idForWmo(idF(id)), 4};
         idPos = strfind(value, 'a0=');
         if (~isempty(idPos))
            rtOffsetValue.(fieldName) = value(idPos+3:end);
         else
            fprintf('ERROR: while parsing CALIB_RT_COEFFICIENT for float %d => exit\n', floatList(idFloat));
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
      rtOffsetData.VALUE = rtOffsetValue;
      rtOffsetData.DATE = rtOffsetDate;
      
      metaStruct.RT_OFFSET = rtOffsetData;
   end
   
   % create the directory of json output files
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
   
   % create the json output files
   outputFileName = [outputDirName '/' sprintf('%d_meta.json', floatList(idFloat))];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
      return;
   end
   
   fprintf(fidOut, '{\n');
   
   metaStructNames = fieldnames(metaStruct);
   for idBSN = 1:length(metaStructNames)
      fprintf(fidOut, '   "%s" : ', char(metaStructNames(idBSN)));
      fieldVal = getfield(metaStruct, char(metaStructNames(idBSN)));
      if (strcmp(metaStructNames{idBSN}, 'CALIBRATION_COEFFICIENT') == 1)
         fieldVal = getfield(metaStruct, metaStructNames{idBSN});
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
         fieldVal = getfield(metaStruct, metaStructNames{idBSN});
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
         fieldVal = getfield(metaStruct, metaStructNames{idBSN});
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
                           char(metaStructNames(idBSN)), ...
                           idDim1, ...
                           fieldSubVal);
                     else
                        fprintf(fidOut, '      "%s_%d_%d" : "%s"', ...
                           char(metaStructNames(idBSN)), ...
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

return;

% ------------------------------------------------------------------------------
function [o_metaStruct] = add_multi_dim_data( ...
   a_itemList, ...
   a_metaData, a_idForWmo, a_dimLevlist, ...
   a_metaStruct, a_mandatoryList)

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
         val{idLev, 1} = char(a_metaData(a_idForWmo(idF(idL)), 4));
      end
      for idL = 1:length(dimLevListAll)
         if (isempty(val{idL, 1}))
            val{idL, 1} = 'n/a';
         end
      end
      o_metaStruct.(a_itemList{idItem}) = val;
   else
      if (~isempty(find(strcmp(a_mandatoryList, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'n/a';
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
function [o_configStruct] = get_config_init_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'4.2', '4.21', '4.22', '4.4', '4.41'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', '255', ...
         'CONFIG_PM1_CyclePeriod', '10', ...
         'CONFIG_PM2_ReferenceDay', '2', ...
         'CONFIG_PM3_AscentStartTime', '23', ...
         'CONFIG_PM4_DelayBeforeMission', '0', ...
         'CONFIG_PM5_DescentSamplingPeriod', '0', ...
         'CONFIG_PM6_DriftSamplingPeriod', '12', ...
         'CONFIG_PM7_AscentSamplingPeriod', '10', ...
         'CONFIG_PM8_DriftDepth', '1000', ...
         'CONFIG_PM9_ProfileDepth', '2000', ...
         'CONFIG_PM10_DelayBeforeProfile', '10', ...
         'CONFIG_PM11_ThresholdSurfaceBottomPressure', '200', ...
         'CONFIG_PM12_ThicknessOfTheSurfaceSlices', '10', ...
         'CONFIG_PM13_ThicknessOfTheBottomSlices', '25', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', '40', ...
         'CONFIG_PA1_Retransmission', '25', ...
         'CONFIG_PA2_ArgosTransmissionDuration', '6', ...
         'CONFIG_PX0_Direction', '');
   case {'4.5'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', '255', ...
         'CONFIG_PM1_CyclePeriod', '10', ...
         'CONFIG_PM2_ReferenceDay', '2', ...
         'CONFIG_PM3_AscentStartTime', '23', ...
         'CONFIG_PM4_DelayBeforeMission', '0', ...
         'CONFIG_PM5_DescentSamplingPeriod', '0', ...
         'CONFIG_PM6_DriftSamplingPeriod', '12', ...
         'CONFIG_PM7_AscentSamplingPeriod', '10', ...
         'CONFIG_PM8_DriftDepth', '1000', ...
         'CONFIG_PM9_ProfileDepth', '2000', ...
         'CONFIG_PM10_ThresholdSurfaceBottomPressure', '200', ...
         'CONFIG_PM11_ThicknessOfTheSurfaceSlices', '10', ...
         'CONFIG_PM12_ThicknessOfTheBottomSlices', '25', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', '40', ...
         'CONFIG_PA1_ArgosEolPeriod', '100', ...
         'CONFIG_PA2_Retransmission', '25', ...
         'CONFIG_PA3_ArgosTransmissionDuration', '1', ...
         'CONFIG_PA6_PreludeDuration', '180', ...
         'CONFIG_PX0_Direction', '');
   case {'4.23', '4.51', '4.43'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', '255', ...
         'CONFIG_PM1_CyclePeriod', '10', ...
         'CONFIG_PM2_ReferenceDay', '2', ...
         'CONFIG_PM3_EstimatedSurfaceTime', '6', ...
         'CONFIG_PM4_DelayBeforeMission', '0', ...
         'CONFIG_PM5_DescentSamplingPeriod', '0', ...
         'CONFIG_PM6_DriftSamplingPeriod', '12', ...
         'CONFIG_PM7_AscentSamplingPeriod', '10', ...
         'CONFIG_PM8_DriftDepth', '1000', ...
         'CONFIG_PM9_ProfileDepth', '2000', ...
         'CONFIG_PM10_ThresholdSurfaceMiddlePressure', '10', ...
         'CONFIG_PM11_ThresholdMiddleBottomPressure', '200', ...
         'CONFIG_PM12_ThicknessOfTheSurfaceSlices', '1', ...
         'CONFIG_PM13_ThicknessOfTheMiddleSlices', '10', ...
         'CONFIG_PM14_ThicknessOfTheBottomSlices', '25', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', '40', ...
         'CONFIG_PA1_ArgosEolPeriod', '100', ...
         'CONFIG_PA2_Retransmission', '25', ...
         'CONFIG_PA3_ArgosTransmissionDuration', '1', ...
         'CONFIG_PA6_PreludeDuration', '180', ...
         'CONFIG_PX0_Direction', '');
   case {'4.42', '4.44', '4.45'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', '255', ...
         'CONFIG_PM1_CyclePeriod', '10', ...
         'CONFIG_PM2_ReferenceDay', '2', ...
         'CONFIG_PM3_EstimatedSurfaceTime', '6', ...
         'CONFIG_PM4_DelayBeforeMission', '0', ...
         'CONFIG_PM5_DescentSamplingPeriod', '0', ...
         'CONFIG_PM6_DriftSamplingPeriod', '12', ...
         'CONFIG_PM7_AscentSamplingPeriod', '10', ...
         'CONFIG_PM8_DriftDepth', '1000', ...
         'CONFIG_PM9_ProfileDepth', '2000', ...
         'CONFIG_PM10_ThresholdSurfaceMiddlePressure', '10', ...
         'CONFIG_PM11_ThresholdMiddleBottomPressure', '200', ...
         'CONFIG_PM12_ThicknessOfTheSurfaceSlices', '1', ...
         'CONFIG_PM13_ThicknessOfTheMiddleSlices', '10', ...
         'CONFIG_PM14_ThicknessOfTheBottomSlices', '25', ...
         'CONFIG_PT20_CTDPumpSwitchOffPres', '5', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', '40', ...
         'CONFIG_PA1_ArgosEolPeriod', '100', ...
         'CONFIG_PA2_Retransmission', '25', ...
         'CONFIG_PA3_ArgosTransmissionDuration', '1', ...
         'CONFIG_PA6_PreludeDuration', '180', ...
         'CONFIG_PX0_Direction', '');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta for dacFormatId %s\n', a_dacFormatId);
end

return;

% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_bdd_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'4.2', '4.21', '4.22', '4.4', '4.41'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_PM1_CyclePeriod', 'CYCLE_TIME', ...
         'CONFIG_PM2_ReferenceDay', 'PRCFG_Reference_day', ...
         'CONFIG_PM3_AscentStartTime', 'PRCFG_Start_time', ...
         'CONFIG_PM4_DelayBeforeMission', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_PM5_DescentSamplingPeriod', 'DESC_PROFILE_PERIOD', ...
         'CONFIG_PM6_DriftSamplingPeriod', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_PM7_AscentSamplingPeriod', 'ASC_PROFILE_PERIOD', ...
         'CONFIG_PM8_DriftDepth', 'PARKING_PRESSURE', ...
         'CONFIG_PM9_ProfileDepth', 'DEEPEST_PRESSURE', ...
         'CONFIG_PM10_DelayBeforeProfile', 'DEEP_PROFILE_DESCENT_DELAY', ...
         'CONFIG_PM11_ThresholdSurfaceBottomPressure', 'SHALLOW_DEEP_THRESHOLD', ...
         'CONFIG_PM12_ThicknessOfTheSurfaceSlices', 'SURF_SLICE_THICKNESS', ...
         'CONFIG_PM13_ThicknessOfTheBottomSlices', 'DEPTH_SLICE_THICKNESS', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', 'TRANS_REPETITION', ...
         'CONFIG_PA1_Retransmission', 'CONFIG_TeleRepetition_COUNT', ...
         'CONFIG_PA2_ArgosTransmissionDuration', 'CONFIG_TransMinTime_HOURS', ...
         'CONFIG_PX0_Direction', 'DIRECTION');
   case {'4.5'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_PM1_CyclePeriod', 'CYCLE_TIME', ...
         'CONFIG_PM2_ReferenceDay', 'PRCFG_Reference_day', ...
         'CONFIG_PM3_AscentStartTime', 'PRCFG_Start_time', ...
         'CONFIG_PM4_DelayBeforeMission', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_PM5_DescentSamplingPeriod', 'DESC_PROFILE_PERIOD', ...
         'CONFIG_PM6_DriftSamplingPeriod', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_PM7_AscentSamplingPeriod', 'ASC_PROFILE_PERIOD', ...
         'CONFIG_PM8_DriftDepth', 'PARKING_PRESSURE', ...
         'CONFIG_PM9_ProfileDepth', 'DEEPEST_PRESSURE', ...
         'CONFIG_PM10_ThresholdSurfaceBottomPressure', 'SHALLOW_DEEP_THRESHOLD', ...
         'CONFIG_PM11_ThicknessOfTheSurfaceSlices', 'SURF_SLICE_THICKNESS', ...
         'CONFIG_PM12_ThicknessOfTheBottomSlices', 'DEPTH_SLICE_THICKNESS', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', 'TRANS_REPETITION', ...
         'CONFIG_PA1_ArgosEolPeriod', 'PRCFG_EOL_trans_period', ...
         'CONFIG_PA2_Retransmission', 'CONFIG_TeleRepetition_COUNT', ...
         'CONFIG_PA3_ArgosTransmissionDuration', 'CONFIG_TransMinTime_HOURS', ...
         'CONFIG_PA6_PreludeDuration', 'CONFIG_PreludeDuration_MINUTES', ...
         'CONFIG_PX0_Direction', 'DIRECTION');
   case {'4.23', '4.51', '4.43'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_PM1_CyclePeriod', 'CYCLE_TIME', ...
         'CONFIG_PM2_ReferenceDay', 'PRCFG_Reference_day', ...
         'CONFIG_PM3_EstimatedSurfaceTime', 'PRCFG_End_time', ...
         'CONFIG_PM4_DelayBeforeMission', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_PM5_DescentSamplingPeriod', 'DESC_PROFILE_PERIOD', ...
         'CONFIG_PM6_DriftSamplingPeriod', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_PM7_AscentSamplingPeriod', 'ASC_PROFILE_PERIOD', ...
         'CONFIG_PM8_DriftDepth', 'PARKING_PRESSURE', ...
         'CONFIG_PM9_ProfileDepth', 'DEEPEST_PRESSURE', ...
         'CONFIG_PM10_ThresholdSurfaceMiddlePressure', 'INT_SURF_THRESHOLD', ...
         'CONFIG_PM11_ThresholdMiddleBottomPressure', 'DEPTH_INT_THRESHOLD', ...
         'CONFIG_PM12_ThicknessOfTheSurfaceSlices', 'SURF_SLICE_THICKNESS', ...
         'CONFIG_PM13_ThicknessOfTheMiddleSlices', 'INT_SLICE_THICKNESS', ...
         'CONFIG_PM14_ThicknessOfTheBottomSlices', 'DEPTH_SLICE_THICKNESS', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', 'TRANS_REPETITION', ...
         'CONFIG_PA1_ArgosEolPeriod', 'PRCFG_EOL_trans_period', ...
         'CONFIG_PA2_Retransmission', 'CONFIG_TeleRepetition_COUNT', ...
         'CONFIG_PA3_ArgosTransmissionDuration', 'CONFIG_TransMinTime_HOURS', ...
         'CONFIG_PA6_PreludeDuration', 'CONFIG_PreludeDuration_MINUTES', ...
         'CONFIG_PX0_Direction', 'DIRECTION');
   case {'4.42', '4.44', '4.45'}
      o_configStruct = struct( ...
         'CONFIG_PM0_NumberOfCycles', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_PM1_CyclePeriod', 'CYCLE_TIME', ...
         'CONFIG_PM2_ReferenceDay', 'PRCFG_Reference_day', ...
         'CONFIG_PM3_EstimatedSurfaceTime', 'PRCFG_End_time', ...
         'CONFIG_PM4_DelayBeforeMission', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_PM5_DescentSamplingPeriod', 'DESC_PROFILE_PERIOD', ...
         'CONFIG_PM6_DriftSamplingPeriod', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_PM7_AscentSamplingPeriod', 'ASC_PROFILE_PERIOD', ...
         'CONFIG_PM8_DriftDepth', 'PARKING_PRESSURE', ...
         'CONFIG_PM9_ProfileDepth', 'DEEPEST_PRESSURE', ...
         'CONFIG_PM10_ThresholdSurfaceMiddlePressure', 'INT_SURF_THRESHOLD', ...
         'CONFIG_PM11_ThresholdMiddleBottomPressure', 'DEPTH_INT_THRESHOLD', ...
         'CONFIG_PM12_ThicknessOfTheSurfaceSlices', 'SURF_SLICE_THICKNESS', ...
         'CONFIG_PM13_ThicknessOfTheMiddleSlices', 'INT_SLICE_THICKNESS', ...
         'CONFIG_PM14_ThicknessOfTheBottomSlices', 'DEPTH_SLICE_THICKNESS', ...
         'CONFIG_PT20_CTDPumpSwitchOffPres', 'CTD_CUT_OFF_PRESSURE', ...
         'CONFIG_PA0_ArgosTransmissionPeriod', 'TRANS_REPETITION', ...
         'CONFIG_PA1_ArgosEolPeriod', 'PRCFG_EOL_trans_period', ...
         'CONFIG_PA2_Retransmission', 'CONFIG_TeleRepetition_COUNT', ...
         'CONFIG_PA3_ArgosTransmissionDuration', 'CONFIG_TransMinTime_HOURS', ...
         'CONFIG_PA6_PreludeDuration', 'CONFIG_PreludeDuration_MINUTES', ...
         'CONFIG_PX0_Direction', 'DIRECTION');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta for dacFormatId %s\n', a_dacFormatId);
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
