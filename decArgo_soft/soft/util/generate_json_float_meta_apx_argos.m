% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in
% individual json files.
%
% SYNTAX :
%  generate_json_float_meta_apx_argos()
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
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_argos()

% meta-data file exported from Coriolis data base
floatMetaFileName = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\export_meta_APEX_from_VB_20150703.txt';

fprintf('Generating json meta-data files from input file: %s\n', floatMetaFileName);

% list of concerned floats
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071412.txt';

fprintf('Generating json meta-data files for floats of the list: %s\n', floatListFileName);

% directory of individual json float meta-data files
outputDirName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_apx_argos_' datestr(now, 'yyyymmddTHHMMSS')];


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
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the same number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the same number of digits
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
% floatList = [6901233];

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
   
   configBddStruct = get_config_bdd_struct(dacFormatId);
   configBddStructNames = fieldnames(configBddStruct);
   
   nbConfig = 1;
   configParamVal = cell(length(configStructNames), nbConfig);
   configRepRate = cell(1, nbConfig);
   for idConf = 1:nbConfig
      configRepRate{1, idConf} = '1';
      for idBSN = 1:length(configBddStructNames)
         configBddStructName = configBddStructNames{idBSN};
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
               
               if (strcmp(configBddStructValue, 'DIRECTION') == 1)
                  bddValue = metaData{idForWmo(idF(idDim)), 4};
                  if (~isempty(bddValue))
                     if (bddValue == 'A')
                        configParamVal{idBSN, idConf} = '1';
                     elseif (bddValue == 'B')
                        configParamVal{idBSN, idConf} = '3';
                     elseif (bddValue == 'D')
                        configParamVal{idBSN, idConf} = '2';
                     else
                        fprintf('ERROR: inconsistent BDD value (''%s'') for ''%s'' information => not considered\n', ...
                           bddValue, 'DIRECTION');
                     end
                  end
               elseif (strcmp(configBddStructValue, 'DEEP_PROFILE_FIRST') == 1)
                  bddValue = metaData{idForWmo(idF(idDim)), 4};
                  if (~isempty(bddValue))
                     if ((strcmpi(bddValue, 'yes')) || (strcmpi(bddValue, 'y')))
                        configParamVal{idBSN, idConf} = '1';
                     elseif ((strcmpi(bddValue, 'no')) || (strcmpi(bddValue, 'n')))
                        configParamVal{idBSN, idConf} = '0';
                     else
                        fprintf('ERROR: inconsistent BDD value (''%s'') for ''%s'' information => not considered\n', ...
                           bddValue, 'DEEP_PROFILE_FIRST');
                     end
                  end
               else
                  configParamVal{idBSN, idConf} = metaData{idForWmo(idF(idDim)), 4};
               end

            end
         else
            % if we want to use default values if the information is
            % missing in the database
         end
      end
   end
   
   %    % we create all configuration from data base information
   %    nbConfig = 1;
   %    idFRepRate = find(strcmp(metaData(idForWmo, 5), 'REPETITION_RATE') == 1);
   %    if (~isempty(idFRepRate))
   %       repRate = str2num(metaData(idForWmo(idFRepRate), 4));
   %       if (repRate > 1)
   %          nbConfig = nbConfig + 1;
   %          fprintf('Multi conf: %d\n', floatList(idFloat));
   %       end
   %    end
   %    dpfFloat = 0;
   %    idFDpf = find(strcmp(metaData(idForWmo, 5), 'DPF_FLOAT') == 1);
   %    if (~isempty(idFDpf))
   %       dpfFloat = str2num(metaData(idForWmo(idFDpf), 4));
   %       if (dpfFloat == 1)
   %          nbConfig = nbConfig + 1;
   %          fprintf('DPF float: %d\n', floatList(idFloat));
   %       end
   %    end

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
function [o_configStruct] = get_config_init_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'071412'}
      o_configStruct = struct( ...
         'CONFIG_CT_CycleTime', '', ...
         'CONFIG_UP_UpTime', '', ...
         'CONFIG_DOWN_DownTime', '', ...
         'CONFIG_PRKP_ParkPressure', '', ...
         'CONFIG_TP_ProfilePressure', '', ...
         'CONFIG_N_ParkAndProfileCycleLength', '', ...
         'CONFIG_DIR_ProfilingDirection', '', ...
         'CONFIG_DPF_DeepProfileFirstFloat', '', ...
         'CONFIG_PRE_MissionPreludePeriod', '', ...
         'CONFIG_PDP_ParkDescentPeriod', '', ...
         'CONFIG_DPDP_DeepProfileDescentPeriod', '', ...
         'CONFIG_ASCEND_AscentTimeOut', '', ...
         'CONFIG_REP_ArgosTransmissionRepetitionPeriod', '', ...
         'CONFIG_TOD_DownTimeExpiryTimeOfDay', '', ...
         'CONFIG_PACT_PressureActivationPistonPosition', '', ...
         'CONFIG_PPP_ParkPistonPosition', '', ...
         'CONFIG_TPP_ProfilePistonPosition', '', ...
         'CONFIG_FEXT_PistonFullExtension', '', ...
         'CONFIG_FRET_PistonFullRetraction', '', ...
         'CONFIG_NUDGE_AscentBuoyancyNudge', '', ...
         'CONFIG_IBN_InitialBuoyancyNudge', '', ...
         'CONFIG_OK_OkInternalVacuum', '', ...
         'CONFIG_TBP_MaxAirBladderPressure', '', ...
         'CONFIG_CHR_CompensatorHyperRetraction', '', ...
         'CONFIG_DEBUG_LogVerbosity', '');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_apx_argos for dacFormatId %s\n', a_dacFormatId);
end

return;

% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_bdd_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'071412'}
      o_configStruct = struct( ...
         'CONFIG_CT_CycleTime', 'CYCLE_TIME', ...
         'CONFIG_UP_UpTime', 'MissionCfgUpTime', ...
         'CONFIG_DOWN_DownTime', 'MissionCfgDownTime', ...
         'CONFIG_PRKP_ParkPressure', 'PARKING_PRESSURE', ...
         'CONFIG_TP_ProfilePressure', 'DEEPEST_PRESSURE', ...
         'CONFIG_N_ParkAndProfileCycleLength', 'MissionCfgParkAndProfileCount', ...
         'CONFIG_DIR_ProfilingDirection', 'DIRECTION', ...
         'CONFIG_DPF_DeepProfileFirstFloat', 'DEEP_PROFILE_FIRST', ...
         'CONFIG_PRE_MissionPreludePeriod', 'MissionPreludePeriod', ...
         'CONFIG_PDP_ParkDescentPeriod', 'ParkDescentPeriod', ...
         'CONFIG_DPDP_DeepProfileDescentPeriod', 'DeepProfileDescentPeriod', ...
         'CONFIG_ASCEND_AscentTimeOut', 'MissionCfgAscentTimeoutPeriod', ...
         'CONFIG_REP_ArgosTransmissionRepetitionPeriod', 'TRANS_REPETITION', ...
         'CONFIG_TOD_DownTimeExpiryTimeOfDay', 'PRCFG_TimeOfDay', ...
         'CONFIG_PACT_PressureActivationPistonPosition', 'PressureActivationPistonPosition', ...
         'CONFIG_PPP_ParkPistonPosition', 'MissionCfgParkPistonPosition', ...
         'CONFIG_TPP_ProfilePistonPosition', 'MissionCfgTargetProfilePistonPos', ...
         'CONFIG_FEXT_PistonFullExtension', 'FullyExtendedPistonPos', ...
         'CONFIG_FRET_PistonFullRetraction', 'RetractedPistonPos', ...
         'CONFIG_NUDGE_AscentBuoyancyNudge', 'MissionCfgBuoyancyNudge', ...
         'CONFIG_IBN_InitialBuoyancyNudge', 'InitialBuoyancyNudge', ...
         'CONFIG_OK_OkInternalVacuum', 'MissionCfgOKVacuumCount', ...
         'CONFIG_TBP_MaxAirBladderPressure', 'MissionCfgMaxAirBladderPressure', ...
         'CONFIG_CHR_CompensatorHyperRetraction', 'CompensatorHyperRetraction', ...
         'CONFIG_DEBUG_LogVerbosity', 'PRCFG_Verbosity');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_apx_argos for dacFormatId %s\n', a_dacFormatId);
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
   'STARTUP_DATE', 'STARTUP_DATE', ...
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
