% ------------------------------------------------------------------------------
% Check meta-data transmitted in TECH file against BDD contents
%
% SYNTAX :
%    check_pfv2_tech_vs_bdd%
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
%   14/11/2024 - RNU - creation
% ------------------------------------------------------------------------------
function check_pfv2_tech_vs_bdd

% current float WMO number
global g_decArgo_floatNum;

% management of meta-data transmitted in TECH files
global g_decArgo_metaFromTech

% json meta-data
global g_decArgo_jsonMetaData;

% file to store BDD update
global g_decArgo_bddUpdateCsvFileName;
global g_decArgo_bddUpdateCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;


for idT = 1:length(g_decArgo_metaFromTech.techId)
   switch g_decArgo_metaFromTech.techId(idT)
      case 0
         % FLOAT_SERIAL_NO
         if (~strcmp(g_decArgo_jsonMetaData.FLOAT_SERIAL_NO, g_decArgo_metaFromTech.value{idT}))
            if (g_decArgo_bddUpdateCsvFileId == -1)
               % output CSV file creation
               g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
               g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
               if (g_decArgo_bddUpdateCsvFileId == -1)
                  fprintf('ERROR: Float #%d: Unable to create CSV output file: %s\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_bddUpdateCsvFileName);
                  return
               end

               header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
               fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
            end

            paramId = 392;
            dimLevel = 1;
            paramCode = 'INST_REFERENCE';

            fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
               g_decArgo_floatNum, ...
               paramId, dimLevel, g_decArgo_metaFromTech.value{idT}, paramCode);

            fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'') and configuration value (''%s'') differ - BDD contents should be updated (see %s)\n', ...
               g_decArgo_floatNum, ...
               paramCode, ...
               g_decArgo_metaFromTech.value{idT}, ...
               g_decArgo_jsonMetaData.FLOAT_SERIAL_NO, ...
               g_decArgo_bddUpdateCsvFileName);
         end
      case 1
         % FIRMWARE_VERSION
         if (~strcmp(g_decArgo_jsonMetaData.FIRMWARE_VERSION, g_decArgo_metaFromTech.value{idT}))
            if (g_decArgo_bddUpdateCsvFileId == -1)
               % output CSV file creation
               g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
               g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
               if (g_decArgo_bddUpdateCsvFileId == -1)
                  fprintf('ERROR: Float #%d: Unable to create CSV output file: %s\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_bddUpdateCsvFileName);
                  return
               end

               header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
               fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
            end

            paramId = 961;
            dimLevel = 1;
            paramCode = 'FIRMWARE_VERSION';

            fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
               g_decArgo_floatNum, ...
               paramId, dimLevel, g_decArgo_metaFromTech.value{idT}, paramCode);

            fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'') and configuration value (''%s'') differ - BDD contents should be updated (see %s)\n', ...
               g_decArgo_floatNum, ...
               paramCode, ...
               g_decArgo_metaFromTech.value{idT}, ...
               g_decArgo_jsonMetaData.FIRMWARE_VERSION, ...
               g_decArgo_bddUpdateCsvFileName);
         end
      case 600201
         % Aanderaa4330 serial number
         if (isfield(g_decArgo_jsonMetaData, 'SENSOR') && isfield(g_decArgo_jsonMetaData, 'SENSOR_SERIAL_NO'))
            idOptode = find(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR), 'OPTODE_DOXY'));
            if (~isempty(idOptode))
               sensorSnList = struct2cell(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO);
               optodeSn = sensorSnList{idOptode};
               if (~strcmp(optodeSn, g_decArgo_metaFromTech.value{idT}))
                  if (g_decArgo_bddUpdateCsvFileId == -1)
                     % output CSV file creation
                     g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                     g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
                     if (g_decArgo_bddUpdateCsvFileId == -1)
                        fprintf('ERROR: Float #%d: Unable to create CSV output file: %s\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_bddUpdateCsvFileName);
                        return
                     end

                     header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
                  end

                  paramId = 411;
                  dimLevel = 101;
                  paramCode = 'SENSOR_SERIAL_NO';

                  fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                     g_decArgo_floatNum, ...
                     paramId, dimLevel, g_decArgo_metaFromTech.value{idT}, paramCode);

                  fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'' for SENSOR ''%s'') and configuration value (''%s'') differ - BDD contents should be updated (see %s)\n', ...
                     g_decArgo_floatNum, ...
                     paramCode, ...
                     g_decArgo_metaFromTech.value{idT}, ...
                     'OPTODE_DOXY', ...
                     optodeSn, ...
                     g_decArgo_bddUpdateCsvFileName);
               end
            end
         end
      case 600308
         % RBRargo3 serial number
         if (isfield(g_decArgo_jsonMetaData, 'SENSOR') && isfield(g_decArgo_jsonMetaData, 'SENSOR_SERIAL_NO'))
            sensorSnList = struct2cell(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO);
            for idS = 1:3
               if (idS == 1)
                  sensorName = 'CTD_PRES';
               elseif (idS == 2)
                  sensorName = 'CTD_TEMP';
               elseif (idS == 3)
                  sensorName = 'CTD_CNDC';
               end

               idSensor = find(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR), sensorName));
               if (~isempty(idSensor))
                  sensorSn = sensorSnList{idSensor};
                  if (~strcmp(sensorSn, g_decArgo_metaFromTech.value{idT}))
                     if (g_decArgo_bddUpdateCsvFileId == -1)
                        % output CSV file creation
                        g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                        g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
                        if (g_decArgo_bddUpdateCsvFileId == -1)
                           fprintf('ERROR: Float #%d: Unable to create CSV output file: %s\n', ...
                              g_decArgo_floatNum, ...
                              g_decArgo_bddUpdateCsvFileName);
                           return
                        end

                        header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                        fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
                     end

                     paramId = 411;
                     dimLevel = idS;
                     paramCode = 'SENSOR_SERIAL_NO';

                     fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                        g_decArgo_floatNum, ...
                        paramId, dimLevel, g_decArgo_metaFromTech.value{idT}, paramCode);

                     fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'' for SENSOR ''%s'') and configuration value (''%s'') differ - BDD contents should be updated (see %s)\n', ...
                        g_decArgo_floatNum, ...
                        paramCode, ...
                        g_decArgo_metaFromTech.value{idT}, ...
                        sensorName, ...
                        sensorSn, ...
                        g_decArgo_bddUpdateCsvFileName);
                  end
               end
            end
         end
      case 611601
         % SBE41 serial number
         if (isfield(g_decArgo_jsonMetaData, 'SENSOR') && isfield(g_decArgo_jsonMetaData, 'SENSOR_SERIAL_NO'))
            idCtdTemp = find(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR), 'CTD_TEMP'));
            if (~isempty(idCtdTemp))
               sensorSnList = struct2cell(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO);
               ctdTempSn = sensorSnList{idCtdTemp};
               if (~strcmp(ctdTempSn, g_decArgo_metaFromTech.value{idT}))
                  if (g_decArgo_bddUpdateCsvFileId == -1)
                     % output CSV file creation
                     g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                     g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
                     if (g_decArgo_bddUpdateCsvFileId == -1)
                        fprintf('ERROR: Float #%d: Unable to create CSV output file: %s\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_bddUpdateCsvFileName);
                        return
                     end

                     header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
                  end

                  paramId = 411;
                  dimLevel = 2;
                  paramCode = 'SENSOR_SERIAL_NO';

                  fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                     g_decArgo_floatNum, ...
                     paramId, dimLevel, g_decArgo_metaFromTech.value{idT}, paramCode);

                  fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'' for SENSOR ''%s'') and configuration value (''%s'') differ - BDD contents should be updated (see %s)\n', ...
                     g_decArgo_floatNum, ...
                     paramCode, ...
                     g_decArgo_metaFromTech.value{idT}, ...
                     'CTD_TEMP', ...
                     ctdTempSn, ...
                     g_decArgo_bddUpdateCsvFileName);
               end
            end
            idCtdCndc = find(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR), 'CTD_CNDC'));
            if (~isempty(idCtdCndc))
               sensorSnList = struct2cell(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO);
               ctdCndcSn = sensorSnList{idCtdCndc};
               if (~strcmp(ctdCndcSn, g_decArgo_metaFromTech.value{idT}))
                  if (g_decArgo_bddUpdateCsvFileId == -1)
                     % output CSV file creation
                     g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                     g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
                     if (g_decArgo_bddUpdateCsvFileId == -1)
                        fprintf('ERROR: Float #%d: Unable to create CSV output file: %s\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_bddUpdateCsvFileName);
                        return
                     end

                     header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                     fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
                  end

                  paramId = 411;
                  dimLevel = 3;
                  paramCode = 'SENSOR_SERIAL_NO';

                  fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                     g_decArgo_floatNum, ...
                     paramId, dimLevel, g_decArgo_metaFromTech.value{idT}, paramCode);

                  fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'' for SENSOR ''%s'') and configuration value (''%s'') differ - BDD contents should be updated (see %s)\n', ...
                     g_decArgo_floatNum, ...
                     paramCode, ...
                     g_decArgo_metaFromTech.value{idT}, ...
                     'CTD_CNDC', ...
                     ctdCndcSn, ...
                     g_decArgo_bddUpdateCsvFileName);
               end
            end
         end

      otherwise
         fprintf('ERROR: Float #%d: Unable to manage CSV vs BDD comparison for techId %d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_metaFromTech.techId(idT));
   end
end

return
