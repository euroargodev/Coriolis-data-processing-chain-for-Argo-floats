% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_rudics_cts5_124_125
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%    o_decArgoConfParamNames : internal configuration parameter names
%    o_ncConfParamNames      : NetCDF configuration parameter names
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_rudics_cts5_124_125

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];

% current float WMO number
global g_decArgo_floatNum;

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% float configuration
global g_decArgo_floatConfig;

% Id of the first payload configuration parameter
global g_decArgo_firstPayloadConfigParamId


% APMT configuration parameters

% sensor names
apmtSensorList = [ ...
   {'CTD'}
   ];

% create configuration names for decoder and associated one for NetCDF
decConfNames = [];
ncConfNames = [];
configInfoList = [ ...
   {'SYSTEM'} {0:12} {[100:102 300 103:111]}; ...
   {'TECHNICAL'} {0:22} {112:134}; ...
   {'PATTERN_'} {1:6} {135:140}; ...
   {'ALARM'} {[0:5 9 10 16 21]} {141:150}; ...
   {'TEMPORIZATION'} {0:3} {151:154}; ...
   {'END_OF_LIFE'} {1:3} {155:157}; ...
   {'SECURITY'} {0:4} {[158:161 241]}; ...
   {'SURFACE_APPROACH'} {1} {162}; ...
   {'ICE'} {1:3} {163:165}; ...
   {'IRIDIUM_RUDICS'} {[0:1 3:7]} {[301:303 166:169]}; ...
   {'MOTOR'} {0:1} {[304 170]}; ...
   {'PAYLOAD'} {0:3} {[305 306 171 172]}; ...
   {'GPS'} {0:4} {[307 308 173 174 242]}; ...
   {'SENSOR_'} {[]} {[]}; ... % see below
   {'SPECIAL'} {0:1} {244:245}; ...
   {'PRESSURE_ACTIVATION'} {0:2} {246:248}; ...
   {'BATTERY'} {0:3} {189:192}; ...
   {'PRESSURE_I'} {0:3} {193:196}; ...
   {'SBE41'} {0} {309} ...
   ];
for idConfig = 1:length(configInfoList)
   section = configInfoList{idConfig, 1};
   paramNumList = configInfoList{idConfig, 2};
   paramIdList = configInfoList{idConfig, 3};
   if (strcmp(section, 'PATTERN_'))
      for patternNum = 1:10
         for idP = 1:length(paramNumList)
            decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, patternNum, paramNumList(idP));
            idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
            ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         end
      end
   elseif (strcmp(section, 'SENSOR_'))
      for idS = 1:length(apmtSensorList)
         paramNumList = 1:9;
         paramIdList = 175:183;
         for idZ = 1:5
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, idS, (idZ-1)*9 + paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
                  [{'<short_sensor_name>'} {apmtSensorList{idS}} {'<N>'} {num2str(idZ)}]);
               ncConfNames{end+1} = paramName;
            end
         end
         paramNumList = 46;
         paramIdList = 184;
         for idZ = 1:4
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, idS, (idZ-1) + paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
                  [{'<short_sensor_name>'} {apmtSensorList{idS}} {'<N>'} {num2str(idZ)} {'<N+1>'} {num2str(idZ+1)}]);
               ncConfNames{end+1} = paramName;
            end
         end
         paramNumList = 50:52;
         paramIdList = 185:187;
         for idP = 1:length(paramNumList)
            decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, idS, paramNumList(idP));
            idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
            paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
               [{'<short_sensor_name>'} {apmtSensorList{idS}}]);
            ncConfNames{end+1} = paramName;
         end
         if (idS == 1)
            paramNumList = [54 55];
            paramIdList = [188 243];
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, idS, paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
            end
         end
      end
   else
      for idP = 1:length(paramNumList)
         decConfNames{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNumList(idP));
         idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
   end
end

% PAYLOAD configuration parameters

if (g_decArgo_firstPayloadConfigParamId > 0)
   
   % get configuration names
   configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
   
   % get payload configuration names
   configNames = configNames(g_decArgo_firstPayloadConfigParamId:end);
   
   % sensor names
   payloadSensorList = [ ...
      {1} {'Optode'}; ...
      {2} {'Ocr'}; ...
      {3} {'Eco'}; ...
      {6} {'Suna'}; ...
      {7} {'Sfet'}; ...
      {101} {'Psa916'}; ...
      {102} {'OptTak'}; ...
      {103} {'Ocr507Uart1'}; ...
      {104} {'Ocr507Uart2'}; ...
      {105} {'EcoPuck'}; ...
      {106} {'Tilt'}; ...
      {107} {'Uvp'} ...
      ];
   phaseName = [ ...
      {'BuoyancyReductionPhase'}; ...
      {'DescentToParkPhase'}; ...
      {'ParkDriftPhase'}; ...
      {'DescentToProfPhase'}; ...
      {'ProfDriftPhase'}; ...
      {'AscentPhase'}; ...
      {'SurfaceDriftPhase'} ...
      ];
   vpList = [1 2 4 6];
   paramNumListSensorVp = 0:8;
   paramIdListSensorVp = 223:231;
   hpList = [3 5 7];
   paramNumListSensorHp = 0:8;
   paramIdListSensorHp = 232:240;
   posSensor = length('CONFIG_PAYLOAD_USED_SENSOR_') + 1;
   paramNumListIsa = 0:8;
   paramIdListIsa = 197:205;
   posIsa = length('CONFIG_PAYLOAD_USED_ISA_P') + 1;
   paramNumListAid = 0:14;
   paramIdListAid = 206:220;
   posAid = length('CONFIG_PAYLOAD_USED_AID_P') + 1;
   paramNumListAc1 = 0:1;
   paramIdListAc1 = 221:222;
   posAc1 = length('CONFIG_PAYLOAD_USED_AC1_P') + 1;
   for idP = 1:length(configNames)
      configName = configNames{idP};
      if (strncmp(configName, 'CONFIG_PAYLOAD_USED_SENSOR_', length('CONFIG_PAYLOAD_USED_SENSOR_')))
         sensorNum = str2num(configName(posSensor:posSensor+1));
         sensorNum = convert_payload_sensor_number(sensorNum);
         sensorNumId = find([payloadSensorList{:, 1}] == sensorNum, 1);
         if (isempty(sensorNumId))
            fprintf('ERROR: Float #%d: Sensor number #%d not declared in payloadSensorList of create_config_param_names_ir_rudics_cts5\n', ...
               g_decArgo_floatNum, ...
               sensorNum);
         end
         paramNum = str2num(configName(posSensor+4:posSensor+5));
         phaseNum = str2num(configName(posSensor+9:posSensor+10));
         if (ismember(phaseNum, vpList))
            paramId = paramIdListSensorVp(find(paramNumListSensorVp == paramNum, 1));
            templateName = '<vertical_phase_name>';
         elseif (ismember(phaseNum, hpList))
            paramId = paramIdListSensorHp(find(paramNumListSensorHp == paramNum, 1));
            templateName = '<horizontal_phase_name>';
         end
         decConfNames{end+1} = configName;
         idParamName = find(g_decArgo_outputNcConfParamId == paramId);
         paramName = g_decArgo_outputNcConfParamLabel{idParamName};
         if (sensorNum > 100)
            paramName = regexprep(paramName, 'CONFIG_', 'CONFIG_AUX_'); % so that the configuration parameter will be in the final configuration table but with a prefix that can be used to move it to the META_AUX file 
         end
         switch (paramNum)
            case {0}
               paramName = create_param_name_ir_rudics_sbd2(paramName, ...
                  [{'<short_sensor_name>'} {payloadSensorList{sensorNumId, 2}} ...
                  {templateName} {phaseName{phaseNum}}]);
            case {1, 2, 3, 4, 5, 6}
               if (ismember(phaseNum, vpList))
                  idFUs = strfind(configName, '_');
                  depthZoneNum = configName(idFUs(7)+1:end);
                  paramName = create_param_name_ir_rudics_sbd2(paramName, ...
                     [{'<short_sensor_name>'} {payloadSensorList{sensorNumId, 2}} ...
                     {templateName} {phaseName{phaseNum}} ...
                     {'<N>'} {depthZoneNum}]);
               elseif (ismember(phaseNum, hpList))
                  idFUs = strfind(configName, '_');
                  samplingSchemeNum = configName(idFUs(7)+1:end);
                  paramName = create_param_name_ir_rudics_sbd2(paramName, ...
                     [{'<short_sensor_name>'} {payloadSensorList{sensorNumId, 2}} ...
                     {templateName} {phaseName{phaseNum}} ...
                     {'<S>'} {samplingSchemeNum}]);
               end
            case {7, 8}
               if (ismember(phaseNum, vpList))
                  idFUs = strfind(configName, '_');
                  depthZoneNum = configName(idFUs(7)+1:idFUs(8)-1);
                  subSamplingNum = configName(idFUs(8)+1:end);
                  paramName = create_param_name_ir_rudics_sbd2(paramName, ...
                     [{'<short_sensor_name>'} {payloadSensorList{sensorNumId, 2}} ...
                     {templateName} {phaseName{phaseNum}} ...
                     {'<N>'} {depthZoneNum} ...
                     {'<SubS>'} {subSamplingNum}]);
               elseif (ismember(phaseNum, hpList))
                  idFUs = strfind(configName, '_');
                  samplingSchemeNum = configName(idFUs(7)+1:idFUs(8)-1);
                  subSamplingNum = configName(idFUs(8)+1:end);
                  paramName = create_param_name_ir_rudics_sbd2(paramName, ...
                     [{'<short_sensor_name>'} {payloadSensorList{sensorNumId, 2}} ...
                     {templateName} {phaseName{phaseNum}} ...
                     {'<S>'} {samplingSchemeNum} ...
                     {'<SubS>'} {subSamplingNum}]);
               end
         end
         ncConfNames{end+1} = paramName;
      elseif (strncmp(configName, 'CONFIG_PAYLOAD_USED_ISA', length('CONFIG_PAYLOAD_USED_ISA')))
         paramNum = str2num(configName(posIsa:posIsa+1));
         paramId = paramIdListIsa(find(paramNumListIsa == paramNum, 1));
         decConfNames{end+1} = configName;
         idParamName = find(g_decArgo_outputNcConfParamId == paramId);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      elseif (strncmp(configName, 'CONFIG_PAYLOAD_USED_AID', length('CONFIG_PAYLOAD_USED_AID')))
         paramNum = str2num(configName(posAid:posAid+1));
         paramId = paramIdListAid(find(paramNumListAid == paramNum, 1));
         decConfNames{end+1} = configName;
         idParamName = find(g_decArgo_outputNcConfParamId == paramId);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      elseif (strncmp(configName, 'CONFIG_PAYLOAD_USED_AC1', length('CONFIG_PAYLOAD_USED_AC1')))
         paramNum = str2num(configName(posAc1:posAc1+1));
         paramId = paramIdListAc1(find(paramNumListAc1 == paramNum, 1));
         decConfNames{end+1} = configName;
         idParamName = find(g_decArgo_outputNcConfParamId == paramId);
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      end
   end
end

% misc sensor static configuration parameters
for idT = 0:3
   for idS = 0:7
      for idP = 0:1
         for idI = 0:3
            for idK = 0:8
               paramNum = 100000 + idK + idI*10 + idP*100 + idS*1000 + idT*10000;
               idParamName = find(g_decArgo_outputNcConfParamId == paramNum);
               if (~isempty(idParamName))
                  decConfNames{end+1} = sprintf('CONFIG_PX_%d_%d_%d_%d_%d', idT, idS, idP, idI, idK);
                  ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               end
            end
         end
      end
   end
end

% output for check
% for id = 1:length(decConfNames)
%    fprintf('%s;%s\n', decConfNames{id}, ncConfNames{id});
% end

% update output parameters
o_decArgoConfParamNames = decConfNames;
o_ncConfParamNames = ncConfNames;

return
