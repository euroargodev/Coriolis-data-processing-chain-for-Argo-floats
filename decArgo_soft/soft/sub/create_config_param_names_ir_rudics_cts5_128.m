% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames, o_ncConfParamIds] = ...
%    create_config_param_names_ir_rudics_cts5_128
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%    o_decArgoConfParamNames : internal configuration parameter names
%    o_ncConfParamNames      : NetCDF configuration parameter names
%    o_ncConfParamIds        : NetCDF configuration parameter Ids
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames, o_ncConfParamIds] = ...
   create_config_param_names_ir_rudics_cts5_128

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];
o_ncConfParamIds = [];

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% max index for misc configuration parameters (CONFIG_PX)
global g_decArgo_configPxMaxT;
global g_decArgo_configPxMaxS;
global g_decArgo_configPxMaxP;
global g_decArgo_configPxMaxI;
global g_decArgo_configPxMaxK;


% APMT configuration parameters

% sensor names
apmtSensorList = [ ...
   {'Ctd'}
   {'Optode'}
   {'Ocr'}
   {'Eco'}
   {'Sfet'}
   {'Crover'}
   {'Suna'}
   {'Uvp'}
   {'Opus'}
   {'Ramses'}
   {'Mpe'}
   {'Hydroc'}
   ];

% create configuration names for decoder and associated one for NetCDF
decConfNames = [];
ncConfNames = [];
ncConfIds = [];
configInfoList = [ ...
   {'SYSTEM'} {0:12} {[100:102 300 103:111]}; ...
   {'TECHNICAL'} {0:22} {112:134}; ...
   {'PATTERN_'} {1:6} {135:140}; ...
   {'ALARM'} {[0:5 9 10 16 21]} {141:150}; ...
   {'TEMPORIZATION'} {0:3} {151:154}; ...
   {'END_OF_LIFE'} {1:3} {155:157}; ...
   {'SECURITY'} {0:4} {[158:161 241]}; ...
   {'SURFACE_APPROACH'} {1} {162}; ...
   {'SURFACE_ACQUISITION'} {0:1} {249:250}; ...
   {'ICE'} {1:3} {274:276}; ...
   {'ICE_AVOIDANCE'} {1:4} {262:265}; ...
   {'ISA'} {1:4} {266:269}; ...
   {'IRIDIUM_RUDICS'} {[0:1 3:8]} {[301:303 166:169 277]}; ...
   {'MOTOR'} {0:1} {[304 170]}; ...
   {'PAYLOAD'} {0:3} {[305 306 171 172]}; ...
   {'EMAP_1'} {0:2} {310:312}; ...
   {'GPS'} {0:4} {[307 308 173 174 242]}; ...
   {'SENSOR_'} {[]} {[]}; ... % see below
   {'SPECIAL'} {0:1} {244:245}; ...
   {'PRESSURE_ACTIVATION'} {0:2} {246:248}; ...
   {'BATTERY'} {0:3} {189:192}; ...
   {'PRESSURE_I'} {0:3} {193:196}; ...
   {'SBE41'} {0} {309}; ...
   {'DO'} {0} {313}; ...
   {'OCR'} {0} {314}; ...
   {'ECO'} {0} {315}; ...
   {'SBEPH'} {0} {330}; ...
   {'CROVER'} {0} {331}; ...
   {'SUNA'} {0} {332}; ...
   {'UVP6'} {0} {316}; ...
   {'OPUS'} {0} {333}; ...
   {'RAMSES'} {0} {339}; ...
   {'MPE'} {0} {340}; ...
   {'HYDROC'} {0} {350} ...
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
            ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
         end
      end
   elseif (strcmp(section, 'SENSOR_'))
      for idS = 1:length(apmtSensorList)
         paramNumList = 1:9;
         paramIdList = 175:183;
         sensorNum = idS;
         if (idS == 8) % <short_sensor_name> = 'Uvp'
            paramIdList = paramIdList + 1000;
         end
         if (idS == 9) % <short_sensor_name> = 'Opus'
            paramIdList = paramIdList + 1100;
            sensorNum = 15;
         end
         if (idS == 10) % <short_sensor_name> = 'Ramses'
            paramIdList = paramIdList + 1200;
            sensorNum = 14;
         end
         if (idS == 11) % <short_sensor_name> = 'Mpe'
            paramIdList = paramIdList + 1300;
            sensorNum = 17;
         end
         if (idS == 12) % <short_sensor_name> = 'Hydroc'
            paramIdList = paramIdList + 1400;
            sensorNum = 18;
         end
         for idZ = 1:5
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (idZ-1)*9 + paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
                  [{'<short_sensor_name>'} {apmtSensorList{idS}} {'<N>'} {num2str(idZ)}]);
               ncConfNames{end+1} = paramName;
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
         end
         paramNumList = 46;
         paramIdList = 184;
         if (idS == 8) % <short_sensor_name> = 'Uvp'
            paramIdList = paramIdList + 1000;
         end
         if (idS == 9) % <short_sensor_name> = 'Opus'
            paramIdList = paramIdList + 1100;
         end
         if (idS == 10) % <short_sensor_name> = 'Ramses'
            paramIdList = paramIdList + 1200;
         end
         if (idS == 11) % <short_sensor_name> = 'Mpe'
            paramIdList = paramIdList + 1300;
         end
         if (idS == 12) % <short_sensor_name> = 'Hydroc'
            paramIdList = paramIdList + 1400;
         end
         for idZ = 1:4
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (idZ-1) + paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
                  [{'<short_sensor_name>'} {apmtSensorList{idS}} {'<N>'} {num2str(idZ)} {'<N+1>'} {num2str(idZ+1)}]);
               ncConfNames{end+1} = paramName;
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
         end
         paramNumList = [50:52 60];
         paramIdList = [185:187 251];
         if (idS == 8) % <short_sensor_name> = 'Uvp'
            paramIdList = paramIdList + 1000;
         end
         if (idS == 9) % <short_sensor_name> = 'Opus'
            paramIdList = paramIdList + 1100;
         end
         if (idS == 10) % <short_sensor_name> = 'Ramses'
            paramIdList = paramIdList + 1200;
         end
         if (idS == 11) % <short_sensor_name> = 'Mpe'
            paramIdList = paramIdList + 1300;
         end
         if (idS == 12) % <short_sensor_name> = 'Hydroc'
            paramIdList = paramIdList + 1400;
         end
         for idP = 1:length(paramNumList)
            decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, paramNumList(idP));
            idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
            paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
               [{'<short_sensor_name>'} {apmtSensorList{idS}}]);
            ncConfNames{end+1} = paramName;
            ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
         end
         if (idS == 1) % <short_sensor_name> = 'Ctd'
            paramNumList = [54 55];
            paramIdList = [188 243];
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
         elseif (idS == 8) % <short_sensor_name> = 'Uvp'
            paramNumList = 54;
            paramIdList = 252;
            for idZ = 1:5
               for idP = 1:length(paramNumList)
                  decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (idZ-1) + paramNumList(idP));
                  idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
                  paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
                     [{'<N>'} {num2str(idZ)}]);
                  ncConfNames{end+1} = paramName;
                  ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
               end
            end
            paramNumList = [59 61 62];
            paramIdList = 253:255;
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
         elseif (idS == 9) % <short_sensor_name> = 'Opus'
            paramNumList = [54:57];
            paramIdList = [256:259];
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
            paramNumList = [61 66];
            paramIdList = [260 261];
            for idZ = 1:5
               for idP = 1:length(paramNumList)
                  decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (idZ-1) + paramNumList(idP));
                  idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
                  paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
                     [{'<N>'} {num2str(idZ)}]);
                  ncConfNames{end+1} = paramName;
                  ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
               end
            end
         elseif (idS == 10) % <short_sensor_name> = 'Ramses'
            paramNumList = [54:56];
            paramIdList = [271:273];
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
         elseif (idS == 12) % <short_sensor_name> = 'Hydroc'
            paramNumList = [54:59];
            paramIdList = [278:283];
            for idP = 1:length(paramNumList)
               decConfNames{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, paramNumList(idP));
               idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
               ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
            end
         end
      end
   else
      for idP = 1:length(paramNumList)
         decConfNames{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNumList(idP));
         idParamName = find(g_decArgo_outputNcConfParamId == paramIdList(idP));
         ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
         ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
      end
   end
end

% misc sensor static configuration parameters
for idT = 0:g_decArgo_configPxMaxT
   for idS = 0:g_decArgo_configPxMaxS
      for idP = 0:g_decArgo_configPxMaxP
         for idI = 0:g_decArgo_configPxMaxI
            for idK = 0:g_decArgo_configPxMaxK
               if (idS < 10)
                  paramNum = 100000 + idK + idI*10 + idP*100 + idS*1000 + idT*10000;
               else
                  paramNum = 1000000 + idK + idI*10 + idP*100 + idS*1000 + idT*100000;
               end
               idParamName = find(g_decArgo_outputNcConfParamId == paramNum);
               if (~isempty(idParamName))
                  decConfNames{end+1} = sprintf('CONFIG_PX_%d_%d_%d_%d_%d', idT, idS, idP, idI, idK);
                  ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
                  ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
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
o_ncConfParamIds = ncConfIds;

return
